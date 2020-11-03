## Process the template.

import strutils
import args
import warnings
import env
import readjson
import streams
import vartypes
import os
import prepost
import readlines
import options
import regexes
import tpub

type
  LineParts = object
    prefix: string
    middle: string
    command: string
    continuation: bool
    postfix: string
    lineEnding: bool

  MatchPos = object
    match: string
    pos: int

# <--$ nextline -->\n
# <--$ nextline \-->\n
# <--$ nextline a = 5 \-->\n
# <--$ nextline a = 5; b = \-->\n
# <--$ : 20 \-->\n

var lastPartMatcher: Matcher

proc getCommandMatcher(commands: openArray[string]): Matcher =
  result = newMatcher(r"($1)\s+" % commands.join("|"), 1)

proc getLastPartMatcher(postfix: string): Matcher = 
  let pattern = r"([\\]{0,1})\Q$1\E[\r]{0,1}\n$" % postfix
  lastPartMatcher = newMatcher(pattern, 1)

proc getLastPartMatcher(line: string, postfix: string, start: Natural): Option[Matches] {.tpub.} =

  ## Match the end of the command line and return the optional
  ## continuation character and the length of the match.  Command line
  ## length is limited so we know we have the whole line with an
  ## ending newline.
  if lastPartMatcher.pattern == "":
    let pattern = r"([\\]{0,1})\Q$1\E[\r]{0,1}\n$" % postfix
    lastPartMatcher = newMatcher(pattern, 1)
  result = lastPartMatcher.getMatches(line, start)

    let linePartsO = parseCmdLine(env, prefixMatcher, prepostTable, line)

proc parseCmdLine(env: Env, prefixMatcher: Matcher, prepostTable: PrepostTable,
    line: string): Option[LineParts] =
  ## Parse the line and return its parts. Return quickly when not a
  ## command line.
  # prefix   command    middle    \postfix end
  # <--!$    nextline   a = 5     \-->\n
  var lineParts: LineParts

  # Get the prefix.
  let prefixMatchO = prefixMatcher(line, 0)
  if not prefixMatchO.isSome():
    return
  let prefixMatch = prefixMatchO.get()
  lineParts.prefix = prefixMatch.getGroup()

  # Get the command.
  let commandMatchO = commandMatcher(line, prefixMatch.length)
  if not isSome(commandMatchO):
    env.warn("Invalid command")
    return
  var commandMatch = commandMatchO.get()
  lineParts.prefix = commandMatch.getGroup()

  # Get the postfix.
  if lineParts.prefix not in prepostTable:
    env.warn("Invalid postfix")
  lineParts.postfix = prepostTable[lineParts.prefix]

  let middleStart = prefixMatch.length + commandMatch.length

  # Get the optional continuation and its position.
  let lastPartO = matchLastPart(line, lineParts.postfix, middleStart)
  if not isSome(lastPartO):
    env.warn("Missing postfix")
    return
  var lastPart = lastPartO.get()
  let continuation = lastPart.getGroup()
  lineParts.continuation = if continuation == "": false else: true

  let endPos = line.len - lastPart.length


  # Get the middle string.
  let middle = line[middleStart..^endPos]
  lineParts.middle = middle

  # Line ending is required except for the last line of the file.
  lineParts.lineEnding = line.endsWith('\n')

  result = some(lineParts)


proc readCmdLines(env: Env, lb: var LineBuffer, prefixMatches: Matches,
                  cmdLine: string): Option[seq[string]] =
  ## Read the command lines.
  # Strip the prefix, postfix and command out and store the remaining text in lines.
  var lines: seq[string]

  let lineNum = lb.lineNum
  var linePartsO = parseCmdLine(env, cmdLine, prefixMatches)
  if not linePartsO.isSome():
    return
  var lp = linePartsO.get()
  lines.add(lp.middle)

  var lastLineEnding = lp.lineEnding
  while lp.continuation:
    var line = lb.readline()
    if line == "":
      # todo: missing continuation line warning.
      # todo: missing replace block
      return

    if not lastLineEnding:
      env.warn(lb.filename, lb.getlineNum()-1, wCmdLineTooLong)
      return
    lastLineEnding = lp.lineEnding

    linePartsO = parseCmdLine(env, line, prefixMatches)
    if not linePartsO.isSome():
      return
    lp = linePartsO.get()
    if lp.command != ":":
      env.warn("not continuation command")
      return

    lines.add(lp.middle)
    result = some(lines)

