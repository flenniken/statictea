## Collect template command lines.

import std/streams
import env
import matches
import readlines
import parseCmdLine
import messages
import opresultwarn

type
  ExtraLineKind* = enum
    ## The ExtraLine type.
    elkNoLine,     ## there is no line here
    elkOutOfLines, ## no more lines in the template
    elkNormalLine  ## we have a line of some type.

  ExtraLine* = object
    ## The extra line and its type. The line is empty except for the
    ## elkNormalLine type.
    kind*: ExtraLineKind
    line*: string

  CmdLines* = object
    ## The collected command lines and their parts.
    lines*: seq[string]
    lineParts*: seq[LineParts]

func newNormalLine*(line: string): ExtraLine =
  ## Create a normal ExtraLine.
  result = ExtraLine(kind: elkNormalLine, line: line)

func newNoLine*(): ExtraLine =
  ## Create a no line ExtraLine.
  result = ExtraLine(kind: elkNoLine, line: "")

func newOutOfLines*(): ExtraLine =
  ## Create an out of lines ExtraLine.
  result = ExtraLine(kind: elkOutOfLines, line: "")

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
        env.warn(lb.getLineNum(), warn)
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
