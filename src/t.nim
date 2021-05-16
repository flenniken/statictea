## Private module for experimenting.

import typetraits
import tables

type
  VarsDict* = OrderedTableRef[string, Value]
    ## Variables dictionary type. This is a ref type. Create a new
    ## VarsDict with newVarsDict procedure.

  ValueKind* = enum
    ## The type of Variables.
    vkString,
    vkInt,
    vkFloat,
    vkDict,
    vkList

  Value* = ref ValueObj
    ## Variable value reference.

  ValueObj {.acyclic.} = object
    ## Variable object.
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

proc newValue*(num: int | int64): Value =
  ## Create an integer value.
  result = Value(kind: vkInt, intv: num)


proc newValue*[T](args: varargs[T]): Value =
  var valueList: seq[Value]
  for arg in args:
    if arg.type.name == "Value":
      valueList.add(arg)
    else:
      valueList.add(newValue(arg))
  result = newValue(valueList)

var y = newValue(1, 2, 3)
# var x = newValue([newValue(1), newValue("b")])
# var x = newValue(newValue(1), newValue("b"))
# var y = newValue([1, 2, 3])
