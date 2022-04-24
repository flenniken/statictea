## StaticTea variable types.

import std/tables
import std/json
import warnings
import opresultwarn

type
  VarsDict* = OrderedTableRef[string, Value]
    ## The statictea dictionary type. This is a ref type. Create a new
    ## @:VarsDict with newVarsDict procedure.

  VarsDictOr* = OpResultWarn[VarsDict]

  ValueKind* = enum
    ## The statictea variable types.
    vkString,
    vkInt,
    vkFloat,
    vkDict,
    vkList

  Value* = ref ValueObj
    ## A variable's value reference.

  ValueOr* = OpResultWarn[Value]

  ValueObj {.acyclic.} = object
    ## A variable's value object.
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

proc newVarsDict*(): VarsDict =
  ## Create a new empty variables dictionary. VarsDict is a ref type.
  result = newOrderedTable[string, Value]()

func newVarsDictOr*(warning: Warning, p1: string = "", pos = 0):
     VarsDictOr =
  ## Return a new varsDictOr object containing a warning.
  let warningData = newWarningData(warning, p1, pos)
  result = opMessageW[VarsDict](warningData)

func newVarsDictOr*(varsDict: VarsDict): VarsDictOr =
  ## Return a new VarsDict object containing a dictionary.
  result = opValueW[VarsDict](varsDict)

proc newValue*(str: string): Value =
  ## Create a string value.
  result = Value(kind: vkString, stringv: str)

proc newValue*(num: int | int64): Value =
  ## Create an integer value.
  result = Value(kind: vkInt, intv: num)

proc newValue*(a: bool): Value =
  ## Create an integer value from a bool.
  var num: int64
  if a:
    num = 1
  else:
    num = 0
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
  ## @:new value is an alias to the same value.
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
  ## @:same type which may be Value type.
  ## @:
  ## @:~~~
  ## @: let dictValue = newValue([("a", 1), ("b", 2), ("c", 3)])
  ## @: let dictValue = newValue([("a", 1.1), ("b", 2.2), ("c", 3.3)])
  ## @: let dictValue = newValue([("a", newValue(1.1)), ("b", newValue("a"))])
  ## @:~~~~
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
  ## Return true when two variables are equal.
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

func `$`*(kind: ValueKind): string =
  ## Return a string representation of the variable's type.
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

# Recursive prototype.
func valueToString*(value: Value): string

func dictToString*(value: Value): string =
  ## Return a string representation of a dict Value in JSON format.
  result.add("{")
  var ix = 0
  for k, v in value.dictv.pairs:
    if ix > 0:
      result.add(",")
    result.add(escapeJson(k))
    result.add(":")
    result.add(valueToString(v))
    inc(ix)
  result.add("}")

func listToString*(value: Value): string =
  ## Return a string representation of a list variable in JSON format.
  result.add("[")
  for ix, item in value.listv:
    if ix > 0:
      result.add(",")
    result.add(valueToString(item))
  result.add("]")

func valueToString*(value: Value): string =
  ## Return a string representation of a variable in JSON format.
  case value.kind:
    of vkDict:
      result.add(dictToString(value))
    of vkList:
      result.add(listToString(value))
    of vkString:
      result.add(escapeJson(value.stringv))
    of vkInt:
      result.add($value.intv)
    of vkFloat:
      result.add($value.floatv)

func valueToStringRB*(value: Value): string =
  ## Return the string representation of the variable for use in the
  ## replacement blocks.
  case value.kind
  of vkString:
    result = value.stringv
  of vkInt:
    result = $value.intv
  of vkFloat:
    result = $value.floatv
  of vkDict:
    result.add(dictToString(value))
  of vkList:
    result.add(listToString(value))

func `$`*(value: Value): string =
  ## Return a string representation of a Value.
  result = valueToString(value)

proc `$`*(varsDict: VarsDict): string =
  ## Return a string representation of a VarsDict.
  result = valueToString(newValue(varsDict))

func newValueOr*(warning: Warning, p1 = "", pos = 0): ValueOr =
  ## Create a new ValueOr containing a warning.
  let warningData = newWarningData(warning, p1, pos)
  result = opMessageW[Value](warningData)

func newValueOr*(warningData: WarningData): ValueOr =
  ## Create a new ValueOr containing a warning.
  result = opMessageW[Value](warningData)

func newValueOr*(value: Value): ValueOr =
  ## Create a new ValueOr containing a value.
  result = opValueW[Value](value)
