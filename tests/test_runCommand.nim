import std/unittest
import std/options
import std/strutils
import std/tables
import runCommand
import runFunction
import parseCmdLine
import env
import args
import vartypes
import variables
import messages
import version
import opresult
import sharedtestcode
import codefile
import readjson
import comparelines
import unicodes
import utf8decoder

proc echoValueAndPosOr(statement: Statement, start: Natural,
    valueAndPosOr: ValueAndPosOr, eValueAndPosOr: ValueAndPosOr) =
  ## Show the statement and the two values and positions so you can
  ## visually compare them.
  echo ""
  echo "0123456789 123456789 123456789"
  echo statement.text
  echo startColumn(statement.text, start, "^ s")
  echo ""
  echo "got:"
  if valueAndPosOr.isValue:
    echo "value: $1" % $valueAndPosOr.value
    echo "0123456789 123456789 123456789"
    echo statement.text
    echo startColumn(statement.text, valueAndPosOr.value.pos, "^ pos")
  else:
    echo getWarnStatement("filename", statement, valueAndPosOr.message)

  echo "expected:"
  if eValueAndPosOr.isValue:
    echo "value: $1" % $eValueAndPosOr.value
    echo "0123456789 123456789 123456789"
    echo statement.text
    echo startColumn(statement.text, eValueAndPosOr.value.pos, "^ pos")
  else:
    echo getWarnStatement("filename", statement, eValueAndPosOr.message)
  echo ""

proc testGetValueAndPos(statement: Statement, start: Natural,
    eValueAndPosOr: ValueAndPosOr, variables: Variables = nil): bool =

  # Set up variables when not passed in.
  var vars = variables
  if vars == nil:
    let funcsVarDict = createFuncDictionary().dictv
    vars = emptyVariables(funcs = funcsVarDict)

  let valueAndPosOr = getValueAndPos(statement, start, vars)

  result = true
  if valueAndPosOr != eValueAndPosOr:
    result = false
    echoValueAndPosOr(statement, start, valueAndPosOr, eValueAndPosOr)

proc testGetValueAndPos(text: string, start: Natural,
    eWarning: MessageId, pos = 0, p1 = "", variables: Variables = nil): bool =
  let statement = newStatement(text)
  let eValueAndPosOr = newValueAndPosOr(eWarning, p1, pos)
  result = testGetValueAndPos(statement, start, eValueAndPosOr, variables)

proc testGetValueAndPos(text: string, start: Natural,
    ePos: Natural, eJson: string, variables: Variables = nil): bool =
  let statement = newStatement(text)
  let eValue = readJsonString(eJson)
  if eValue.isMessage:
    echo "eJson = " & eJson
    echo $eValue
    return false
  let eValueAndPosOr = newValueAndPosOr(eValue.value, ePos)
  result = testGetValueAndPos(statement, start, eValueAndPosOr, variables)

proc testGetMultilineStr(pattern: string, start: Natural,
    eStr: string, ePos: Natural): bool =
  # Test getMultilineStr.

  let text = pattern % tripleQuotes
  let valueAndPosOr = getMultilineStr(text, start)
  if valueAndPosOr.isMessage:
    echo "Unexpected error: " & $valueAndPosOr
    return false
  let eValueAndPosOr = newValueAndPosOr(eStr, ePos)
  result = gotExpected($valueAndPosOr, $eValueAndPosOr)

  if not result:
    let statement = newStatement(text)
    echo visibleControl(text)
    echoValueAndPosOr(statement, start, valueAndPosOr, eValueAndPosOr)
  else:
    let literal = valueAndPosOr.value.value.stringv
    var pos = validateUtf8String(literal)
    if pos != -1:
      echo "Invalid UTF-8 bytes starting at $1." % $pos
      result = false

proc testGetMultilineStrE(pattern: string, start: Natural,
    eWarningData: WarningData): bool =
  ## Test getMultilineStr for expected errors.

  let text = pattern % tripleQuotes
  let valueAndPosOr = getMultilineStr(text, start)
  let eValueAndPosOr = newValueAndPosOr(eWarningData)
  result = gotExpected($valueAndPosOr, $eValueAndPosOr)
  if not result:
    let statement = newStatement(text)
    echo visibleControl(text)
    echoValueAndPosOr(statement, start, valueAndPosOr, eValueAndPosOr)

proc getCmdLinePartsTest(env: var Env,
    commandLines: seq[string]): seq[LineParts] =
  ## Return the line parts from the given lines. Only used for
  ## testing. It doesn't work for custom prefixes.
  let prepostTable = makeDefaultPrepostTable()
  for ix, line in commandLines:
    let linePartsOr = parseCmdLine(prepostTable, line, lineNum = ix + 1)
    if linePartsOr.isMessage:
      echo "cannot get command line parts for:"
      echo """line: "$1"""" % line
      echo $linePartsOr
    result.add(linePartsOr.value)

proc getStatements(cmdLines: CmdLines): seq[Statement] =
  ## Return a list of statements for the given lines.
  for statement in yieldStatements(cmdLines):
    result.add(statement)

proc stripNewline(line: string): string =
  ## Remove an ending newline if it exists.
  if line.len > 0 and line[^1] == '\n':
    result = line[0 .. ^2]
  else:
    result = line

proc compareStatements(statements: seq[Statement], eContent: string): bool =
  ## Return true when the statements match the expected statements.
  let lines = splitNewLines(eContent)
  for ix, statement in statements:
    let expected = stripNewline(lines[ix])
    let got = $statement
    if got != expected:
      echo "     got: $1" % got
      echo "expected: $1" % expected
      return false
  return true

proc testGetStatements(content: string, expected: string): bool =
  ## Return true when the template content generates the expected statements.

  var env = openEnvTest("_getStatements.txt")
  var cmdLines: CmdLines
  cmdLines.lines = splitNewLines(content)
  cmdLines.lineParts = getCmdLinePartsTest(env, cmdLines.lines)

  var statements = getStatements(cmdLines)

  discard env.readCloseDeleteEnv()

  result = true
  if not compareStatements(statements, expected):
    result = false

proc testGetNumber(statement: Statement, start: Natural,
    eValueAndPosOr: ValueAndPosOr): bool =
  ## Return true when the statement contains the expected number. When
  ## it doesn't, show the values and expected values and return false.

  let valueAndPosOr = getNumber(statement, start)
  result = gotExpected($valueAndPosOr, $eValueAndPosOr, statement.text)
  if not result:
    echoValueAndPosOr(statement, start, valueAndPosOr, eValueAndPosOr)

func sameNumBytesStr(text: string): Option[string] =
  ## Create an ascii string with the same number of bytes as the given
  ## UTF-8 string.
  var newStr = newStringOfCap(text.len+10)
  var ixFirst: int
  var ixLast: int
  var codePoint: uint32
  var pattern = "U234"
  for valid in yieldUtf8Chars(text, ixFirst, ixLast, codePoint):
    if not valid:
      # invalid UTF-8 byte sequence
      return
    let length = ixLast - ixFirst + 1
    if length == 1:
      newStr.add(text[ixFirst])
    elif length < 1 or length > 4:
      # A UTF-8 byte sequence is 1 to 4 bytes.
      return
    else:
      newStr.add(pattern[0 ..< length])
  result = some(newStr)

proc testSameNumBytesStr(str: string, eStr: string): bool =
  let stringO = sameNumBytesStr(str)
  if not stringO.isSome:
    echo "Invalid string"
    return false
  result = gotExpected(stringO.get(), eStr)

proc testStartColumn(text: string, start: Natural, eStr = "", message = "^"): bool =
  let str = startColumn(text, start, message)
  result = gotExpected(str, eStr)
  if not result:
    let stringO = sameNumBytesStr(text)
    if not stringO.isSome:
      echo "Invalid string"
      return false
    echo "start = " & $start
    echo stringO.get() & " - expanded bytes"
    echo "0123456789 123456789 123456789"
    echo text & " - text"
    echo str & " - got"
    echo eStr & " - expected"

proc testGetString(statement: Statement, start: Natural,
    eValueAndPosOr: ValueAndPosOr): bool =

  let valueAndPosOr = getString(statement, start)
  result = gotExpected($valueAndPosOr, $eValueAndPosOr)
  if not result:
    let numBytesStrO = sameNumBytesStr(statement.text)
    if not numBytesStrO.isSome:
      echo "invalid string"
      return false
    let numBytesStr = numBytesStrO.get()
    if numBytesStr != statement.text:
      echo numBytesStr

    echoValueAndPosOr(statement, start, valueAndPosOr, eValueAndPosOr)

