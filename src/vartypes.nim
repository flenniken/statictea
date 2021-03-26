## StaticTea variable types.

import tables
import strutils
import env
import warnings

type
  VarsDict* = OrderedTable[string, Value]
    ## Variables dictionary type.

  ValueKind* = enum
    ## The type of Variables.
    vkString,
    vkInt,
    vkFloat,
    vkDict,
    vkList

  Value* = ref ValueObj
    ## Variable value reference.
  ValueObj* {.acyclic.} = object
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

  Statement* = object
    ## A Statement object stores the statement text and where it
    ## starts in the template file.
    ## ix0
    ## ix0 * lineNum -- Line number starting at 1 where the statement
    ## ix0             starts.
    ## ix0 * start -- Column position starting at 1 where the statement
    ## ix0           starts on the line.
    ## ix0 * text -- The statement text.
    lineNum*: Natural
    start*: Natural
    text*: string

  ValueAndLength* = object
    ## A value and the length of the matching text in the statement.
    ## For the example statement: "var = 567 ". The value 567 starts
    ## index 6 and the matching length is 4 because it includes the
    ## trailing spaces. For example "id = row( 3 )" the value is 3 and
    ## the length is 2.
    value*: Value
    length*: Natural

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
  ## Create a dictionary value.
  result = Value(kind: vkDict, dictv: varsDict)

proc newValue*(value: Value): Value =
  ## Copy the given value.
  result = value

proc newVarsDict*(): VarsDict =
  ## Create variables dictionary.
  return result

proc newValueAndLength*(value: Value, length: Natural): ValueAndLength =
  ## Create a newValueAndLength object.
  result = ValueAndLength(value: value, length: length)


when defined(test):
  proc newValue*[T](list: openArray[T]): Value =
    ## New list value from an array of items.
    var valueList: seq[Value]
    for num in list:
      valueList.add(newValue(num))
    result = Value(kind: vkList, listv: valueList)

  proc newValue*[T](dictPairs: openArray[(string, T)]): Value =
    ## New dict value from an array of pairs.
    var varsTable: VarsDict
    for tup in dictPairs:
      let (a, b) = tup
      let value = newValue(b)
      varsTable[a] = value
    result = Value(kind: vkDict, dictv: varsTable)

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

func `$`*(value: Value): string =
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

func `$`*(varsDict: VarsDict): string =
  ## Return a string representation of a VarsDict.
  var list = newSeq[string]()
  for k, v in varsDict.pairs():
    if v.kind == vkString:
      list.add(""""$1": "$2"""" % [k, v.stringv])
    else:
      list.add(""""$1": $2""" % [k, $v])
  result = "{$1}" % [list.join(", ")]

func `$`*(s: Statement): string =
  ## Retrun a string representation of a Statement.
  result = "$1, $2: '$3'" % [$s.lineNum, $s.start, s.text]

func `==`*(s1: Statement, s2: Statement): bool =
  ## Return true when the two statements are equal.
  if s1.lineNum == s2.lineNum and s1.start == s2.start and
      s1.text == s2.text:
    result = true

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
               fragment, startColumn(pointerPos)
  ]
  env.warn(message)
