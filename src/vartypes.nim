## StaticTea variable types.

import std/tables
import std/strutils
import messages
import warnings
import opresultwarn

type
  VarsDict* = OrderedTableRef[string, Value]
    ## The statictea dictionary type. This is a ref type. Create a new
    ## @:VarsDict with newVarsDict procedure.

  Variables* = VarsDict
    ## Dictionary holding all statictea variables in multiple distinct
    ## logical dictionaries.

  VarsDictOr* = OpResultWarn[VarsDict]

  ValueKind* = enum
    ## The statictea variable types.
    vkString,
    vkInt,
    vkFloat,
    vkDict,
    vkList,
    vkBool
    vkFunc


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
    of vkBool:
      boolv*: bool
    of vkFunc:
      funcv*: Func

  FunctionPtr* = proc (variables: Variables, parameters: seq[Value]):
      FunResult {.noSideEffect.}
    ## Signature of a statictea function. It takes any number of values
    ## and returns a value or a warning message.

  Func* = ref FunctionSpec
    ## A func value is a reference to a FunctionSpec.

  FunctionSpec* = object
    ## The name of a function, a pointer to the code, and its signature
    ## code.
    name*: string
    functionPtr*: FunctionPtr
    signatureCode*: string

  FunResultKind* = enum
    ## The kind of a FunResult object, either a value or warning.
    frValue,
    frWarning

  FunResult* = object
    ## Contains the result of calling a function, either a value or a
    ## warning.
    case kind*: FunResultKind
      of frValue:
        value*: Value       ## Return value of the function.
      of frWarning:
        parameter*: Natural ## Index of problem parameter.
        warningData*: WarningData

proc newVarsDict*(): VarsDict =
  ## Create a new empty variables dictionary. VarsDict is a ref type.
  result = newOrderedTable[string, Value]()

func newVarsDictOr*(warning: MessageId, p1: string = "", pos = 0):
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
  ## Create a bool value.
  result = Value(kind: vkBool, boolv: a)

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

func newFunc*(name: string, functionPtr: FunctionPtr, signatureCode: string): Func =
  ## Create a new func which is a reference to a FunctionSpec.
  new(result)
  result[] = FunctionSpec(name: name, functionPtr: functionPtr, signatureCode: signatureCode)

func newFunc*(functionSpec: FunctionSpec): Func =
  ## Create a new func which is a reference to a FunctionSpec.
  new(result)
  result[] = functionSpec

func newValue*(function: Func): Value =
  ## Create a new func value.
  result = Value(kind: vkFunc, funcv: function)

proc newEmptyListValue*(): Value =
  ## Return an empty list value.
  var valueList: seq[Value]
  result = newValue(valueList)

proc newEmptyDictValue*(): Value =
  ## Create a dictionary value from a VarsDict.
  result = newValue(newVarsDict())

proc `==`*(a: Value, b: Value): bool =
  ## Return true when two variables are equal.
  if a.kind == b.kind:
    case a.kind:
      of vkString:
        result = a.stringv == b.stringv
      of vkInt:
        result = a.intv == b.intv
      of vkFloat:
        result = a.floatv == b.floatv
      of vkDict:
        result = a.dictv == b.dictv
      of vkList:
        result = a.listv == b.listv
      of vkBool:
        result = a.boolv == b.boolv
      of vkFunc:
        result = a.funcv == b.funcv

func `$`*(function: Func): string =
  ## Return a string representation of a function.
  let length = function.signatureCode.len
  let parmCodes = function.signatureCode[0..length-2]
  let returnCode = function.signatureCode[length-1..length-1]
  result = "\"$1($2)$3\"" % [function.name, parmCodes, returnCode]

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
  of vkBool:
    result = "bool"
  of vkFunc:
    result = "func"

proc jsonStringRepr*(str: string): string =
  ## Return the JSON string representation. It is assumed the string
  ## is a valid UTF-8 encoded string.

  # n   U+000A   line feed
  # r   U+000D   carriage return
  # "   U+0022   quotation mark
  # t   U+0009   tab
  # \   U+005C   reverse solidus
  # b   U+0008   backspace
  # f   U+000C   form feed
  # /   U+002F   solidus

  # * Popular characters ordered by ascii value: 8, 9, a, c, d, 22, 2f, 5c.
  # * Escaped characters by ascii value: 0 - 1f, 22, 5c.
  # * Escaped characters, except popular, by ascii ranges:
  #     0 - 7, b, e - 1f.
  # * The unescaped characters are 20 - 21,  23 - 5B and 5D - 10FFFF.

  # You must escape quote, reverse solidus and all 0 - 1f.  In the
  # control character range 0 - 1f use the compact popular escaping
  # for: \n, \r, \t, \b, \f. The solidus character is outside the
  # range but you escape it too \/.

  # Order by popularity: nr"t\bf/

  result.add("\"")
  for byteChar in str:
    case byteChar
    of '\n': result.add("\\n")
    of '\r': result.add("\\r")
    of '"': result.add("\\\"")
    of '\t': result.add("\\t")
    of '\\': result.add("\\\\")
    of '\b': result.add("\\b")
    of '\f': result.add("\\f")
    of '/': result.add("\\/")

    # Escaped characters, except popular, by ascii ranges:
    # 0 - 7, b, e - 1f.

    of '\0'..'\7', '\x0b':
      result.add("\\u000" & $ord(byteChar))
    of '\x0e'..'\x1f':
      result.add("\\u00" & toHex(ord(byteChar), 2))
    else:
      result.add(byteChar)
  result.add("\"")

