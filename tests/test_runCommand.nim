
import unittest
import options
import runCommand
import parseCmdLine
import strutils
import options
import env
import matches
import collectCommand
import vartypes
import variables
import tables
import warnings

proc newStrFromBuffer(buffer: seq[uint8]): string =
  result = newStringOfCap(buffer.len)
  for ix in 0 ..< buffer.len:
    result.add((char)buffer[ix])

proc toString(statements: seq[Statement]): string =
  var lines: seq[string]
  for ix, statement in statements:
    lines.add "$1: $2" % [$(ix+1), $statement]
  result = join(lines, "\n")

proc getCmdLineParts(line: string, lineNum: Natural = 1): Option[LineParts] =
  ## Return the line parts from the given line.
  # todo: remove this. Call it at a higher level.
  var env = openEnvTest("_testRunCommand.log")

  let compiledMatchers = getCompiledMatchers()
  result = parseCmdLine(env, compiledMatchers, line, lineNum)

  discard env.readCloseDelete()

proc getCmdLineParts(cmdLines: seq[string]): seq[LineParts] =
  ## Return the line parts from the given lines.
  for ix, line in cmdLines:
    let partsO = getCmdLineParts(line, lineNum = ix + 1)
    if not partsO.isSome():
      echo "cannot get command line parts for:"
      echo "line: '$1'" % line
    result.add(partsO.get())

proc getStatements(cmdLines: seq[string], cmdLineParts: seq[LineParts]): seq[Statement] =
  ## Return a list of statements for the given lines.
  let matchers = getCompiledMatchers()
  for statement in yieldStatements(cmdLines, cmdLineParts, matchers.allSpaceTabMatcher):
    result.add(statement)

proc testGetStatements(content: string): seq[Statement] =
  ## Return a list of statements for the given multiline content.
  let cmdLines = splitNewLines(content)
  let cmdLineParts = getCmdLineParts(cmdLines)
  # for part in cmdLineParts:
  #   echo $part
  result = getStatements(cmdLines, cmdLineParts)

proc testGetNumber(
    statement: Statement,
    start: Natural,
    eValueAndLengthO: Option[ValueAndLength],
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[]): bool =
  ## Return true when the statement contains the expected number. When
  ## it doesn't, show the values and expected values and return false.

  var env = openEnvTest("_testGetNumber.log", "template.html")

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

  var env = openEnvTest("_testGetString.log", "template.html")

  let compiledMatchers = getCompiledMatchers()
  let valueAndLengthO = getString(env, compiledMatchers, statement, start)

  let (logLines, errLines, outLines) = env.readCloseDelete()
  result = true

  if not testSome(valueAndLengthO, eValueAndlengthO, statement.text, start):
    result = false
  if not expectedItems("logLines", logLines, eLogLines):
    result = false
  if not expectedItems("outLines", outLines, eOutLines):
    result = false
  if not statement.text.contains("stringwithbadutf8"):
    if not expectedItems("errLines", errLines, eErrLines):
      result = false

proc stripNewline(line: string): string =
  if line.len > 0 and line[^1] == '\n':
    result = line[0 .. ^2]
  else:
    result = line

proc compareStatements(statements: seq[Statement], eContent: string): bool =
  ## Return true when the statements match the expected
  ## statements.
  let lines = splitNewLines(eContent)
  for ix, statement in statements:
    let got = $statement
    let expected = stripNewline(lines[ix])
    if got != expected:
      echo "     got: $1" % got
      echo "expected: $1" % expected
      return false
  return true

proc testGetVariable(statement: Statement, start: Natural, nameSpace: string, varName: string, eValueO:
                     Option[Value] = none(Value),
                     eLogLines: seq[string] = @[],
                     eErrLines: seq[string] = @[],
                     eOutLines: seq[string] = @[],
                    ): bool =

  var env = openEnvTest("_getVariable.log", "template.html")

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

  var env = openEnvTest("_getVariable.log", "template.html")

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

  var env = openEnvTest("_getVariable.log", "template.html")

  env.warnStatement(statement, warning, start, p1, p2)

  result = env.readCloseDeleteCompare(eLogLines, eErrLines, eOutLines)

proc testGetFunctionValue(functionName: string, statement: Statement, start: Natural,
    eValueAndLengthO: Option[ValueAndLength] = none(ValueAndLength),
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[]
  ): bool =

  var env = openEnvTest("_testGetFunctionValue.log", "template.html")

  var variables = getTestVariables()
  let compiledMatchers = getCompiledMatchers()
  let valueAndLengthO = getFunctionValue(env, compiledMatchers,
                          functionName, statement, start, variables)

  result = env.readCloseDeleteCompare(eLogLines, eErrLines, eOutLines)

  if not expectedItem("valueAndLength", valueAndLengthO, eValueAndLengthO):
    result = false

