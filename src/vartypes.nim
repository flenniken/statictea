## StaticTea variable types.

import tables

type
  ValueKind* = enum
    vkString,
    vkInt,
    vkFloat,
    vkDict,
    vkList,

  Value* = ref ValueObj
  ValueObj* = object
    case kind*: ValueKind
    of vkString:
      stringv*: string
    of vkInt:
      intv*: int64
    of vkFloat:
      floatv*: float64
    of vkDict:
      dictv*: Table[string, Value]
    of vkList:
      listv*: seq[Value]

func `$`*(value: Value): string =
  ## A string representation of Value.
  case value.kind
  of vkString:
    result = value.stringv
  of vkInt:
    result = $value.intv
  of vkFloat:
    result = $value.floatv
  of vkDict:
    result = $value.dictv
  of vkList:
    result = $value.listv
