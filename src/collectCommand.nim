## Collect template command lines.

import std/streams
import std/options
import env
import matches
import readlines
import parseCmdLine

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

proc collectCommand*(env: var Env, lb: var LineBuffer,
      prepostTable: PrepostTable, resultStream: Stream,
      cmdLines: var seq[string], cmdLineParts: var seq[LineParts],
      firstReplaceLine: var string
  ) =
  ## Read template lines and write out non-command lines. When a
  ## command is found, collect its lines in the given lists, cmdLines,
  ## cmdLineParts and firstReplaceLine. When no command found, return with
  ## no lines.
  var line: string
  while true:
    if firstReplaceLine != "":
      line = firstReplaceLine
      firstReplaceLine = ""
    else:
      line = lb.readline()
      if line == "":
        break # No more lines.

    var linePartsO = parseCmdLine(env, prepostTable, line, lb.lineNum)
    if not linePartsO.isSome:
      # Write out non-command lines.
      resultStream.write(line)
    else:
      # Found command line.
      var lineParts = linePartsO.get()

      cmdLines.add(line)
      cmdLineParts.add(lineParts)

      # Collect all the continuation command lines and the line after.
      while true:
        line = lb.readline()
        if line == "":
          return # No more lines

        let lPartsO = parseCmdLine(env, prepostTable, line, lb.lineNum)
        # Skip everything except the continue command. Other lines
        # that look like commands are part of the replacement block.
        if lPartsO.isSome:
          lineParts = lPartsO.get()
          if lineParts.command == ":":
            cmdLines.add(line)
            cmdLineParts.add(lineParts)
            continue # continue looking for more command lines.

        firstReplaceLine = line
        return # return the command lines
