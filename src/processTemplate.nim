## Process the template.

import streams
import strutils
import args
import warnings
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


proc readJson(warn: Stream, filename: string, serverVars: var Table[string, Value]) {.tpub.} =
  ## Read a json file add the variables to the given table.

  warn.writeLine("readJson not implemented")


proc processTemplate*(warnings: Stream, args: Args) =

# templateList: seq[string],
#     serverList: seq[string], sharedList: seq[string],
#     resultFilename: string , prepostList: seq[Prepost]) =

  assert args.templateList.len > 0
  if args.templateList.len > 1:
    let skipping = join(args.templateList[1..^1], ", ")
    warning(warnings, "starting", 0, wOneTemplateAllowed, skipping)
  echo "processing template"

  var serverVars = initTable[string, Value]()
  for filename in args.serverList:
    readJson(warnings, filename, serverVars)

  var sharedVars = initTable[string, Value]()
  for filename in args.sharedList:
    readJson(warnings, filename, sharedVars)
