## StaticTea variable types.

import tables

type
  VarsDict* = OrderedTable[string, Value]

  ValueKind* = enum
    vkString,
    vkInt,
    vkFloat,
    vkDict,
    vkList,

  Value* = ref ValueObj
  ValueObj* {.acyclic.} = object
    case kind*: ValueKind
    of vkString:
      stringv*: string
    of vkInt:
      intv*: int64
    of vkFloat:
      floatv*: float64
    of vkDict:
      dictv*: VarsDict
    of vkList:
      listv*: seq[Value]

func `$`*(value: Value): string =
  ## A string representation of Value.
  case value.kind
  of vkString:
    result = "\"" & value.stringv & "\""
  of vkInt:
    result = $value.intv
  of vkFloat:
    result = $value.floatv
  of vkDict:
    if value.dictv.len == 0:
      result = "{}"
    else:
      result = $value.dictv
  of vkList:
    var str = $value.listv
    result = str[1..^1]
