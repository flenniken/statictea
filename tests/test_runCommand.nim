
import std/unittest
import std/options
import std/strutils
import std/options
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
import tostring
import readlines

proc startPointer*(start: Natural): string =
  ## Return a string containing the number of spaces and symbols to
  ## point at the line start value. Display it under the line.
  if start > 100:
    result.add("$1" % $start)
  else:
    for ix in 0..<start:
      result.add(' ')
    result.add("^$1" % $start)

proc testSome*[T](valueAndLengthO: Option[T], eValueAndLengthO: Option[T],
    text: string, start: Natural): bool =

  if valueAndLengthO == eValueAndLengthO:
    return true

  if not isSome(eValueAndLengthO):
    echo "Expected nothing but got something."
    echo $valueAndLengthO
    return false

  let value = valueAndLengthO.get().value
  let length = valueAndLengthO.get().length
  let eValue = eValueAndLengthO.get().value
  let eLength = eValueAndLengthO.get().length

  echo "Did not get the expected value."
  echo " text: $1" % text
  echo "start: $1" % startPointer(start)
  echo "got value: $1" % $value
  echo " expected: $1" % $evalue
  echo "got length: $1" % $length
  echo "  expected: $1" % $eLength

proc newStrFromBuffer(buffer: seq[uint8]): string =
  result = newStringOfCap(buffer.len)
  for ix in 0 ..< buffer.len:
    result.add((char)buffer[ix])

proc getCmdLineParts(env: var Env, cmdLines: seq[string]): seq[LineParts] =
  ## Return the line parts from the given lines.
  for ix, line in cmdLines:
    let prepostTable = makeDefaultPrepostTable()
    let partsO = parseCmdLine(env, prepostTable, line, lineNum = ix + 1)
    if not partsO.isSome():
      echo "cannot get command line parts for:"
      echo """line: "$1"""" % line
    result.add(partsO.get())

proc getStatements(cmdLines: seq[string], cmdLineParts: seq[LineParts]): seq[Statement] =
  ## Return a list of statements for the given lines.
  for statement in yieldStatements(cmdLines, cmdLineParts):
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
    let got = $statement
    let expected = stripNewline(lines[ix])
    if got != expected:
      echo "     got: $1" % got
      echo "expected: $1" % expected
      return false
  return true

proc testGetStatements(content: string, expected: string): bool =
  ## Return true when the template content generates the expected statements.

  var env = openEnvTest("_getStatements.txt")
  let cmdLines = splitNewLines(content)
  let cmdLineParts = getCmdLineParts(env, cmdLines)

  var statements = getStatements(cmdLines, cmdLineParts)

  discard env.readCloseDeleteEnv()

  result = true
  if not compareStatements(statements, expected):
    result = false

proc testGetNumber(
    statement: Statement,
    start: Natural,
    eValueAndLengthO: Option[ValueAndLength],
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[]): bool =
  ## Return true when the statement contains the expected number. When
  ## it doesn't, show the values and expected values and return false.

  var env = openEnvTest("_testGetNumber.log")

  let prepostTable = makeDefaultPrepostTable()
  let valueAndLengthO = getNumber(env, prepostTable, statement, start)

  result = env.readCloseDeleteCompare(eLogLines, eErrLines, eOutLines)

  if not testSome(valueAndLengthO, eValueAndLengthO, statement.text, start):
    result = false

proc testGetString(
    statement: Statement,
    start: Natural,
    eValueAndlengthO: Option[ValueAndLength],
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[]): bool =
  ## Return true when the statement contains the expected string. When
  ## it doesn't, show the values and expected values and return false.

  var env = openEnvTest("_testGetString.log")

  let prepostTable = makeDefaultPrepostTable()
  let valueAndLengthO = getString(env, prepostTable, statement, start)

  result = env.readCloseDeleteCompare(eLogLines, eErrLines, eOutLines)

  if not testSome(valueAndLengthO, eValueAndlengthO, statement.text, start):
    result = false

