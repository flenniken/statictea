import env
import streams
import matches
import readlines
import options
import parseCmdLine
import regexes

proc dumpCmdLines(resultStream: Stream, cmdLines: var seq[string],
    cmdLineParts: var seq[LineParts]) =
  for line in cmdLines:
    resultStream.write(line)
  cmdLines.setlen(0)
  cmdLineParts.setlen(0)

proc processLinesReturnCmd*(env: Env, lb: var LineBuffer, prepostTable: PrepostTable,
      prefixMatcher: Matcher, commandMatcher: Matcher, resultStream: Stream,
      cmdLines: var seq[string], cmdLineParts: var seq[LineParts]) =
  ## Read template lines and write out non-command lines. When a
  ## command is found, collect its lines and return them. When no more
  ## template lines, return with no lines.

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

      cmdLines.add(line)
      cmdLineParts.add(lineParts)

      # Collect all the continuation command lines.
      while lineParts.continuation:

        line = lb.readline()
        if line == "":
          env.warn("No more lines but need a command continuation line.")
          dumpCmdLines(resultStream, cmdLines, cmdLineParts)
          return

        linePartsO = parseCmdLine(env, prepostTable, prefixMatcher,
            commandMatcher, line, lb.filename, lb.lineNum)
        if not linePartsO.isSome:
          env.warn("Did not get the expected continuation command, abandoning the command.")
          dumpCmdLines(resultStream, cmdLines, cmdLineParts)
          break
        lineParts = linePartsO.get()
        if lineParts.command != ":":
          env.warn("Did not get the expected continuation command, abandoning the command.")
          dumpCmdLines(resultStream, cmdLines, cmdLineParts)
          break

        cmdLines.add(line)
        cmdLineParts.add(lineParts)
      return
