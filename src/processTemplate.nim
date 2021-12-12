## Process the template.

import std/streams
import std/os
import std/options
import std/tables
import args
import messages
import env
import matches
import readlines
import parseCmdLine
import collectCommand
import runCommand
import variables
import vartypes
import readjson
import replacement
# import tostring

template getNewLineBuffer(env: Env): untyped =
  ## Get a new line buffer for the environment's template.
  ## When there is not enough memory for the line buffer, generate a
  ## warning and return.
  let lineBufferO = newLineBuffer(env.templateStream,
      filename = env.templateFilename)
  if not lineBufferO.isSome():
    env.warn(0, wNotEnoughMemoryForLB)
    return
  lineBufferO.get()
  # var lb {.inject.} = lineBufferO.get()

iterator yieldContentLine*(content: string): string =
  ## Yield one content line at a time and keep the line endings.
  var start = 0
  for pos in 0 ..< content.len:
    let ch = content[pos]
    if ch == '\n':
      yield(content[start .. pos])
      start = pos+1
  if start < content.len:
    yield(content[start ..< content.len])

proc processTemplateLines(env: var Env, variables: var Variables,
                          prepostTable: PrepostTable) =
  ## Process the given template file.

  # Allocate a buffer for reading lines. Return when not enough memory.
  var lb = getNewLineBuffer(env)

  var inOutExtraLine: ExtraLine
  var firstReplaceLine: string

  # Read and process template lines.
  var tea = variables["t"].dictv
  while true:
    # Read template lines and write out non-commands lines. When a
    # command that needs processing is found, return its lines.
    let cmdLines = collectCommand(env, lb, prepostTable, inOutExtraLine)
    if inOutExtraLine.kind == elkOutOfLines:
      break

    if inOutExtraLine.kind == elkNormalLine:
      firstReplaceLine = inOutExtraLine.line
      inOutExtraLine = newNoLine()
    else:
      firstReplaceLine = ""

    let command = cmdLines.lineParts[0].command

    # Run the command the first time.
    var row = 0
    tea["row"] = newValue(row)
    runCommand(env, cmdLines, prepostTable, variables)

    # Show a warning when the replace command does not have t.content
    # set.
    if command == "replace" and not tea.contains("content"):
      # lineNum-1 because the current line number is at the first
      # replacement line.
      env.warn(lb.getLineNum()-1, wContentNotSet)

    let repeat = getTeaVarIntDefault(variables, "repeat")
    var maxLines = getTeaVarIntDefault(variables, "maxLines")

    # If repeat is 0, read the replacement lines and the endblock and
    # discard them.
    if repeat == 0:
      for replaceLine in yieldReplacementLine(env,
        firstReplaceLine, lb, prepostTable, command, maxLines):
        discard
      continue

    # Create a new TempSegments object for storing segments.
    var startLineNum = lb.getLineNum()
    var tempSegmentsO = newTempSegments(env, lb, prepostTable,
      command, repeat, variables)
    if not isSome(tempSegmentsO):
      break # Cannot create temp file or allocate memory, quit.
    var tempSegments = tempSegmentsO.get()

    var lastLine: ReplaceLine
    if command == "replace" and tea.contains("content"):
      # Discard the replacement block lines and the endblock.
      for replaceLine in yieldReplacementLine(env, firstReplaceLine,
          lb, prepostTable, command, maxLines):
        discard
      # Use the content as the replacement lines.
      var content = getVariable(variables, "t.content").value.stringv

      for line in yieldContentLine(content):
        storeLineSegments(env, tempSegments, prepostTable, line)
    else:
      # Read the replacement lines and store their compiled segments in
      # TempSegments.  Ignore the last line, the endblock, if it exists.
      for replaceLine in yieldReplacementLine(env,
          firstReplaceLine, lb, prepostTable, command, maxLines):
        lastLine = replaceLine
        if replaceLine.kind == rlReplaceLine:
          storeLineSegments(env, tempSegments, prepostTable, replaceLine.line)

    # Generate t.repeat number of replacement blocks. Recalculate the
    # variables for each one.
    var tea = variables["t"].dictv
    while true:
      # Write out all the stored replacement block lines and make the
      # variable substitutions.
      writeTempSegments(env, tempSegments, startLineNum, variables)

      # Increment the row variable.
      inc(row)
      if row >= repeat:
        break
      tea["row"] = newValue(row)

      # Run the command and fill in the variables.
      runCommand(env, cmdLines, prepostTable, variables)

    closeDelete(tempSegments)

    if lastLine.kind == rlNormalLine:
      inOutExtraLine = newNormalLine(lastLine.line)

