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
import replacement
import readjson

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




    # var cmdLines: seq[string] = @[]
    # var cmdLineParts: seq[LineParts] = @[]

    # Run the commands that are allowed statements and skip the others.
    # let command = cmdLineParts[0].command
    # if not (command in ["nextline", "block", "replace"]):
    #   # The command was one of these: endblock, : continue, # comment.
    #   if command == "#":
    #     continue
    #   var warning: MessageId
    #   if command == "endblock":
    #     warning = wBareEndblock
    #   else:
    #     warning = wBareContinue
    #   env.warn(lb.getLineNum()-1, warning)
    #   continue

    # # Show a warning when the replace command does not have t.content
    # # set.
    # if command == "replace" and not tea.contains("content"):
    #   # lineNum-1 because the current line number is at the first
    #   # replacement line.
    #   env.warn(lb.getLineNum()-1, wContentNotSet)

    # If repeat is 0, read the replacement lines and the endblock and
    # # discard them.
    # if repeat == 0:
    #   for replaceLine in yieldReplacementLine(env,
    #       firstReplaceLine, lb, prepostTable, command, maxLines):
    #     discard
    #   # todo: handle the last line.
    #   firstReplaceLine = ""
    #   continue

    # # Create a new TempSegments object for storing segments.
    # var startLineNum = lb.getLineNum()
    # var tempSegmentsO = newTempSegments(env, lb, prepostTable,
    #                                     command, repeat, variables)
    # if not isSome(tempSegmentsO):
    #   break # Cannot create temp file or allocate memory, quit.
    # var tempSegments = tempSegmentsO.get()

    # var lastLine: ReplaceLine



    #   # Read the replacement lines and the line after.
    #   # Discard the replacement block lines and the endblock.
    #   for replaceLine in yieldReplacementLine(env, firstReplaceLine,
    #       lb, prepostTable, command, maxLines):
    #     lastLine = replaceLine
    #   # Use the content as the replacement lines.
    #   var content = getVariable(variables, "t.content").value.stringv
    #   for line in yieldContentLine(content):
    #     storeLineSegments(env, tempSegments, prepostTable, line)
    # else:
    #   # Read the replacement lines and the line after. Store the
    #   # replacement lines in compiled segments in TempSegments.
    #   for replaceLine in yieldReplacementLine(env,
    #       firstReplaceLine, lb, prepostTable, command, maxLines):
    #     lastLine = replaceLine
    #     if replaceLine.kind == rlReplaceLine:
    #       storeLineSegments(env, tempSegments, prepostTable, replaceLine.line)

    # # Generate t.repeat number of replacement blocks. Recalculate the
    # # variables for each one.
    # var tea = variables["t"].dictv
    # while true:
    #   # Write out all the stored replacement block lines and make the
    #   # variable substitutions.
    #   writeTempSegments(env, tempSegments, startLineNum, variables)

    #   # Increment the row variable.
    #   inc(row)
    #   if row >= repeat:
    #     break
    #   tea["row"] = newValue(row)

    #   # Run the command and fill in the variables.
    #   runCommand(env, cmdLines, cmdLineParts, prepostTable,
    #              variables)

    # closeDelete(tempSegments)



    # if lastLine.kind == rlNormalLine:
    #   # todo: feed the line back into the collectCommand function in
    #   # the loop instead.
    #   env.resultStream.write(lastLine.line)
    # # rlEndBlockLine, rlReplaceLine, rlNoLine:

    # firstReplaceLine = ""


  # var tea = variables["t"].dictv
    # var row = 0
    # tea["row"] = newValue(0)

    # let repeat = getTeaVarIntDefault(variables, "repeat")
    # var maxLines = getTeaVarIntDefault(variables, "maxLines")


proc processTemplateLines(env: var Env, variables: var Variables,
                          prepostTable: PrepostTable) =
  ## Process the given template file lines.

  # Allocate a buffer for reading lines.
  var lineBufferO = newLineBuffer(env.templateStream,
      filename = env.templateFilename)
  if not lineBufferO.isSome():
    env.warn(0, wNotEnoughMemoryForLB)
    return
  var lb = lineBufferO.get()

  # Read and process template lines.
  var extraLine: ExtraLine
  while true:
    # Read template lines and write out non-commands lines. When a
    # command that needs processing is found, return its lines.
    # ExtraLine is an input and output parameter.
    let cmdLines = collectCommand(env, lb, prepostTable, extraLine)
    if extraLine.noMoreLines:
      break

    # Run the command to fill in the variables.
    runCommand(env, cmdLines, cmdLineParts, prepostTable, variables)

    # Treat a replace command without content as a block command.
    var command: string
    if cmdLines.command == ckReplace and not tea.contains("content"):
      # The replace command doesn't set content, treating it as a
      # block command.
      env.warn(0, wContentNotSet)
      command = ckBlock
    else:
      command = cmdLines.command
      
    # Fill in the replacement block. ExtraLine is an input and output
    # parameter.

    # note: ftc = fill type command
    case command:
      of ftcReplace:
        fillReplaceCommand(extraLine)
      of ftcBlock:
        fillBlockCommand(extraLine)
      of ftcNextline:
        fillNextLineCommand(extraLine)
    if extraLine.noMoreLines:
      break
        

proc dumpCmdLines*(resultStream: Stream, cmdLines: var seq[string],
                  cmdLineParts: var seq[LineParts], line: string) =
  ## Write the stored command lines and the current line to the result
  ## stream and empty the stored commands.
  for cmdline in cmdLines:
    resultStream.write(cmdline)
  if line != "":
    resultStream.write(line)
  cmdLines.setlen(0)
  cmdLineParts.setlen(0)


proc updateTemplateLines(env: var Env, variables: var Variables,
                          prepostTable: PrepostTable) =
  ## Update the given template file's replacement blocks.

  #[ Read template lines and write them out. Read command lines and
  write them out. Run the command to determine the t.content, then
  write out the t.content. Repeat.

  If the template is coming from a file, write the content to a temp
  file then rename it at the end overwriting the original template
  file.  If the template comes from standard in, write the new
  template to standard out. ]#

  # Allocate a buffer for reading lines.
  var lineBufferO = newLineBuffer(env.templateStream,
      filename = env.templateFilename)
  if not lineBufferO.isSome():
    env.warn(0, wNotEnoughMemoryForLB)
    return
  var lb = lineBufferO.get()

  # Read and process template lines.
  var extraLine: ExtraLine
  while true:
    # Read template lines and write out non-command lines. When a
    # replace command is found, collect its lines and return them.
    # ExtraLine is an input and output parameter.
    var cmdLines = collectReplaceCommand(env, lb, prepostTable, extraLine)
    if cmdLines.noMoreLines:
      break

    # Run the replace command to set the content variable.
    runCommand(env, cmdLines, prepostTable, variables)

    # Update the replacement block with lines from the content
    # variable. ExtraLine is an input and output parameter.
    updateReplacementBlock(extraLine)
    if extraLine.noMoreLines:
      break

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

# todo: using t.content on a block command? show message?

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
