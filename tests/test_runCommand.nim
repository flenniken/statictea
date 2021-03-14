
import unittest
import options
import runCommand
import runFunction
import parseCmdLine
import strutils
import options
import env
import matches
import vartypes
import variables
import tables
import warnings
import regexes
import version

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
    let compiledMatchers = getCompiledMatchers()
    let partsO = parseCmdLine(env, compiledMatchers, line, lineNum = ix + 1)
    if not partsO.isSome():
      echo "cannot get command line parts for:"
      echo "line: '$1'" % line
    result.add(partsO.get())

proc getStatements(cmdLines: seq[string], cmdLineParts: seq[LineParts]): seq[Statement] =
  ## Return a list of statements for the given lines.
  let matchers = getCompiledMatchers()
  for statement in yieldStatements(cmdLines, cmdLineParts, matchers.allSpaceTabMatcher):
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

  let compiledMatchers = getCompiledMatchers()
  let valueAndLengthO = getNumber(env, compiledMatchers, statement, start)

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

  let compiledMatchers = getCompiledMatchers()
  let valueAndLengthO = getString(env, compiledMatchers, statement, start)

  result = env.readCloseDeleteCompare(eLogLines, eErrLines, eOutLines)

  if not testSome(valueAndLengthO, eValueAndlengthO, statement.text, start):
    result = false

proc testGetStringInvalid(buffer: seq[uint8]): bool =
  let str = newStrFromBuffer(buffer)
  let statement = "a = 'stringwithbadutf8:$1:end'" % str
  let expectedLine = "statement: a = 'stringwithbadutf8:$1:end'" % str
  let eErrLines = @[
    "template.html(1): w32: Invalid UTF-8 byte in the string.\n",
    expectedLine & "\n",
    "                                  ^\n",
  ]
  result = testGetString(newStatement(statement), 4, none(ValueAndLength), eErrLines = eErrLines)

proc testGetVariable(statement: Statement, start: Natural, nameSpace: string, varName: string,
    eValueO: Option[Value],
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[],
  ): bool =

  var env = openEnvTest("_getVariable.log")

  var variables = getTestVariables()
  let valueO = getVariable(env, statement, variables, namespace, varName, start)

  result = env.readCloseDeleteCompare(eLogLines, eErrLines, eOutLines)

  if not expectedItem("value", valueO, eValueO):
    result = false

