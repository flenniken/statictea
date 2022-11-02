## Process the template.

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
import replacement
import startingvars

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

proc processTemplate*(env: var Env, args: Args) =
  ## Process the template.

  var variables = getStartingVariables(env, args)

  var prepostTable = getPrepostTable(args)

  # Process the template.
  processTemplateLines(env, variables, prepostTable)

proc processTemplateTop*(env: var Env, args: Args) =
  ## Setup the environment streams then process the template.

  # Add the template and result streams to the environment.
  let warningDataO = env.addExtraStreams(args)
  if warningDataO.isSome:
    env.warnNoFile(warningDataO.get())
    return

  # Process the template.
  processTemplate(env, args)

