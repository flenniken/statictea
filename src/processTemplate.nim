## Process the template.

import strutils
import args
import warnings
import env
import readjson
import streams
import vartypes
import os
import matches
import readlines
import options
import regexes
import tpub
import parseCmdLine

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

proc readCmdLines(env: Env, lb: var LineBuffer, lineParts: lineParts,
    prepostTable: PrepostTable, prefixMatcher: Matcher, commandMatcher: Matcher,
    line: string, templateFilename: string,
    lineNum: Natural): Option[seq[string]] =

  ## Read the lines from the current position until the
  ## command doesn't continue. Return the list of lines.

  # Each line has a command. The current line continues when it has a
  # slash at the end. The continue line starts with a : command.  It
  # may continue too. The last line doesn't have a slash.

  #[
<--!$ nextline a = 5 \-->\n
<--!$ : a = 5 \-->\n
<--!$ : b = 6 \-->\n
<--!$ : c = 7  -->\n
  ]#


  var lines: seq[string]

  let lineNum = lb.lineNum
  let linePartsO = parseCmdLine(env, prepostTable, prefixMatcher,
    commandMatcher, line, lb.templateFilename, lb.lineNum)
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

    let linePartsO = parseCmdLine(env, prepostTable, prefixMatcher,
      commandMatcher, line, lb.templateFilename, lb.lineNum)
    if not linePartsO.isSome():
      return
    lp = linePartsO.get()
    if lp.command != ":":
      env.warn("not continuation command")
      return

    lines.add(lp.middle)
    result = some(lines)


proc processCmd(env: Env, lb: var LineBuffer, resultStream: Stream,
   serverVars: VarsDict, sharedVars: VarsDict, lineParts: LineParts): bool =
  ## Collect cmd lines, process them, then process replacement block
  ## lines.
  # There is a limit on cmd line length 1K and memory for all
  # lines 16K.

  var cmdLines = readCmdLines(...)


  # let localVars = runCmds(cmdLines, serverVars, sharedVars)
  # processBlockLines(...)


proc processTemplateLines(env: Env, templateStream: Stream, resultStream: Stream,
    serverVars: VarsDict, sharedVars: VarsDict,
    prepostList: seq[Prepost], templateFilename: string) =
  ## Process the given template file.

  # Get the line matchers.
  var prepostTable = getPrepostTable(prepostList)
  var prefixMatcher = getPrefixMatcher(prepostTable)
  var commandMatcher = getCommandMatcher()

  # Allocate a buffer for reading lines.
  var lineBufferO = newLineBuffer(templateStream, templateFilename=templateFilename)
  # todo: handle error case.
  var lb = lineBufferO.get()

  # Read and process lines.
  while true:
    var line = lb.readline()
    if line == "":
      break

    let linePartsO = parseCmdLine(env, prepostTable, prefixMatcher,
        commandMatcher, line, lb.templateFilename, lb.lineNum)
    if not linePartsO.isSome:
      resultStream.write(line)
    else:
      # Process the command lines and replacement block.
      let done = processCmd(...)
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

  # Process the template.
  processTemplateLines(env, templateStream, resultStream, serverVars,
    sharedVars, args.prepostList, templateFilename)

  # Close the streams.
  if args.resultFilename != "":
    resultStream.close()
  if templateFilename != "stdin":
    templateStream.close()
