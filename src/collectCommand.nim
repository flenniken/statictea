## Collect template command lines.

import std/streams
import std/options
import env
import matches
import readlines
import parseCmdLine
import messages

type
  ExtraLine* = object
    ## The extra line and its type.
    ## "" -- there is no line here
    ## "outOflines" -- read all lines in the template
    ## "normalLine" -- we have a line of some type.
    kind*: string  # "outOfLines", "", "normalLine"
    line*: string

  CmdLines* = object
    lines*: seq[string]
    lineParts*: seq[LineParts]

func newExtraLineNormal*(line: string): ExtraLine =
  result = ExtraLine(kind: "normalLine", line: line)

func newExtraLineSpecial*(kind: string): ExtraLine =
  case kind
  of "outOfLines", "":
    result = ExtraLine(kind: kind, line: "")
  else:
    result = ExtraLine(kind: "", line: "")

proc collectCommand*(env: var Env, lb: var LineBuffer,
      prepostTable: PrepostTable, extraLine: var ExtraLine): CmdLines =
  ## Read template lines and write out non-commands lines. When a
  ## command that needs processing is found, return its line and
  ## continue lines.  On input extraLine is the first line to use.  On
  ## exit extraLine is the line that caused the collection to stop
  ## (the first replacement block line).

  assert extraLine.kind != "outOfLines"

  var collecting = false
  while true:
    # Get the next line
    var line: string
    if extraLine.kind == "normalLine":
      # Use the extra line.
      line = extraLine.line
      extraLine = newExtraLineSpecial("")
    else:
      # Read a new line.
      line = lb.readline()
      if line == "":
        extraLine = newExtraLineSpecial("outOfLines")
        break

    # Parse the line.
    let linePartsO = parseCmdLine(env, prepostTable, line, lb.getLineNum())

    if not collecting:
      # If not a command, write it out and continue.
      if not linePartsO.isSome:
        env.resultStream.write(line)
        continue

      # Skip comment lines.
      let lineParts = linePartsO.get()
      if lineParts.command == "#":
        continue

      # Warn about the continue or endblock commands but output them anyway.
      if lineParts.command == ":" or lineParts.command == "endblock":
        var warn: MessageId
        if lineParts.command == ":":
          warn = wBareContinue
        else:
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
      if linePartsO.isSome:
        let lineParts = linePartsO.get()
        if lineParts.command == ":":
          result.lineParts.add(lineParts)
          result.lines.add(line)
          continue

      # Any other type of line is part of the replacement block, even
      # lines that look like commands.

      # All done collecting.
      extraLine = newExtraLineNormal(line)
      break