proc testGetStringInvalid(buffer: seq[uint8]): bool =
  let str = newStrFromBuffer(buffer)
  let statement = """a = "stringwithbadutf8:$1:end"""" % str
  let expectedLine = """statement: a = "stringwithbadutf8:$1:end"""" % str
  let eErrLines = @[
    "template.html(1): w32: Invalid UTF-8 byte in the string.\n",
    expectedLine & "\n",
    "                                  ^\n",
  ]
  #  statement: a = "stringwithbadutf8:$1:end
  result = testGetString(newStatement(statement), 4, none(ValueAndLength), eErrLines = eErrLines)

proc testGetVarOrFunctionValue(variables: Variables, statement: Statement, start: Natural,
    eValueAndLengthO: Option[ValueAndLength] = none(ValueAndLength),
                     eLogLines: seq[string] = @[],
                     eErrLines: seq[string] = @[],
                     eOutLines: seq[string] = @[],
                              ): bool =
  ## Get the variable or function value of the rhs for the given
  ## statement. The rhs starts at the given start index. Compare the
  ## value and number of characters processed with the given expected
  ## values and compare the with the given error lines. Return true
  ## when they match.

  var env = openEnvTest("_getVariable.log")

  let prepostTable = makeDefaultPrepostTable()

  let valueAndLengthO = getVarOrFunctionValue(env, prepostTable,
                                              statement, start,
                                              variables)

  result = env.readCloseDeleteCompare(eLogLines, eErrLines, eOutLines)

  if not expectedItem("valueAndLength", valueAndLengthO, eValueAndLengthO):
    result = false

proc testWarnStatement(statement: Statement,
    warning: Warning, start: Natural, p1: string="", p2: string="",
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[]
  ): bool =

  var env = openEnvTest("_getVariable.log")

  env.warnStatement(statement, warning, start, p1, p2)

  result = env.readCloseDeleteCompare(eLogLines, eErrLines, eOutLines)

proc testGetFunctionValue(functionName: string, statement: Statement, start: Natural,
    eValueAndLengthO: Option[ValueAndLength] = none(ValueAndLength),
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[]
  ): bool =

  var env = openEnvTest("_testGetFunctionValue.log")

  var variables = emptyVariables()
  let prepostTable = makeDefaultPrepostTable()
  let valueAndLengthO = getFunctionValue(env, prepostTable,
                          functionName, statement, start, variables)

  result = env.readCloseDeleteCompare(eLogLines, eErrLines, eOutLines)

  if not expectedItem("valueAndLength", valueAndLengthO, eValueAndLengthO):
    result = false

proc testRunStatement(statement: Statement, variables: var Variables,
    eVariableDataO: Option[VariableData] = none(VariableData),
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[]
  ): bool =
  var env = openEnvTest("_runStatement.log")

  let prepostTable = makeDefaultPrepostTable()
  let variableDataO = runStatement(env, statement, prepostTable, variables)

  result = env.readCloseDeleteCompare(eLogLines, eErrLines, eOutLines)

  if not expectedItem("variableDataO", variableDataO, eVariableDataO):
    result = false

