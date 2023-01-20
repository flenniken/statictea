## StaticTea variable types.

import std/tables
import std/strutils
import messages
import opresult
import options

const
  variableStartChars*: set[char] = {'a'..'z', 'A'..'Z'}
    ## The characters that make up a variable dotname.  A variable
    ## starts with an ascii letter.
  variableMiddleChars*: set[char] = {'a'..'z', 'A'..'Z', '0' .. '9', '_', '-'}
    ## A variable contains ascii letters, digits, underscores and
    ## hypens.
  variableChars*: set[char] = {'a'..'z', '.', 'A'..'Z', '0' .. '9', '_', '-'}
    ## A variable contains ascii letters, digits, underscores and
    ## hypens. Variables are connected with dots to make a dot name.
  startTFVarNumber*: set[char] = {'a'..'z', 'A'..'Z', '0' .. '9', '-'}
    ## A character that starts true, false, a variable or a number.

type
  VarsDict* = OrderedTableRef[string, Value]
    ## The statictea dictionary type. This is a ref type. Create a new
    ## @:VarsDict with newVarsDict procedure.

  Variables* = VarsDict
    ## Dictionary holding all statictea variables in multiple distinct
    ## logical dictionaries.

  VarsDictOr* = OpResultWarn[VarsDict]
    ## A VarsDict object or a warning.

  ValueKind* = enum
    ## The statictea variable types.
    ## @:* vkString -- string of UTF-8 characters
    ## @:* vkInt -- 64 bit signed integer
    ## @:* vkFloat -- 64 bit floating point number
    ## @:* vkDict -- hash table mapping strings to any value
    ## @:* vkList -- a list of values of any type
    ## @:* vkBool -- true or false
    ## @:* vkFunc -- reference to a function
    vkString = "string"
    vkInt = "int"
    vkFloat = "float"
    vkDict = "dict"
    vkList = "list"
    vkBool = "bool"
    vkFunc = "func"

  Value* = ref ValueObj
    ## A variable's value reference.

  ValueOr* = OpResultWarn[Value]
    ## A Value object or a warning.

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
      funcv*: FunctionSpec

  Statement* = object
    ## A Statement object stores the statement text and where it
    ## @:starts in the template file.
    ## @:
    ## @:* text -- a line containing a statement without the line ending
    ## @:* lineNum -- line number in the file starting at 1 where the
    ## @:* ending -- the line ending, either \n or \r\n
    ## @:statement starts.
    text*: string
    lineNum*: Natural
    # todo: support ending so we can reproduce the original given a statement.
    # ending*: string

  FunctionPtr* = proc (variables: Variables, parameters: seq[Value]):
      FunResult {.noSideEffect.}
    ## Signature of a statictea built in function. It takes any number of values
    ## and returns a value or a warning message.

  ParamCode* = char
    ## Parameter type, one character of "ifsldpa" corresponding to int,
    ## float, string, list, dict, func, any.

  ParamType* = enum
    ## The statictea parameter types. The same as the variable types
    ## ValueKind with an extra for "any".
    ## @:* ptString -- string parameter type
    ## @:* ptInt -- integer
    ## @:* ptFloat -- floating point number
    ## @:* ptDict -- dictionary
    ## @:* ptList -- list
    ## @:* ptBool -- boolean
    ## @:* ptFunc -- function pointer
    ## @:* ptAny -- any parameter type
    ptString = "string"
    ptInt = "int"
    ptFloat = "float"
    ptDict = "dict"
    ptList = "list"
    ptBool = "bool"
    ptFunc = "func"
    ptAny = "any"

  Param* = object
    ## Holds attributes for one parameter.
    ## @:* name -- the parameter name
    ## @:* paramType -- the parameter type
    name*: string
    paramType*: ParamType

  Signature* = object
    ## Holds the function signature.
    ## @:* optional -- true when the last parameter is optional
    ## @:* name -- the function name
    ## @:* params -- a list of the function parameter names and types
    ## @:* returnType -- the function return type
    optional*: bool
    name*: string
    params*: seq[Param]
    returnType*: ParamType

  SignatureOr* = OpResultWarn[Signature]
    ## A signature or message.

  FunctionSpec* = object
    ## Holds the function details.
    ## @:
    ## @:* builtIn -- true for the built-in functions, false for user functions
    ## @:* signature -- the function signature
    ## @:* docComment -- the function document comment
    ## @:* filename -- the filename where the function is defined either the code file or functions.nim
    ## @:* lineNum -- the line number where the function definition starts
    ## @:* numLines -- the number of lines to define the function
    ## @:* statements -- a list of the function statements for user functions
    ## @:* functionPtr -- pointer to the function for built-in functions
    builtIn*: bool
    signature*: Signature
    docComment*: string
    filename*: string
    lineNum*: Natural
    numLines*: Natural
    statements*: seq[Statement]
    functionPtr*: FunctionPtr

  FunResultKind* = enum
    ## The kind of a FunResult object, either a value or warning.
    ## @:* frValue -- a value
    ## @:* frWarning -- a warning message
    frValue,
    frWarning

  FunResult* = object
    ## Contains the result of calling a function, either a value or a
    ## warning. The parameter field is the index of the problem
    ## argument or -1 to point at the function itself.
    case kind*: FunResultKind
      of frValue:
        value*: Value
      of frWarning:
        parameter*: int
        warningData*: WarningData

  SideEffect* = enum
    ## The kind of side effect for a statement.
    ## @:
    ## @:* seNone -- no side effect, the normal case
    ## @:* seReturn -- a return side effect, either stop or skip. stop
    ## @:the command or skip the replacement block iteration.
    ## @:* seLogMessage -- the log function specified to write a message to the log file
    ## @:* seBareIfIgnore -- the bare IF was false, ignore the statement
    seNone = "none",
    seReturn = "return",
    seLogMessage = "log",
    seBareIfIgnore = "bareIfIgnore",

  # todo: rename ValueAndPos to ValuePosSE
  ValueAndPos* = object
    ## A value and the position after the value in the statement along
    ## with the side effect, if any. The position includes the trailing
    ## whitespace.  For the example statement below, the value 567
    ## starts at index 6 and ends at position 10.
    ## @:
    ## @:~~~
    ## @:0123456789 123456789
    ## @:var = 567 # test
    ## @:      ^ start
    ## @:          ^ end position
    ## @:~~~~
    value*: Value
    pos*: Natural
    sideEffect*: SideEffect

  ValueAndPosOr* = OpResultWarn[ValueAndPos]
    ## A ValueAndPos object or a warning.

