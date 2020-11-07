
import unittest
import parseCmdLine
import env
import matches
import options
import strutils

proc testParseCmdLine(line: string, expectedLineParts: LineParts,
    templateFilename: string = "template.html", lineNum: Natural=12,
    expectedLogLines: seq[string] = @[],
    expectedErrLines: seq[string] = @[],
    expectedOutLines: seq[string] = @[] ): bool =
  ## Return true on success.

  var env = openEnv("_parseCmdLine.log")

  var prepostTable = getPrepostTable()
  var prefixMatcher = getPrefixMatcher(prepostTable)
  var commandMatcher = getCommandMatcher()
  let linePartsO = parseCmdLine(env, prepostTable, prefixMatcher,
    commandMatcher, line, templateFilename, lineNum)

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

proc parseCmdLineError(line: string,
    expectedLogLines: seq[string] = @[],
    expectedErrLines: seq[string] = @[],
    expectedOutLines: seq[string] = @[] ): bool =
  ## Test that we get an error parsing the command line. Return true
  ## when we get the expected errors.

  var env = openEnv("_parseCmdLine.log")
  let templateFilename = "template.html"
  let lineNum = 12

  var prepostTable = getPrepostTable()
  var prefixMatcher = getPrefixMatcher(prepostTable)
  var commandMatcher = getCommandMatcher()
  let linePartsO = parseCmdLine(env, prepostTable, prefixMatcher,
    commandMatcher, line, templateFilename, lineNum)

  let (logLines, errLines, outLines) = env.readCloseDelete()

  if linePartsO.isSome:
    echo line
    echo "We parsed the line when we shouldn't have."
    return false

  if expectedLogLines != logLines:
    for line in logLines:
      echo "log line: $1" % line
    for line in expectedLogLines:
      echo "expected: $1" % line
    return false

  if expectedErrLines != errLines:
    for line in errLines:
      echo "error line: $1" % line
    for line in expectedErrLines:
      echo "  expected: $1" % line
    return false

  if expectedoutLines != outLines:
    for line in outLines:
      echo "out line:: $1" % line
    for line in expectedoutLines:
      echo " expected: $1" % line
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

  test "parseCmdLine middle 2":
    let line = "<--!$ nextline    middle part  -->\n"
    var expectedLineParts = newLineParts(middle = "   middle part  ")
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

  # We require the command on the first line.
  # test "parseCmdLine no command":
  #   let line = r"#$   \"
  #   var expectedLineParts = newLineParts(prefix = "#$", command = "",
  #     postfix = "", ending = "")
  #   check testParseCmdLine(line, expectedLineParts)

  test "no prefix":
    let line = " nextline -->\n"
    check parseCmdLineError(line)

  test "no command error":
    let line = "<--!$ -->\n"
    let expectedWarn = "template.html(12): w22: No valid command found on the line, skipping."
    check parseCmdLineError(line, expectedErrLines = @[expectedWarn])

  test "no postfix error":
    let line = "<--!$ nextline \n"
    let expectedWarn = """template.html(12): w23: The matching closing comment was not found. Expected: "-->""""
    check parseCmdLineError(line, expectedErrLines = @[expectedWarn])
