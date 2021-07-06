## StaticTea variable types.

import std/tables
import warnings

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

  ValueOrWarningKind* = enum
    ## The kind of a ValueOrWarning object, either a value or warning.
    vwValue,
    vwWarning

  ValueOrWarning* = object
    ## Holds a value or a warning.
    case kind*: ValueOrWarningKind
      of vwValue:
        value*: Value
      of vwWarning:
        warningData*: WarningData

proc newVarsDict*(): VarsDict =
  ## Create a new empty variables dictionary. VarsDict is a ref type.
  result = newOrderedTable[string, Value]()

proc newValue*(str: string): Value =
  ## Create a string value.
  result = Value(kind: vkString, stringv: str)

proc newValue*(num: int | int64): Value =
  ## Create an integer value.
  result = Value(kind: vkInt, intv: num)

proc newValue*(num: float): Value =
  ## Create a float value.
  result = Value(kind: vkFloat, floatv: num)

proc newValue*(valueList: seq[Value]): Value =
  ## Create a list value.
  result = Value(kind: vkList, listv: valueList)

proc newValue*(varsDict: VarsDict): Value =
  ## Create a dictionary value from a VarsDict.
  result = Value(kind: vkDict, dictv: varsDict)

proc newValue*(value: Value): Value =
  ## New value from an existing value. Since values are ref types, the
  ## new value is an alias to the same value.
  result = value

proc newValue*[T](list: openArray[T]): Value =
  ## New list value from an array of items of the same kind.
  ## @:
  ## @:~~~
  ## @:let listValue = newValue([1, 2, 3])
  ## @:let listValue = newValue(["a", "b", "c"])
  ## @:let listValue = newValue([newValue(1), newValue("b")])
  ## @:~~~~
  var valueList: seq[Value]
  for num in list:
    valueList.add(newValue(num))
  result = Value(kind: vkList, listv: valueList)

proc newValue*[T](dictPairs: openArray[(string, T)]): Value =
  ## New dict value from an array of pairs where the pairs are the
  ## same type (may be Value type).
  ##
  ## let dictValue = newValue([("a", 1), ("b", 2), ("c", 3)])
  ## let dictValue = newValue([("a", 1.1), ("b", 2.2), ("c", 3.3)])
  ## let dictValue = newValue([("a", newValue(1.1)), ("b", newValue("a"))])
  var varsTable = newVarsDict()
  for tup in dictPairs:
    let (a, b) = tup
    let value = newValue(b)
    varsTable[a] = value
  result = Value(kind: vkDict, dictv: varsTable)

proc newEmptyListValue*(): Value =
  ## Return an empty list value.
  var valueList: seq[Value]
  result = newValue(valueList)

proc newEmptyDictValue*(): Value =
  ## Create a dictionary value from a VarsDict.
  result = newValue(newVarsDict())

proc `==`*(value1: Value, value2: Value): bool =
  ## Return true when two values are equal.
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

func newValueOrWarning*(value: Value): ValueOrWarning =
  ## Return a new ValueOrWarning object containing a value.
  result = ValueOrWarning(kind: vwValue, value: value)

func newValueOrWarning*(warning: Warning, p1: string = "",
    p2: string = ""): ValueOrWarning =
  ## Return a new ValueOrWarning object containing a warning.
  let warningData = newWarningData(warning, p1, p2)
  result = ValueOrWarning(kind: vwWarning, warningData: warningData)

func newValueOrWarning*(warningData: WarningData): ValueOrWarning =
  ## Return a new ValueOrWarning object containing a warning.
  result = ValueOrWarning(kind: vwWarning, warningData: warningData)

func `==`*(vw1: ValueOrWarning, vw2: ValueOrWarning): bool =
  ## Compare two ValueOrWarning objects and return true when equal.
  if vw1.kind == vw2.kind:
    if vw1.kind == vwValue:
      result = vw1.value == vw2.value
    else:
      result = vw1.warningData == vw2.warningData

func `$`*(kind: ValueKind): string =
  ## Return a string representation of a value's type.
  case kind
  of vkString:
    result = "string"
  of vkInt:
    result = "int"
  of vkFloat:
    result = "float"
  of vkDict:
    result = "dict"
  of vkList:
    result = "list"