proc newSignature*(optional: bool, name: string, params: seq[Param], returnType: ParamType): Signature =
  ## Create a Signature object.
  result = Signature(optional: optional, name: name, params: params, returnType: returnType)

func newSignatureOr*(warning: MessageId, p1 = "", pos = 0): SignatureOr =
  ## Create a new SignatureOr with a message.
  let warningData = newWarningData(warning, p1, pos)
  result = opMessageW[Signature](warningData)

func newSignatureOr*(warningData: WarningData): SignatureOr =
  ## Create a new SignatureOr with a message.
  result = opMessageW[Signature](warningData)

func newSignatureOr*(signature: Signature): SignatureOr =
  ## Create a new SignatureOr with a value.
  result = opValueW[Signature](signature)

proc newSignatureOr*(optional: bool, name: string, params: seq[Param],
    returnType: ParamType): SignatureOr =
  ## Create a SignatureOr object.
  let signature = Signature(optional: optional, name: name, params: params, returnType: returnType)
  result = opValueW[Signature](signature)

func newParam*(name: string, paramType: ParamType): Param =
  ## Create a new Param object.
  result = Param(name: name, paramType: paramType)

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

func newFunc*(builtIn: bool, signature: Signature, docComment: string,
    filename: string, lineNum: Natural, numLines: Natural,
    statements: seq[Statement], functionPtr: FunctionPtr): FunctionSpec =
  ## Create a new func which is a FunctionSpec.

  when defined(test):
    if builtIn:
      if functionPtr == nil:
        raiseAssert("a built-in function requires a function pointer")
    else:
      if statements.len < 1:
        raiseAssert("a user function requires statement lines")

  result = FunctionSpec(builtIn: builtIn, signature: signature, docComment: docComment,
                          filename: filename, lineNum: lineNum, numLines: numLines,
                          statements: statements, functionPtr: functionPtr)

func newValue*(function: FunctionSpec): Value =
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

func newStatement*(text: string, lineNum: Natural = 1): Statement =
  ## Create a new statement.
  result = Statement(lineNum: lineNum, text: text)

func `$`*(signature: Signature): string =
  ## Return a string representation of a signature.
  result.add(signature.name)
  result.add("(")
  for ix, param in signature.params:
    if ix > 0:
      result.add(", ")
    result.add(param.name)
    result.add(": ")
    if signature.optional and ix == signature.params.len - 1:
      result.add("optional ")
    result.add($param.paramType)
  result.add(") ")
  result.add($signature.returnType)

func `$`*(function: FunctionSpec): string =
  ## Return a string representation of a function.
  result.add("\"")
  result.add(function.signature.name)
  result.add("\"")

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
    result = value.funcv.signature.name

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

func newFunResultWarn*(warning: MessageId, parameter: int = 0,
    p1: string = "", pos = 0): FunResult =
  ## Return a new FunResult object containing a warning. It takes a
  ## message id, the index of the problem parameter, and the optional
  ## string that goes with the warning.
  let warningData = newWarningData(warning, p1, pos)
  result = FunResult(kind: frWarning, parameter: parameter,
                     warningData: warningData)

func newFunResultWarn*(warningData: Warningdata, parameter: int = 0): FunResult =
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

