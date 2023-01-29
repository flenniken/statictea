## Update a template.

import std/streams
import std/os
import std/options
import std/tables
import args
import messages
import env
import linebuffer
import parseCmdLine
import runCommand
import variables
import vartypes
import replacement
import startingvars
import opresult

proc collectReplaceCommand*(env: var Env, lb: var LineBuffer,
      prepostTable: PrepostTable, extraLine: var ExtraLine): CmdLines =
  ## Collect the replace commands.  Read template lines and write out
  ## non-command lines. When a replace command is found, return its
  ## lines.  This includes the command line and its continue lines.
  ## On input extraLine is the first line to use.  On exit extraLine
  ## is the line that caused the collection to stop which is commonly
  ## the first replacement block line.
  type
    State = enum
      ## Finite state machine states.
      sStart, sBlock, sNextline, sContinue

  var state = sStart
  while true:
    var line: string
    if extraLine.kind == elkNormalLine:
      # Use the extra line.
      line = extraLine.line
      # Mark it so we don't use it again.
      extraLine = newNoLine()
    else:
      # Read a new line.
      line = lb.readline()
      if line == "":
        extraLine = newOutOfLines()
        break

    # Get the line command if any.
    var command: string
    let linePartsOr = parseCmdLine(prepostTable, line, lb.getLineNum())
    var lineParts: LineParts
    if linePartsOr.isValue:
      lineParts = linePartsOr.value
      command = lineParts.command
    else:
      command = "other"

    case state:
      of sStart:
        if command == "nextline":
          state = sNextline
        elif command == "block":
          state = sBlock
        elif command == "replace":
          state = sContinue
      of sBlock:
        if command == "endblock":
          state = sStart
      of sNextline:
        state = sStart
      of sContinue:
        if command != ":":
          extraLine = newNormalLine(line)
          break

    if state == sContinue:
      result.lineParts.add(lineParts)
      result.lines.add(line)
    else:
      env.resultStream.write(line)

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
  let lineBufferO = newLineBuffer(env.templateStream,
      filename=env.templateFilename)
  if not lineBufferO.isSome():
    # Not enough memory for the line buffer.
    env.warnNoFile(wNotEnoughMemoryForLB)
    return
  var lb = lineBufferO.get()


  # Read and process template lines.
  var tea = variables["t"].dictv.dict
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
      var valueOr = getVariable(variables, "t.content", npLocal)
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

proc updateTemplate*(env: var Env, args: Args) =
  ## Update the template and return 0 on success. Return 1 if a
  ## warning messages was written while processing the template.

  var variables = getStartVariables(env, args)
  var prepostTable = getPrepostTable(args)
  updateTemplateLines(env, variables, prepostTable)

proc updateTemplateTop*(env: var Env, args: Args) =
  ## Update the template.

  # Add the template and result streams to the environment. Result
  # file is either a temp file or standard out.
  let warningDataO = env.addExtraStreamsForUpdate(args.resultFilename, args.templateFilename)
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
