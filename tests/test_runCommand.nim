
import std/unittest
import std/options
import std/strutils
import std/tables
import runCommand
import runFunction
import parseCmdLine
import env
import matches
import vartypes
import variables
import messages
import warnings
import version
import readlines
import collectCommand
import opresultwarn
import sharedtestcode

proc cmpVariableDataOr(statement: Statement,
     g: VariableDataOr, e: VariableDataOr,
     templateName = "tmpl"): bool =
  ## Compare two VariableDataOr. When not equal show the differences.
  if $g == $e:
    return true

  echo statement.text
  echo ""
  if e.isMessage and e.isMessage == g.isMessage:
    echo "expected message:"
    echo getWarnStatement(statement, e.message, templateName)
    echo "got message:"
    echo getWarnStatement(statement, g.message, templateName)
  elif e.isValue and e.isValue == g.isValue:
    echo "expected value: " & $e.value
    echo "     got value: " & $g.value
  elif e.isMessage:
    echo "expected message:"
    echo getWarnStatement(statement, e.message, templateName)
    echo "got value:"
    echo $g.value
  else:
    echo "expected value: " & $e.value
    echo "got message:"
    echo getWarnStatement(statement, g.message, templateName)
  echo ""

proc getCmdLinePartsTest(env: var Env,
    commandLines: seq[string]): seq[LineParts] =
  ## Return the line parts from the given lines. Only used for
  ## testing. It doesn't work for custom prefixes.
  let prepostTable = makeDefaultPrepostTable()
  for ix, line in commandLines:
    let partsO = parseCmdLine(env, prepostTable, line, lineNum = ix + 1)
    if not partsO.isSome():
      echo "cannot get command line parts for:"
      echo """line: "$1"""" % line
    result.add(partsO.get())

proc getStatements(cmdLines: CmdLines): seq[Statement] =
  ## Return a list of statements for the given lines.
  for statement in yieldStatements(cmdLines):
    result.add(statement)

proc stripNewline(line: string): string =
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
      echo "expected: $1" % expected
      echo "     got: $1" % got
      return false
  return true

proc cmpValueAndLengthOr(statement: Statement,
    g, e: OpResultWarn[ValueAndLength], start = 0): bool =
  ## Compare the two values and show the differences when
  ## different. Return true when they are the same.

  result = true
  if $g != $e:
    if e.isValue:
      echo "$1|" % statement.text
      echo startColumn(start + e.value.length)
    if g.isValue:
      echo startColumn(start + g.value.length)
    echo "expected: $1" % $e
    echo "     got: $1" % $g
    if e.isMessage:
      echo getWarnStatement(statement, e.message, "template.html")
    if g.isMessage:
      echo getWarnStatement(statement, g.message, "template.html")
    result = false

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
    eValueAndLengthOr: OpResultWarn[ValueAndLength]): bool =
  ## Return true when the statement contains the expected number. When
  ## it doesn't, show the values and expected values and return false.

  let valueAndLengthOr = getNumber(statement, start)

  result = true
  if $valueAndLengthOr != $eValueAndLengthOr:
    echo "expected: $1" % $eValueAndLengthOr
    echo "     got: $1" % $valueAndLengthOr
    result = false

proc testGetString(statement: Statement, start: Natural,
    eValueAndLengthOr: OpResultWarn[ValueAndLength]): bool =

  let valueAndLengthOr = getString(statement, start)
  result = cmpValueAndLengthOr(statement, valueAndLengthOr, eValueAndLengthOr)