proc testRunStatement(statement: Statement,
    eSpaceNameValueO = none(SpaceNameValue),
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[]
  ): bool =
  var env = openEnvTest("_runStatement.log", "template.html")

  var variables = newVariables()
  let compiledMatchers = getCompiledMatchers()
  let spaceNameValueO = runStatement(env, statement, compiledMatchers, variables)

  result = env.readCloseDeleteCompare(eLogLines, eErrLines, eOutLines)

  if not expectedItem("SpaceNameValue", spaceNameValueO, eSpaceNameValueO):
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
    let cmdLines = splitNewLines(content)
    let cmdLineParts = getCmdLineParts(cmdLines)
    let statements = getStatements(cmdLines, cmdLineParts)
    let expected = """
1, 15: 'a = 5 '
"""
    check compareStatements(statements, expected)

  test "two statements":
    let content = """
<!--$ nextline a = 5; b = 6 -->
"""
    let cmdLines = splitNewLines(content)
    let cmdLineParts = getCmdLineParts(cmdLines)
    let statements = getStatements(cmdLines, cmdLineParts)
    let expected = """
1, 15: 'a = 5'
1, 21: ' b = 6 '
"""
    check compareStatements(statements, expected)

  test "three statements":
    let content = """
<!--$ nextline a = 5; b = 6 ;c=7-->
"""
    let cmdLines = splitNewLines(content)
    let cmdLineParts = getCmdLineParts(cmdLines)
    let statements = getStatements(cmdLines, cmdLineParts)
    let expected = """
1, 15: 'a = 5'
1, 21: ' b = 6 '
1, 29: 'c=7'
"""
    check compareStatements(statements, expected)

  test "two lines":
    let content = """
<!--$ nextline a = 5; \-->
<!--$ : asdf -->
"""
    let cmdLines = splitNewLines(content)
    let cmdLineParts = getCmdLineParts(cmdLines)
    let statements = getStatements(cmdLines, cmdLineParts)
    let expected = """
1, 15: 'a = 5'
1, 21: ' asdf '
"""
    check compareStatements(statements, expected)

  test "three statements split":
    let content = """
<!--$ block a = 5; b = \-->
<!--$ : "hello"; \-->
<!--$ : c = t.len(s.header) -->
"""
    let statements = testGetStatements(content)
    let expected = """
1, 12: 'a = 5'
1, 18: ' b = "hello"'
2, 16: ' c = t.len(s.header) '
"""
    check compareStatements(statements, expected)

  test "semicolon at the start":
    let content = """
<!--$ nextline ;a = 5 -->
"""
    let statements = testGetStatements(content)
    let expected = """
1, 16: 'a = 5 '
"""
    check compareStatements(statements, expected)

  test "double quotes":
    let content = """
<!--$ nextline a="hi" -->
"""
    let statements = testGetStatements(content)
    let expected = """
1, 15: 'a="hi" '
"""
    check compareStatements(statements, expected)

  test "double quotes with semicolon":
    let content = """
<!--$ nextline a="h\i;" -->
"""
    let statements = testGetStatements(content)
    let expected = """
1, 15: 'a="h\i;" '
"""
    check compareStatements(statements, expected)

  test "double quotes with slashed double quote":
    let content = """
<!--$ nextline a="\"hi\"" -->
"""
    let statements = testGetStatements(content)
    let expected = """
1, 15: 'a="\"hi\"" '
"""
    check compareStatements(statements, expected)

  test "double quotes with single quote":
    let content = """
<!--$ nextline a="'hi'" -->
"""
    let statements = testGetStatements(content)
    let expected = """
1, 15: 'a="'hi'" '
"""
    check compareStatements(statements, expected)

  test "single quotes":
    let content = """
<!--$ nextline a='hi' -->
"""
    let statements = testGetStatements(content)
    let expected = """
1, 15: 'a='hi' '
"""
    check compareStatements(statements, expected)

  test "single quotes with semicolon":
    let content = """
<!--$ nextline a='hi;there' -->
"""
    let statements = testGetStatements(content)
    let expected = """
1, 15: 'a='hi;there' '
"""
    check compareStatements(statements, expected)

  test "single quotes with slashed single quote":
    let content = """
<!--$ nextline a='hi\'there' -->
"""
    let statements = testGetStatements(content)
    let expected = """
1, 15: 'a='hi\'there' '
"""
    check compareStatements(statements, expected)

  test "single quotes with double quote":
    let content = """
<!--$ nextline a='hi "there"' -->
"""
    let statements = testGetStatements(content)
    let expected = """
1, 15: 'a='hi "there"' '
"""
    check compareStatements(statements, expected)

  test "semicolon at the end":
    let content = """
<!--$ nextline a = 5;-->
"""
    let statements = testGetStatements(content)
    let expected = """
1, 15: 'a = 5'
"""
    check compareStatements(statements, expected)

  test "two semicolons together":
    let content = """
<!--$ nextline asdf;;fdsa-->
"""
    let statements = testGetStatements(content)
    let expected = """
1, 15: 'asdf'
1, 21: 'fdsa'
"""
    check compareStatements(statements, expected)

  test "white space statement":
    let content = """
<!--$ nextline asdf; -->
"""
    let statements = testGetStatements(content)
    let expected = """
1, 15: 'asdf'
"""
    check compareStatements(statements, expected)

  test "white space statement 2":
    let content = """
<!--$ nextline asdf; \-->
<!--$ : ;   ; \-->
<!--$ : ;x = y -->
"""
    let statements = testGetStatements(content)
    let expected = """
1, 15: 'asdf'
3, 9: 'x = y '
"""
    check compareStatements(statements, expected)

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
    let eErrLines = @[
      "template.html(1): w26: Invalid number.",
      "statement: a = -abc",
      "               ^",
    ]
    check testGetNumber(newStatement("a = -abc"), 4,
                        none(ValueAndLength), eErrLines = eErrLines)

  test "getNumberIntTooBig":
    let eErrLines = @[
      "template.html(1): w27: The number is too big or too small.",
      "statement: a = 9_223_372_036_854_775_808",
      "               ^",
    ]
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
    var str: string
    var eLength: int
    for buffer in byteBuffers:
      str = newStrFromBuffer(buffer)
      eLength = buffer.len + 2
    var statement = "a = '$1'" % str
    check testGetString(newStatement(statement), 4, newStringValueAndLengthO(str, eLength))

  test "getString invalid utf-8":
    var byteBuffers: seq[seq[uint8]] = @[
      @[0xc3u8, 0x28],
      @[0xa0u8, 0xa1],
      @[0xe2u8, 0x28, 0xa1],
      @[0xe2u8, 0x82, 0x28],
      @[0xf0u8, 0x28, 0x8c, 0xbc],
      @[0xf0u8, 0x90, 0x28, 0xbc],
    ]
    var str: string
    for ix, buffer in byteBuffers:
      str = newStrFromBuffer(buffer)
      var statement = "a = 'stringwithbadutf8:$1:end'" % str
      var eErrLines = @[
        "template.html(1): w32: Invalid UTF-8 byte in the string.",
        "statement: a = 'stringwithbadutf8:?(?:end'",
        "                               ^",
      ]
      if not testGetString(newStatement(statement), 4, none(ValueAndLength), eErrLines = eErrLines):
        echo $ix & " failed"
        check false

  test "getString not string":
    let eErrLines = @[
      "template.html(1): w30: Invalid string.",
      "statement: a = 'abc",
      "               ^",
    ]
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
    let eErrLines = @[
      "template.html(12): w36: The variable 's.missing' does not exist.",
      "statement: tea = s.missing",
      "                 ^",
    ]
    check testGetVariable(statement, 6, "s.", "missing", none(Value), eErrLines = eErrLines)

  test "getVariable invalid namespace":
    let eErrLines = @[
      "template.html(12): w35: The variable namespace 'd.' does not exist.",
      "statement: tea = d.five",
      "                 ^",
    ]
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
    let eErrLines = @[
      "template.html(12): w36: The variable 'a' does not exist.",
      "statement: tea = a+123",
      "                 ^",
    ]
    check testGetVarOrFunctionValue(statement, 6, none(ValueAndLength), eErrLines = eErrLines)

  test "getVarOrFunctionValue not defined":
    let statement = newStatement(text="tea = a123", lineNum=12, 0)
    let eErrLines = @[
      "template.html(12): w36: The variable 'a123' does not exist.",
      "statement: tea = a123",
      "                 ^",
    ]
    check testGetVarOrFunctionValue(statement, 6, none(ValueAndLength), eErrLines = eErrLines)

  test "getNewVariables":
    var variables = newVariables()
    # echoVariables(variables)
    check variables.contains("content") == false
    check variables["local"].dictv.len == 0
    check variables["global"].dictv.len == 0
    check variables["output"] == Value(kind: vkString, stringv: "result")
    check variables["maxRepeat"] == Value(kind: vkInt, intv: 100)
    check variables["maxLines"] == Value(kind: vkInt, intv: 10)
    check variables["repeat"] == Value(kind: vkInt, intv: 1)
    check variables["row"] == Value(kind: vkInt, intv: 0)
    check variables["server"].dictv.len == 0
    check variables["shared"].dictv.len == 0

  test "warnStatement":
    let statement = newStatement(text="tea = a123", lineNum=12, 0)
    let eErrLines: seq[string] = @[
        "template.html(12): w36: The variable 'a123' does not exist.",
        "statement: tea = a123",
        "                 ^",
    ]
    check testWarnStatement(statement, wVariableMissing, 6, p1="a123", eErrLines = eErrLines)

  test "warnStatement long":
    let statement = newStatement(text="""tea  =  concat(a123, len(hello), format(len(asdfom)), 123456778, 1243123456, "this is a long statement", 678, 899)""", lineNum=12, 0)
    let eErrLines: seq[string] = @[
      "template.html(12): w36: The variable 'a123' does not exist.",
      "statement: tea  =  concat(a123, len(hello), format(len(asdfom)), 123456...",
      "                          ^",
    ]
    check testWarnStatement(statement, wVariableMissing, 15, p1="a123", eErrLines = eErrLines)

  test "warnStatement long":
    let statement = newStatement(text="""tea  =  concat(a123, len(hello), format(len(asdfom)), 123456778, 1243123456, "this is a long statement", 678, test)""", lineNum=12, 0)
    let eErrLines: seq[string] = @[
      "template.html(12): w36: The variable 'test' does not exist.",
      """statement: ...is is a long statement", 678, test)""",
        "                                            ^",
    ]
    check testWarnStatement(statement, wVariableMissing, 110, p1="test", eErrLines = eErrLines)

  test "warnStatement long2":
    let statement = newStatement(text="""tea                         =        concat(a123, len(hello), format(len(asdfom)), 123456778, num,   "this is a long statement with more on each end of the statement.", 678, test)""", lineNum=12, 0)
    let eErrLines: seq[string] = @[
      "template.html(12): w36: The variable 'num' does not exist.",
      """statement: ...rmat(len(asdfom)), 123456778, num,   "this is a long stateme...""",
        "                                            ^",
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
    let statement = newStatement(text="""tea = concat("abc", concat("xyz"), "def") """, lineNum=16, 0)
    let start = 13
    let value = Value(kind: vkString, stringv: "abcxyzdef")
    let eValueAndLengthO = some(ValueAndLength(value: value, length: 29))
    check testGetFunctionValue(functionName, statement, start, eValueAndLengthO = eValueAndLengthO)

  test "getFunctionValue no parameters":
    let functionName = "concat"
    let statement = newStatement(text="""tea = concat()""", lineNum=16, 0)
    let start = 13
    let value = Value(kind: vkString, stringv: "")
    let eValueAndLengthO = some(ValueAndLength(value: value, length: 1))
    check testGetFunctionValue(functionName, statement, start, eValueAndLengthO = eValueAndLengthO)

  test "getFunctionValue missing )":
    let statement = newStatement(text="""tea = len("abc" """, lineNum=16, 0)
    let eErrLines = @[
      "template.html(16): w46: Expected comma or right parentheses.",
      """statement: tea = len("abc" """,
        "                           ^",
    ]
    check testGetFunctionValue("len", statement, 10, eErrLines = eErrLines)

  test "getFunctionValue missing quote":
    let statement = newStatement(text="""tea = len("abc) """, lineNum=16, 0)
    let eErrLines = @[
      "template.html(16): w30: Invalid string.",
      """statement: tea = len("abc) """,
        "                     ^",
    ]
    check testGetFunctionValue("len", statement, 10, eErrLines = eErrLines)

  test "getFunctionValue extra comma":
    let statement = newStatement(text="""tea = len("abc",) """, lineNum=16, 0)
    let eErrLines = @[
      "template.html(16): w33: Expected a string, number, variable or function.",
      """statement: tea = len("abc",) """,
        "                           ^",
    ]
    check testGetFunctionValue("len", statement, 10, eErrLines = eErrLines)


  test "runStatement":
    let statement = newStatement(text="""t.repeat = 4 """, lineNum=1, 0)
    let eSpaceNameValueO = some(newSpaceNameValue("t.", "repeat", newValue(4)))
    check testRunStatement(statement, eSpaceNameValueO)

  test "runStatement string":
    let statement = newStatement(text="""str = "testing" """, lineNum=1, 0)
    let eSpaceNameValueO = some(newSpaceNameValue("", "str", newValue("testing")))
    check testRunStatement(statement, eSpaceNameValueO)

  test "runStatement junk at end":
    let statement = newStatement(text="""str = "testing" junk at end""", lineNum=1, 0)
    let eErrLines = @[
      "template.html(1): w31: Unused text at the end of the statement.",
      """statement: str = "testing" junk at end""",
        "                           ^",
    ]
    check testRunStatement(statement, eErrLines = eErrLines)

  test "getVariables 2":
    var variables = getTestVariables()
    let valueO = getVariable(variables, "s.", "test")
    check expectedItem("valueO", valueO, some(newValue("hello")))