proc newValueAndPos*(value: Value, pos: Natural,
    sideEffect: SideEffect = seNone): ValueAndPos =
  ## Create a newValueAndPos object.
  result = ValueAndPos(value: value, pos: pos, sideEffect: sideEffect)

func newValueAndPosOr*(warning: MessageId, p1 = "", pos = 0):
    ValueAndPosOr =
  ## Create a ValueAndPosOr warning.
  let warningData = newWarningData(warning, p1, pos)
  result = opMessageW[ValueAndPos](warningData)

func newValueAndPosOr*(warningData: WarningData):
    ValueAndPosOr =
  ## Create a ValueAndPosOr warning.
  result = opMessageW[ValueAndPos](warningData)

proc `==`*(a: ValueAndPosOr, b: ValueAndPosOr): bool =
  ## Return true when a equals b.
  if a.kind == b.kind:
    if a.isMessage:
      result = a.message == b.message
    else:
      result = a.value == b.value

proc `!=`*(a: ValueAndPosOr, b: ValueAndPosOr): bool =
  ## Compare two ValueAndPosOr objects and return false when equal.
  result = not (a == b)

func newValueAndPosOr*(value: Value, pos: Natural, sideEffect: SideEffect = seNone):
    ValueAndPosOr =
  ## Create a ValueAndPosOr from a value, pos and exit.
  let val = ValueAndPos(value: value, pos: pos, sideEffect: sideEffect)
  result = opValueW[ValueAndPos](val)

proc newValueAndPosOr*(number: int | int64 | float64 | string,
    pos: Natural): ValueAndPosOr =
  ## Create a ValueAndPosOr value from a number or string.
  result = newValueAndPosOr(newValue(number), pos)

func newValueAndPosOr*(val: ValueAndPos):
    ValueAndPosOr =
  ## Create a ValueAndPosOr from a ValueAndPos.
  result = opValueW[ValueAndPos](val)

const
  singleCodes = {'a', 'i', 'f', 's', 'l', 'd', 'b', 'p'}

static:
  # Generate a compile error when the single code list doesn't have a
  # letter for each type of value excluding "a".
  const numCodes = len(singleCodes)-1
  const numKinds = ord(high(ValueKind))+1
  when numCodes != numKinds:
    const message = "Update singleCodes:\nnumCode = $1, numKinds = $2\n" % [$numCodes, $numKinds]
    {.error: message .}

func codeToParamType*(code: ParamCode): ParamType =
  ## Convert a parameter code letter to a ParamType.
  case code:
  of 'i':
    result = ptInt
  of 'f':
    result = ptFloat
  of 's':
    result = ptString
  of 'l':
    result = ptList
  of 'd':
    result = ptDict
  of 'b':
    result = ptBool
  of 'p':
    result = ptFunc
  of 'a':
    result = ptAny
  else:
    assert(false, "invalid ParamCode")
    result = ptInt

func strToParamType*(str: string): ParamType =
  ## Return the parameter type for the given string, e.g. "int" to
  ## ptInt.
  case str:
  of "int":
    result = ptInt
  of "float":
    result = ptFloat
  of "string":
    result = ptString
  of "list":
    result = ptList
  of "dict":
    result = ptDict
  of "bool":
    result = ptBool
  of "func":
    result = ptFunc
  of "any":
    result = ptAny
  else:
    assert(false, "invalid parameter type string")
    result = ptInt

proc shortName*(index: Natural): string =
  ## Return a short name based on the given index value. Return a for
  ## 0, b for 1, etc.  It returns names a, b, c, ..., z then repeats
  ## a0, b0, c0,....

  const
    letters = "abcdefghijklmnopqrstuvwxyz"
  let remainder = index mod len(letters)
  let num = index div len(letters)

  result = $letters[remainder]
  if num != 0:
    result &= $num

func newSignatureO*(functionName: string, signatureCode: string): Option[Signature] =
  ## Return a new signature for the function name and signature code.
  ## The parameter names come from the shortName function for letters
  ## a through z in order. The last letter in the code is the
  ## function's return type.
  ## @:
  ## @:Example:
  ## @:
  ## @:~~~
  ## @:var signatureO = newSignatureO("myname", "ifss")
  ## @:echo $signatureO.get()
  ## @:=>
  ## @:myname(a: int, b: float, c: string) string
  ## @:~~~~

  var params: seq[Param]
  var nameIx = 0
  var optional = false

  if len(signatureCode) < 1:
    return
  for ix in countUp(0, signatureCode.len - 2):
    var code = signatureCode[ix]
    if code in singleCodes:
      let parmType = codeToParamType(code)
      params.add(newParam(shortName(nameIx), parmType))
      inc(nameIx)
    elif code == 'o':
      if optional:
        # You can only have one optional parameter.
        return
      optional = true
    else:
      # Invalid signature code.
      return

  let returnCode = signatureCode[signatureCode.len-1]
  let returnType = codeToParamType(returnCode)
  result = some(newSignature(optional, functionName, params, returnType))