proc processCmd(env: Env, lb: var LineBuffer, resultStream: Stream,
    serverVars: VarsDict, sharedVars: VarsDict, prefixMatches: Matches, cmdLine: string): bool =
  # Collect cmd lines, process them, then process block lines
  # There is a limit on cmd line length 1K and memory for all lines 16K.

  let currentLineNum = lb.lineNum
  var cmdLinesO = readCmdLines(env, lb, prefixMatches, cmdLine)
  if not isSome(cmdLinesO):
    return false
  # let localVars = runCmds(cmdLines, serverVars, sharedVars)
  # processBlockLines(...)


proc processTemplateLines(env: Env, templateStream: Stream, resultStream: Stream,
    serverVars: VarsDict, sharedVars: VarsDict,
    prepostList: seq[Prepost], templateFilename: string) =
  ## Process the given template file.

  var prepostTable = getPrepostTable(prepostList)
  var prefixMatcher = getPrefixMatcher(prepostTable)

  var lineBufferO = newLineBuffer(templateStream, templateFilename=templateFilename)
  # todo: handle error case.
  var lb = lineBufferO.get()

  while true:
    var line = lb.readline()
    if line == "":
      break

    let linePartsO = parseCmdLine(env, prefixMatcher, prepostTable, line)
    if not linePartsO.isSome:
      resultStream.write(line)
    else:
      let done = processCmd(env, lb, resultStream, serverVars, sharedVars, linePartsO.get())
      if done:
        break


#[
There are three line types:

* cmd lines -- cmd lines start with a prefix. One or more lines that follow each other.
* replacement block lines -- block lines follow cmd lines. One or more lines that follow each other.
* other lines -- not cmd or block lines.  These lines get echoed to the output file unchanged.

Read lines and echo other lines. Collect up the cmd lines into a list of lines then process them. Then read the block lines, if any, and process them.

modes:
* other line mode
* collecting cmd lines -- you're done collecting when you find a non cmd line, reach the limit or reach the end of file.
* collecting block lines -- you're done when you find an ending cmd line, reach the limit or reach the end of file.


Read a command's lines until no more continuation lines.

]#


proc processTemplate*(env: Env, args: Args): int =
  ## Process the template and return 0 on success.

  # Read the server json.
  var serverVars = getEmptyVars()
  for filename in args.serverList:
    readJson(env, filename, serverVars)

  # Read the shared json.
  var sharedVars = getEmptyVars()
  for filename in args.sharedList:
    readJson(env, filename, sharedVars)

  # Get the template filename.
  assert args.templateList.len > 0
  if args.templateList.len > 1:
    let skipping = join(args.templateList[1..^1], ", ")
    env.warn("starting", 0, wOneTemplateAllowed, skipping)
  let templateFilename = args.templateList[0]

  # Open the template stream.
  var templateStream: Stream
  if templateFilename == "stdin":
    templateStream = newFileStream(stdin)
    if templateStream == nil:
      env.warn("startup", 0, wCannotOpenStd, "stdin")
      return 1
  else:
    if not fileExists(templateFilename):
      env.warn("startup", 0, wFileNotFound, templateFilename)
      return 1
    templateStream = newFileStream(templateFilename, fmRead)
    if templateStream == nil:
      env.warn("startup", 0, wUnableToOpenFile, templateFilename)
      return 1

  # Open the result stream.
  var resultStream: Stream
  if args.resultFilename == "":
    resultStream = env.outStream
  else:
    resultStream = newFileStream(args.resultFilename, fmWrite)
    if resultStream == nil:
      env.warn("startup", 0, wUnableToOpenFile, args.resultFilename)
      return 1

  processTemplateLines(env, templateStream, resultStream, serverVars,
    sharedVars, args.prepostList, templateFilename)

  if args.resultFilename != "":
    resultStream.close()

  if templateFilename != "stdin":
    templateStream.close()