proc testGetStringInvalid(buffer: seq[uint8]): bool =
  let str = bytesToString(buffer)
  let statement = newStatement("""a = "stringwithbadutf8:$1:end"""" % str)
  let start = 4
  let valueAndLengthOr = getString(statement, start)
  let eValueAndLengthOr = newValueAndLengthOr(wInvalidUtf8, "", 23)
  result = cmpValueAndLengthOr(statement, valueAndLengthOr, eValueAndLengthOr)

proc testWarnStatement(statement: Statement,
    warning: Warning, start: Natural, p1: string="",
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[]
  ): bool =

  var env = openEnvTest("_getVariable.log")

  let warningData = newWarningData(warning, p1, start)
  env.warnStatement(statement, warningData)

  result = env.readCloseDeleteCompare(eLogLines, eErrLines, eOutLines)

proc testGetFunctionValueAndLength(
  functionName: string,
  statement: Statement,
  start: Natural,
  eValueAndLengthOr: OpResultWarn[ValueAndLength]
    ): bool =

  var variables = emptyVariables()
  let valueAndLengthOr = getFunctionValueAndLength(functionName,
    statement, start, variables, list=false, skip=false)
  result = cmpValueAndLengthOr(statement, valueAndLengthOr, eValueAndLengthOr, start)

proc testRunStatement(
  statement: Statement,
  eVariableDataOr: VariableDataOr,
  variables: Variables = emptyVariables()
     ): bool =

  let variableDataOr = runStatement(statement, variables)
  result = cmpVariableDataOr(statement, variableDataOr, eVariableDataOr)

suite "runCommand.nim":

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
      newValueAndLengthOr(5, 1))
    check testGetNumber(newStatement("a = 123456"), 4,
      newValueAndLengthOr(123456, 6))
    check testGetNumber(newStatement("a = 1_23_456"), 4,
      newValueAndLengthOr(123456, 8))
    check testGetNumber(newStatement("a = 1_23_456.78"), 4,
      newValueAndLengthOr(123456.78, 11))

  test "getNumber more":
    check testGetNumber(newStatement("a = 5.0"), 4,
      newValueAndLengthOr(5.0, 3))
    check testGetNumber(newStatement("a = -2"), 4,
      newValueAndLengthOr(-2, 2))
    check testGetNumber(newStatement("a = -3.4"), 4,
      newValueAndLengthOr(-3.4, 4))
    check testGetNumber(newStatement("a = 88 "), 4,
      newValueAndLengthOr(88, 3))

    # Starts with Valid number but invalid statement.
    check testGetNumber(newStatement("a = 88 abc "), 4,
      newValueAndLengthOr(88, 3))

  test "getNumber not a number":
    check testGetNumber(newStatement("a = -abc"), 4,
      newValueAndLengthOr(wNotNumber, "", 4))

  test "getNumberIntTooBig":
    let statement = newStatement("a = 9_223_372_036_854_775_808")
    check testGetNumber(statement, 4, newValueAndLengthOr(wNumberOverFlow, "", 4))

  test "getString":
    check testGetString(newStatement("""a = "hello""""), 4,
      newValueAndLengthOr("hello", 7))

    check testGetString(newStatement("a = \"hello\""), 4,
      newValueAndLengthOr("hello", 7))

    check testGetString(newStatement("""a = "hello"  """), 4,
      newValueAndLengthOr("hello", 9))

  test "getString two bytes":
    let str = bytesToString(@[0xc3u8, 0xb1])
    let statement = newStatement("""a = "$1"""" % str)
    check testGetString(statement, 4, newValueAndLengthOr(str, 4))

  test "getString three bytes":

    let str = bytesToString(@[0xe2u8, 0x82, 0xa1])
    let statement = newStatement("""a = "$1"""" % str)
    check testGetString(statement, 4, newValueAndLengthOr(str, 5))

  test "getString four bytes":
    let str = bytesToString(@[0xf0u8, 0x90, 0x8c, 0xbc])
    let statement = newStatement("""a = "$1"""" % str)
    check testGetString(statement, 4, newValueAndLengthOr(str, 6))

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
      newValueAndLengthOr(wNoEndingQuote, "", 8))

  test "getNewVariables":
    var variables = emptyVariables()
    check variables["l"].dictv.len == 0
    check variables["g"].dictv.len == 0
    check variables["s"].dictv.len == 0
    check variables["h"].dictv.len == 0
    check variables["t"].dictv.len != 0
    let tea = variables["t"].dictv
    check tea["row"] == Value(kind: vkInt, intv: 0)
    check tea["version"] == Value(kind: vkString, stringv: staticteaVersion)
    check tea.contains("content") == false

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
    let valueAndLength = newValueAndLength(newValue(3), 7)
    let eValueAndLengthOr = newValueAndLengthOr(valueAndLength)
    check testGetFunctionValueAndLength("len", statement, 10, eValueAndLengthOr)

  test "getFunctionValue 2 parameters":
    let statement = newStatement(text="""tea = concat("abc", "def") """,
      lineNum=16, 0)
    let valueAndLength = newValueAndLength(newValue("abcdef"), 14)
    let eValueAndLengthOr = newValueAndLengthOr(valueAndLength)
    check testGetFunctionValueAndLength("concat", statement, 13, eValueAndLengthOr)

  test "getFunctionValue nested":
    let text = """tea = concat("abc", concat("xyz", "123")) """
                 #0123456789 123456789 123456789 123456789 12345
    let statement = newStatement(text)
    let valueAndLength = newValueAndLength(newValue("abcxyz123"), 29)
    let eValueAndLengthOr = newValueAndLengthOr(valueAndLength)
    check testGetFunctionValueAndLength("concat", statement, 13, eValueAndLengthOr)

  test "getFunctionValue missing )":
    let statement = newStatement(text="""tea = len("abc"""", lineNum=16, 0)
    let eValueAndLengthOr = newValueAndLengthOr(wMissingCommaParen, "", 15)
    check testGetFunctionValueAndLength("len", statement, 10, eValueAndLengthOr)

  test "getFunctionValue missing quote":
    let statement = newStatement(text="""tea = len("abc)""", lineNum=16, 0)
    let eValueAndLengthOr = newValueAndLengthOr(wNoEndingQuote, "", 15)
    check testGetFunctionValueAndLength("len", statement, 10, eValueAndLengthOr)

  test "getFunctionValue extra comma":
    let statement = newStatement(text="""tea = len("abc",) """, lineNum=16, 0)
    let eValueAndLengthOr = newValueAndLengthOr(wInvalidRightHandSide, "", 16)
    check testGetFunctionValueAndLength("len", statement, 10, eValueAndLengthOr)

  test "runStatement":
    let statement = newStatement(text="""t.repeat = 4 """, lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("t.repeat", "=", newValue(4))
    check testRunStatement(statement, eVariableDataOr)

  test "runStatement string":
    let statement = newStatement(text="""str = "testing" """, lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("str", "=", newValue("testing"))
    check testRunStatement(statement, eVariableDataOr)

  test "runStatement set log":
    let statement = newStatement(text="""t.output = "log" """, lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("t.output", "=", newValue("log"))
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
    let eVariableDataOr = newVariableDataOr(kNotEnoughArgs, "2", 47)
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
    # todo: better at 24?
    # let eVariableDataOr = newVariableDataOr(kNotEnoughArgs, "2", 24)
    let eVariableDataOr = newVariableDataOr(kNotEnoughArgs, "2", 17)
    check testRunStatement(statement, eVariableDataOr)

  test "cmpVersion strings":
    let statement = newStatement(text="""cmp = cmpVersion("1.2.3", 3.5)""",
      lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr(kWrongType, "string", 26)
    check testRunStatement(statement, eVariableDataOr)

  test "getFragmentAndPos":
    let text = """a = if1(0, missing(["123", cat(4, 5)], cat()), len("ab") )"""
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

  test "startColumn":
    check startColumn(0) == "^"
    check startColumn(1) == " ^"
    check startColumn(2) == "  ^"
    check startColumn(3) == "   ^"

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
    let eVariableDataOr = newVariableDataOr(wInvalidFunction, "missing", 4)
    check testRunStatement(statement, eVariableDataOr)

  test "if0 when 0":
    let statement = newStatement(text="""a = if0(0, 1, 2)""", lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("a", "=", newValue(1))
    check testRunStatement(statement, eVariableDataOr)

  test "if0 when 0":
    let statement = newStatement(text="""a = if0(0, 1, 2)""", lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("a", "=", newValue(1))
    check testRunStatement(statement, eVariableDataOr)

  test "if0 skipping":
    let text = """a = if0(0, len("123"), len("ab") )"""
    let statement = newStatement(text, lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("a", "=", newValue(3))
    check testRunStatement(statement, eVariableDataOr)

  test "if1 skipping":
    let text = """a = if1(0, len("123"), len("ab") )"""
    let statement = newStatement(text, lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("a", "=", newValue(2))
    check testRunStatement(statement, eVariableDataOr)

  test "if0 missing":
    let text = """a = if0(0, len("123"), missing("ab") )"""
    let statement = newStatement(text, lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("a", "=", newValue(3))
    check testRunStatement(statement, eVariableDataOr)

  test "if1 missing":
    let text = """a = if1(0, missing("123"), len("ab") )"""
    let statement = newStatement(text, lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("a", "=", newValue(2))
    check testRunStatement(statement, eVariableDataOr)

  test "if1 missing 2":
    let text = """a = if1(0, missing(["123", cat(4, 5)], cat()), len("ab") )"""
    let statement = newStatement(text, lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("a", "=", newValue(2))
    check testRunStatement(statement, eVariableDataOr)

  test "if1 exists":
    let text = """exists = if1(exists(t, "repeat"), "exists", "does not")"""
    let statement = newStatement(text, lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("exists", "=", newValue("does not"))
    check testRunStatement(statement, eVariableDataOr)

  test "if1 not int cond":
    let text = """a = if1(2.3, "second", "third")"""
    let statement = newStatement(text)
    let eVariableDataOr = newVariableDataOr(wExpectedInteger, "", 8)
    check testRunStatement(statement, eVariableDataOr)

  test "if1 one parameter":
    let text = """a = if1(2)"""
    let statement = newStatement(text)
    let eVariableDataOr = newVariableDataOr(wThreeParameters, "", 8)
    check testRunStatement(statement, eVariableDataOr)

  test "warn syntax error":
    let text = """a = warn("hello""""
    let statement = newStatement(text)
    let eVariableDataOr = newVariableDataOr(wMissingCommaParen, "", 16)
    check testRunStatement(statement, eVariableDataOr)

  test "warn extra parameter":
    let text = """a = warn("hello", 4)"""
    let statement = newStatement(text)
    let eVariableDataOr = newVariableDataOr(kTooManyArgs, "1", 18)
    check testRunStatement(statement, eVariableDataOr)

  test "if1 no second":
    let text = """a = if1(2,)"""
    let statement = newStatement(text)
    let eVariableDataOr = newVariableDataOr(wInvalidRightHandSide, "", 10)
    check testRunStatement(statement, eVariableDataOr)

  test "if1 invalid second":
    let text = """a = if1(2, _abc)"""
    let statement = newStatement(text)
    let eVariableDataOr = newVariableDataOr(wInvalidRightHandSide, "", 11)
    check testRunStatement(statement, eVariableDataOr)

  test "if1 no third":
    let text = """a = if1(2, "abc",  )"""
    let statement = newStatement(text)
    let eVariableDataOr = newVariableDataOr(wInvalidRightHandSide, "", 19)
    check testRunStatement(statement, eVariableDataOr)

  test "if1 no third again":
    let text = """a = if1(2, "abc"  )"""
    let statement = newStatement(text)
    let eVariableDataOr = newVariableDataOr(wThreeParameters, "", 18)
    check testRunStatement(statement, eVariableDataOr)

  test "if1 no closing paren":
    let text = """a = if1(2, "abc", 456 """
    let statement = newStatement(text)
    let eVariableDataOr = newVariableDataOr(wThreeParameters, "", 22)
    check testRunStatement(statement, eVariableDataOr)

  test "if1 extra text":
    let text = """a = if1(2, "abc", 456) * 2"""
    let statement = newStatement(text)
    let eVariableDataOr = newVariableDataOr(wTextAfterValue, "", 23)
    check testRunStatement(statement, eVariableDataOr)

  test "if0 missing required":
    let text = """a = if0(3, len("123"), missing("ab") )"""
    let statement = newStatement(text, lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr(wInvalidFunction, "missing", 23)
    check testRunStatement(statement, eVariableDataOr)

  test "if0 missing required":
    let text = """a = b"""
    let statement = newStatement(text, lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr(wVariableMissing, "b", 4)
    check testRunStatement(statement, eVariableDataOr)

  test "slice":
    let text = """a = slice("abc", 0, 2)"""
    let statement = newStatement(text, lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr("a", "=", newValue("ab"))
    check testRunStatement(statement, eVariableDataOr)

  test "slice wrong type":
    let text = """a = slice("abc", 2, "b")"""
    let statement = newStatement(text, lineNum=1, 0)
    let eVariableDataOr = newVariableDataOr(kWrongType, "int", 20)
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




# todo: test prepost when user specified.
# todo: test the maximum variable length.
# todo: test endblock by itself.
