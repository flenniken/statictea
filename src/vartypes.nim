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

proc `==`*(value1: Value, value2: Value): bool =
  if value1.kind == value2.kind:
    case value1.kind:
      of vkString:
        result = value1.stringv == value2.stringv
      of vkInt:
        result = value1.intv == value2.intv
      of vkFloat:
        result = value1.floatv == value2.floatv
      of vkDict:
        result = value1.dictv == value2.dictv
      of vkList:
        result = value1.listv == value2.listv

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