proc testGetStringInvalid(buffer: seq[uint8]): bool =
  let str = bytesToString(buffer)
  let statement = newStatement("""a = "stringwithbadutf8:$1:end"""" % str)
  let start = 4
  let valueAndPosOr = getString(statement, start)
  let eValueAndPosOr = newValueAndPosOr(wInvalidUtf8ByteSeq, "23", 23)
  result = gotExpected($valueAndPosOr, $eValueAndPosOr)
  if not result:
    echoValueAndPosOr(statement, start, valueAndPosOr, eValueAndPosOr)

proc testWarnStatement(statement: Statement,
    warning: MessageId, start: Natural, p1: string="",
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[]
  ): bool =

  var env = openEnvTest("_getVariable.log")

  let warningData = newWarningData(warning, p1, start)
  env.warnStatement(statement, warningData)

  result = env.readCloseDeleteCompare(eLogLines, eErrLines, eOutLines)

proc testGetFunctionValueAndPos(
  functionName: string,
  statement: Statement,
  start: Natural,
  eValueAndPosOr: ValueAndPosOr
    ): bool =

  let funcsVarDict = createFuncDictionary().dictv
  let variables = emptyVariables(funcs = funcsVarDict)
  let valueAndPosOr = getFunctionValueAndPos(functionName,
    statement, start, variables, list=false)
  result = gotExpected($valueAndPosOr, $eValueAndPosOr, statement.text)
  if not result:
    echoValueAndPosOr(statement, start, valueAndPosOr, eValueAndPosOr)

proc testRunStatement(statement: Statement, eVariableDataOr: VariableDataOr, variables: Variables = nil): bool =
  var vars: Variables
  if variables == nil:
    let funcsVarDict = createFuncDictionary().dictv
    vars = emptyVariables(funcs = funcsVarDict)
  else:
    vars = variables
  let variableDataOr = runStatement(statement, vars)
  result = gotExpected($variableDataOr, $eVariableDataOr)
  if not result:
    echo statement.text
    if variableDataOr.isMessage:
      echo "got:"
      echo getWarnStatement("filename", statement, variableDataOr.message)
    if eVariableDataOr.isMessage:
      echo "expected:"
      echo getWarnStatement("filename", statement, eVariableDataOr.message)


proc testRunBoolOp(left: bool | Value, op: string, right: bool | Value, eValue: Value): bool =
  let value = runBoolOp(newValue(left), op, newValue(right))
  result = true
  if value != eValue:
    result = gotExpected($value, $eValue)

proc testRunCompareOp(left: bool | Value, op: string, right: bool | Value, eValue: Value): bool =
  let value = runCompareOp(newValue(left), op, newValue(right))
  result = true
  if value != eValue:
    result = gotExpected($value, $eValue)

proc testSkipArgument(text: string, startPos: Natural, ePosOr: PosOr): bool =
  let statement = newStatement(text)
  let posOr = skipArgument(statement, startPos)
  result = true
  if posOr != ePosOr:
    result = gotExpected($posOr, $ePosOr)

    echo "          10        20        30        40"
    echo "0123456789 123456789 123456789 123456789 123456789"
    echo text
    echo startColumn(text, startPos, "^ start")
    if posOr.isValue:
      echo startColumn(text, posOr.value, "^ got")
    else:
      echo startColumn(text, posOr.message.pos, "^ got")
    if ePosOr.isValue:
      echo startColumn(text, ePosOr.value, "^ expected")
    else:
      echo startColumn(text, ePosOr.message.pos, "^ expected")

proc testGetCondition(text: string, start: Natural, eBool: bool, ePos: Natural): bool =
  let funcsVarDict = createFuncDictionary().dictv
  let variables = emptyVariables(funcs = funcsVarDict)

  let statement = newStatement(text)
  let valueAndPosOr = getCondition(statement, start, variables)
  let eValueAndPosOr = newValueAndPosOr(newValue(eBool), ePos)
  result = gotExpected($valueAndPosOr, $eValueAndPosOr)
  if not result:
    echoValueAndPosOr(statement, start, valueAndPosOr, eValueAndPosOr)

proc testGetConditionWarn(text: string, start: Natural, eWarning: MessageId,
    ePos = 0, eP1 = ""): bool =
  let funcsVarDict = createFuncDictionary().dictv
  let variables = emptyVariables(funcs = funcsVarDict)
  let statement = newStatement(text)
  let valueAndPosOr = getCondition(statement, start, variables)
  let eValueAndPosOr = newValueAndPosOr(eWarning, eP1, ePos)
  result = gotExpected($valueAndPosOr, $eValueAndPosOr)
  if not result:
    echoValueAndPosOr(statement, start, valueAndPosOr, eValueAndPosOr)

suite "runCommand.nim":
  test "startColumn":
    check testStartColumn("abcdefghij", 0, "^")
    check testStartColumn("abcdefghij", 1, " ^")
    check testStartColumn("abcdefghij", 2, "  ^")
    check testStartColumn("abcdefghij", 2, "  ", "")
    check testStartColumn("abcdefghij", 2, "  ^ start", "^ start")
    let twoBytes = bytesToString(@[0xc3u8, 0xb1])
    let threeBytes = bytesToString(@[0xe2u8, 0x82, 0xa1])
    let fourBytes = bytesToString(@[0xf0u8, 0x90, 0x8c, 0xbc])
    check testStartColumn(twoBytes & "abcdefghij", 0, "^")
    check testStartColumn(twoBytes & "abcdefghij", 1, " ^")
    check testStartColumn(twoBytes & "abcdefghij", 2, " ^")
    check testStartColumn(twoBytes & "abcdefghij", 3, "  ^")
    check testStartColumn(twoBytes & "abcdefghij", 4, "   ^")
    let text = "abc" & twoBytes & "de" & threeBytes & "fg" & fourBytes & "h"
    check testStartColumn(text, 0, "^")
    check testStartColumn(text, 2, "  ^")
    check testStartColumn(text, 3, "   ^")
    check testStartColumn(text, 4, "    ^")
    check testStartColumn(text, 5, "    ^")
    check testStartColumn(text, 6, "     ^")
    check testStartColumn(text, 7, "      ^")
    check testStartColumn(text, 8, "       ^")
    check testStartColumn(text, 9, "       ^")
    check testStartColumn(text, 10, "       ^")
    check testStartColumn(text, 11, "        ^")
    check testStartColumn(text, 12, "         ^")
    check testStartColumn(text, 13, "          ^")
    check testStartColumn(text, 14, "          ^")
    check testStartColumn(text, 15, "          ^")
    check testStartColumn(text, 16, "          ^")
    let fragment = """a = "₡ invalid \4 slashed " # test"""
    check testStartColumn(fragment, 18, "                ^")

  test "sameNumBytesStr":
    check testSameNumBytesStr("", "")
    check testSameNumBytesStr("a", "a")
    check testSameNumBytesStr("abc", "abc")
    let twoBytes = bytesToString(@[0xc3u8, 0xb1])
    let threeBytes = bytesToString(@[0xe2u8, 0x82, 0xa1])
    let fourBytes = bytesToString(@[0xf0u8, 0x90, 0x8c, 0xbc])
    check testSameNumBytesStr(twoBytes, "U2")
    check testSameNumBytesStr(threeBytes, "U23")
    check testSameNumBytesStr(fourBytes, "U234")
    check testSameNumBytesStr("abc" & twoBytes & "def", "abcU2def")

  test "stripNewline":
    check stripNewline("") == ""
    check stripNewline("\n") == ""
    check stripNewline("1\n") == "1"
    check stripNewline("asdf") == "asdf"
    check stripNewline("asdf\n") == "asdf"

  test "compareStatements one":
    let expected = """
1, 0: "a = 5"
"""
    check compareStatements(@[newStatement("a = 5")], expected)

  test "compareStatements two":
    let expected = """
1, 0: "a = 5"
1, 0: "  b = 235 "
"""
    check compareStatements(@[
      newStatement("a = 5"),
      newStatement("  b = 235 ")
    ], expected)

  test "compareStatements three":
    let expected = """
1, 0: "a = 5"
2, 10: "  b = 235 "
2, 20: "  c = 0"
"""
    check compareStatements(@[
      newStatement("a = 5"),
      newStatement("  b = 235 ", lineNum = 2, start = 10),
      newStatement("  c = 0", lineNum = 2, start = 20)
    ], expected)

  test "no statements":
    var cmdLines: CmdLines
    cmdLines.lines = @["<!--$ nextline -->\n"]
    cmdLines.lineParts = @[newLineParts()]
    let statements = getStatements(cmdLines)
    check statements.len == 0

  test "one statement":
    let content = """
<!--$ nextline a = 5 -->
"""
    let expected = """
1, 15: "a = 5"
"""
    check testGetStatements(content, expected)

  test "one statement string":
    let content = """
<!--$ nextline a = "tea" -->
"""
    let expected = """
1, 15: "a = "tea""
"""
    check testGetStatements(content, expected)

  test "two lines newline":
    let content = """
<!--$ nextline a = 5 -->
<!--$ : asdf -->
"""
#123456789 123456789 123456789
    let expected = """
1, 15: "a = 5"
2, 8: "asdf"
"""
    check testGetStatements(content, expected)

  test "three lines":
    let content = """
$$ nextline
$$ : a = 5
$$ : asddasfd
$$ : c = len("hello")
"""
#123456789 123456789 123456789
    let expected = """
2, 5: "a = 5"
3, 5: "asddasfd"
4, 5: "c = len("hello")"
"""
    check testGetStatements(content, expected)

  test "double quotes":
    let content = """
<!--$ nextline a="hi" -->
"""
    let expected = """
1, 15: "a="hi""
"""
    check testGetStatements(content, expected)

  test "double quotes with semicolon":
    let content = """
<!--$ nextline a="hi;" -->
"""
    let expected = """
1, 15: "a="hi;""
"""
    check testGetStatements(content, expected)

  test "double quotes with slashed double quote":
    # '_"hi"_'
    let content = """
<!--$ nextline a = "_\"hi\"_"-->
"""
    let expected = """
1, 15: "a = "_\"hi\"_""
"""
    check testGetStatements(content, expected)

  test "getNumber":
    check testGetNumber(newStatement("a = 5"), 4,
      newValueAndPosOr(5, 5))
    check testGetNumber(newStatement("a = 22  ,  # test"), 4,
      newValueAndPosOr(22, 8))
    check testGetNumber(newStatement("a = 123456"), 4,
      newValueAndPosOr(123456, 10))
    check testGetNumber(newStatement("a = 1_23_456"), 4,
      newValueAndPosOr(123456, 12))
    check testGetNumber(newStatement("a = 1_23_456.78"), 4,
      newValueAndPosOr(123456.78, 15))

  test "getNumber more":
    check testGetNumber(newStatement("a = 5.0"), 4,
      newValueAndPosOr(5.0, 7))
    check testGetNumber(newStatement("a = -2"), 4,
      newValueAndPosOr(-2, 6))
    check testGetNumber(newStatement("a = -3.4"), 4,
      newValueAndPosOr(-3.4, 8))
    check testGetNumber(newStatement("a = 88 "), 4,
      newValueAndPosOr(88, 7))

    # Starts with Valid number but invalid statement.
    check testGetNumber(newStatement("a = 88 abc "), 4,
      newValueAndPosOr(88, 7))

  test "getNumber not a number":
    check testGetNumber(newStatement("a = -abc"), 4,
      newValueAndPosOr(wNotNumber, "", 4))

  test "getNumberIntTooBig":
    let statement = newStatement("a = 9_223_372_036_854_775_808")
    check testGetNumber(statement, 4, newValueAndPosOr(wNumberOverFlow, "", 4))

  test "getString":
    check testGetString(newStatement("""a = "hello""""), 4,
      newValueAndPosOr("hello", 11))

    check testGetString(newStatement("a = \"hello\""), 4,
      newValueAndPosOr("hello", 11))

    check testGetString(newStatement("""a = "hello"  """), 4,
      newValueAndPosOr("hello", 13))

    check testGetString(newStatement("a = \"hello\"\n"), 4,
      newValueAndPosOr("hello", 12))

    check testGetString(newStatement("a = \"hello\"   #\n"), 4,
      newValueAndPosOr("hello", 14))

  test "getString two bytes":
    let str = bytesToString(@[0xc3u8, 0xb1])
    let statement = newStatement("""a = "$1"""" % str)
    check testGetString(statement, 4, newValueAndPosOr(str, 8))

  test "getString three bytes":
    let str = bytesToString(@[0xe2u8, 0x82, 0xa1])
    let statement = newStatement("""a = "$1"""" % str)
    check testGetString(statement, 4, newValueAndPosOr(str, 9))

  test "getString four bytes":
    let str = bytesToString(@[0xf0u8, 0x90, 0x8c, 0xbc])
    let statement = newStatement("""a = "$1"""" % str)
    check testGetString(statement, 4, newValueAndPosOr(str, 10))

  test "getString invalid after multibytes":
    let threeBytes = bytesToString(@[0xe2u8, 0x82, 0xa1])
    let statement = newStatement("""a = "$1 invalid \4 slashed " # test""" % threeBytes)
    check testGetString(statement, 4, newValueAndPosOr(wNotPopular, "", 18))

  test "getString invalid ff":
    check testGetStringInvalid(@[0xffu8])

  test "getString invalid 2":
    check testGetStringInvalid(@[0xc3u8, 0x28])

  test "getString invalid 22":
    check testGetStringInvalid(@[0xa0u8, 0xa1])

  test "getString invalid 3":
    check testGetStringInvalid(@[0xe2u8, 0x28, 0xa1])

  test "getString invalid 33":
    check testGetStringInvalid(@[0xe2u8, 0x82, 0x28])

  test "getString invalid 4":
    check testGetStringInvalid(@[0xf0u8, 0x28, 0x8c, 0xbc])

  test "getString invalid 44":
    check testGetStringInvalid(@[0xf0u8, 0x90, 0x28, 0xbc])

  test "getString not string":
    check testGetString(newStatement("""a = "abc"""), 4,
      newValueAndPosOr(wNoEndingQuote, "", 8))

  test "getNewVariables":
    let funcsVarDict = createFuncDictionary().dictv
    let variables = emptyVariables(funcs = funcsVarDict)
    check variables["f"].dictv.len != 0
    check variables["g"].dictv.len == 0
    check variables["l"].dictv.len == 0
    check variables["s"].dictv.len == 0
    check variables["o"].dictv.len == 0
    check variables["t"].dictv.len != 0
    let tea = variables["t"].dictv
    check tea["row"] == Value(kind: vkInt, intv: 0)
    check tea["version"] == Value(kind: vkString, stringv: staticteaVersion)
    check tea.contains("content") == false

    let fDict = variables["f"].dictv
    let existsList = fDict["exists"].listv
    check existsList.len == 1
    let function = existsList[0]
    check function.funcv.name == "exists"

  test "warnStatement":
    let statement = newStatement(text="tea = a123", lineNum=12, 0)
    let eErrLines: seq[string] = splitNewLines """
template.html(12): w36: The variable 'a123' does not exist.
statement: tea = a123
                 ^
"""
    check testWarnStatement(statement, wVariableMissing, 6, p1="a123", eErrLines = eErrLines)

  test "warnStatement long":
    let statement = newStatement(text="""tea  =  concat(a123, len(hello), format(len(asdfom)), 123456778, 1243123456, "this is a long statement", 678, 899)""", lineNum=12, 0)
    let eErrLines: seq[string] = splitNewLines """
template.html(12): w36: The variable 'a123' does not exist.
statement: tea  =  concat(a123, len(hello), format(len(asdfom)), 123456...
                          ^
"""
    check testWarnStatement(statement, wVariableMissing, 15, p1="a123", eErrLines = eErrLines)

  test "warnStatement long":
    let statement = newStatement(text="""tea  =  concat(a123, len(hello), format(len(asdfom)), 123456778, 1243123456, "this is a long statement", 678, test)""", lineNum=12, 0)
    let eErrLines: seq[string] = @[
      """template.html(12): w36: The variable 'test' does not exist.""" & "\n",
      """statement: ...is is a long statement", 678, test)""" & "\n",
        "                                            ^\n",
    ]
    check testWarnStatement(statement, wVariableMissing, 110, p1="test", eErrLines = eErrLines)

  test "warnStatement long2":
    let statement = newStatement(text="""tea                         =        concat(a123, len(hello), format(len(asdfom)), 123456778, num,   "this is a long statement with more on each end of the statement.", 678, test)""", lineNum=12, 0)
    let eErrLines: seq[string] = @[
      "template.html(12): w36: The variable 'num' does not exist.\n",
      """statement: ...rmat(len(asdfom)), 123456778, num,   "this is a long stateme...""" & "\n",
        "                                            ^\n",
    ]
    check testWarnStatement(statement, wVariableMissing, 94, p1="num", eErrLines = eErrLines)

  test "getFunctionValue":
    let statement = newStatement(text="""tea = len("abc") """, lineNum=16, 0)
    let valueAndPos = newValueAndPos(newValue(3), 17)
    let eValueAndPosOr = newValueAndPosOr(valueAndPos)
    check testGetFunctionValueAndPos("len", statement, 10, eValueAndPosOr)

  test "getFunctionValue 2 parameters":
    let statement = newStatement(text="""tea = concat("abc", "def") """,
      lineNum=16, 0)
    let valueAndPos = newValueAndPos(newValue("abcdef"), 27)
    let eValueAndPosOr = newValueAndPosOr(valueAndPos)
    check testGetFunctionValueAndPos("concat", statement, 13, eValueAndPosOr)

  test "getFunctionValue nested":
    let text = """tea = concat("abc", concat("xyz", "123")) """
                 #0123456789 123456789 123456789 123456789 12345
    let statement = newStatement(text)
    let valueAndPos = newValueAndPos(newValue("abcxyz123"), 42)
    let eValueAndPosOr = newValueAndPosOr(valueAndPos)
    check testGetFunctionValueAndPos("concat", statement, 13, eValueAndPosOr)

  test "getFunctionValue missing )":
    let statement = newStatement(text="""tea = len("abc"""", lineNum=16, 0)
    let eValueAndPosOr = newValueAndPosOr(wMissingCommaParen, "", 15)
    check testGetFunctionValueAndPos("len", statement, 10, eValueAndPosOr)

  test "getFunctionValue missing quote":
    let statement = newStatement(text="""tea = len("abc)""", lineNum=16, 0)
    let eValueAndPosOr = newValueAndPosOr(wNoEndingQuote, "", 15)
    check testGetFunctionValueAndPos("len", statement, 10, eValueAndPosOr)

  test "getFunctionValue extra comma":
    let statement = newStatement(text="""tea = len("abc",) """, lineNum=16, 0)
    let eValueAndPosOr = newValueAndPosOr(wInvalidRightHandSide, "", 16)
    check testGetFunctionValueAndPos("len", statement, 10, eValueAndPosOr)

  test "runStatement":
    let statement = newStatement(text="""t.repeat = 4 """, lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("t.repeat", "=", newValue(4))
    check testRunStatement(statement, eVariableDataOr)

  test "runStatement string":
    let statement = newStatement(text="""str = "testing" """, lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("str", "=", newValue("testing"))
    check testRunStatement(statement, eVariableDataOr)

  test "runStatement string newline":
    let statement = newStatement(text="str = \"testing\"\n", lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("str", "=", newValue("testing"))
    check testRunStatement(statement, eVariableDataOr)

  test "runStatement set log":
    let statement = newStatement(text="""t.output = "log" """, lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("t.output", "=", newValue("log"))
    check testRunStatement(statement, eVariableDataOr)

  test "runStatement a5":
    let statement = newStatement(text="""a = 5   """, lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("a", "=", newValue(5))
    check testRunStatement(statement, eVariableDataOr)

  test "runStatement junk at end":
    let statement = newStatement(text="""str = "testing" junk at end""",
      lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr(wTextAfterValue, "", 16)
    check testRunStatement(statement, eVariableDataOr)

  test "does not start with var":
    let statement = newStatement(text="123 = 343", lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr(wMissingStatementVar)
    check testRunStatement(statement, eVariableDataOr)

  test "missing statement left hand":
    let statement = newStatement(text="return(5)", lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr(wMissingStatementVar)
    check testRunStatement(statement, eVariableDataOr)

  test "no equal sign":
    let statement = newStatement(text="var 343", lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr(wInvalidVariable, "", 4)
    check testRunStatement(statement, eVariableDataOr)

  test "invalid missing needed vararg parameter":
    let statement = newStatement(
      text="""result = dict(list("1", "else", "2", "two", "3"))""",
      lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr(wDictRequiresEven, "", 14)
    check testRunStatement(statement, eVariableDataOr)

  test "parameter error position":
    let text = """result = case(33, 2, 22, "abc", 11, len(concat()))"""
    let statement = newStatement(text, lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr(wNotEnoughArgs, "2", 47)
    check testRunStatement(statement, eVariableDataOr)

  test "assignTeaVariable missing":
    # The runStatement returns a dot name string and a value.  The
    # assignment doesn't happen until later. So t.missing, "1.2.3" is
    # a value return.
    let statement = newStatement(text="""t.missing = "1.2.3"""", lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("t.missing", "=", newValue("1.2.3"))
    check testRunStatement(statement, eVariableDataOr)

  test "assignTeaVariable content":
    let statement = newStatement(text="""t.content = "1.2.3"""", lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("t.content", "=", newValue("1.2.3"))
    check testRunStatement(statement, eVariableDataOr)

  test "parseVersion":
    check parseVersion("1.2.3") == some((1, 2, 3))
    check parseVersion("111.222.333") == some((111, 222, 333))

  test "cmpVersion equal":
    let statement = newStatement(text="""cmp = cmpVersion("1.2.3", "1.2.3")""",
      lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("cmp", "=", newValue(0))
    check testRunStatement(statement, eVariableDataOr)

  test "cmpVersion less":
    let statement = newStatement(text="""cmp = cmpVersion("1.2.2", "1.2.3")""",
      lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("cmp", "=", newValue(-1))
    check testRunStatement(statement, eVariableDataOr)

  test "cmpVersion greater":
    let statement = newStatement(
      text="""cmp = cmpVersion("1.2.4", "1.2.3")""",
      lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("cmp", "=", newValue(1))
    check testRunStatement(statement, eVariableDataOr)

  test "cmpVersion less 2":
    let statement = newStatement(text="""cmp = cmpVersion("1.22.3", "2.1.0")""",
      lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("cmp", "=", newValue(-1))
    check testRunStatement(statement, eVariableDataOr)

  test "cmpVersion less 3":
    let statement = newStatement(text="""cmp = cmpVersion("2.22.3", "2.44.0")""",
      lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("cmp", "=", newValue(-1))
    check testRunStatement(statement, eVariableDataOr)

  test "cmpVersion two parameters":
    let statement = newStatement(
      text="""cmp = cmpVersion("1.2.3")""", lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr(wNotEnoughArgs, "2", 17)
    check testRunStatement(statement, eVariableDataOr)

  test "cmpVersion strings":
    let statement = newStatement(text="""cmp = cmpVersion("1.2.3", 3.5)""",
      lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr(wWrongType, "string", 26)
    check testRunStatement(statement, eVariableDataOr)

  test "getFragmentAndPos":
    let text = """a = if0(1, missing(["123", cat(4, 5)], cat()), len("ab") )"""
    let statement = newStatement(text, lineNum=1, 0)
    var (fragment, pointerPos) = getFragmentAndPos(statement, 4)
    check fragment == text
    check pointerPos == 4
    (fragment, pointerPos) = getFragmentAndPos(statement, 20)
    check fragment == text
    check pointerPos == 20

  test "incomplete function":
    let statement = newStatement(text="""a = len("asdf"""", lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr(wMissingCommaParen, "", 14)
    check testRunStatement(statement, eVariableDataOr)

  test "incomplete function 2":
    let statement = newStatement(text="a = len(case(5,", lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr(wInvalidRightHandSide, "", 15)
    check testRunStatement(statement, eVariableDataOr)

  test "dot name":
    let statement = newStatement(text="a# = 5", lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr(wInvalidVariable, "", 1)
    check testRunStatement(statement, eVariableDataOr)

  test "one quote":
    let statement = newStatement(text="""  quote = "\""   """, lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("quote", "=", newValue("""""""))
    check testRunStatement(statement, eVariableDataOr)

  test "literal list emtpy":
    let statement = newStatement(text="""a = [] """, lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("a", "=", newEmptyListValue())
    check testRunStatement(statement, eVariableDataOr)

  test "literal list 1":
    let statement = newStatement(text="""a = [1] """, lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("a", "=", newValue(@[1]))
    check testRunStatement(statement, eVariableDataOr)

  test "list space before":
    let statement = newStatement(text="""a = [ 1]""", lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("a", "=", newValue(@[1]))
    check testRunStatement(statement, eVariableDataOr)

  test "list space after":
    let statement = newStatement(text="""a = [1    ]""", lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("a", "=", newValue(@[1]))
    check testRunStatement(statement, eVariableDataOr)

  test "list space before and after":
    let statement = newStatement(text="""a = [   1    ]""", lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("a", "=", newValue(@[1]))
    check testRunStatement(statement, eVariableDataOr)

  test "literal list 2":
    let statement = newStatement(text="""a = [1,2]""", lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("a", "=", newValue(@[1,2]))
    check testRunStatement(statement, eVariableDataOr)

  test "literal list 3":
    let statement = newStatement(text="""a = [1,2,"3"]""", lineNum=1, 0)
    var eValue = newValue(@[newValue(1), newValue(2), newValue("3")])
    let eVariableDataOr = newVariableDataOr("a", "=", eValue)
    check testRunStatement(statement, eVariableDataOr)

  test "literal list nested":
    let statement = newStatement(text="""a = [1,len("3")]""", lineNum=1, 0)
    var eValue = newValue(@[newValue(1), newValue(1)])
    let eVariableDataOr = newVariableDataOr("a", "=", eValue)
    check testRunStatement(statement, eVariableDataOr)

  test "literal list err":
    let statement = newStatement(text="a = [)", lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr(wInvalidRightHandSide, "", 5)
    check testRunStatement(statement, eVariableDataOr)

  test "literal list no ]":
    let statement = newStatement(text="a = [1,2", lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr(wMissingCommaBracket, "", 8)
    check testRunStatement(statement, eVariableDataOr)

  test "literal list junk after":
    let statement = newStatement(text="a = [ 1 ] xyz", lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr(wTextAfterValue, "", 10)
    check testRunStatement(statement, eVariableDataOr)

  test "operator":
    let statement = newStatement(text="a &= 5", lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("a", "&=", newValue(5))
    check testRunStatement(statement, eVariableDataOr)

  test "extra after":
    let statement = newStatement(text="""a = len("abc")  z""", lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr(wTextAfterValue, "", 16)
    check testRunStatement(statement, eVariableDataOr)

  test "undefined function":
    let text = """a = missing(2.3, "second", "third")"""
    let statement = newStatement(text)
    let eVariableDataOr = newVariableDataOr(wNotInF, "missing", 4)
    check testRunStatement(statement, eVariableDataOr)

  test "if when true":
    let statement = newStatement(text="""a = if(bool(1), 1, 2)""", lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("a", "=", newValue(1))
    check testRunStatement(statement, eVariableDataOr)

  test "if when false":
    let statement = newStatement(text="""a = if(bool(0), 1, 2)""", lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("a", "=", newValue(2))
    check testRunStatement(statement, eVariableDataOr)

  test "if0 when 0":
    let statement = newStatement(text="""a = if0(0, 1, 2)""", lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("a", "=", newValue(1))
    check testRunStatement(statement, eVariableDataOr)

  test "if0 when 0.0":
    let statement = newStatement(text="""a = if0(0.0, 1, 2)""", lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("a", "=", newValue(1))
    check testRunStatement(statement, eVariableDataOr)

  test "if0 when empty string":
    let statement = newStatement(text="""a = if0("", 1, 2)""", lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("a", "=", newValue(1))
    check testRunStatement(statement, eVariableDataOr)

  test "if0 when empty list":
    let statement = newStatement(text="""a = if0([], 1, 2)""", lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("a", "=", newValue(1))
    check testRunStatement(statement, eVariableDataOr)

  test "if0 when empty dict":
    let statement = newStatement(text="""a = if0(dict(), 1, 2)""", lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("a", "=", newValue(1))
    check testRunStatement(statement, eVariableDataOr)

  test "if0 when not empty list":
    let statement = newStatement(text="""a = if0([4], 1, 2)""", lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("a", "=", newValue(2))
    check testRunStatement(statement, eVariableDataOr)

  test "if0 skipping":
    let text = """a = if0(0, len("123"), len("ab") )"""
    let statement = newStatement(text, lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("a", "=", newValue(3))
    check testRunStatement(statement, eVariableDataOr)

  test "if0 missing":
    let text = """a = if0(0, len("123"), missing("ab") )"""
    let statement = newStatement(text, lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("a", "=", newValue(3))
    check testRunStatement(statement, eVariableDataOr)

  test "if0 two arguments":
    let text = """a = if0(2, "abc")"""
    let statement = newStatement(text)
    let eVariableDataOr = newVariableDataOr(wAssignmentIf, "", 16)
    check testRunStatement(statement, eVariableDataOr)

  test "if assignment takes 3 args":
    let text = """a = if0(0, "abc")"""
    let statement = newStatement(text)
    let eVariableDataOr = newVariableDataOr(wAssignmentIf, "", 16)
    check testRunStatement(statement, eVariableDataOr)

  test "warn syntax error":
    let text = """a = warn("hello""""
    let statement = newStatement(text)
    let eVariableDataOr = newVariableDataOr(wMissingCommaParen, "", 16)
    check testRunStatement(statement, eVariableDataOr)

  test "warn extra parameter":
    let text = """a = warn("hello", 4)"""
    let statement = newStatement(text)
    let eVariableDataOr = newVariableDataOr(wTooManyArgs, "1", 18)
    check testRunStatement(statement, eVariableDataOr)

  test "if0 missing required":
    let text = """a = b"""
    let statement = newStatement(text, lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr(wNotInL, "b", 4)
    check testRunStatement(statement, eVariableDataOr)

  test "slice":
    let text = """a = slice("abc", 0, 2)"""
    let statement = newStatement(text, lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("a", "=", newValue("ab"))
    check testRunStatement(statement, eVariableDataOr)

  test "slice wrong type":
    let text = """a = slice("abc", 2, "b")"""
    let statement = newStatement(text, lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr(wWrongType, "int", 20)
    check testRunStatement(statement, eVariableDataOr)

  test "slice missing comma":
    let text = """a = slice("abc", 2 100)"""
    let statement = newStatement(text, lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr(wMissingCommaParen, "", 19)
    check testRunStatement(statement, eVariableDataOr)

  test "max var length":
    let text = """a23456789_123456789_123456789_123456789_123456789_123456789_1234 = slice("abc", 2 100)"""
    let statement = newStatement(text, lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr(wMissingCommaParen, "", 82)
    check testRunStatement(statement, eVariableDataOr)

  test "max var length + 1":
    let text = """a23456789_123456789_123456789_123456789_123456789_123456789_12345 = slice("abc", 2 100)"""
    let statement = newStatement(text, lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr(wInvalidVariable, "", 64)
    check testRunStatement(statement, eVariableDataOr)

  test "warn plus stuff":
    let text = """a = [1, 2, 3, warn("hello"), 4] junk"""
    let statement = newStatement(text)
    let eVariableDataOr = newVariableDataOr(wUserMessage, "hello", 19)
    check testRunStatement(statement, eVariableDataOr)

  test "warn plus stuff":
    let text = """a = len(warn("hello"), 4) junk"""
    let statement = newStatement(text)
    let eVariableDataOr = newVariableDataOr(wUserMessage, "hello", 13)
    check testRunStatement(statement, eVariableDataOr)

  test "return empty":
    let text = """a = return("")"""
    let statement = newStatement(text)
    let eVariableDataOr = newVariableDataOr("", "exit", newValue(""))
    check testRunStatement(statement, eVariableDataOr)

  test "return skip":
    let text = """a = return("skip")"""
    let statement = newStatement(text)
    let eVariableDataOr = newVariableDataOr("", "exit", newValue("skip"))
    check testRunStatement(statement, eVariableDataOr)

  test "return stop nested":
    let text = """a = if0(0, return("stop"))"""
    let statement = newStatement(text)
    let eVariableDataOr = newVariableDataOr("", "exit", newValue("stop"))
    check testRunStatement(statement, eVariableDataOr)

  test "if assignment takes three args":
    let text = """a = if0(1, return("stop"))"""
    let statement = newStatement(text)
    let eVariableDataOr = newVariableDataOr(wAssignmentIf, "", 25)
    check testRunStatement(statement, eVariableDataOr)

  test "return no stop":
    let text = """a = if0(0, [1,2,return("stop")])"""
    let statement = newStatement(text)
    let eVariableDataOr = newVariableDataOr("", "exit", newValue("stop"))
    check testRunStatement(statement, eVariableDataOr)

  test "return cond stop":
    let text = """a = if0(return("stop"),5)"""
    let statement = newStatement(text)
    let eVariableDataOr = newVariableDataOr("", "exit", newValue("stop"))
    check testRunStatement(statement, eVariableDataOr)

  test "return third stop":
    let text = """a = if0(1, 5, return("stop"))"""
    let statement = newStatement(text)
    let eVariableDataOr = newVariableDataOr("", "exit", newValue("stop"))
    check testRunStatement(statement, eVariableDataOr)

  test "return third stop":
    let text = """a = len(return("stop"))"""
    let statement = newStatement(text)
    let eVariableDataOr = newVariableDataOr("", "exit", newValue("stop"))
    check testRunStatement(statement, eVariableDataOr)

  test "bare if taken":
    let text = """if0(0, return("stop"))"""
    let statement = newStatement(text)
    let eVariableDataOr = newVariableDataOr("", "exit", newValue("stop"))
    check testRunStatement(statement, eVariableDataOr)

  test "bare if not taken":
    let text = """if0(1, return("stop"))"""
    let statement = newStatement(text)
    let eVariableDataOr = newVariableDataOr("", "", newValue(0))
    check testRunStatement(statement, eVariableDataOr)

  test "bare if takes two args":
    let text = """if0(0, "second", "third")"""
    let statement = newStatement(text)
    let eVariableDataOr = newVariableDataOr(wBareIfTwoArguments, "", 15)
    check testRunStatement(statement, eVariableDataOr)

  test "bare if third":
    let text = """if0(1, "second", "third")"""
    let statement = newStatement(text)
    let eVariableDataOr = newVariableDataOr(wBareIfTwoArguments, "", 15)
    check testRunStatement(statement, eVariableDataOr)

  test "bare extra":
    let text = """if0(1, warn("got one")) junk"""
    let statement = newStatement(text)
    let eVariableDataOr = newVariableDataOr(wTextAfterValue, "", 24)
    check testRunStatement(statement, eVariableDataOr)

  test "empty line":
    let text = ""
    let statement = newStatement(text)
    let eVariableDataOr = newVariableDataOr("", "", newValue(0))
    check testRunStatement(statement, eVariableDataOr)

  test "blank line":
    let text = "     \t  "
    let statement = newStatement(text)
    let eVariableDataOr = newVariableDataOr("", "", newValue(0))
    check testRunStatement(statement, eVariableDataOr)

  test "comment":
    let text = "# this is a comment"
    let statement = newStatement(text)
    let eVariableDataOr = newVariableDataOr("", "", newValue(0))
    check testRunStatement(statement, eVariableDataOr)

  test "comment leading spaces":
    let text = "    # this is a comment"
    let statement = newStatement(text)
    let eVariableDataOr = newVariableDataOr("", "", newValue(0))
    check testRunStatement(statement, eVariableDataOr)

  test "trailing comment":
    let statement = newStatement(text="""a = 5# comment """, lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("a", "=", newValue(5))
    check testRunStatement(statement, eVariableDataOr)

  test "trailing comment leading sp":
    let statement = newStatement(text="""a = 5  # comment """, lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("a", "=", newValue(5))
    check testRunStatement(statement, eVariableDataOr)

  test "multiline":
    let text = """
o.x = $1
Black
Green
White
$1
""" % tripleQuotes
    let multiline = """
Black
Green
White
"""
    let statement = newStatement(text=text, lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("o.x", "=", newValue(multiline))
    check testRunStatement(statement, eVariableDataOr)

  test "multiline 2":
    let text = """
o.x = $1
Black
Green
White$1
""" % tripleQuotes
    let multiline = """
Black
Green
White"""
    let statement = newStatement(text=text, lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("o.x", "=", newValue(multiline))
    check testRunStatement(statement, eVariableDataOr)

  test "multiline 3":
    let text = """
o.x = ""t
Black
Green
White$1
""" % tripleQuotes
    let statement = newStatement(text=text, lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr(wTextAfterValue, "", 8)
    check testRunStatement(statement, eVariableDataOr)

  test "getMultilineStr":
    check testGetMultilineStr("$1\n$1\n", 3, "", 8)
    check testGetMultilineStr("$1\na$1\n", 3, "a", 9)
    check testGetMultilineStr("$1\n\n$1\n", 3, "\n", 9)
    check testGetMultilineStr("$1\nabc$1\n", 3, "abc", 11)
    check testGetMultilineStr("  $1\n$1\n", 5, "", 10)
    check testGetMultilineStr("  $1\nabc\ndef\n$1\n", 5, "abc\ndef\n", 18)

  test "getMultilineStr error":
    check testGetMultilineStrE("$1", 3,
      newWarningData(wTripleAtEnd, "", 3))

    check testGetMultilineStrE("a = $1", 6,
      newWarningData(wTripleAtEnd, "", 6))

    check testGetMultilineStrE("$1abc$1\n", 3,
      newWarningData(wTripleAtEnd, "", 3))

    check testGetMultilineStrE("$1\n\"\"\n", 3,
      newWarningData(wMissingEndingTriple, "", 7))

    check testGetMultilineStrE("$1\n   \"\"\n", 3,
      newWarningData(wMissingEndingTriple, "", 10))

    check testGetMultilineStrE("$1\n", 3,
      newWarningData(wMissingEndingTriple, "", 4))

  test "true and true":
    let statement = newStatement(text="""a = and(true, true)""", lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("a", "=", newValue(true))
    check testRunStatement(statement, eVariableDataOr)

  test "true and false":
    let statement = newStatement(text="""a = and(true, false)""", lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("a", "=", newValue(false))
    check testRunStatement(statement, eVariableDataOr)

  test "false and true":
    let statement = newStatement(text="""a = and(false, true)""", lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("a", "=", newValue(false))
    check testRunStatement(statement, eVariableDataOr)

  test "false and false":
    let statement = newStatement(text="""a = and(false, false)""", lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("a", "=", newValue(false))
    check testRunStatement(statement, eVariableDataOr)

  test "true or true":
    let statement = newStatement(text="""a = or(true, true)""", lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("a", "=", newValue(true))
    check testRunStatement(statement, eVariableDataOr)

  test "true or false":
    let statement = newStatement(text="""a = or(true, false)""", lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("a", "=", newValue(true))
    check testRunStatement(statement, eVariableDataOr)

  test "false or true":
    let statement = newStatement(text="""a = or(false, true)""", lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("a", "=", newValue(true))
    check testRunStatement(statement, eVariableDataOr)

  test "false or false":
    let statement = newStatement(text="""a = or(false, false)""", lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("a", "=", newValue(false))
    check testRunStatement(statement, eVariableDataOr)

  test "runBoolOp":
    check testRunBoolOp(true, "or", true, newValue(true))
    check testRunBoolOp(true, "or", false, newValue(true))
    check testRunBoolOp(false, "or", true, newValue(true))
    check testRunBoolOp(false, "or", false, newValue(false))

    check testRunBoolOp(true, "and", true, newValue(true))
    check testRunBoolOp(true, "and", false, newValue(false))
    check testRunBoolOp(false, "and", true, newValue(false))
    check testRunBoolOp(false, "and", false, newValue(false))

  test "runCompareOp":
    check testRunCompareOp(newValue(5), "==", newValue(5), newValue(true))
    check testRunCompareOp(newValue(2), "==", newValue(5), newValue(false))

    check testRunCompareOp(newValue(5), "!=", newValue(5), newValue(false))
    check testRunCompareOp(newValue(2), "!=", newValue(5), newValue(true))

    check testRunCompareOp(newValue(5), "<", newValue(5), newValue(false))
    check testRunCompareOp(newValue(2), "<", newValue(5), newValue(true))
    check testRunCompareOp(newValue(7), "<", newValue(5), newValue(false))

    check testRunCompareOp(newValue(5), ">", newValue(5), newValue(false))
    check testRunCompareOp(newValue(2), ">", newValue(5), newValue(false))
    check testRunCompareOp(newValue(7), ">", newValue(5), newValue(true))

    check testRunCompareOp(newValue(5), ">=", newValue(5), newValue(true))
    check testRunCompareOp(newValue(2), ">=", newValue(5), newValue(false))
    check testRunCompareOp(newValue(7), ">=", newValue(5), newValue(true))

    check testRunCompareOp(newValue(5), "<=", newValue(5), newValue(true))
    check testRunCompareOp(newValue(2), "<=", newValue(5), newValue(true))
    check testRunCompareOp(newValue(7), "<=", newValue(5), newValue(false))

    check testRunCompareOp(newValue(5.3), ">", newValue(5.3), newValue(false))
    check testRunCompareOp(newValue(2.4), ">", newValue(5.8), newValue(false))
    check testRunCompareOp(newValue(7.2), ">", newValue(5.2), newValue(true))

    check testRunCompareOp(newValue("abc"), "==", newValue("abc"), newValue(true))
    check testRunCompareOp(newValue("abc"), "==", newValue("abcd"), newValue(false))

  test "testSkipArgument":
    check testSkipArgument("a = ( b < c ) # test", 4, newPosOr(14))
    #                       0123456789 123456789
    check testSkipArgument("()", 0, newPosOr(2))
    check testSkipArgument("(())", 0, newPosOr(4))
    check testSkipArgument("((()))", 0, newPosOr(6))
    check testSkipArgument("(a < b)", 0, newPosOr(7))
    check testSkipArgument("((a and b) or c)", 0, newPosOr(16))
    check testSkipArgument("((a and b) or c)", 1, newPosOr(11))
    check testSkipArgument("(len(b) < 5) ,", 0, newPosOr(13))
    check testSkipArgument("""(len("abc") < 5) ,""", 0, newPosOr(17))
    check testSkipArgument("""(len("a\"bc") < 5) ,""", 0, newPosOr(19))
    check testSkipArgument("""(len("(((bc") < 5) ,""", 0, newPosOr(19))
    check testSkipArgument("""a = ( true or true and false )""", 4, newPosOr(30))
    # check testSkipArgument("if(a,b,c)", 3, newPosOr(4))
    #                       0123456789 123456789 123456789

  test "testSkipArgument warning":
    check testSkipArgument("(", 0, newPosOr(wNoMatchingParen, "", 1))
    check testSkipArgument("( abc", 0, newPosOr(wNoMatchingParen, "", 5))
    check testSkipArgument("((())", 0, newPosOr(wNoMatchingParen, "", 5))
    check testSkipArgument("  (", 2, newPosOr(wNoMatchingParen, "", 3))

  test "getCondition":
    #                         0123456789 123456789 123456789 12345
    check testGetCondition("""a = (3 < 5)""", 4, true, 11)
    check testGetCondition("""a = (true)""", 4, true, 10)
    check testGetCondition("""a = (false)""", 4, false, 11)
    check testGetCondition("""a = (false or false)""", 4, false, 20)
    check testGetCondition("""a = (false or true)""", 4, true, 19)
    check testGetCondition("""a = (true or false)""", 4, true, 19)
    check testGetCondition("""a = (true or true)""", 4, true, 18)
    check testGetCondition("""a = (true or true)  # test""", 4, true, 20)
    check testGetCondition("""a = (3 < 5)  # abc""", 4, true, 13)
    check testGetCondition("""a = (false and false)""", 4, false, 21)
    check testGetCondition("""a = (false and true)""", 4, false, 20)
    check testGetCondition("""a = (true and false)""", 4, false, 20)
    check testGetCondition("""a = (true and true)""", 4, true, 19)
    check testGetCondition("""a = (false or false or false)""", 4, false, 29)
    check testGetCondition("""a = (false or false or true)""", 4, true, 28)
    check testGetCondition("""a = (false or true or true)""", 4, true, 27)
    check testGetCondition("""a = (true or true or true)""", 4, true, 26)
    check testGetCondition("""a = (true and true and true)""", 4, true, 28)
    check testGetCondition("""a = (exists(l, "abc"))""", 4, false, 22)
    check testGetCondition("""a = ( (true) )""", 4, true, 14)
    check testGetCondition("""a = ( true and (true) )""", 4, true, 23)
    check testGetCondition("""a = ( 3 < 5 and (4 < 6) )""", 4, true, 25)
    check testGetCondition("""a = ( 3 < 5 or (4 < 6) )""", 4, true, 24)
    check testGetCondition("""a = ( 4 < 6 or 5 < 2 )""", 4, true, 22)
    check testGetCondition("""a = ( (4 < 6) )""", 4, true, 15)
    check testGetCondition("""a = ( (false or false) ) """, 4, false, 25)
    check testGetCondition("""a = ( (true or false) )  # test""", 4, true, 25)
    check testGetCondition("""a = ( (4 < 6 or 5 < 2) )""", 4, true, 24)
    check testGetCondition("""a = ( 3 < 5 and (4 < 6 or 5 < 2) )""", 4, true, 34)
    #                         0123456789 123456789 123456789 12345

  test "getCondition warning":
    #                             0123456789 123456789 123456789 12345
    check testGetConditionWarn("""a = ( 3 xor 5 )""", 4, wNotBoolOperator, 8)
    check testGetConditionWarn("""a = ( 3 and 5 )""", 4, wBoolOperatorLeft, 8)
    check testGetConditionWarn("""a = ( true and true or false )""", 4, wNeedPrecedence, 20)
    check testGetConditionWarn("""a = ( false or false and false )""", 4, wNeedPrecedence, 21)
    check testGetConditionWarn("""a = ( true < 5 )""", 4, wCompareOperator, 11)
    check testGetConditionWarn("""a = ( false and true # no right paren""", 4, wNoMatchingParen, 37)
    check testGetConditionWarn("""a = ( 3 < 5.5 )""", 4, wCompareOperatorSame, 10)
    check testGetConditionWarn("""a = ( 3.2 < 5 )""", 4, wCompareOperatorSame, 12)
    check testGetConditionWarn("""a = ( "a" < 5 )""", 4, wCompareOperatorSame, 12)
    check testGetConditionWarn("""a = ( 3 < 5 and 3 xor 8)""", 4, wNotCompareOperator, 18)
    check testGetConditionWarn("""a = ( 3 < 5 and 3 == 8.8)""", 4, wCompareOperatorSame, 21)
    #                             0123456789 123456789 123456789 12345

    # When a condition is short ciruited, the rest of the condition is skipped. This means
    # the rest might not be well formed.
    check testGetCondition("""a = ( false and true or false )""", 4, false, 31)
    check testGetCondition("""a = ( false and true and 3 xor 5 )""", 4, false, 34)
    check testGetCondition("""a = ( true or true and false )""", 4, true, 30)
    #                         0123456789 123456789 123456789 12345

  test "a = cmp":
    let statement = newStatement(text="""a = f.cmp""", lineNum=1, 0)
    let funcsVarDict = createFuncDictionary().dictv
    let variables = emptyVariables(funcs = funcsVarDict)
    let cmpValueOr = getVariable(variables, "f.cmp")
    if cmpValueOr.isMessage:
      echo cmpValueOr.message
      fail
    let eVariableDataOr = newVariableDataOr("a", "=", cmpValueOr.value)
    check testRunStatement(statement, eVariableDataOr, variables)

  test "a = get(cmp, 0)":
    let statement = newStatement(text="""a = get(f.cmp, 0)""", lineNum=1, 0)
    let funcsVarDict = createFuncDictionary().dictv
    let variables = emptyVariables(funcs = funcsVarDict)
    let cmpValueOr = getVariable(variables, "f.cmp")
    if cmpValueOr.isMessage:
      echo cmpValueOr.message
      fail
    let eVariableDataOr = newVariableDataOr("a", "=", cmpValueOr.value.listv[0])
    check testRunStatement(statement, eVariableDataOr, variables)

  test "a5#":
    check testGetValueAndPos("""a = 5 #""", 4, 6, "5")

  test "getValueAndPos and skip":
    # var valueOr = readJsonString("{b:1,c:2}")
    let statements = [
      ("""a = 5 # number""", 4, 6, "5"),
      ("""a = "abc" # string""", 4, 10, """"abc""""),
      ("""a = [1,2,3] # list""", 4, 12, "[1,2,3]"),
      ("""a = dict(["b", 1,"c", 2]) # dict""", 4, 26, """{"b":1,"c":2}"""),
      ("""a = len("3") # var""", 4, 13, "1"),
      ("""a = (3 < 5) # var""", 4, 12, "true"),
      ("""a = t.row # variable""", 4, 10, "0"),
      ("""a = if( (1 < 2), 3, 4) # if a""", 4, 23, "3"),
      ("""a = if( bool(len("tea")), 22, 33) # if b""", 4, 34, "22"),
      ("""a = if( bool(len("tea")), 22, 33) # if c""", 8, 24, "true"),
      ("""a = if( bool(len("tea")), 22, 33) # if d""", 13, 23, "3"),
      ("""a = if( bool(len("tea")), 22, 33) # if e""", 17, 22, """"tea""""),
      ("""a = if( bool(len("tea")), 22, 33) # if f""", 26, 28, "22"),
      ("""a = if( bool(len("tea")), 22, 33) # if g""", 30, 32, "33"),
      #   0123456789 123456789 123456789 123456789 1234
      ("""a = if( bool( len( "tea" ) ) , 22 , 33 ) # if h""", 4, 41, "22"),
      ("""a = if( bool( len( "tea" ) ) , 22 , 33 ) # if i""", 8, 29, "true"),
      ("""a = if( bool( len( "tea" ) ) , 22 , 33 ) # if j""", 14, 27, "3"),
      ("""a = if( bool( len( "tea" ) ) , 22 , 33 ) # if k""", 19, 25, """"tea""""),
      ("""a = if( bool( len( "tea" ) ) , 22 , 33 ) # if l""", 31, 34, "22"),
      ("""a = if( bool( len( "tea" ) ) , 22 , 33 ) # if m""", 36, 39, "33"),
      #   0123456789 123456789 123456789 123456789 1234
      #             10        20        30        40
    ]
    for (text, start, ePos, eJson) in statements:
      check testGetValueAndPos(text, start, ePos, eJson)
      check testSkipArgument(text, start, newPosOr(ePos))

  test "getValueAndPos warnings":
    check testGetValueAndPos("""a = 5""", 1, wInvalidRightHandSide, 1)
    check testGetValueAndPos("""a = b""", 4, wNotInL, 4, "b")
    check testGetValueAndPos("""a = _""", 4, wInvalidRightHandSide, 4)

  test "skipArgument":
    check testSkipArgument("""a = fn(1)""", 7, newPosOr(8))
    check testSkipArgument("""a = Fn(1)""", 7, newPosOr(8))
    check testSkipArgument("""a = fn(1 )""", 7, newPosOr(9))
    check testSkipArgument("""a = fn(123)""", 7, newPosOr(10))
    check testSkipArgument("""a = fn(1,2)""", 7, newPosOr(8))
    check testSkipArgument("""a = fn(1 ,2)""", 7, newPosOr(9))
    check testSkipArgument("""a = fn(-1)""", 7, newPosOr(9))
    check testSkipArgument("""a = fn(b)""", 7, newPosOr(8))
    check testSkipArgument("""a = fn(b )""", 7, newPosOr(9))
    check testSkipArgument("""a = fn("t")""", 7, newPosOr(10))
    check testSkipArgument("""a = fn("t" )""", 7, newPosOr(11))
    check testSkipArgument("""a = fn("t",b)""", 7, newPosOr(10))
    check testSkipArgument("""a = fn("t" ,b)""", 7, newPosOr(11))
    check testSkipArgument("""a = fn("\"")""", 7, newPosOr(11))
    check testSkipArgument("""a = fn((1<2))""", 7, newPosOr(12))
    check testSkipArgument("""a = fn((1<2) )""", 7, newPosOr(13))
    check testSkipArgument("""a = fn((1<2),a)""", 7, newPosOr(12))
    check testSkipArgument("""a = fn((1<2)  ,a)""", 7, newPosOr(14))
    check testSkipArgument("""a = fn([1])""", 7, newPosOr(10))
    check testSkipArgument("""a = fn([1] )""", 7, newPosOr(11))
    check testSkipArgument("""a = fn([1],b)""", 7, newPosOr(10))
    check testSkipArgument("""a = fn([1] ,b)""", 7, newPosOr(11))
    check testSkipArgument("""a = fn(f2(1))""", 7, newPosOr(12))
    check testSkipArgument("""a = fn(f2(1)  )""", 7, newPosOr(14))
    check testSkipArgument("""a = fn(f2(1,2))""", 7, newPosOr(14))
    check testSkipArgument("""a = fn(f2(1),b)""", 7, newPosOr(12))
    check testSkipArgument("""a = fn(f2(1) ,b)""", 7, newPosOr(13))
    check testSkipArgument("""a = fn([[1]])""", 7, newPosOr(12))
    check testSkipArgument("""a = fn([[1],2])""", 7, newPosOr(14))
    check testSkipArgument("""a = fn([[1],[2]])""", 7, newPosOr(16))
    check testSkipArgument("""a = fn(l.b)""", 7, newPosOr(10))
    check testSkipArgument("""a = fn(l_)""", 7, newPosOr(9))
    check testSkipArgument("""a = fn(lA)""", 7, newPosOr(9))
    check testSkipArgument("""a = fn(f2(f3(1)))""", 7, newPosOr(16))
    check testSkipArgument("""a = fn(f2(1,f4(1)))""", 7, newPosOr(18))
    check testSkipArgument("""a = fn(f2(1,f4(1)),3)""", 7, newPosOr(18))
    check testSkipArgument("""a = fn(f2(1,f4(1)) ,3)""", 7, newPosOr(19))
    check testSkipArgument("""a = fn(f2("abc"))""", 7, newPosOr(16))
    check testSkipArgument("""a = fn(f2("))"))""", 7, newPosOr(15))
    check testSkipArgument("""a = fn(f2("(("))""", 7, newPosOr(15))

  test "skipArgument warnings":
    check testSkipArgument("""a = fn(_b)""", 7, newPosOr(wInvalidFirstArgChar, "", 7))
    check testSkipArgument("""a = fn(b$)""", 7, newPosOr(wInvalidCharacter, "", 8))
    check testSkipArgument("""a = fn(fn2(b""", 7, newPosOr(wNoMatchingParen, "", 12))
    check testSkipArgument("""a = fn([1,2)""", 7, newPosOr(wNoMatchingBracket, "", 12))
    #                         0123456789 123456789
    check testSkipArgument("""a = fn(fn2(b,fn3()""", 7, newPosOr(wNoMatchingParen, "", 18))
    check testSkipArgument("""a = fn("tea""", 7, newPosOr(wNotEnoughCharacters, "", 11))

  test "a = b[0]":
    let funcsVarDict = createFuncDictionary().dictv
    var variables = emptyVariables(funcs = funcsVarDict)
    discard assignVariable(variables, "l.b", newValue(2), "&=")
    check $variables["l"] == """{"b":[2]}"""
    check testGetValueAndPos("""a = b[0]""", 4, 8, "2", variables)

  test "index 1":
    let funcsVarDict = createFuncDictionary().dictv
    var variables = emptyVariables(funcs = funcsVarDict)
    discard assignVariable(variables, "l.b", newValue(2), "&=")
    discard assignVariable(variables, "l.b", newValue(3), "&=")
    check $variables["l"] == """{"b":[2,3]}"""
    check testGetValueAndPos("""a = b[1]""", 4, 8, "3", variables)

  test "brackets with spaces":
    let funcsVarDict = createFuncDictionary().dictv
    var variables = emptyVariables(funcs = funcsVarDict)
    discard assignVariable(variables, "l.b", newValue(2), "&=")
    check testGetValueAndPos("""a = b[ 0 ]""", 4, 10, "2", variables)

  test "brackets with function":
    let funcsVarDict = createFuncDictionary().dictv
    var variables = emptyVariables(funcs = funcsVarDict)
    discard assignVariable(variables, "l.b", newValue(2), "&=")
    check testGetValueAndPos("""a = b[ len("") ]""", 4, 16, "2", variables)

  test "a = d['abc']":
    let funcsVarDict = createFuncDictionary().dictv
    var variables = emptyVariables(funcs = funcsVarDict)
    let content = """{"abc": 5}"""
    var valueOr = readJsonString(content)
    let value = valueOr.value
    discard assignVariable(variables, "l.d", value, "=")
    check $variables["l"] == """{"d":{"abc":5}}"""
    check testGetValueAndPos("""a = d["abc"]""", 4, 12, "5", variables)

  test "bracketed variable missing":
    check testGetValueAndPos("""a = b[0]""", 4, wNotInL, 4, "b")

  test "bracketed list or dict":
    let funcsVarDict = createFuncDictionary().dictv
    var variables = emptyVariables(funcs = funcsVarDict)
    discard assignVariable(variables, "l.b", newValue(2), "=")
    check testGetValueAndPos("""a = b[0]""", 4, wIndexNotListOrDict, 4, "int", variables)

  test "bracketed list warnings":
    let funcsVarDict = createFuncDictionary().dictv
    var variables = emptyVariables(funcs = funcsVarDict)
    discard assignVariable(variables, "l.ix", newValue(22), "=")
    discard assignVariable(variables, "l.b", newValue(2), "&=")
    check testGetValueAndPos("""a = b[abc]""", 4, wNotInL, 6, "abc", variables)
    check testGetValueAndPos("""a = b[%abc]""", 4, wInvalidRightHandSide, 6, "", variables)
    check testGetValueAndPos("""a = b[2.3]""", 4, wIndexNotInt, 6, "", variables)
    check testGetValueAndPos("""a = b[-1]""", 4, wInvalidIndexRange, 6, "-1", variables)
    check testGetValueAndPos("""a = b[ix]""", 4, wInvalidIndexRange, 6, "22", variables)

  test "bracketed dict warnings":
    let funcsVarDict = createFuncDictionary().dictv
    var variables = emptyVariables(funcs = funcsVarDict)
    let content = """{"abc": 5}"""
    var valueOr = readJsonString(content)
    let value = valueOr.value
    discard assignVariable(variables, "l.d", value, "=")

    check testGetValueAndPos("""a = d[5]""", 4, wKeyNotString, 6, "", variables)
    check testGetValueAndPos("""a = d["missing"]""", 4, wMissingKey, 6, "", variables)

  test "missing ending bracket":
    let funcsVarDict = createFuncDictionary().dictv
    var variables = emptyVariables(funcs = funcsVarDict)
    discard assignVariable(variables, "l.b", newValue(2), "&=")
    check testGetValueAndPos("""a = b[0""", 4, wMissingRightBracket, 7, "", variables)
