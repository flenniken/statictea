import env
import streams
import matches
import readlines
import options
import parseCmdLine
import regexes
import warnings

proc dumpCmdLines(resultStream: Stream, cmdLines: var seq[string],
                  cmdLineParts: var seq[LineParts], line: string) =
  ## Write the stored command lines and the current line to the result
  ## stream and empty the stored commands.
  for cmdline in cmdLines:
    resultStream.write(cmdline)
  if line != "":
    resultStream.write(line)
  cmdLines.setlen(0)
  cmdLineParts.setlen(0)

template warnNoContinuationAndDump() =
  warn(env, lb.filename, lb.lineNum, wNoContinuationLine)
  dumpCmdLines(resultStream, cmdLines, cmdLineParts, line)


# todo: rename to collectCommand
proc processLinesReturnCmd*(env: Env, lb: var LineBuffer, prepostTable: PrepostTable,
      prefixMatcher: Matcher, commandMatcher: Matcher, resultStream: Stream,
      cmdLines: var seq[string], cmdLineParts: var seq[LineParts]) =
  ## Read template lines and write out non-command lines. When a
  ## command is found, collect its lines in the given lists, cmdLines
  ## and cmdLineParts, and return. When no command found, return with
  ## no lines.

  while true:
    var line = lb.readline()
    if line == "":
      break

    var linePartsO = parseCmdLine(env, prepostTable, prefixMatcher,
        commandMatcher, line, lb.filename, lb.lineNum)
    if not linePartsO.isSome:
      resultStream.write(line)
    else:
      var lineParts = linePartsO.get()

      # Collect all the continuation command lines.
      while true:
        cmdLines.add(line)
        cmdLineParts.add(lineParts)

        if not lineParts.continuation:
          return # Return the command lines.

        line = lb.readline()
        if line == "":
          warnNoContinuationAndDump()
          return # No more lines

        linePartsO = parseCmdLine(env, prepostTable, prefixMatcher,
            commandMatcher, line, lb.filename, lb.lineNum)
        if not linePartsO.isSome:
          warnNoContinuationAndDump()
          break # Continue looking for a command.

        lineParts = linePartsO.get()
        if lineParts.command != ":":
          warnNoContinuationAndDump()
          break # Continue looking for a command.
