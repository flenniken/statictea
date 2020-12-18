
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

proc newStrFromBuffer(buffer: seq[uint8]): string =
  result = newStringOfCap(buffer.len)
  for ix in 0 ..< buffer.len:
    result.add((char)buffer[ix])

proc toString(statements: seq[Statement]): string =
  var lines: seq[string]
  for ix, statement in statements:
    lines.add "$1: $2" % [$(ix+1), $statement]
  result = join(lines, "\n")

proc getCmdLineParts(line: string, templateFilename = "template.html",
    lineNum: Natural = 1): Option[LineParts] =
  ## Return the line parts from the given line.
  var env = openEnvTest("_testRunCommand.log")
  # todo: get pass in the compiledMatchers.
  let compiledMatchers = getCompiledMatchers()
  result = parseCmdLine(env, compiledMatchers, line, templateFilename, lineNum)
  # todo: remove open and close of the env.
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
  for statement in yieldStatements(cmdLines, cmdLineParts):
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

  var env = openEnvTest("_testGetNumber.log")
  env.templateFilename = "template.html"

  let compiledMatchers = getCompiledMatchers()
  let valueAndLengthO = getNumber(env, compiledMatchers, statement, start)
  let (logLines, errLines, outLines) = env.readCloseDelete()

  notReturn testSome(valueAndLengthO, eValueAndLengthO, statement.text, start)
  notReturn expectedItems("logLines", logLines, eLogLines)
  notReturn expectedItems("errLines", errLines, eErrLines)
  notReturn expectedItems("outLines", outLines, eOutLines)
  result = true

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
  env.templateFilename = "template.html"

  let compiledMatchers = getCompiledMatchers()
  let valueAndLengthO = getString(env, compiledMatchers, statement, start)
  let (logLines, errLines, outLines) = env.readCloseDelete()

  notReturn testSome(valueAndLengthO, eValueAndlengthO, statement.text, start)
  notReturn expectedItems("logLines", logLines, eLogLines)
  notReturn expectedItems("errLines", errLines, eErrLines)
  notReturn expectedItems("outLines", outLines, eOutLines)
  result = true

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

func getTestVariables(): Variables =
  result = newVariables()
  let value1 = Value(kind: vkString, stringv: "hello")
  result.server["test"] = value1
  let value2 = Value(kind: vkString, stringv: "there")
  result.shared["test"] = value2
  let value3 = Value(kind: vkInt, intv: 5)
  result.local["five"] = value3
  let value4 = Value(kind: vkInt, intv: 5)
  result.tea["five"] = value4
  let value5 = Value(kind: vkFloat, floatv: 5.11)
  result.global["aboutfive"] = value5


proc testGetVariable(nameSpace: string, varName: string, eValueO:
                     Option[Value] = none(Value), eErrLines:
                        seq[string] = @[]): bool =

  var env = openEnvTest("_getVariable.log")
  env.templateFilename = "template.html"
  let statement = newStatement("test statement", 12, 4)
  var variables = getTestVariables()

  let valueO = getVariable(env, statement, variables, namespace, varName)

  let (logLines, errLines, outLines) = env.readCloseDelete()
  notReturn expectedItem("value", valueO, eValueO)
  notReturn logLines.len == 0
  notReturn expectedItems("errLines", errLines, eErrLines)
  notReturn outLines.len == 0
  result = true

