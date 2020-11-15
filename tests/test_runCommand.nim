
import unittest
import options
import runCommand
import parseCmdLine
import strutils
import options
import env
import matches
import collectCommand

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
  var eLines = collectCommand.splitLines(content)
  for line in eLines:
    var rline = line.replace('_', ' ')
    if rline.len > 0:
      let lastIndex = rline.len - 1
      if rline[lastIndex] == '\n':
        rline = rline[0 ..< lastIndex]
    result.add(rline)

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
    let cmdLines = collectCommand.splitLines(content)
    let cmdLineParts = getCmdLineParts(cmdLines)
    let statements = getStatements(cmdLines, cmdLineParts)
    check statements.len == 1
    check statements[0] == "a = 5 "
    # echo "'$1'" % statements

  test "two statements":
    let content = """
<--!$ nextline a = 5; b = 6 -->
"""
    let cmdLines = collectCommand.splitLines(content)
    let cmdLineParts = getCmdLineParts(cmdLines)
    let statements = getStatements(cmdLines, cmdLineParts)
    check statements.len == 2
    check statements[0] == "a = 5"
    check statements[1] == " b = 6 "

  test "three statements":
    let content = """
<--!$ nextline a = 5; b = 6 ;c=7-->
"""
    let cmdLines = collectCommand.splitLines(content)
    let cmdLineParts = getCmdLineParts(cmdLines)
    let statements = getStatements(cmdLines, cmdLineParts)
    let eStatements = """
a = 5
 b = 6_
c=7
"""
    check compareStatements(statements, eStatements)
