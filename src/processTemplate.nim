## Process the template.

import strutils
import args
import warnings
import env
import readjson
import streams
import vartypes
import os

proc processTemplate(env: Env, templateStream: Stream, resultStream: Stream,
    serverVars: VarsDict, sharedVars: VarsDict) =
  ## Process the given template file.
  resultStream.writeLine("template result")

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

  assert args.templateList.len > 0

  if args.templateList.len > 1:
    let skipping = join(args.templateList[1..^1], ", ")
    env.warn("starting", 0, wOneTemplateAllowed, skipping)

  let templateFilename = args.templateList[0]

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

  var resultStream: Stream
  if args.resultFilename == "":
    resultStream = newFileStream(stdout)
    if resultStream == nil:
      env.warn("startup", 0, wCannotOpenStd, "stdout")
      return 1
  else:
    resultStream = newFileStream(args.resultFilename, fmWrite)
    if resultStream == nil:
      env.warn("startup", 0, wUnableToOpenFile, args.resultFilename)
      return 1

  processTemplate(env, templateStream, resultStream, serverVars, sharedVars)

  if args.resultFilename != "":
    resultStream.close()

  if templateFilename != "stdin":
    templateStream.close()
