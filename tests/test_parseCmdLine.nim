
import unittest
import parseCmdLine
import env
import matches
import options
import strutils

proc testParseCmdLine(line: string, expectedLineParts: LineParts,
    expectedLogLines: seq[string] = @[],
    expectedErrLines: seq[string] = @[],
    expectedOutLines: seq[string] = @[] ): bool =
  ## Return true on success.

  var env = openEnv("_parseCmdLine.log")

  var prepostTable = getPrepostTable()
  var prefixMatcher = getPrefixMatcher(prepostTable)
  var commandMatcher = getCommandMatcher()
  let linePartsO = parseCmdLine(env, prepostTable, prefixMatcher, commandMatcher, line)

  let (logLines, errLines, outLines) = env.readCloseDelete()

  if not linePartsO.isSome:
    echo line
    echo "parseCmdLine didn't find a line"
    return false

  let lps = linePartsO.get()
  let elps = expectedLineParts
  if lps != elps:
    echo line
    echo "got prefix: '$1'" % lps.prefix
    echo "  expected: '$1'" % elps.prefix
    echo "got command: '$1'" % lps.command
    echo "   expected: '$1'" % elps.command
    echo "got middle: '$1'" % lps.middle
    echo "  expected: '$1'" % elps.middle
    echo "got continuation: $1" % $lps.continuation
    echo "        expected: $1" % $elps.continuation
    echo "got postfix: '$1'" % lps.postfix
    echo "    postfix: '$1'" % elps.postfix
    echo "got ending: '$1'" % getEndingString(lps.ending)
    echo "  expected: '$1'" % getEndingString(elps.ending)
    return false

  if expectedLogLines != logLines:
    echo "expectedLogLines"
    return false
  if expectedErrLines != errLines:
    echo "expectedErrLines"
    return false
  if expectedoutLines != outLines:
    echo "expectedoutLines"
    return false

  return true

suite "parseCmdLine.nim":

  test "newLineParts":
    var lps = newLineParts()
    check lps.prefix == "<--!$"
    check lps.command == "nextline"
    check lps.middle == ""
    check lps.continuation == false
    check lps.postfix == "-->"
    check lps.ending == "\n"

  test "newLineParts set":
    var lps = newLineParts(prefix = "asdf", command = "command",
      middle="middle", continuation = true, postfix = "post", ending = "ending")
    check lps.prefix == "asdf"
    check lps.command == "command"
    check lps.middle == "middle"
    check lps.continuation == true
    check lps.postfix == "post"
    check lps.ending == "ending"

  test "parseCmdLine":
    let line = "<--!$ nextline -->\n"
    var expectedLineParts = newLineParts()
    check testParseCmdLine(line, expectedLineParts)

  test "parseCmdLine middle":
    let line = "<--!$ nextline middle part -->\n"
    var expectedLineParts = newLineParts(middle = "middle part ")
    check testParseCmdLine(line, expectedLineParts)

  test "parseCmdLine continue":
    let line = "<--!$ nextline \\-->\n"
    var expectedLineParts = newLineParts(continuation = true)
    check testParseCmdLine(line, expectedLineParts)

  test "parseCmdLine last line":
    let line = "<--!$ nextline -->"
    var expectedLineParts = newLineParts(ending = "")
    check testParseCmdLine(line, expectedLineParts)

  test "parseCmdLine block":
    let line = "<--!$ block -->\n"
    var expectedLineParts = newLineParts(command = "block")
    check testParseCmdLine(line, expectedLineParts)

  test "parseCmdLine prefix":
    let line = "#$ nextline \n"
    var expectedLineParts = newLineParts(prefix = "#$", postfix = "")
    check testParseCmdLine(line, expectedLineParts)

  test "parseCmdLine multiple":
    let line = "#$ block a = 5; b = 'hi'"
    var expectedLineParts = newLineParts(prefix = "#$", command = "block",
      middle = "a = 5; b = 'hi'", postfix = "", ending = "")
    check testParseCmdLine(line, expectedLineParts)

