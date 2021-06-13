## StaticTea variable types.

import std/strutils
import std/tables
import std/json
import env
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
  ## @
  ## let listValue = newValue([1, 2, 3])
  ## let listValue = newValue(["a", "b", "c"])
  ## let listValue = newValue([newValue(1), newValue("b")])
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

when defined(test):
  proc newListValue*[T](args: varargs[T]): Value =
    ## Return a list value from any number of parameters of the same
    ## type. For an empty list use newEmptyListValue.
    ## @
    ## let strings = newListValue("a", "b", "c")
    ## let intList = newListValue(1, 2)
    ## let intList = newListValue(newValue(1), newValue("a"))
    var valueList: seq[Value]
    for arg in args:
      valueList.add(newValue(arg))
    result = newValue(valueList)

  proc newDictValue*[T](args: varargs[(string, T)]): Value =
    ## New dict value from any number of pairs where the pairs are the
    ## same type.
    ## @
    ## let dictValue = newValue(("a", 1), ("b", 2), ("c", 3))
    ## let dictValue = newValue(("a", 1.1), ("b", 2.2), ("c", 3.3))
    ## let dictValue = newValue(("a", newValue(1.1)), ("b", newValue("a")))
    ##
    ## See newValue that takes an array.
    var varsDict = newVarsDict()
    for tup in args:
      let (a, b) = tup
      let value = newValue(b)
      varsDict[a] = value
    result = newValue(varsDict)

# todo: move the toString methods to their own module.
# Recursive prototype.
func valueToString*(value: Value): string

func dictToString*(value: Value): string =
  ## Return a string representation of a dict Value in JSON format.
  result.add("{")
  var insideLines: seq[string]
  for k, v in value.dictv.pairs:
    insideLines.add("$1:$2" % [escapeJson(k), valueToString(v)])
  result.add(insideLines.join(","))
  result.add("}")

func listToString*(value: Value): string =
  ## Return a string representation of a list Value in JSON format.
  result.add("[")
  var insideLines: seq[string]
  for item in value.listv:
    insideLines.add(valueToString(item))
  result.add(insideLines.join(","))
  result.add("]")

func valueToString*(value: Value): string =
  ## Return a string representation of a Value in JSON format.
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

func `$`*(value: Value): string =
  ## Return a string representation of a Value.
  result = valueToString(value)

func shortValueToString*(value: Value): string =
  ## Return a string representation of Value. This is used to convert
  ## values to strings in replacement blocks.
  case value.kind
  of vkString:
    result = value.stringv
  of vkInt:
    result = $value.intv
  of vkFloat:
    result = $value.floatv
  of vkDict:
    if value.dictv.len == 0:
      result = "{}"
    else:
      result = "{...}"
  of vkList:
    if value.listv.len == 0:
      result = "[]"
    else:
      result = "[...]"

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

proc `$`*(varsDict: VarsDict): string =
  ## Return a string representation of a VarsDict.
  result = valueToString(newValue(varsDict))

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

func `$`*(vw: ValueOrWarning): string =
  ## Return a string representation of a ValueOrWarning object.
  if vw.kind == vwValue:
    result = $vw.value
  else:
    result = $vw.warningData

# todo: move statement types and methods to another file.

type
  Statement* = object
    ## A Statement object stores the statement text and where it
    ## starts in the template file.
    ## @
    ## @ * lineNum -- Line number starting at 1 where the statement
    ## @              starts.
    ## @ * start -- Column position starting at 1 where the statement
    ## @            starts on the line.
    ## @ * text -- The statement text.
    lineNum*: Natural
    start*: Natural
    text*: string

  # todo: move ValueAndLength to another file.
  ValueAndLength* = object
    ## A value and the length of the matching text in the statement.
    ## For the example statement: "var = 567 ". The value 567 starts
    ## at index 6 and the matching length is 4 because it includes the
    ## trailing space. For example "id = row(3 )" the value is 3 and
    ## the length is 2.
    value*: Value
    length*: Natural

func newStatement*(text: string, lineNum: Natural = 1,
    start: Natural = 1): Statement =
  ## Create a new statement.
  result = Statement(lineNum: lineNum, start: start, text: text)

proc startColumn*(start: Natural): string =
  ## Return enough spaces to point at the warning column.  Used under
  ## the statement line.
  for ix in 0..<start:
    result.add(' ')
  result.add("^")

proc warnStatement*(env: var Env, statement: Statement, warning:
                    Warning, start: Natural, p1: string = "", p2:
                                         string = "") =
  ## Warn about an invalid statement. Show and tell the statement with
  ## the problem.  Start is the position in the statement where the
  ## problem starts. If the statement is long, trim it around the
  ## problem area.

  var fragment: string
  var extraStart = ""
  var extraEnd = ""
  let fragmentMax = 60
  let halfFragment = fragmentMax div 2
  var startPos: int
  var endPos: int
  var pointerPos: int
  if statement.text.len <= fragmentMax:
    fragment = statement.text
    startPos = start
    pointerPos = start
  else:
    startPos = start.int - halfFragment
    if startPos < 0:
      startPos = 0
    else:
      extraStart = "..."

    endPos = startPos + fragmentMax
    if endPos > statement.text.len:
      endPos = statement.text.len
    else:
      extraEnd = "..."
    fragment = extraStart & statement.text[startPos ..< endPos] & extraEnd
    pointerPos = start.int - startPos + extraStart.len

  var message = """
$1
statement: $2
           $3""" % [
    getWarning(env.templateFilename, statement.lineNum, warning, p1, p2),
    fragment,
    startColumn(pointerPos)
  ]
  env.outputWarning(message)

func `==`*(s1: Statement, s2: Statement): bool =
  ## Return true when the two statements are equal.
  if s1.lineNum == s2.lineNum and s1.start == s2.start and
      s1.text == s2.text:
    result = true

func `$`*(s: Statement): string =
  ## Retrun a string representation of a Statement.
  result = "$1, $2: '$3'" % [$s.lineNum, $s.start, s.text]

proc newValueAndLength*(value: Value, length: Natural): ValueAndLength =
  ## Create a newValueAndLength object.
  result = ValueAndLength(value: value, length: length)
