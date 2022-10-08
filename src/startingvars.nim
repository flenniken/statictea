## Get the starting variables.

import std/streams
import std/os
# import std/options
import std/tables
import std/strutils
import args
import messages
import env
# import matches
# import readlines
# import parseCmdLine
# import collectCommand
# import runCommand
import variables
import vartypes
import readjson
# import replacement
import opresultwarn
import codefile
import runFunction

proc readJsonFileLog*(env: var Env, filename: string): ValueOr =
  ## Read a json file and log.

  if not fileExists(filename):
    # File not found: $1.
    env.warnNoFile(wFileNotFound, filename)
    return

  var file: File
  try:
    file = open(filename, fmRead)
  except:
    # Unable to open file: $1.
    env.warnNoFile(wUnableToOpenFile, filename)
    return

  # Create a stream out of the file.
  var stream: Stream
  stream = newFileStream(file)
  if stream == nil:
    # Unable to open file: $1.
    return newValueOr(wUnableToOpenFile, filename)

  # Log the filename and size.
  let fileSize = file.getFileSize()
  env.log("Json filename: $1\n" % filename)
  env.log("Json file size: $1\n" % $fileSize)

  result = readJsonStream(stream)

proc readJsonFiles*(env: var Env, filenames: seq[string]): VarsDict =
  ## Read json files and return a variable dictionary.  Skip a
  ## duplicate variable and generate a warning.

  var varsDict = newVarsDict()
  for filename in filenames:
    let valueOr = readJsonFileLog(env, filename)
    if valueOr.isMessage:
      env.warn(filename, 0, valueOr.message)
    else:
      # Merge in the variables.
      for k, v in valueOr.value.dictv.pairs:
        if k in varsDict:
          # Duplicate json variable '$1' skipped.
          env.warn(filename, 0, wDuplicateVar, k)
        else:
          varsDict[k] = v
  result = varsDict

proc getStartingVariables*(env: var Env, args: Args): Variables =
  ## Return the starting variables.  Read the server json files, run
  ## the code files and setup the initial tea variables.

  let serverVarDict = readJsonFiles(env, args.serverList)
  let argsVarDict = getTeaArgs(args).dictv
  let funcsVarDict = createFuncDictionary().dictv
  result = emptyVariables(serverVarDict, argsVarDict, funcsVarDict)
  runCodeFiles(env, result, args.codeList)

