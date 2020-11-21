
import unittest
import options
import runCommand
import parseCmdLine
import strutils
import options
import env
import matches
import collectCommand
import testUtils
import vartypes

proc getCmdLineParts(line: string): Option[LineParts] =
  var env = openEnv("_testRunCommand.log")
  var prepostTable = getPrepostTable()
  var prefixMatcher = getPrefixMatcher(prepostTable)
  var commandMatcher = getCommandMatcher()
  result = parseCmdLine(env, prepostTable, prefixMatcher,
                        commandMatcher, line, "templateFilename", 99)
  discard env.readCloseDelete()

proc getCmdLineParts(cmdLines: seq[string]): seq[LineParts] =
  for line in cmdLines:
    let parts = getCmdLineParts(line)
    if not parts.isSome():
      echo "cannot get command line parts for:"
      echo "line: '$1'" % line
    result.add(parts.get())

proc getStatements(cmdLines: seq[string], cmdLineParts: seq[LineParts]): seq[string] =
  for statement in yieldStatements(cmdLines, cmdLineParts):
    result.add(statement)

proc splitStatements(content: string): seq[string] =
  ## Split a multiline string into lines. The ending newlines get
  ## removed and underscores get converted to spaces.
  ## example: let content = """
  ## a = 5
  ## b = 6_
  ## """
  ## returns two strings: "a = 5" and "b = 6 ".
  var eLines = splitNewLines(content)
  for line in eLines:
    var rline = line.replace('_', ' ')
    if rline.len > 0:
      let lastIndex = rline.len - 1
      if rline[lastIndex] == '\n':
        rline = rline[0 ..< lastIndex]
    result.add(rline)

proc testGetStatements(content: string): seq[string] =
  let cmdLines = splitNewLines(content)
  let cmdLineParts = getCmdLineParts(cmdLines)
  result = getStatements(cmdLines, cmdLineParts)

proc testGetNumber(
    statement: string,
    start: Natural,
    eValueO: Option[Value],
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[]): bool =
  ## Return true when the statement contains the expected number.

  var env = openEnv("_testGetNumber.log")
  let valueO = getNumber(env, statement, start)
  let (logLines, errLines, outLines) = env.readCloseDelete()

  notReturn testSome(valueO, eValueO, statement, start)
  notReturn expectedItems("logLines", logLines, eLogLines)
  notReturn expectedItems("errLines", errLines, eErrLines)
  notReturn expectedItems("outLines", outLines, eOutLines)
  result = true

proc compareStatements(statements: seq[string], eContent: string): bool =
  ## Return true when the statements match the expected
  ## statements. The newlines in the eStatements are stripped out
  ## before comparing.
  let eLines = splitStatements(eContent)
  if statements == eLines:
    return true
  if statements.len != eLines.len:
    echo "got $1 statements, expected $2" % [$statements.len, $eLines.len]
    for line in statements:
      echo "'$1'" % line
    echo "expected:"
    for line in eLines:
      echo "'$1'" % line
    return false
  for ix in 0 ..< eLines.len:
    let line = statements[ix]
    let eLine = eLines[ix]
    if line == eLine:
      echo "$1 same" % $ix
    else:
      echo "$1      got: '$2'" % [$ix, line]
      echo "$1 expected: '$2'" % [$ix, eLine]

