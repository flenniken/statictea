## Process the template.

import std/streams
import std/os
import std/options
import std/tables
import std/strutils
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
import opresultwarn
import codefile
import runFunction

template getNewLineBuffer(env: Env): untyped =
  ## Get a new line buffer for the environment's template.
  ## When there is not enough memory for the line buffer, generate a
  ## warning and return.
  let lineBufferO = newLineBuffer(env.templateStream,
      filename=env.templateFilename)
  if not lineBufferO.isSome():
    # Not enough memory for the line buffer.
    env.warnNoFile(wNotEnoughMemoryForLB)
    return
  lineBufferO.get()

iterator yieldContentLine*(content: string): string =
  ## Yield one line at a time and keep the line endings.
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
  var loopControl = ""
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
    loopControl = runCommand(env, cmdLines, variables)

    # Show a warning when the replace command does not have t.content
    # set.
    if command == "replace" and not tea.contains("content"):
      # lineNum-1 because the current line number is at the first
      # replacement line.
      env.warn(lb.getFilename(), lb.getLineNum()-1, wContentNotSet)

    let repeat = getTeaVarIntDefault(variables, "repeat")
    var maxLines = getTeaVarIntDefault(variables, "maxLines")

    # If repeat is 0, read the replacement lines and the endblock and
    # discard them.
    if repeat == 0 or loopControl == "stop":
      for replaceLine in yieldReplacementLine(env,
        firstReplaceLine, lb, prepostTable, command, maxLines):
        discard
      continue

    # Create a new TempSegments object for storing segments.
    var startLineNum = lb.getLineNum()
    var tempSegmentsO = allocTempSegments(env, startLineNum)
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
        storeLineSegments(env, tempSegments, line)
    else:
      # Read the replacement lines and store their compiled segments in
      # TempSegments.  Ignore the last line, the endblock, if it exists.
      for replaceLine in yieldReplacementLine(env,
          firstReplaceLine, lb, prepostTable, command, maxLines):
        lastLine = replaceLine
        if replaceLine.kind == rlReplaceLine:
          storeLineSegments(env, tempSegments, replaceLine.line)

    # Generate t.repeat number of replacement blocks. Recalculate the
    # variables for each one.
    var tea = variables["t"].dictv
    while true:
      # Write out all the stored replacement block lines and make the
      # variable substitutions.
      if loopControl == "":
        writeTempSegments(env, tempSegments, startLineNum, variables)

      # Increment the row variable.
      inc(row)
      if row >= repeat:
        break
      tea["row"] = newValue(row)

      # Run the command and fill in the variables.
      loopControl = runCommand(env, cmdLines, variables)
      if loopControl == "stop":
        break

    closeDeleteTempSegments(tempSegments)

    if lastLine.kind == rlNormalLine:
      inOutExtraLine = newNormalLine(lastLine.line)

  env.log("Template lines: $1\n" % $(lb.getLineNum()-1))

proc updateTemplateLines(env: var Env, variables: var Variables,
                          prepostTable: PrepostTable) =
  ## Update the given template file.

  # Read template lines and write them out. Read command lines and
  # write them out. Run the command to determine the t.content, then
  # write out the t.content. Repeat.

  # If the template is coming from a file, write the content to a temp
  # file then rename it at the end overwriting the original template
  # file.  If the template comes from standard in, write the new
  # template to standard out.

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
      discard runCommand(env, cmdLines, variables)

    # Write out the command lines.
    for dumpLine in cmdLines.lines:
      env.resultStream.write(dumpLine)

    # Show a warning when the replace command does not have t.content set.
    if command == "replace" and not tea.contains("content"):
      # lineNum-1 because the current line number is at the first
      # replacement line.
      env.warn(lb.getFilename(), lb.getLineNum()-1, wContentNotSet)

    if command == "replace" and tea.contains("content"):
      # Discard the replacement block lines and save the endblock if it exists.
      var lastLine: ReplaceLine
      for replaceLine in yieldReplacementLine(env,
          firstReplaceLine, lb, prepostTable, command, maxLines):
        lastLine = replaceLine

      # Write the content as the replacement lines.
      var valueOr = getVariable(variables, "t.content")
      var content = valueOr.value.stringv
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