proc testGetVarOrFunctionValue(statement: Statement, start: Natural,
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

  var variables = getTestVariables()
  let compiledMatchers = getCompiledMatchers()

  let valueAndLengthO = getVarOrFunctionValue(env, compiledMatchers,
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

  var variables = getTestVariables()
  let compiledMatchers = getCompiledMatchers()
  var functionO = getFunction(functionName)
  if not isSome(functionO):
    return false
  let function = functionO.get()
  let valueAndLengthO = getFunctionValue(env, compiledMatchers,
                          function, statement, start, variables)

  result = env.readCloseDeleteCompare(eLogLines, eErrLines, eOutLines)

  if not expectedItem("valueAndLength", valueAndLengthO, eValueAndLengthO):
    result = false

proc testRunStatement(statement: Statement, nameSpace: string = "", varName: string = "",
    eValueO: Option[Value] = none(Value),
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[]
  ): bool =
  var env = openEnvTest("_runStatement.log")

  var emptyVarsDict: VarsDict
  var variables = newVariables(emptyVarsDict, emptyVarsDict)
  let compiledMatchers = getCompiledMatchers()
  runStatement(env, statement, compiledMatchers, variables)

  result = env.readCloseDeleteCompare(eLogLines, eErrLines, eOutLines)

  let valueO = getVariable(variables, namespace, varName)
  if not expectedItem("value", valueO, eValueO):
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
1, 1: 'a = 5'
"""
    check compareStatements(@[newStatement("a = 5")], expected)

  test "compareStatements two":
    let expected = """
1, 1: 'a = 5'
1, 1: '  b = 235 '
"""
    check compareStatements(@[
      newStatement("a = 5"),
      newStatement("  b = 235 ")
    ], expected)

  test "compareStatements three":
    let expected = """
1, 1: 'a = 5'
2, 10: '  b = 235 '
2, 20: '  c = 0'
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
1, 15: 'a = 5 '
"""
    check testGetStatements(content, expected)

  test "two statements":
    let content = """
<!--$ nextline a = 5; b = 6 -->
"""
    let expected = """
1, 15: 'a = 5'
1, 21: ' b = 6 '
"""
    check testGetStatements(content, expected)

  test "three statements":
    let content = """
<!--$ nextline a = 5; b = 6 ;c=7-->
"""
    let expected = """
1, 15: 'a = 5'
1, 21: ' b = 6 '
1, 29: 'c=7'
"""
    check testGetStatements(content, expected)

  test "two lines":
    let content = """
<!--$ nextline a = 5; \-->
<!--$ : asdf -->
"""
    let expected = """
1, 15: 'a = 5'
1, 21: ' asdf '
"""
    check testGetStatements(content, expected)

  test "three statements split":
    let content = """
<!--$ block a = 5; b = \-->
<!--$ : "hello"; \-->
<!--$ : c = t.len(s.header) -->
"""
    let expected = """
1, 12: 'a = 5'
1, 18: ' b = "hello"'
2, 16: ' c = t.len(s.header) '
"""
    check testGetStatements(content, expected)

  test "semicolon at the start":
    let content = """
<!--$ nextline ;a = 5 -->
"""
    let expected = """
1, 16: 'a = 5 '
"""
    check testGetStatements(content, expected)

  test "double quotes":
    let content = """
<!--$ nextline a="hi" -->
"""
    let expected = """
1, 15: 'a="hi" '
"""
    check testGetStatements(content, expected)

  test "double quotes with semicolon":
    let content = """
<!--$ nextline a="h\i;" -->
"""
    let expected = """
1, 15: 'a="h\i;" '
"""
    check testGetStatements(content, expected)

  test "double quotes with slashed double quote":
    let content = """
<!--$ nextline a="\"hi\"" -->
"""
    let expected = """
1, 15: 'a="\"hi\"" '
"""
    check testGetStatements(content, expected)

  test "double quotes with single quote":
    let content = """
<!--$ nextline a="'hi'" -->
"""
    let expected = """
1, 15: 'a="'hi'" '
"""
    check testGetStatements(content, expected)

  test "single quotes":
    let content = """
<!--$ nextline a='hi' -->
"""
    let expected = """
1, 15: 'a='hi' '
"""
    check testGetStatements(content, expected)

  test "single quotes with semicolon":
    let content = """
<!--$ nextline a='hi;there' -->
"""
    let expected = """
1, 15: 'a='hi;there' '
"""
    check testGetStatements(content, expected)

  test "single quotes with slashed single quote":
    let content = """
<!--$ nextline a='hi\'there' -->
"""
    let expected = """
1, 15: 'a='hi\'there' '
"""
    check testGetStatements(content, expected)

  test "single quotes with double quote":
    let content = """
<!--$ nextline a='hi "there"' -->
"""
    let expected = """
1, 15: 'a='hi "there"' '
"""
    check testGetStatements(content, expected)

  test "semicolon at the end":
    let content = """
<!--$ nextline a = 5;-->
"""
    let expected = """
1, 15: 'a = 5'
"""
    check testGetStatements(content, expected)

  test "two semicolons together":
    let content = """
<!--$ nextline asdf;;fdsa-->
"""
    let expected = """
1, 15: 'asdf'
1, 21: 'fdsa'
"""
    check testGetStatements(content, expected)

  test "white space statement":
    let content = """
<!--$ nextline asdf; -->
"""
    let expected = """
1, 15: 'asdf'
"""
    check testGetStatements(content, expected)

  test "white space statement 2":
    let content = """
<!--$ nextline asdf; \-->
<!--$ : ;   ; \-->
<!--$ : ;x = y -->
"""
    let expected = """
1, 15: 'asdf'
3, 9: 'x = y '
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
    check testGetString(newStatement("a = 'hello'"), 4, newStringValueAndLengthO("hello", 7))
    check testGetString(newStatement("a = \"hello\""), 4, newStringValueAndLengthO("hello", 7))
    check testGetString(newStatement("a = 'hello'  "), 4, newStringValueAndLengthO("hello", 9))
    check testGetString(newStatement("a = \"hello\"  "), 4, newStringValueAndLengthO("hello", 9))

  test "getString valid utf-8":
    var byteBuffers: seq[seq[uint8]] = @[
      @[0xc3u8, 0xb1],
      @[0xe2u8, 0x82, 0xa1],
      @[0xf0u8, 0x90, 0x8c, 0xbc],
    ]
    for buffer in byteBuffers:
      let str = newStrFromBuffer(buffer)
      let eLength = buffer.len + 2
      let statement = "a = '$1'" % str
      check testGetString(newStatement(statement), 4, newStringValueAndLengthO(str, eLength))

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
template.html(1): w30: Invalid string.
statement: a = 'abc
               ^
"""
    check testGetString(newStatement("a = 'abc"), 4, none(ValueAndLength), eErrLines = eErrLines)

  test "getVariable server":
    # s.test = "hello"
    # h.test = "there"
    # five = 5
    # t.five = 5
    # g.aboutfive = 5.11
    let statement = newStatement("tea = s.test", lineNum=12, start=0)
    let value = Value(kind: vkString, stringv: "hello")
    check testGetVariable(statement, 6, "s.", "test", some(value))

  test "getVariable shared":
    let statement = newStatement("tea = h.test", lineNum=12, start=0)
    let value = Value(kind: vkString, stringv: "there")
    check testGetVariable(statement, 6, "h.", "test", some(value))

  test "getVariable local":
    let statement = newStatement("tea = five", lineNum=12, start=0)
    let value = Value(kind: vkInt, intv: 5)
    check testGetVariable(statement, 6, "", "five", some(value))

  test "getVariable tea":
    let statement = newStatement("tea = t.five", lineNum=12, start=0)
    let value = Value(kind: vkInt, intv: 5)
    check testGetVariable(statement, 6, "t.", "five", some(value))

  test "getVariable global":
    let statement = newStatement("tea = g.aboutfive", lineNum=12, start=0)
    let value = Value(kind: vkFloat, floatv: 5.11)
    check testGetVariable(statement, 6, "g.", "aboutfive", some(value))

  test "getVariable missing":
    let statement = newStatement("tea = s.missing", lineNum=12, start=0)
    let eErrLines = splitNewLines """
template.html(12): w36: The variable 's.missing' does not exist.
statement: tea = s.missing
                 ^
"""
    check testGetVariable(statement, 6, "s.", "missing", none(Value), eErrLines = eErrLines)

  test "getVariable invalid namespace":
    let eErrLines = splitNewLines """
template.html(12): w35: The variable namespace 'd.' does not exist.
statement: tea = d.five
                 ^
"""
    let statement = newStatement(text="tea = d.five", lineNum=12, 0)
    check testGetVariable(statement, 6, "d.", "missing", none(Value), eErrLines = eErrLines)

  test "getVarOrFunctionValue var1":
    # Test processing the right hand side when it is a variable.
    # The rhs should return 5 and it should process 4 characters.

    # s.test = "hello"
    # h.test = "there"
    # five = 5
    # t.five = 5
    # g.aboutfive = 5.11
    let statement = newStatement(text="tea = five", lineNum=12, 0)
    let value = Value(kind: vkInt, intv: 5)
    let eValueAndLengthO = some(ValueAndLength(value: value, length: 4))
    check testGetVarOrFunctionValue(statement, 6, eValueAndLengthO)

  test "getVarOrFunctionValue var2":
    let statement = newStatement(text="""tea = s.test """, lineNum=12, 0)
    let value = Value(kind: vkString, stringv: "hello")
    let eValueAndLengthO = some(ValueAndLength(value: value, length: 7))
    check testGetVarOrFunctionValue(statement, 6, eValueAndLengthO)

  test "getVarOrFunctionValue var2":
    let statement = newStatement(text="""tea = g.aboutfive """, lineNum=12, 0)
    let value = Value(kind: vkFloat, floatv: 5.11)
    let eValueAndLengthO = some(ValueAndLength(value: value, length: 12))
    check testGetVarOrFunctionValue(statement, 6, eValueAndLengthO)

  test "getVarOrFunctionValue not defined":
    let statement = newStatement(text="tea = a+123", lineNum=12, 0)
    let eErrLines = splitNewLines """
template.html(12): w36: The variable 'a' does not exist.
statement: tea = a+123
                 ^
"""
    check testGetVarOrFunctionValue(statement, 6, none(ValueAndLength), eErrLines = eErrLines)

  test "getVarOrFunctionValue not defined":
    let statement = newStatement(text="tea = a123", lineNum=12, 0)
    let eErrLines = splitNewLines """
template.html(12): w36: The variable 'a123' does not exist.
statement: tea = a123
                 ^
"""
    check testGetVarOrFunctionValue(statement, 6, none(ValueAndLength), eErrLines = eErrLines)

  test "getNewVariables":
    var emptyVarsDict: VarsDict
    var variables = newVariables(emptyVarsDict, emptyVarsDict)
    # echoVariables(variables)
    check variables.contains("content") == false
    check variables["local"].dictv.len == 0
    check variables["global"].dictv.len == 0
    check variables["row"] == Value(kind: vkInt, intv: 0)
    check variables["server"].dictv.len == 0
    check variables["shared"].dictv.len == 0
    check variables["version"] == Value(kind: vkString, stringv: staticteaVersion)

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
      "template.html(12): w36: The variable 'test' does not exist.\n",
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
      "template.html(16): w30: Invalid string.\n",
      """statement: tea = len("abc) """ & "\n",
        "                     ^\n",
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

  test "getVariables 2":
    var variables = getTestVariables()
    let valueO = getVariable(variables, "s.", "test")
    check expectedItem("valueO", valueO, some(newValue("hello")))

  test "runStatement":
    let statement = newStatement(text="""t.repeat = 4 """, lineNum=1, 0)
    check testRunStatement(statement, "t.", "repeat", some(newValue(4)))

  test "runStatement string":
    let statement = newStatement(text="""str = "testing" """, lineNum=1, 0)
    check testRunStatement(statement, "", "str", some(newValue("testing")))

  test "runStatement set log":
    let statement = newStatement(text="""t.output = "log" """, lineNum=1, 0)
    check testRunStatement(statement, "t.", "output", eValueO = some(newValue("log")))

  test "set invalid output":
    let statement = newStatement(text="t.output = 'notvalidv'", lineNum=1, 0)
    let eErrLines = splitNewLines """
template.html(1): w41: Invalid t.output value, use: "result", "stderr", "log", or "skip".
statement: t.output = 'notvalidv'
                      ^
"""
    # The expected value is none, because it doesn't exist yet.
    check testRunStatement(statement, "t.", "output", eErrLines = eErrLines,
                           eValueO = none(Value))

  test "runStatement junk at end":
    let statement = newStatement(text="""str = "testing" junk at end""", lineNum=1, 0)
    let eErrLines = @[
      "template.html(1): w31: Unused text at the end of the statement. Missing semicolon?\n",
      """statement: str = "testing" junk at end""" & "\n",
        "                           ^\n",
    ]
    check testRunStatement(statement, eErrLines = eErrLines)

  test "does not start with var":
    let statement = newStatement(text="123 = 343", lineNum=1, 0)
    let eErrLines = splitNewLines """
template.html(1): w29: Statement does not start with a variable name.
statement: 123 = 343
           ^
"""
    check testRunStatement(statement, eErrLines = eErrLines)

  test "no equal sign":
    let statement = newStatement(text="var 343", lineNum=1, 0)
    let eErrLines = splitNewLines """
template.html(1): w34: Invalid variable or missing equal sign.
statement: var 343
           ^
"""
    check testRunStatement(statement, eErrLines = eErrLines)

  test "read only var":
    let statement = newStatement(text="t.server = 343", lineNum=1, 0)
    let eErrLines = splitNewLines """
template.html(1): w39: You cannot change the server tea variable.
statement: t.server = 343
           ^
"""
    check testRunStatement(statement, eErrLines = eErrLines)

  test "invalid namespace":
    let statement = newStatement(text="e.server = 343", lineNum=1, 0)
    let eErrLines = splitNewLines """
template.html(1): w35: The variable namespace 'e.' does not exist.
statement: e.server = 343
           ^
"""
    check testRunStatement(statement, eErrLines = eErrLines)

  test "invalid maxLines":
    let statement = newStatement(text="t.maxLines = 'hello'", lineNum=1, 0)
    let eErrLines = splitNewLines """
template.html(1): w42: Invalid count. It must be a positive integer.
statement: t.maxLines = 'hello'
                        ^
"""
    check testRunStatement(statement, eErrLines = eErrLines)

  test "content must be a string":
    let statement = newStatement(text="t.content = 3.45", lineNum=1, 0)
    let eErrLines = splitNewLines """
template.html(1): w43: Invalid t.content, it must be a string.
statement: t.content = 3.45
                       ^
"""
    check testRunStatement(statement, eErrLines = eErrLines)

  test "invalid repeat":
    let statement = newStatement(text="t.repeat = 3.45", lineNum=1, 0)
    let eErrLines = splitNewLines """
template.html(1): w44: Invalid t.repeat, it must be an integer >= 0 and <= t.maxRepeat.
statement: t.repeat = 3.45
                      ^
"""
    check testRunStatement(statement, eErrLines = eErrLines)

  test "invalid tea var":
    let statement = newStatement(text="t.asdf = 3.45", lineNum=1, 0)
    let eErrLines = splitNewLines """
template.html(1): w40: Invalid tea variable: asdf.
statement: t.asdf = 3.45
           ^
"""
    check testRunStatement(statement, eErrLines = eErrLines)


  test "invalid missing needed else":
    let statement = newStatement(text="result = case(1, 2, 22, 'abc', 33)", lineNum=1, 0)
    let eErrLines = splitNewLines """
template.html(1): w94: None of the case conditions match and no else case.
template.html(1): w48: Invalid statement, skipping it.
statement: result = case(1, 2, 22, 'abc', 33)
                         ^
"""
    check testRunStatement(statement, eErrLines = eErrLines)

  test "parameter error position":
    let text = "result = case(33, 2, 22, 'abc', 11, len(concat('a')))"
    let statement = newStatement(text, lineNum=1, 0)
    let eErrLines = splitNewLines """
template.html(1): w66: The function takes two or more parameters.
template.html(1): w48: Invalid statement, skipping it.
statement: result = case(33, 2, 22, 'abc', 11, len(concat('a')))
                                                          ^
"""
    check testRunStatement(statement, eErrLines = eErrLines)


  test "assignTeaVariable version":
    let statement = newStatement(text="""t.version = "1.2.3"""", lineNum=1, 0)
    let eErrLines = splitNewLines """
template.html(1): w39: You cannot change the version tea variable.
statement: t.version = "1.2.3"
           ^
"""
    check testRunStatement(statement, eErrLines = eErrLines)

  test "assignTeaVariable missing":
    let statement = newStatement(text="""t.missing = "1.2.3"""", lineNum=1, 0)
    let eErrLines = splitNewLines """
template.html(1): w40: Invalid tea variable: missing.
statement: t.missing = "1.2.3"
           ^
"""
    check testRunStatement(statement, eErrLines = eErrLines)

  test "assignTeaVariable content":
    let statement = newStatement(text="""t.content = "1.2.3"""", lineNum=1, 0)
    check testRunStatement(statement)

  test "parseVersion":
    check parseVersion("1.2.3") == some((1, 2, 3))
    check parseVersion("111.222.333") == some((111, 222, 333))

  test "cmpVersion equal":
    let statement = newStatement(text="cmp = cmpVersion('1.2.3', '1.2.3')", lineNum=1, 0)
    check testRunStatement(statement, varName = "cmp", eValueO = some(newValue(0)))

  test "cmpVersion less":
    let statement = newStatement(text="cmp = cmpVersion('1.2.2', '1.2.3')", lineNum=1, 0)
    check testRunStatement(statement, varName = "cmp", eValueO = some(newValue(-1)))

  test "cmpVersion greater":
    let statement = newStatement(text="cmp = cmpVersion('1.2.4', '1.2.3')", lineNum=1, 0)
    check testRunStatement(statement, varName = "cmp", eValueO = some(newValue(1)))

  test "cmpVersion less 2":
    let statement = newStatement(text="cmp = cmpVersion('1.22.3', '2.1.0')", lineNum=1, 0)
    check testRunStatement(statement, varName = "cmp", eValueO = some(newValue(-1)))

  test "cmpVersion less 3":
    let statement = newStatement(text="cmp = cmpVersion('2.22.3', '2.44.0')", lineNum=1, 0)
    check testRunStatement(statement, varName = "cmp", eValueO = some(newValue(-1)))

  test "cmpVersion two parameters":
    let statement = newStatement(text="cmp = cmpVersion('1.2.3')", lineNum=1, 0)
    let eErrLines = splitNewLines """
template.html(1): w62: The function takes two parameters.
template.html(1): w48: Invalid statement, skipping it.
statement: cmp = cmpVersion('1.2.3')
                            ^
"""
    check testRunStatement(statement, eErrLines = eErrLines)

  test "cmpVersion strings":
    let statement = newStatement(text="cmp = cmpVersion('1.2.3', 3.5)", lineNum=1, 0)
    let eErrLines = splitNewLines """
template.html(1): w47: Expected a string.
template.html(1): w48: Invalid statement, skipping it.
statement: cmp = cmpVersion('1.2.3', 3.5)
                                     ^
"""
    check testRunStatement(statement, eErrLines = eErrLines)


# todo: test that a warning is generated when the item doesn't exist.
# todo: test prepost when user specified.
# todo: test the maximum variable length of 64, 66 including the optional prefix.
# todo: test endblock by itself.
# todo: use "import std/strutils to include system modules
# todo: update to the latest nim version
# 
