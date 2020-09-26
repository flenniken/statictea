## Process the template.

import strutils
import args
import warnings
import warnenv
import tables
import tpub
import readjson
import vartypes

proc processTemplate*(args: Args): int =

# templateList: seq[string],
#     serverList: seq[string], sharedList: seq[string],
#     resultFilename: string , prepostList: seq[Prepost]) =

  assert args.templateList.len > 0
  if args.templateList.len > 1:
    let skipping = join(args.templateList[1..^1], ", ")
    warn("starting", 0, wOneTemplateAllowed, skipping)
  echo "processing template"

  var serverVars = initTable[string, Value]()
  for filename in args.serverList:
    readJson(filename, serverVars)

  var sharedVars = initTable[string, Value]()
  for filename in args.sharedList:
    readJson(filename, sharedVars)