proc readJsonFileLog*(env: var Env, filename: string): ValueOr =
  ## Read a json file and log.

  if not fileExists(filename):
    # File not found: $1.
    env.warnNoFile(wFileNotFound, filename)
    return

  var file: File
  try:
    file = open(filename, fmRead)
  except:
    # Unable to open file: $1.
    env.warnNoFile(wUnableToOpenFile, filename)
    return

  # Create a stream out of the file.
  var stream: Stream
  stream = newFileStream(file)
  if stream == nil:
    # Unable to open file: $1.
    return newValueOr(wUnableToOpenFile, filename)

  # Log the filename and size.
  let fileSize = file.getFileSize()
  env.log("Json filename: $1\n" % filename)
  env.log("Json file size: $1\n" % $fileSize)

  result = readJsonStream(stream)

proc readJsonFiles*(env: var Env, filenames: seq[string]): VarsDict =
  ## Read json files and return a variable dictionary.  Skip a
  ## duplicate variable and generate a warning.

  var varsDict = newVarsDict()
  for filename in filenames:
    let valueOr = readJsonFileLog(env, filename)
    if valueOr.isMessage:
      env.warn(filename, 0, valueOr.message)
    else:
      # Merge in the variables.
      for k, v in valueOr.value.dictv.pairs:
        if k in varsDict:
          # Duplicate json variable '$1' skipped.
          env.warn(filename, 0, wDuplicateVar, k)
        else:
          varsDict[k] = v
  result = varsDict

proc getStartingVariables*(env: var Env, args: Args): Variables =
  ## Return the starting variables.  Read the server json files, run
  ## the code files and setup the initial tea variables.

  let serverVarDict = readJsonFiles(env, args.serverList)
  let argsVarDict = getTeaArgs(args).dictv
  let funcsVarDict = createFuncDictionary().dictv
  result = emptyVariables(serverVarDict, argsVarDict, funcsVarDict)
  runCodeFiles(env, result, args.codeList)

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

proc processTemplate*(env: var Env, args: Args) =
  ## Process the template.

  var variables = getStartingVariables(env, args)

  var prepostTable = getPrepostTable(args)

  # Process the template.
  processTemplateLines(env, variables, prepostTable)

proc updateTemplate*(env: var Env, args: Args) =
  ## Update the template and return 0 on success. Return 1 if a
  ## warning messages was written while processing the template.

  var variables = getStartingVariables(env, args)
  var prepostTable = getPrepostTable(args)
  updateTemplateLines(env, variables, prepostTable)

proc processTemplateTop*(env: var Env, args: Args) =
  ## Setup the environment streams then process the template.

  # Add the template and result streams to the environment.
  let warningDataO = env.addExtraStreams(args)
  if warningDataO.isSome:
    env.warnNoFile(warningDataO.get())
    return

  # Process the template.
  processTemplate(env, args)

proc updateTemplateTop*(env: var Env, args: Args) =
  ## Update the template.

  # Add the template and result streams to the environment. Result
  # file is either a temp file or standard out.
  let warningDataO = env.addExtraStreamsForUpdate(args)
  if warningDataO.isSome:
    env.warnNoFile(warningDataO.get())
    return

  # Update the template.
  updateTemplate(env, args)

  # When the template is coming from a file, the result file is a temp
  # file. You can tell this case because templateFilename is not
  # "stdin".  Rename the temp file to be the new template.

  # When the template is coming from stdin, the result file is
  # stdout. No renaming needs to be done for this case.

  if env.templateFilename != "stdin":

    # Close the template and result files.
    env.templateStream.close()
    env.templateStream = nil
    env.resultStream.close()
    env.resultStream = nil

    # Don't overwrite a read only template.
    # If no write permissions, assume it is readonly.
    let permissions = getFilePermissions(env.templateFilename)
    let writeSet = {fpUserWrite, fpGroupWrite, fpOthersWrite}
    let writeable = writeSet * permissions
    if writeable.len == 0:
      # Cannot update the readonly template.
      env.warnNoFile(wUpdateReadonly)
      return

    # Rename the temp result file overwriting the template file.
    try:
      moveFile(env.resultFilename, env.templateFilename)
    except OSError:
      # Unable to rename temporary file over template file.
      env.warnNoFile(wUnableToRenameTemp)
      # Delete the temp file.
      discard tryRemoveFile(env.resultFilename)
