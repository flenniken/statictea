
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

proc toString(statements: seq[Statement]): string =
  var lines: seq[string]
  for ix, statement in statements:
    lines.add "$1: $2" % [$(ix+1), $statement]
  result = join(lines, "\n")

proc getCmdLineParts(line: string, templateFilename = "template.html",
    lineNum: Natural = 1): Option[LineParts] =
  ## Return the line parts from the given line.
  var env = openEnv("_testRunCommand.log")
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
    eValueO: Option[Value],
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[]): bool =
  ## Return true when the statement contains the expected number. When
  ## it doesn't show the values and expected values and return false.

  var env = openEnv("_testGetNumber.log")
  let compiledMatchers = getCompiledMatchers()
  let valueO = getNumber(env, compiledMatchers, statement, start)
  let (logLines, errLines, outLines) = env.readCloseDelete()

  notReturn testSome(valueO, eValueO, statement.text, start)
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
    check testGetNumber(newStatement("a = 5"), 4, newIntValueO(5))
    check testGetNumber(newStatement("a = 5.0"), 4, newFloatValueO(5.0))
    check testGetNumber(newStatement("a = -2"), 4, newIntValueO(-2))
    check testGetNumber(newStatement("a = -3.4"), 4, newFloatValueO(-3.4))
    check testGetNumber(newStatement("a = 88 "), 4, newIntValueO(88))

  test "getNumber with extra":
    let message = "template.html(23): w26: Invalid number, skipping the statement."
    check testGetNumber(newStatement("a = 5 abc"), 4, none(Value), eErrLines = @[message])

  test "getNumber not a number":
    let message = "template.html(23): w26: Invalid number, skipping the statement."
    check testGetNumber(newStatement("a = -abc"), 4, none(Value), eErrLines = @[message])

  test "getNumberIntTooBig":
    let message = "template.html(23): w27: The number is too big or too small, skipping the statement."
    check testGetNumber(newStatement("a = 9_223_372_036_854_775_808"), 4, none(Value), eErrLines = @[message])
