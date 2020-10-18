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

proc processCmd(env: Env, line: string, lineNum: int,
    templateStream: Stream, resultStream: Stream, serverVars: VarsDict,
    sharedVars: VarsDict, prefix: string, templateFilename: string) =
  ## Process the command line.
  let cmdTypeO = getCmdType(line, prefix)
  if not cmdTypeO.isSome:
    env.warn(templateFilename, lineNum, wNotACommand)

proc processTemplate(env: Env, templateStream: Stream, resultStream: Stream,
    serverVars: VarsDict, sharedVars: VarsDict,
    prepostList: seq[Prepost], templateFilename: string) =
  ## Process the given template file.

  initPrepost(prepostList)

  var lineNum = 0
  var longCmdLineMaybe = false
  for line, ascii in readline(templateStream):
    if line[^1] == '\n':
      inc(lineNum)
    let prefixO = getPrefix(line)
    if not prefixO.isSome:
      resultStream.write(line)
      continue
    if longCmdLineMaybe:
      env.warn(templateFilename, lineNum-1, wCmdLineTooLong)
    longCmdLineMaybe = line.len == maxLineLen
    processCmd(env, line, lineNum, templateStream, resultStream, serverVars,
               sharedVars, prefixO.get(), templateFilename)

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

  processTemplate(env, templateStream, resultStream, serverVars,
    sharedVars, args.prepostList, templateFilename)

  if args.resultFilename != "":
    resultStream.close()

  if templateFilename != "stdin":
    templateStream.close()