suite "runCommand.nim":

  test "stripNewline":
    check stripNewline("") == ""
    check stripNewline("\n") == ""
    check stripNewline("1\n") == "1"
    check stripNewline("asdf") == "asdf"
    check stripNewline("asdf\n") == "asdf"

  test "compareStatements one":
    let expected = """
1, 1: "a = 5"
"""
    check compareStatements(@[newStatement("a = 5")], expected)

  test "compareStatements two":
    let expected = """
1, 1: "a = 5"
1, 1: "  b = 235 "
"""
    check compareStatements(@[
      newStatement("a = 5"),
      newStatement("  b = 235 ")
    ], expected)

  test "compareStatements three":
    let expected = """
1, 1: "a = 5"
2, 10: "  b = 235 "
2, 20: "  c = 0"
"""
    check compareStatements(@[
      newStatement("a = 5"),
      newStatement("  b = 235 ", lineNum = 2, start = 10),
      newStatement("  c = 0", lineNum = 2, start = 20)
    ], expected)

  test "no statements":
    let cmdLines = @["<!--$ nextline -->\n"]
    let cmdLineParts = @[newLineParts()]
    let statements = getStatements(cmdLines, cmdLineParts)
    check statements.len == 0

  test "one statement":
    let content = """
<!--$ nextline a = 5 -->
"""
    let expected = """
1, 15: "a = 5 "
"""
    check testGetStatements(content, expected)

  test "one statement string":
    let content = """
<!--$ nextline a = "tea" -->
"""
    let expected = """
1, 15: "a = "tea" "
"""
    check testGetStatements(content, expected)

  test "two statements":
    let content = """
<!--$ nextline a = 5; b = 6 -->
"""
    let expected = """
1, 15: "a = 5"
1, 21: " b = 6 "
"""
    check testGetStatements(content, expected)

  test "three statements":
    let content = """
<!--$ nextline a = 5; b = 6 ;c=7-->
"""
    let expected = """
1, 15: "a = 5"
1, 21: " b = 6 "
1, 29: "c=7"
"""
    check testGetStatements(content, expected)

  test "two lines":
    let content = """
<!--$ nextline a = 5; +-->
<!--$ : asdf -->
"""
    let expected = """
1, 15: "a = 5"
1, 21: " asdf "
"""
    check testGetStatements(content, expected)

  test "two lines newline":
    let content = """
<!--$ nextline a = 5 -->
<!--$ : asdf -->
"""
#123456789 123456789 123456789
    let expected = """
1, 15: "a = 5 "
2, 8: "asdf "
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

  test "continuation and not":
    let content = """
$$ nextline 234;4546;
$$ : a = 5;bbb = +
$$ : concat("1", "e")
$$ : c = len("hello")
"""
#123456789 123456789 123456789
    let expected = """
1, 12: "234"
1, 16: "4546"
2, 5: "a = 5"
2, 11: "bbb = concat("1", "e")"
4, 5: "c = len("hello")"
"""
    check testGetStatements(content, expected)

  test "three statements split":
    let content = """
<!--$ block a = 5; b = +-->
<!--$ : "hello"; +-->
<!--$ : c = t.len(s.header) -->
"""
    let expected = """
1, 12: "a = 5"
1, 18: " b = "hello""
2, 16: " c = t.len(s.header) "
"""
    check testGetStatements(content, expected)

  test "semicolon at the start":
    let content = """
<!--$ nextline ;a = 5 -->
"""
    let expected = """
1, 16: "a = 5 "
"""
    check testGetStatements(content, expected)

  test "double quotes":
    let content = """
<!--$ nextline a="hi" -->
"""
    let expected = """
1, 15: "a="hi" "
"""
    check testGetStatements(content, expected)

  test "double quotes with semicolon":
    let content = """
<!--$ nextline a="h\i;" -->
"""
    let expected = """
1, 15: "a="h\i;" "
"""
    check testGetStatements(content, expected)

  test "double quotes with slashed double quote":
    let content = """
<!--$ nextline a="\"hi\"" -->
"""
    let expected = """
1, 15: "a="\"hi\"" "
"""
    check testGetStatements(content, expected)

  test "double quotes with single quote":
    let content = """
<!--$ nextline a=""hi"" -->
"""
    let expected = """
1, 15: "a=""hi"" "
"""
    check testGetStatements(content, expected)

  test "single quotes":
    let content = """
<!--$ nextline a="hi" -->
"""
    let expected = """
1, 15: "a="hi" "
"""
    check testGetStatements(content, expected)

  test "single quotes with semicolon":
    let content = """
<!--$ nextline a="hi;there" -->
"""
    let expected = """
