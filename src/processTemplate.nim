## Process the template.

import strutils
import args
import warnings
import warnenv
import tables
import tpub

type
  ValueKind = enum
    vkString,
    vkInt,
    vkFloat,
    vkDict,
    vkList,

  Value = ref ValueObj
  ValueObj = object
    case kind: ValueKind
      of vkString:
        stringValue: string
      of vkInt:
        intValue: int
      of vkFloat:
        floatValue: float
      of vkDict:
        dictValue: Table[string, Value]
      of vkList:
        listValue: seq[Value]


proc readJson(filename: string, serverVars: var Table[string, Value]) {.tpub.} =
  ## Read a json file add the variables to the given table.

  echo "readJson not implemented"


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
