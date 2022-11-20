## Get the starting variables.

import std/os
import std/tables
import std/strutils
import args
import messages
import env
import variables
import vartypes
import readjson
import opresult
import codefile
import runFunction

proc readJsonFiles*(env: var Env, filenames: seq[string]): VarsDict =
  ## Read json files and return a variable dictionary.  Skip a
  ## duplicate variable and generate a warning.

  var varsDict = newVarsDict()
  for filename in filenames:
    env.log("Json filename: $1\n" % filename)
    env.log("Json file size: $1\n" % $getFileSize(filename))
    let valueOr = readJsonFile(filename)
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

