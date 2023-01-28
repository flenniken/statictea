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
import runCommand
import functions

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
      for k, v in valueOr.value.dictv.dict.pairs:
        if k in varsDict:
          # Duplicate json variable '$1' skipped.
          env.warn(filename, 0, wDuplicateVar, k)
        else:
          varsDict[k] = v
  result = varsDict

func argsPrepostList*(prepostList: seq[Prepost]): seq[seq[string]] =
  ## Create a prepost list of lists for t args.
  for prepost in prepostList:
    result.add(@[prepost.prefix, prepost.postfix])

func getTeaArgs*(args: Args): Value =
  ## Create the t args dictionary from the statictea arguments.
  var varsDict = newVarsDict()
  varsDict["help"] = newValue(args.help)
  varsDict["version"] = newValue(args.version)
  varsDict["update"] = newValue(args.update)
  varsDict["log"] = newValue(args.log)
  varsDict["repl"] = newValue(args.repl)
  varsDict["serverList"] = newValue(args.serverList)
  varsDict["codeList"] = newValue(args.codeList)
  varsDict["resultFilename"] = newValue(args.resultFilename)
  varsDict["templateFilename"] = newValue(args.templateFilename)
  varsDict["logFilename"] = newValue(args.logFilename)
  varsDict["prepostList"] = newValue(argsPrepostList(args.prepostList))
  result = newValue(varsDict)

proc getStartVariables*(env: var Env, args: Args): Variables =
  ## Return the starting variables.  Read the server json files, run
  ## the code files and setup the initial tea variables.

  let serverVarDict = readJsonFiles(env, args.serverList)
  let argsVarDict = getTeaArgs(args).dictv.dict
  result = startVariables(serverVarDict, argsVarDict, funcsVarDict)
  runCodeFiles(env, result, args.codeList)