proc testGetVarOrFunctionValue(statement: Statement, start: Natural,
                               eValueAndLengthO: Option[ValueAndLength]
                                   = none(ValueAndLength), eErrLines:
                                     seq[string] = @[]): bool =
  var env = openEnvTest("_getVariable.log")
  env.templateFilename = "template.html"
  var variables = getTestVariables()
  let compiledMatchers = getCompiledMatchers()

  let valueAndLengthO = getVarOrFunctionValue(env, compiledMatchers,
                                              statement, start,
                                              variables)

  let (logLines, errLines, outLines) = env.readCloseDelete()
  notReturn expectedItems("errLines", errLines, eErrLines)
  notReturn expectedItem("valueAndLength", valueAndLengthO, eValueAndLengthO)
  notReturn logLines.len == 0
  notReturn outLines.len == 0
  result = true

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
    let cmdLines = @["<--!$ nextline -->\n"]
    let cmdLineParts = @[newLineParts()]
    let statements = getStatements(cmdLines, cmdLineParts)
    check statements.len == 0

  test "one statement":
    let content = """
<--!$ nextline a = 5 -->
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
<--!$ nextline a = 5; b = 6 -->
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
<--!$ nextline a = 5; b = 6 ;c=7-->
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
<--!$ nextline a = 5; \-->
<--!$ : asdf -->
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
<--!$ block a = 5; b = \-->
<--!$ : "hello"; \-->
<--!$ : c = t.len(s.header) -->
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
<--!$ nextline ;a = 5 -->
"""
    let statements = testGetStatements(content)
    let expected = """
1, 16: 'a = 5 '
"""
    check compareStatements(statements, expected)

  test "double quotes":
    let content = """
<--!$ nextline a="hi" -->
"""
    let statements = testGetStatements(content)
    let expected = """
1, 15: 'a="hi" '
"""
    check compareStatements(statements, expected)

  test "double quotes with semicolon":
    let content = """
<--!$ nextline a="h\i;" -->
"""
    let statements = testGetStatements(content)
    let expected = """
1, 15: 'a="h\i;" '
"""
    check compareStatements(statements, expected)

  test "double quotes with slashed double quote":
    let content = """
<--!$ nextline a="\"hi\"" -->
"""
    let statements = testGetStatements(content)
    let expected = """
1, 15: 'a="\"hi\"" '
"""
    check compareStatements(statements, expected)

  test "double quotes with single quote":
    let content = """
<--!$ nextline a="'hi'" -->
"""
    let statements = testGetStatements(content)
    let expected = """
1, 15: 'a="'hi'" '
"""
    check compareStatements(statements, expected)

  test "single quotes":
    let content = """
<--!$ nextline a='hi' -->
"""
    let statements = testGetStatements(content)
    let expected = """
1, 15: 'a='hi' '
"""
    check compareStatements(statements, expected)

  test "single quotes with semicolon":
    let content = """
<--!$ nextline a='hi;there' -->
"""
    let statements = testGetStatements(content)
    let expected = """
1, 15: 'a='hi;there' '
"""
    check compareStatements(statements, expected)

  test "single quotes with slashed single quote":
    let content = """
<--!$ nextline a='hi\'there' -->
"""
    let statements = testGetStatements(content)
    let expected = """
1, 15: 'a='hi\'there' '
"""
    check compareStatements(statements, expected)

  test "single quotes with double quote":
    let content = """
<--!$ nextline a='hi "there"' -->
"""
    let statements = testGetStatements(content)
    let expected = """
1, 15: 'a='hi "there"' '
"""
    check compareStatements(statements, expected)

  test "semicolon at the end":
    let content = """
<--!$ nextline a = 5;-->
"""
    let statements = testGetStatements(content)
    let expected = """
1, 15: 'a = 5'
"""
    check compareStatements(statements, expected)

  test "two semicolons together":
    let content = """
<--!$ nextline asdf;;fdsa-->
"""
    let statements = testGetStatements(content)
    let expected = """
1, 15: 'asdf'
1, 21: 'fdsa'
"""
    check compareStatements(statements, expected)

  test "white space statement":
    let content = """
<--!$ nextline asdf; -->
"""
    let statements = testGetStatements(content)
    let expected = """
1, 15: 'asdf'
"""
    check compareStatements(statements, expected)

  test "white space statement 2":
    let content = """
<--!$ nextline asdf; \-->
<--!$ : ;   ; \-->
<--!$ : ;x = y -->
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
    let messages = @[
      "template.html(1): w37: The statement starting at column 1 has an error.",
      "template.html(1): w26: Invalid number, skipping the statement.",
    ]
    check testGetNumber(newStatement("a = -abc"), 4,
                        none(ValueAndLength), eErrLines = messages)

  test "getNumberIntTooBig":
    let messages = @[
      "template.html(1): w37: The statement starting at column 1 has an error.",
      "template.html(1): w27: The number is too big or too small, skipping the statement.",
    ]
    check testGetNumber(newStatement("a = 9_223_372_036_854_775_808"),
                        4, none(ValueAndLength), eErrLines = messages)

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
    for buffer in byteBuffers:
      str = newStrFromBuffer(buffer)
    var statement = "a = '$1'" % str
    var messages = @[
      "template.html(1): w37: The statement starting at column 1 has an error.",
      "template.html(1): w32: Invalid UTF-8 byte in the string at column 5.",
    ]
    check testGetString(newStatement(statement), 4, none(ValueAndLength), eErrLines = messages)

  test "getString not string":
    let messages = @[
      "template.html(1): w37: The statement starting at column 1 has an error.",
      "template.html(1): w30: Invalid string.",
    ]
    check testGetString(newStatement("a = 'abc"), 4, none(ValueAndLength), eErrLines = messages)

  test "getVariable server":
    let value = Value(kind: vkString, stringv: "hello")
    check testGetVariable("s.", "test", some(value))

  test "getVariable shared":
    let value = Value(kind: vkString, stringv: "there")
    check testGetVariable("h.", "test", some(value))

  test "getVariable local":
    let value = Value(kind: vkInt, intv: 5)
    check testGetVariable("", "five", some(value))

  test "getVariable tea":
    let value = Value(kind: vkInt, intv: 5)
    check testGetVariable("t.", "five", some(value))

  test "getVariable global":
    let value = Value(kind: vkFloat, floatv: 5.11)
    check testGetVariable("g.", "aboutfive", some(value))

  test "getVariable missing":
    let eErrLines = @[
      "template.html(12): w37: The statement starting at column 4 has an error.",
      "template.html(12): w36: The variable 's.missing' does not exist.",
    ]
    check testGetVariable("s.", "missing", eErrLines = eErrLines)

  test "getVariable invalid namespace":
    let eErrLines = @[
      "template.html(12): w37: The statement starting at column 4 has an error.",
      "template.html(12): w35: The variable namespace 'd.' does not exist.",
    ]
    check testGetVariable("d.", "key", eErrLines = eErrLines)

  test "getVarOrFunctionValue":
    let start = 6
    let statement = newStatement(text="tea = five", lineNum=12, start)
    let value = Value(kind: vkInt, intv: 5)
    let eValueAndLengthO = some(ValueAndLength(value: value, length: 4))
    check testGetVarOrFunctionValue(statement, start, eValueAndLengthO)
