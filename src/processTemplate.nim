## Process the template.

import std/options
import std/tables
import std/strutils
import std/streams
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

proc collectCommand*(env: var Env, lb: var LineBuffer,
      prepostTable: PrepostTable, extraLine: var ExtraLine): CmdLines =
  ## Read template lines and write out non-command lines. When a
  ## @:nextline, block or replace command is found, return its lines.
  ## @:This includes the command line and its continue lines.
  ## @:
  ## @:On input extraLine is the first line to use.  On exit extraLine
  ## @:is the line that caused the collection to stop which is commonly
  ## @:the first replacement block line.

  assert extraLine.kind != elkOutOfLines

  var collecting = false
  while true:
    # Get the next line
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

    # Parse the line.
    let linePartsOr = parseCmdLine(prepostTable, line, lb.getLineNum())

    if not collecting:
      # If not a command, write it out and continue.
      if linePartsOr.isMessage:
        env.resultStream.write(line)
        continue

      # Skip comment lines.
      let lineParts = linePartsOr.value
      if lineParts.command == "#":
        continue

      # Warn about the continue or endblock commands but output them anyway.
      if lineParts.command == ":" or lineParts.command == "endblock":
        var warn: MessageId
        if lineParts.command == ":":
          # The continue command is not part of a command.
          warn = wBareContinue
        else:
          # The endblock command does not have a matching block command.
          warn = wBareEndblock
        env.warn(lb.getFilename, lb.getLineNum(), warn)
        env.resultStream.write(line)
        continue

      # Collect the nextline, block or replace command.
      collecting = true
      result.lineParts.add(lineParts)
      result.lines.add(line)
    else:
      # We're in collecting mode.

      # Collect continue commands.
      if linePartsOr.isValue():
        let lineParts = linePartsOr.value
        if lineParts.command == ":":
          result.lineParts.add(lineParts)
          result.lines.add(line)
          continue

      # Any other type of line is part of the replacement block, even
      # lines that look like commands.

      # All done collecting.
      extraLine = newNormalLine(line)
      break

proc processTemplateLines(env: var Env, variables: var Variables,
                          prepostTable: PrepostTable) =
  ## Process the given template file.

  # Allocate a buffer for reading lines. Return when not enough memory.
  let lineBufferO = newLineBuffer(env.templateStream,
      filename=env.templateFilename)
  if not lineBufferO.isSome():
    # Not enough memory for the line buffer.
    env.warnNoFile(wNotEnoughMemoryForLB)
    return
  var lb = lineBufferO.get()

  var inOutExtraLine: ExtraLine
  var firstReplaceLine: string

  # Read and process template lines.
  var loopControl = lcContinue
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
    loopControl = runCommand(env, cmdLines, variables, inCommand)

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
    if repeat == 0 or loopControl == lcStop:
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
      if loopControl != lcSkip:
        writeTempSegments(env, tempSegments, startLineNum, variables)

      # Increment the row variable.
      inc(row)
      if row >= repeat:
        break
      tea["row"] = newValue(row)

      # Run the command and fill in the variables.
      loopControl = runCommand(env, cmdLines, variables, inCommand)
      if loopControl == lcStop:
        break

    closeDeleteTempSegments(tempSegments)

    if lastLine.kind == rlNormalLine:
      inOutExtraLine = newNormalLine(lastLine.line)

  env.log("Template lines: $1\n" % $(lb.getLineNum()-1))

proc processTemplate*(env: var Env, args: Args) =
  ## Process the template.

  var variables = getStartingVariables(env, args)

  var prepostTable = getPrepostTable(args)

  # Process the template.
  processTemplateLines(env, variables, prepostTable)

proc processTemplateTop*(env: var Env, args: Args) =
  ## Setup the environment streams then process the template.

  # Add the template and result streams to the environment.
  assert args.templateFilename != ""
  let warningDataO = addExtraStreams(env, args.templateFilename, args.resultFilename)
  if warningDataO.isSome:
    env.warnNoFile(warningDataO.get())
    return

  # Process the template.
  processTemplate(env, args)

