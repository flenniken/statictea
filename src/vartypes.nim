## StaticTea variable types.

import tables
import strutils

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

proc newStringValue*(str: string): Value =
  result = Value(kind: vkString, stringv: str)

proc newIntValue*(num: int64): Value =
  result = Value(kind: vkInt, intv: num)

proc newFloatValue*(num: float64): Value =
  result = Value(kind: vkFloat, floatv: num)

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