suite "runCommand.nim":

  test "splitStatements empty":
    check splitStatements("").len == 0

  test "splitStatements one":
    let content = """
a = 5
"""
    let sLines = splitStatements(content)
    check sLines.len == 1
    check sLines[0] == "a = 5"

  test "splitStatements two":
    let content = """
a = 5
 b = 6_
"""
    let sLines = splitStatements(content)
    check sLines.len == 2
    check sLines[0] == "a = 5"
    check sLines[1] == " b = 6 "

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
    check statements.len == 1
    check statements[0] == "a = 5 "
    # echo "'$1'" % statements

  test "two statements":
    let content = """
<--!$ nextline a = 5; b = 6 -->
"""
    let cmdLines = splitNewLines(content)
    let cmdLineParts = getCmdLineParts(cmdLines)
    let statements = getStatements(cmdLines, cmdLineParts)
    check statements.len == 2
    check statements[0] == "a = 5"
    check statements[1] == " b = 6 "

  test "three statements":
    let content = """
<--!$ nextline a = 5; b = 6 ;c=7-->
"""
    let cmdLines = splitNewLines(content)
    let cmdLineParts = getCmdLineParts(cmdLines)
    let statements = getStatements(cmdLines, cmdLineParts)
    let eStatements = """
a = 5
 b = 6_
c=7
"""
    check compareStatements(statements, eStatements)

  test "two lines":
    let content = """
<--!$ nextline a = 5; \-->
<--!$ : asdf -->
"""
    let cmdLines = splitNewLines(content)
    let cmdLineParts = getCmdLineParts(cmdLines)
    let statements = getStatements(cmdLines, cmdLineParts)
    let eStatements = """
a = 5
 asdf_
"""
    check compareStatements(statements, eStatements)

  test "semicolon at the start":
    let content = """
<--!$ nextline ;a = 5 -->
"""
    let statements = testGetStatements(content)
    let eStatements = """
a = 5_
"""
    check compareStatements(statements, eStatements)

  test "double quotes":
    let content = """
<--!$ nextline a="hi" -->
"""
    let statements = testGetStatements(content)
    let eStatements = """
a="hi"_
"""
    check compareStatements(statements, eStatements)

  test "double quotes with semicolon":
    let content = """
<--!$ nextline a="h\i;" -->
"""
    let statements = testGetStatements(content)
    let eStatements = """
a="h\i;"_
"""
    check compareStatements(statements, eStatements)

  test "double quotes with slashed double quote":
    let content = """
<--!$ nextline a="\"hi\"" -->
"""
    let statements = testGetStatements(content)
    let eStatements = """
a="\"hi\""_
"""
    check compareStatements(statements, eStatements)

  test "double quotes with single quote":
    let content = """
<--!$ nextline a="'hi'" -->
"""
    let statements = testGetStatements(content)
    let eStatements = """
a="'hi'"_
"""
    check compareStatements(statements, eStatements)

  test "single quotes":
    let content = """
<--!$ nextline a='hi' -->
"""
    let statements = testGetStatements(content)
    let eStatements = """
a='hi'_
"""
    check compareStatements(statements, eStatements)

  test "single quotes with semicolon":
    let content = """
<--!$ nextline a='hi;there' -->
"""
    let statements = testGetStatements(content)
    let eStatements = """
a='hi;there'_
"""
    check compareStatements(statements, eStatements)

  test "single quotes with slashed single quote":
    let content = """
<--!$ nextline a='hi\'there' -->
"""
    let statements = testGetStatements(content)
    let eStatements = """
a='hi\'there'_
"""
    check compareStatements(statements, eStatements)

  test "single quotes with double quote":
    let content = """
<--!$ nextline a='hi "there"' -->
"""
    let statements = testGetStatements(content)
    let eStatements = """
a='hi "there"'_
"""
    check compareStatements(statements, eStatements)

  test "semicolon at the end":
    let content = """
<--!$ nextline a = 5;-->
"""
    let statements = testGetStatements(content)
    let eStatements = """
a = 5
"""
    check compareStatements(statements, eStatements)

  test "two semicolons together":
    let content = """
<--!$ nextline asdf;;fdsa-->
"""
    let statements = testGetStatements(content)
    let eStatements = """
asdf
fdsa
"""
    check compareStatements(statements, eStatements)

  test "white space statement":
    let content = """
<--!$ nextline asdf; -->
"""
    let statements = testGetStatements(content)
    let eStatements = """
asdf
"""
    check compareStatements(statements, eStatements)

  test "white space statement 2":
    let content = """
<--!$ nextline asdf; \-->
<--!$ : ;   ; \-->
<--!$ : ;x = y -->
"""
    let statements = testGetStatements(content)
    let eStatements = """
asdf
x = y_
"""
    check compareStatements(statements, eStatements)

  test "getNumber":
    check testGetNumber("a = 5", 4, some(Value(kind: vkInt, intv: 5)))
    check testGetNumber("a = 5.0", 4, some(Value(kind: vkFloat, floatv: 5.0)))
    check testGetNumber("a = -2", 4, some(Value(kind: vkInt, intv: -2)))
    check testGetNumber("a = -3.4", 4, some(Value(kind: vkFloat, floatv: -3.4)))

  test "getNumberExtra":
    let message = "template.html(23): w25: Ignoring extra text after the number."
    check testGetNumber("a = 88 ", 4, some(Value(kind: vkInt, intv: 88)),
      eErrLines = @[message])

  test "getNumberExtra":
    let message = "template.html(23): w25: Ignoring extra text after the number."
    check testGetNumber("a = 5 abc", 4, some(Value(kind: vkInt, intv: 5)),
      eErrLines = @[message])

  test "getNumberNotNumber":
    let message = "template.html(23): w26: Invalid number, skipping the statement."
    check testGetNumber("a = -abc", 4, none(Value), eErrLines = @[message])

  test "getNumberIntTooBig":
    let message = "template.html(23): w27: The number is too big or too small, skipping the statement."
    check testGetNumber("a = 9_223_372_036_854_775_808", 4, none(Value), eErrLines = @[message])
