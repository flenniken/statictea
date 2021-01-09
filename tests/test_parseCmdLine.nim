
import unittest
import parseCmdLine
import env
import matches
import options
import strutils

proc testParseCmdLine(
    line: string,
    lineNum: Natural = 1,
    expectedLineParts: LineParts,
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[]
  ): bool =
  ## Return true on success.

  var env = openEnvTest("_parseCmdLine.log", "template.html")

  let compiledMatchers = getCompiledMatchers()
  let linePartsO = parseCmdLine(env, compiledMatchers, line, lineNum)

  result = env.readCloseDeleteCompare(eLogLines, eErrLines, eOutLines)

  if not linePartsO.isSome:
    echo line
    echo "parseCmdLine didn't find a line"
    return false

  let lps = linePartsO.get()
  let elps = expectedLineParts
  if lps != elps:
    echo line
    echo "0123456789 123456789 123456789"
    if not expectedItem("prefix", lps.prefix, elps.prefix):
      result = false
    if not expectedItem("command", lps.command, elps.command):
      result = false
    if not expectedItem("middleStart", lps.middleStart, elps.middleStart):
      result = false
    if not expectedItem("middleLen", lps.middleLen, elps.middleLen):
      result = false
    if not expectedItem("continuation", lps.continuation, elps.continuation):
      result = false
    if not expectedItem("postfix", lps.postfix, elps.postfix):
      result = false
    if not expectedItem("ending", getEndingString(lps.ending), getEndingString(elps.ending)):
      result = false
    if not expectedItem("lineNum", lps.lineNum, elps.lineNum):
      result = false

proc parseCmdLineError(
    line: string,
    lineNum: Natural = 12,
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[] ): bool =
  ## Test that we get an error parsing the command line. Return true
  ## when we get the expected errors.

  var env = openEnvTest("_parseCmdLine.log", "template.html")

  let compiledMatchers = getCompiledMatchers()
  let linePartsO = parseCmdLine(env, compiledMatchers, line, lineNum)

  result = env.readCloseDeleteCompare(eLogLines, eErrLines, eOutLines)

  if linePartsO.isSome:
    echo line
    echo "We parsed the line when we shouldn't have."
    result = false

suite "parseCmdLine.nim":

  test "newLineParts":
    var lps = newLineParts()
    check lps.prefix == "<!--$"
    check lps.command == "nextline"
    check lps.middleStart == 15
    check lps.middleLen == 0
    check lps.continuation == false
    check lps.postfix == "-->"
    check lps.ending == "\n"
    check lps.lineNum == 1

  test "newLineParts set":
    var lps = newLineParts(prefix = "asdf", command = "command",
      middleStart = 15, middleLen = 20, continuation = true,
      postfix = "post", ending = "ending", lineNum = 12)
    check lps.prefix == "asdf"
    check lps.command == "command"
    check lps.middleStart == 15
    check lps.middleLen == 20
    check lps.continuation == true
    check lps.postfix == "post"
    check lps.ending == "ending"
    check lps.lineNum == 12

  test "parseCmdLine":
    let line = "<!--$ nextline -->\n"
    var elps = newLineParts()
    check testParseCmdLine(line, expectedLineParts = elps)

  test "parseCmdLine middle":
    let line = "<!--$ nextline middle part -->\n"
    var elps = newLineParts(middleStart = 15, middleLen = 12)
    check testParseCmdLine(line, expectedLineParts = elps)

  test "parseCmdLine middle 2":
    let line = "<!--$ nextline    middle part  -->\n"
    var elps = newLineParts(middleStart = 15, middleLen = 16)
    check testParseCmdLine(line, expectedLineParts = elps)

  test "parseCmdLine continue":
    let line = "<!--$ nextline \\-->\n"
    var elps = newLineParts(continuation = true)
    check testParseCmdLine(line, expectedLineParts = elps)

  test "parseCmdLine last line":
    let line = "<!--$ nextline -->"
    var elps = newLineParts(ending = "")
    check testParseCmdLine(line, expectedLineParts = elps)

  test "parseCmdLine block":
    let line = "<!--$ block -->\n"
    var elps = newLineParts(command = "block", middleStart = 12)
    check testParseCmdLine(line, expectedLineParts = elps)

  test "parseCmdLine endblock":
    let line = "<!--$ endblock -->"
    var elps = newLineParts(command = "endblock", middleStart = 15, ending = "")
    check testParseCmdLine(line, expectedLineParts = elps)

  test "parseCmdLine comment":
    let line = "<!--$ # this is comment -->"
    var elps = newLineParts(command = "#", middleStart = 8, middleLen = 16, ending = "")
    check testParseCmdLine(line, expectedLineParts = elps)

  test "parseCmdLine prefix":
    let line = "#$ nextline \n"
    var elps = newLineParts(prefix = "#$",
      middleStart = 12, postfix = "")
    check testParseCmdLine(line, expectedLineParts = elps)

  test "parseCmdLine multiple":
    let line = "#$ block a = 5; b = 'hi'"
    var elps = newLineParts(prefix = "#$", command = "block",
      middleStart = 9, middleLen = 15, postfix = "", ending = "")
    check testParseCmdLine(line, expectedLineParts = elps)

  # todo: enable this test.
  # test "parseCmdLine endblock":
  #   let line = "#$ endblock\n"
  #   var elps = newLineParts(prefix = "#$", command = "endblock",
  #     middleStart = 11, middleLen = 1, postfix = "", ending = "")
  #   check testParseCmdLine(line, expectedLineParts = elps)

  test "no prefix":
    let line = " nextline -->\n"
    check parseCmdLineError(line)

  test "no command error":
    let line = "<!--$ -->\n"
    let expectedWarn = "template.html(12): w22: No command found at column 7, skipping line."
    check parseCmdLineError(line, eErrLines = @[expectedWarn])

  test "no postfix error":
    let line = "<!--$ nextline \n"
    let expectedWarn = """template.html(16): w23: The matching closing comment postfix was not found, expected: "-->"."""
    check parseCmdLineError(line, lineNum = 16, eErrLines = @[expectedWarn])