1, 15: "a="hi;there" "
"""
    check testGetStatements(content, expected)

  test "single quotes with slashed single quote":
    let content = """
<!--$ nextline a="hi\"there" -->
"""
    let expected = """
1, 15: "a="hi\"there" "
"""
    check testGetStatements(content, expected)

  test "single quotes with double quote":
    let content = """
<!--$ nextline a="hi "there"" -->
"""
    let expected = """
1, 15: "a="hi "there"" "
"""
    check testGetStatements(content, expected)

  test "semicolon at the end":
    let content = """
<!--$ nextline a = 5;-->
"""
    let expected = """
1, 15: "a = 5"
"""
    check testGetStatements(content, expected)

  test "two semicolons together":
    let content = """
<!--$ nextline asdf;;fdsa-->
"""
    let expected = """
1, 15: "asdf"
1, 21: "fdsa"
"""
    check testGetStatements(content, expected)

  test "white space statement":
    let content = """
<!--$ nextline asdf; -->
"""
    let expected = """
1, 15: "asdf"
"""
    check testGetStatements(content, expected)

  test "white space statement 2":
    let content = """
<!--$ nextline asdf; +-->
<!--$ : ;   ; +-->
<!--$ : ;x = y -->
"""
    let expected = """
1, 15: "asdf"
3, 9: "x = y "
"""
    check testGetStatements(content, expected)

  test "getNumber":
    check testGetNumber(newStatement("a = 5"), 4, newIntValueAndLengthO(5, 1))
    check testGetNumber(newStatement("a = 5.0"), 4, newFloatValueAndLengthO(5.0, 3))
    check testGetNumber(newStatement("a = -2"), 4, newIntValueAndLengthO(-2, 2))
    check testGetNumber(newStatement("a = -3.4"), 4, newFloatValueAndLengthO(-3.4, 4))
    check testGetNumber(newStatement("a = 88 "), 4, newIntValueAndLengthO(88, 3))

    # Starts with Valid number but invalid statement.
    check testGetNumber(newStatement("a = 88 abc "), 4,
                        newIntValueAndLengthO(88, 3))

  test "getNumber not a number":
    let eErrLines = splitNewLines """
template.html(1): w26: Invalid number.
statement: a = -abc
               ^
"""
    check testGetNumber(newStatement("a = -abc"), 4,
                        none(ValueAndLength), eErrLines = eErrLines)

  test "getNumberIntTooBig":
    let eErrLines = splitNewLines """
template.html(1): w27: The number is too big or too small.
statement: a = 9_223_372_036_854_775_808
               ^
"""
    check testGetNumber(newStatement("a = 9_223_372_036_854_775_808"),
                        4, none(ValueAndLength), eErrLines = eErrLines)

  test "getString":
    check testGetString(newStatement("""a = "hello""""), 4,
      newStringValueAndLengthO("hello", 7))

    check testGetString(newStatement("a = \"hello\""), 4,
      newStringValueAndLengthO("hello", 7))

    check testGetString(newStatement("""a = "hello"  """), 4,
      newStringValueAndLengthO("hello", 9))

  test "getString valid utf-8":
    var byteBuffers: seq[seq[uint8]] = @[
      @[0xc3u8, 0xb1],
      @[0xe2u8, 0x82, 0xa1],
      @[0xf0u8, 0x90, 0x8c, 0xbc],
    ]
    for buffer in byteBuffers:
      let str = newStrFromBuffer(buffer)
      let eLength = buffer.len + 2
      let statement = """a = "$1"""" % str
      check testGetString(newStatement(statement), 4, newStringValueAndLengthO(str, eLength))

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
    let eErrLines = splitNewLines """
template.html(1): w139: No ending double quote.
statement: a = "abc
                   ^
