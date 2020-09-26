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
