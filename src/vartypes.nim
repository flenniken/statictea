## StaticTea variable types.

import tables
import strutils
import env
import warnings

const
  outputValues* = ["result", "stderr", "log", "skip"]

type
  VarsDict* = OrderedTable[string, Value]

  ValueKind* = enum
    vkString,
    vkInt,
    vkFloat,
    vkDict,
    vkList

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

  Statement* = object
    ## A Statement object stores the statement text and where it
    ## starts in the template file.
    ##
    ## * lineNum -- Line number starting at 1 where the statement
    ##              starts.
    ## * start -- Column position starting at 1 where the statement
    ##            starts on the line.
    ## * text -- The statement text.
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
  result = Value(kind: vkString, stringv: str)

proc newValue*(num: int): Value =
  result = Value(kind: vkInt, intv: num)

proc newValue*(num: float): Value =
  result = Value(kind: vkFloat, floatv: num)

proc newValue*(valueList: seq[Value]): Value =
  result = Value(kind: vkList, listv: valueList)

proc newValue*(varsDict: VarsDict): Value =
  result = Value(kind: vkDict, dictv: varsDict)

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
      result = "{...}"
  of vkList:
    if value.listv.len == 0:
      result = "[]"
    else:
      result = "[...]"

func `$`*(s: Statement): string =
  ## A string representation of a Statement.
  result = "$1, $2: '$3'" % [$s.lineNum, $s.start, s.text]

func `==`*(s1: Statement, s2: Statement): bool =
  ## Return true when the two statements are equal.
  if s1.lineNum == s2.lineNum and s1.start == s2.start and
      s1.text == s2.text:
    result = true

func newStatement*(text: string, lineNum: Natural = 1,
    start: Natural = 1): Statement =
  result = Statement(lineNum: lineNum, start: start, text: text)

proc startColumn*(start: Natural): string =
  ## Return a string containing the number of spaces and symbols to
  ## point at the line start value used under the statement line.
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

  env.warn(statement.lineNum, warning, p1, p2)
  env.warn("statement: $1" % fragment)
  env.warn("           $1" % startColumn(pointerPos))