"""
    check testGetString(newStatement("""a = "abc"""), 4,
      none(ValueAndLength), eErrLines = eErrLines)

  test "getVarOrFunctionValue var1":
    # Test processing the right hand side when it is a variable.
    # The rhs should return 5 and it should process 4 characters.
    var variables = emptyVariables()
    discard assignVariable(variables, "five", newValue(5))
    let statement = newStatement(text="tea = five", lineNum=12, 0)
    let eValueAndLengthO = some(newValueAndLength(newValue(5), 4))
    check testGetVarOrFunctionValue(variables, statement, 6, eValueAndLengthO)

  test "getVarOrFunctionValue var2":
    var variables = emptyVariables()
    discard assignVariable(variables, "g.aboutfive", newValue(5.11))
    let statement = newStatement(text="""tea = g.aboutfive """, lineNum=12, 0)
    let eValueAndLengthO = some(newValueAndLength(newValue(5.11), 12))
    check testGetVarOrFunctionValue(variables, statement, 6, eValueAndLengthO)

  test "getVarOrFunctionValue not defined":
    let statement = newStatement(text="tea = a+123", lineNum=12, 0)
    let eErrLines = splitNewLines """
template.html(12): w36: The variable 'a' does not exist.
statement: tea = a+123
                 ^
"""
    var variables = emptyVariables()
    check testGetVarOrFunctionValue(variables, statement, 6, none(ValueAndLength), eErrLines = eErrLines)

  test "getVarOrFunctionValue not defined":
    let statement = newStatement(text="tea = a123", lineNum=12, 0)
    let eErrLines = splitNewLines """
template.html(12): w36: The variable 'a123' does not exist.
statement: tea = a123
                 ^
"""
    var variables = emptyVariables()
    check testGetVarOrFunctionValue(variables, statement, 6, none(ValueAndLength), eErrLines = eErrLines)

  test "getNewVariables":
    var variables = emptyVariables()
    check variables["l"].dictv.len == 0
    check variables["g"].dictv.len == 0
    check variables["s"].dictv.len == 0
    check variables["h"].dictv.len == 0
    check variables["row"] == Value(kind: vkInt, intv: 0)
    check variables["version"] == Value(kind: vkString, stringv: staticteaVersion)
    check variables.contains("content") == false

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
    let functionName = "len"
    let statement = newStatement(text="""tea = len("abc") """, lineNum=16, 0)
    let start = 10
    let value = Value(kind: vkInt, intv: 3)
    let eValueAndLengthO = some(ValueAndLength(value: value, length: 7))
    check testGetFunctionValue(functionName, statement, start, eValueAndLengthO = eValueAndLengthO)

  test "getFunctionValue 2 parameters":
    let functionName = "concat"
    let statement = newStatement(text="""tea = concat("abc", "def") """, lineNum=16, 0)
    let start = 13
    let value = Value(kind: vkString, stringv: "abcdef")
    let eValueAndLengthO = some(ValueAndLength(value: value, length: 14))
    check testGetFunctionValue(functionName, statement, start, eValueAndLengthO = eValueAndLengthO)

  test "getFunctionValue nested":
    let functionName = "concat"
    let statement = newStatement(text="""tea = concat("abc", concat("xyz", "123"), "def") """, lineNum=16, 0)
    let start = 13
    let value = Value(kind: vkString, stringv: "abcxyz123def")
    let eValueAndLengthO = some(ValueAndLength(value: value, length: 36))
    check testGetFunctionValue(functionName, statement, start, eValueAndLengthO = eValueAndLengthO)

  test "getFunctionValue missing )":
    let statement = newStatement(text="""tea = len("abc" """, lineNum=16, 0)
    let eErrLines = @[
      "template.html(16): w46: Expected comma or right parentheses.\n",
      """statement: tea = len("abc" """ & "\n",
        "                           ^\n",
    ]
    check testGetFunctionValue("len", statement, 10, eErrLines = eErrLines)

  test "getFunctionValue missing quote":
    let statement = newStatement(text="""tea = len("abc) """, lineNum=16, 0)
    let eErrLines = @[
      "template.html(16): w139: No ending double quote.\n",
      """statement: tea = len("abc) """ & "\n",
        "                           ^\n",
    ]
    check testGetFunctionValue("len", statement, 10, eErrLines = eErrLines)

  test "getFunctionValue extra comma":
    let statement = newStatement(text="""tea = len("abc",) """, lineNum=16, 0)
    let eErrLines = @[
      "template.html(16): w33: Expected a string, number, variable or function.\n",
      """statement: tea = len("abc",) """ & "\n",
        "                           ^\n",
    ]
    check testGetFunctionValue("len", statement, 10, eErrLines = eErrLines)

  test "runStatement":
    let statement = newStatement(text="""t.repeat = 4 """, lineNum=1, 0)
    var variables = emptyVariables()
    check testRunStatement(statement, variables,
                           some(newVariableData("t.repeat", newValue(4))))

  test "runStatement string":
    let statement = newStatement(text="""str = "testing" """, lineNum=1, 0)
    var variables = emptyVariables()
    check testRunStatement(statement, variables,
      eVariableDataO = some(newVariableData("str", newValue("testing"))))

  # test "runStatement nested":
  #   let statement = newStatement(text="""signature = replaceRe(substr(code, 0, pos), "\bFunResult\b", "RunResult_")""", lineNum=1, 0)
  #   var variables = emptyVariables()
  #   check testRunStatement(statement, variables,

  test "runStatement set log":
    let statement = newStatement(text="""t.output = "log" """, lineNum=1, 0)
    var variables = emptyVariables()
    check testRunStatement(statement, variables,
                           some(newVariableData("t.output", newValue("log"))))

  test "set invalid output":
    let statement = newStatement(text="""t.output = "notvalidv"""", lineNum=1, 0)
    let eErrLines = splitNewLines """
template.html(1): w41: Invalid t.output value, use: "result", "stderr", "log", or "skip".
statement: t.output = "notvalidv"
           ^
"""
    # The expected value is none, because it doesn't exist yet.
    var variables = emptyVariables()
    check testRunStatement(statement, variables, eErrLines = eErrLines)

  test "runStatement junk at end":
    let statement = newStatement(text="""str = "testing" junk at end""", lineNum=1, 0)
    let eErrLines = @[
      "template.html(1): w31: Unused text at the end of the statement.\n",
      """statement: str = "testing" junk at end""" & "\n",
        "                           ^\n",
    ]
    var variables = emptyVariables()
    check testRunStatement(statement, variables, eErrLines = eErrLines)

  test "does not start with var":
    let statement = newStatement(text="123 = 343", lineNum=1, 0)
    let eErrLines = splitNewLines """
template.html(1): w29: Statement does not start with a variable name.
statement: 123 = 343
           ^
"""
    var variables = emptyVariables()
    check testRunStatement(statement, variables, eErrLines = eErrLines)

  test "no equal sign":
    let statement = newStatement(text="var 343", lineNum=1, 0)
    let eErrLines = splitNewLines """
template.html(1): w34: Invalid variable or missing equal sign.
statement: var 343
           ^
"""
    var variables = emptyVariables()
    check testRunStatement(statement, variables, eErrLines = eErrLines)

  test "read only var":
    let statement = newStatement(text="t.server = 343", lineNum=1, 0)
    let eErrLines = splitNewLines """
template.html(1): w40: Invalid tea variable: server.
statement: t.server = 343
           ^
"""
    var variables = emptyVariables()
    check testRunStatement(statement, variables, eErrLines = eErrLines)

  test "invalid namespace":
    let statement = newStatement(text="e.server = 343", lineNum=1, 0)
    let eErrLines = splitNewLines """
template.html(1): w102: Name, e, doesn't exist in the parent dictionary.
statement: e.server = 343
           ^
"""
    var variables = emptyVariables()
    check testRunStatement(statement, variables, eErrLines = eErrLines)

  test "invalid maxLines":
    let statement = newStatement(text="""t.maxLines = "hello"""", lineNum=1, 0)
    let eErrLines = splitNewLines """
template.html(1): w42: Invalid count. It must be a positive integer.
statement: t.maxLines = "hello"
           ^
"""
    var variables = emptyVariables()
    check testRunStatement(statement, variables, eErrLines = eErrLines)

  test "content must be a string":
    let statement = newStatement(text="t.content = 3.45", lineNum=1, 0)
    let eErrLines = splitNewLines """
template.html(1): w43: Invalid t.content, it must be a string.
statement: t.content = 3.45
           ^
"""
    var variables = emptyVariables()
    check testRunStatement(statement, variables, eErrLines = eErrLines)

  test "invalid repeat":
    let statement = newStatement(text="t.repeat = 3.45", lineNum=1, 0)
    let eErrLines = splitNewLines """
template.html(1): w44: Invalid t.repeat, it must be an integer >= 0 and <= t.maxRepeat.
statement: t.repeat = 3.45
           ^
"""
    var variables = emptyVariables()
    check testRunStatement(statement, variables, eErrLines = eErrLines)

  test "invalid tea var":
    let statement = newStatement(text="t.asdf = 3.45", lineNum=1, 0)
    let eErrLines = splitNewLines """
template.html(1): w40: Invalid tea variable: asdf.
statement: t.asdf = 3.45
           ^
"""
    var variables = emptyVariables()
    check testRunStatement(statement, variables, eErrLines = eErrLines)


  test "invalid missing needed vararg parameter":
    let statement = newStatement(
      text="""result = dict("1", "else", "2", "two", "3")""", lineNum=1, 0)
    let eErrLines = splitNewLines """
template.html(1): w122: Missing vararg parameter, expected groups of 2 got 1.
statement: result = dict("1", "else", "2", "two", "3")
                                                  ^
"""
    var variables = emptyVariables()
    check testRunStatement(statement, variables, eErrLines = eErrLines)

  test "parameter error position":
    let text = """result = case(33, 2, 22, "abc", 11, len(concat()))"""
    let statement = newStatement(text, lineNum=1, 0)
    let eErrLines = splitNewLines """
template.html(1): w119: Not enough parameters, expected 1 got 0.
statement: result = case(33, 2, 22, "abc", 11, len(concat()))
                                                          ^
"""
    var variables = emptyVariables()
    check testRunStatement(statement, variables, eErrLines = eErrLines)


  test "assignTeaVariable version":
    let statement = newStatement(text="""t.version = "1.2.3"""", lineNum=1, 0)
    let eErrLines = splitNewLines """
template.html(1): w39: You cannot change the version tea variable.
statement: t.version = "1.2.3"
           ^
"""
    var variables = emptyVariables()
    check testRunStatement(statement, variables, eErrLines = eErrLines)

  test "assignTeaVariable missing":
    let statement = newStatement(text="""t.missing = "1.2.3"""", lineNum=1, 0)
    let eErrLines = splitNewLines """
template.html(1): w40: Invalid tea variable: missing.
statement: t.missing = "1.2.3"
           ^
"""
    var variables = emptyVariables()
    check testRunStatement(statement, variables, eErrLines = eErrLines)

  test "assignTeaVariable content":
    let statement = newStatement(text="""t.content = "1.2.3"""", lineNum=1, 0)
    var variables = emptyVariables()
    check testRunStatement(statement, variables,
      some(newVariableData("t.content", newValue("1.2.3"))))

  test "parseVersion":
    check parseVersion("1.2.3") == some((1, 2, 3))
    check parseVersion("111.222.333") == some((111, 222, 333))

  test "cmpVersion equal":
    let statement = newStatement(text="""cmp = cmpVersion("1.2.3", "1.2.3")""",
      lineNum=1, 0)
    var variables = emptyVariables()
    check testRunStatement(statement, variables, some(newVariableData("cmp", newValue(0))))

  test "cmpVersion less":
    let statement = newStatement(text="""cmp = cmpVersion("1.2.2", "1.2.3")""",
      lineNum=1, 0)
    var variables = emptyVariables()
    check testRunStatement(statement, variables, some(newVariableData("cmp", newValue(-1))))

  test "cmpVersion greater":
    let statement = newStatement(text="""cmp = cmpVersion("1.2.4", "1.2.3")""",
      lineNum=1, 0)
    var variables = emptyVariables()
    check testRunStatement(statement, variables,
      some(newVariableData("cmp", newValue(1))))

  test "cmpVersion less 2":
    let statement = newStatement(text="""cmp = cmpVersion("1.22.3", "2.1.0")""",
      lineNum=1, 0)
    var variables = emptyVariables()
    check testRunStatement(statement, variables,
      some(newVariableData("cmp", newValue(-1))))

  test "cmpVersion less 3":
    let statement = newStatement(text="""cmp = cmpVersion("2.22.3", "2.44.0")""",
      lineNum=1, 0)
    var variables = emptyVariables()
    check testRunStatement(statement, variables, some(newVariableData("cmp", newValue(-1))))

  test "cmpVersion two parameters":
    let statement = newStatement(text="""cmp = cmpVersion("1.2.3")""", lineNum=1, 0)
    let eErrLines = splitNewLines """
template.html(1): w119: Not enough parameters, expected 2 got 1.
statement: cmp = cmpVersion("1.2.3")
                            ^
"""
    var variables = emptyVariables()
    check testRunStatement(statement, variables, eErrLines = eErrLines)

  test "cmpVersion strings":
    let statement = newStatement(text="""cmp = cmpVersion("1.2.3", 3.5)""",
      lineNum=1, 0)
    let eErrLines = splitNewLines """
template.html(1): w120: Wrong parameter type, expected string got float.
statement: cmp = cmpVersion("1.2.3", 3.5)
                                     ^
"""
    var variables = emptyVariables()
    check testRunStatement(statement, variables, eErrLines = eErrLines)

  test "incomplete function":
    let statement = newStatement(text="""a = len("asdf"""", lineNum=1, 0)
    let eErrLines = splitNewLines """
template.html(1): w46: Expected comma or right parentheses.
statement: a = len("asdf"
                         ^
"""
    var variables = emptyVariables()
    check testRunStatement(statement, variables, eErrLines = eErrLines)

  test "incomplete function 2":
    let statement = newStatement(text="a = len(case(5,", lineNum=1, 0)
    let eErrLines = splitNewLines """
template.html(1): w33: Expected a string, number, variable or function.
statement: a = len(case(5,
                          ^
"""
    var variables = emptyVariables()
    check testRunStatement(statement, variables, eErrLines = eErrLines)

  test "dot name":
    let statement = newStatement(text="a# = 5", lineNum=1, 0)
    let eErrLines = splitNewLines """
template.html(1): w34: Invalid variable or missing equal sign.
statement: a# = 5
           ^
"""
    var variables = emptyVariables()
    check testRunStatement(statement, variables, eErrLines = eErrLines)

  test "startPointer":
    check startPointer(0) == "^0"
    check startPointer(1) == " ^1"
    check startPointer(2) == "  ^2"
    check startPointer(101) == "101"

  test "startColumn":
    check startColumn(0) == "^"
    check startColumn(1) == " ^"
    check startColumn(2) == "  ^"
    check startColumn(3) == "   ^"

  test "one quote":
    let statement = newStatement(text="""  quote = "\""   """, lineNum=1, 0)
    var variables = emptyVariables()
    check testRunStatement(statement, variables,
                           some(newVariableData("quote", newValue("""""""))))


# todo: test that a warning is generated when the item doesn't exist.
# todo: test prepost when user specified.
# todo: test the maximum variable length of 64, 66 including the optional prefix.
# todo: test endblock by itself.
# todo: use "import std/strutils to include system modules
# todo: update to the latest nim version
#