# Recursive prototype.
func valueToString*(value: Value): string

# todo: string representation of a dict value as dot names.

func dictToString*(value: Value): string =
  ## Return a string representation of a dict Value in JSON format.
  result.add("{")
  var ix = 0
  for k, v in value.dictv.pairs:
    if ix > 0:
      result.add(",")
    result.add(jsonStringRepr(k))
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
      result.add(jsonStringRepr(value.stringv))
    of vkInt:
      result.add($value.intv)
    of vkFloat:
      result.add($value.floatv)
    of vkBool:
      result.add($value.boolv)
    of vkFunc:
      result.add($value.funcv)

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
  of vkBool:
    result = $value.boolv
  of vkFunc:
    result = $value.funcv

func `$`*(value: Value): string =
  ## Return a string representation of a Value.
  result = valueToString(value)

proc `$`*(varsDict: VarsDict): string =
  ## Return a string representation of a VarsDict.
  result = valueToString(newValue(varsDict))

func dotNameRep*(dict: VarsDict, leftSide: string = "", top = false): string =
  ## Return a dot name string representation of a dictionary. The top
  ## variables tells whether the dict is the variables dictionary.
  # Loop through the dictionary and flatten it to dot names.  Stop at
  # a leaf. A list is a leaf.  Use json for the leaf.

  if dict.len == 0:
    if leftSide == "":
      return ""
    return "$1 = {}" % leftSide

  ## Loop through the dictionary items.
  var first = true
  for k, v in pairs(dict):
    if first:
      first = false
    else:
      result.add("\n")

    ## Determine the left side. Do not show the l dictionary prefix
    ## except when it is empty.
    var left: string
    if leftSide == "":
      if top and k == "l" and v.dictv.len != 0:
        left = ""
      else:
        left = k
    else:
      left = "$1.$2" % [leftSide, k]

    if v.kind == vkDict:
      # Recursively call dotNameRep.
      result.add(dotNameRep(v.dictv, left))
    else:
      result.add("$1 = $2" % [left, $v])

func newValueOr*(warning: MessageId, p1 = "", pos = 0): ValueOr =
  ## Create a new ValueOr containing a warning.
  let warningData = newWarningData(warning, p1, pos)
  result = opMessageW[Value](warningData)

func newValueOr*(warningData: WarningData): ValueOr =
  ## Create a new ValueOr containing a warning.
  result = opMessageW[Value](warningData)

func newValueOr*(value: Value): ValueOr =
  ## Create a new ValueOr containing a value.
  result = opValueW[Value](value)


func newFunResultWarn*(warning: MessageId, parameter: Natural = 0,
    p1: string = "", pos = 0): FunResult =
  ## Return a new FunResult object containing a warning. It takes a
  ## message id, the index of the problem parameter, and the optional
  ## string that goes with the warning.
  let warningData = newWarningData(warning, p1, pos)
  result = FunResult(kind: frWarning, parameter: parameter,
                     warningData: warningData)

func newFunResultWarn*(warningData: Warningdata, parameter: Natural = 0): FunResult =
  ## Return a new FunResult object containing a warning created from a
  ## WarningData object.
  result = FunResult(kind: frWarning, parameter: parameter,
                     warningData: warningData)

func newFunResult*(value: Value): FunResult =
  ## Return a new FunResult object containing a value.
  result = FunResult(kind: frValue, value: value)

func `==`*(r1: FunResult, r2: FunResult): bool =
  ## Compare two FunResult objects and return true when equal.
  if r1.kind == r2.kind:
    case r1.kind:
      of frValue:
        result = r1.value == r2.value
      else:
        if r1.warningData == r2.warningData and
           r1.parameter == r2.parameter:
          result = true

proc `!=`*(a: FunResult, b: FunResult): bool =
  ## Compare two FunResult objects and return false when equal.
  result = not (a == b)

func `$`*(funResult: FunResult): string =
  ## Return a string representation of a FunResult object.
  case funResult.kind
  of frValue:
    result = $funResult.value
  else:
    result = "warning: " & $funResult.warningData & ": parameter " & $funResult.parameter
