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

proc getCmdType(line: string, prefix: string): Option[int] =
  result = some(0)

type
  LineMode* = enum
    lmOther,
    lmCommand,
    lmBlock

proc processTemplateLines(env: Env, templateStream: Stream, resultStream: Stream,
    serverVars: VarsDict, sharedVars: VarsDict,
    prepostList: seq[Prepost], templateFilename: string) =
  ## Process the given template file.

  initPrepost(prepostList)

  var longCmdLineMaybe: bool

  var lineBufferO = newLineBuffer(templateStream)
  var lb = lineBufferO.get()

  while true:
    var line = lb.readline()
    if line == "":
      break

    if longCmdLineMaybe:
      env.warn(templateFilename, lb.getlineNum()-1, wCmdLineTooLong)
    longCmdLineMaybe = line.len == lb.getMaxLineLen()

    let prefixO = getPrefix(line)
    if not prefixO.isSome:
      resultStream.write(line)
      continue

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