proc updateTemplateLines(env: var Env, variables: var Variables,
                          prepostTable: PrepostTable) =
  ## Update the given template file.

  #[ Read template lines and write them out. Read command lines and
  write them out. Run the command to determine the t.content, then
  write out the t.content. Repeat.

  If the template is coming from a file, write the content to a temp
  file then rename it at the end overwriting the original template
  file.  If the template comes from standard in, write the new
  template to standard out. ]#

  # Allocate a buffer for reading lines. Return when no enough memory.
  var lb = getNewLineBuffer(env)

  # Read and process template lines.
  var tea = variables["t"].dictv
  var maxLines = getTeaVarIntDefault(variables, "maxLines")
  var inOutExtraLine: ExtraLine
  while true:
    # Read template lines and write out non-command lines. When a
    # replace command is found, collect its lines and return them.
    # ExtraLine is an input and output parameter.
    var cmdLines = collectReplaceCommand(env, lb, prepostTable, inOutExtraLine)
    if inOutExtraLine.kind == elkOutOfLines:
      break

    var firstReplaceLine: string
    if inOutExtraLine.kind == elkNormalLine:
      firstReplaceLine = inOutExtraLine.line
      inOutExtraLine = newNoLine()

    # Run the replace commands but not the others.
    let command = cmdLines.lineParts[0].command
    if command == "replace":
      # Run the command and fill in the variables.
      var row = 0
      tea["row"] = newValue(row)
      runCommand(env, cmdLines, prepostTable, variables)

    # Write out the command lines.
    for dumpLine in cmdLines.lines:
      env.resultStream.write(dumpLine)

    # Show a warning when the replace command does not have t.content set.
    if command == "replace" and not tea.contains("content"):
      # lineNum-1 because the current line number is at the first
      # replacement line.
      env.warn(lb.getLineNum()-1, wContentNotSet)

    if command == "replace" and tea.contains("content"):
      # Discard the replacement block lines and save the endblock if it exists.
      var lastLine: ReplaceLine
      for replaceLine in yieldReplacementLine(env,
          firstReplaceLine, lb, prepostTable, command, maxLines):
        lastLine = replaceLine

      # Write the content as the replacement lines.
      var valueOrWarning = getVariable(variables, "t.content")
      var content = valueOrWarning.value.stringv
      for line in yieldContentLine(content):
        env.resultStream.write(line)

      # If the content does not end with a newline, add one so the
      # endblock command starts on a newline.
      if content.len > 0 and content[^1] != '\n':
        env.resultStream.write('\n')

      # Write out the endblock, if it exists.
      if lastLine.kind == rlEndblockLine:
        env.resultStream.write(lastLine.line)
    else:
      # Read the replacement lines and endblock and write them out.
      for replaceLine in yieldReplacementLine(env,
          firstReplaceLine, lb, prepostTable, command, maxLines):
        env.resultStream.write(replaceLine.line)

proc readJsonFiles*(env: var Env, filenames: seq[string]): VarsDict =
  ## Read json files and return a variable dictionary.  Skip a
  ## duplicate variable and generate a warning.

  var varsDict = newVarsDict()
  for filename in filenames:
    let valueOrWarning = readJsonFile(filename)
    if valueOrWarning.kind == vwWarning:
      env.warn(0, valueOrWarning.warningData)
    else:
      # Merge in the variables.
      for k, v in valueOrWarning.value.dictv.pairs:
        if k in varsDict:
          # Skip the duplicates
          env.warn(0, wDuplicateVar, k)
        else:
          varsDict[k] = v
  result = varsDict

proc getStartingVariables(env: var Env, args: Args): Variables =
  ## Read and return the server and shared variables and setup the
  ## initial tea variables.

  # The tea variables are the top level items.  All variables are tea
  # variables in the sense that they all exists somewhere in this
  # dictionary.

  var serverVarDict = readJsonFiles(env, args.serverList)
  var sharedVarDict = readJsonFiles(env, args.sharedList)
  var argsVarDict = getTeaArgs(args).dictv

  result = emptyVariables(serverVarDict, sharedVarDict, argsVarDict)

proc getPrepostTable(args: Args): PrepostTable =
  ## Get the the prepost settings from the user or use the default
  ## ones.

  # Get the prepost table, either the user specified one or the
  # default one. The defaults are not used when the user specifies
  # them, so that they have complete control over the preposts used.
  if args.prepostList.len > 0:
    # The prepostList has been validated already.
    result = makeUserPrepostTable(args.prepostList)
  else:
    result = makeDefaultPrepostTable()

proc processTemplate*(env: var Env, args: Args): int =
  ## Process the template and return 0 on success. Return 1 if a
  ## warning messages was written while processing the template.

  var variables = getStartingVariables(env, args)
  var prepostTable = getPrepostTable(args)

  # Process the template.
  processTemplateLines(env, variables, prepostTable)

  if env.warningWritten > 0:
    result = 1

proc updateTemplate*(env: var Env, args: Args): int =
  ## Update the template and return 0 on success. Return 1 if a
  ## warning messages was written while processing the template.

  var variables = getStartingVariables(env, args)
  var prepostTable = getPrepostTable(args)

  # Process the template.
  updateTemplateLines(env, variables, prepostTable)

  if env.warningWritten > 0:
    result = 1

proc processTemplateTop*(env: var Env, args: Args): int =
  ## Setup the environment streams then process the template and
  ## return 0 on success.

  # Add the template and result streams to the environment.
  if not env.addExtraStreams(args):
    return 1

  # Process the template.
  result = processTemplate(env, args)

proc updateTemplateTop*(env: var Env, args: Args): int =
  ## Update the template and return 0 on success. This calls
  ## updateTemplate.

  # Add the template and result streams to the environment. Result
  # file is either a temp file or standard out.
  if not env.addExtraStreamsForUpdate(args):
    return 1

  # Update the template.
  result = updateTemplate(env, args)

  # When the template is coming from a file, update it from the temp
  # file.
  if env.templateFilename != "":

    # Close the template and result files.
    env.templateStream.close()
    env.templateStream = nil
    env.resultStream.close()
    env.resultStream = nil

    # Rename the temp file overwriting the template file.
    try:
      moveFile(env.resultFilename, env.templateFilename)
    except OSError:
      env.warn(0, wUnableToRenameTemp)
      # Delete the temp file.
      discard tryRemoveFile(env.resultFilename)
      result = 1
