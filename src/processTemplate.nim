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
import parseCmdLine

#[

<--$ nextline -->\n
<--$ nextline \-->\n
<--$ nextline a = 5 \-->\n
<--$ nextline a = 5; b = \-->\n
<--$ : 20 \-->\n

Each line has a command. The current line continues when it has a
slash at the end. The continue line starts with a : command.  It may
continue too. The last line doesn't have a slash. If an error is
found, a warning is written, and the lines get written as is as if
they weren't command lines.

<--!$ nextline a = 5 \-->\n
<--!$ : a = 5 \-->\n
<--!$ : b = 6 \-->\n
<--!$ : c = 7  -->\n

]#

proc echoCmdLines(resultStream: Stream, cmdLines: seq[string]) =
  for line in cmdLines:
    resultStream.write(line)

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

    var linePartsO = parseCmdLine(env, prepostTable, prefixMatcher,
        commandMatcher, line, lb.filename, lb.lineNum)
    if not linePartsO.isSome:
      resultStream.write(line)
    else:
      var lineParts = linePartsO.get()
      var cmdLines: seq[string] = @[]
      var cmdLineParts: seq[LineParts] = @[]

      # Collect all the continuation command lines.
      while lineParts.continuation:
        line = lb.readline()
        if line == "":
          env.warn("missing continuation line")
          echoCmdLines(resultStream, cmdLines)
          break
        cmdLines.add(line)
        linePartsO = parseCmdLine(env, prepostTable, prefixMatcher,
            commandMatcher, line, lb.filename, lb.lineNum)
        if not linePartsO.isSome:
          env.warn("not command line")
          echoCmdLines(resultStream, cmdLines)
          break
        lineParts = linePartsO.get()
        if lineParts.command != ":":
          env.warn("not continuation line")
          echoCmdLines(resultStream, cmdLines)
          break




#[

There are three line types cmd lines, replacement block lines and
other lines.

Cmd lines start with a prefix, and they may continue on multiple
lines.

Replacement block lines follow cmd lines. One line for the nextline
command and one or more lines for replace and block commands.

Other lines, not cmd or block lines, get echoed to the output file
unchanged.

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
