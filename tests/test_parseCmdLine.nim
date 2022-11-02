
import std/unittest
import std/options
import std/strutils
import parseCmdLine
import env
import matches
import messages
import opresultwarn

proc test_getCodeLength(line: string, codeStart: Natural, eCodeLen: Natural): bool =
  if codeStart >= line.len:
    echo "invalid codeStart"
    return false
  let midLen = line.len - codeStart
  let codeLen = getCodeLength(line, codeStart, midLen)
  if codeLen != eCodeLen:
    echo "line = " & line
    echo "line = 0123456789 123456789 12345678"
    echo "codeStart = " & $codeStart
    echo "midLen = " & $midLen
    echo "expected codeLen = $1" % $ eCodeLen
    echo "     got codeLen = $1" % $ codeLen
    return false
  return true

func getEndingString(ending: string): string =
  if ending == "\n":
    result = r"\n"
  elif ending == "\r\n":
    result = r"\r\n"
  else:
    result = ending

proc testParseCmdLine(
    line: string,
    lineNum: Natural = 1,
    expectedLineParts: LineParts,
  ): bool =
  ## Return true on success.

  result = true

  let prepostTable = makeDefaultPrepostTable()
  let linePartsOr = parseCmdLine(prepostTable, line, lineNum)
  if linePartsOr.isMessage:
    echo line
    echo "parseCmdLine didn't find a line"
    echo $linePartsOr
    return false

  let lps = linePartsOr.value
  let elps = expectedLineParts
  if lps != elps:
    echo line
    echo "0123456789 123456789 123456789"
    if not expectedItem("prefix", lps.prefix, elps.prefix):
      result = false
    if not expectedItem("command", lps.command, elps.command):
      result = false
    if not expectedItem("codeStart", lps.codeStart, elps.codeStart):
      result = false
    if not expectedItem("codeLen", lps.codeLen, elps.codeLen):
      result = false
    if not expectedItem("commentLen", lps.commentLen, elps.commentLen):
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
    eLinePartsOr: LinePartsOr): bool =
  ## Test that we get an error parsing the command line. Return true
  ## when we get the expected errors.

  let prepostTable = makeDefaultPrepostTable()
  let linePartsOr = parseCmdLine(prepostTable, line, lineNum)

  if linePartsOr.isValue:
    echo line
    echo "We parsed the line when we shouldn't have."
    return false

  if $linePartsOr != $eLinePartsOr:
    echo "expected: " & $eLinePartsOr
    echo "     got: " & $linePartsOr
    return false

  result = true

suite "parseCmdLine.nim":

  test "getCodeLength out of bounds":
    check getCodeLength("", 0, 0) == 0
    check getCodeLength("1", 0, 1) == 1

    check getCodeLength("012345", 0, 99) == 99
    check getCodeLength("012345", 1, 99) == 99
    check getCodeLength("012345", 1, 99) == 99
    check getCodeLength("012345", 11, 99) == 99

    check getCodeLength("012345", 6, 1) == 1
    check getCodeLength("012345", 11, 1) == 1

  test "getCodeLength":
    check getCodeLength("$$nextline", 0, 0) == 0
    check getCodeLength("$$ nextline", 0, 0) == 0
    check getCodeLength("$$ nextline\n", 0, 0) == 0
    check getCodeLength("$$ nextline ", 0, 0) == 0
    check getCodeLength("$$ nextline a", 12, 1) == 1
    check getCodeLength("$$nextline a", 11, 1) == 1
    check getCodeLength("$$ nextline ab", 12, 2) == 2
    check getCodeLength("$$ nextline abc", 12, 3) == 3
    check getCodeLength("$$ nextline abc+", 12, 3) == 3
    check getCodeLength("$$ nextline abc\n", 12, 3) == 3
    check getCodeLength("<!--$ nextline abc-->\n", 15, 3) == 3

  test "getCodeLength comment":
    check test_getCodeLength("#", 0, 0)
    check test_getCodeLength("a#", 0, 1)
    check test_getCodeLength("a", 0, 1)
    check test_getCodeLength("ab", 0, 2)
    check test_getCodeLength("ab", 1, 1)
    check test_getCodeLength("abc", 1, 2)
    check test_getCodeLength("a#c", 0, 1)
    check test_getCodeLength("ab#c", 0, 2)
    check test_getCodeLength("ab#c", 1, 1)
    check test_getCodeLength("ab#cd", 1, 1)
    check test_getCodeLength("$$ nextline a = 5 # comment", 12, 6)

    check test_getCodeLength("abc #", 4, 0)
    check test_getCodeLength("abc x#", 4, 1)
    check test_getCodeLength("abc xy#", 4, 2)

  test "getCodeLength quote":
    check test_getCodeLength("""a="#" # comment""", 0, 6)

  test "getCodeLength slash":
    check test_getCodeLength("""a="\n" # comment""", 0, 7)
    check test_getCodeLength("""a=\n # comment""", 0, 5)
    check test_getCodeLength("""a="\"" # comment""", 0, 7)
    check test_getCodeLength("""a="\"#" # comment""", 0, 8)
    check test_getCodeLength("""a="#\"#" # comment""", 0, 9)
    check test_getCodeLength("""a="#\##" # comment""", 0, 9)

  test "newLineParts":
    var lps = newLineParts()
    check lps.prefix == "<!--$"
    check lps.command == "nextline"
    check lps.codeStart == 0
    check lps.codeLen == 0
    check lps.continuation == false
    check lps.postfix == "-->"
    check lps.ending == "\n"
    check lps.lineNum == 1

  test "newLineParts set":
    var lps = newLineParts(prefix = "asdf", command = "command",
      codeStart = 15, codeLen = 20, continuation = true,
      postfix = "post", ending = "ending", lineNum = 12)
    check lps.prefix == "asdf"
    check lps.command == "command"
    check lps.codeStart == 15
    check lps.codeLen == 20
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
    var elps = newLineParts(codeStart = 15, codeLen = 12)
    check testParseCmdLine(line, expectedLineParts = elps)

  test "parseCmdLine middle 2":
    let line = "<!--$ nextline    middle part  -->\n"
    var elps = newLineParts(codeStart = 15, codeLen = 16)
    check testParseCmdLine(line, expectedLineParts = elps)

  test "parseCmdLine middle 3":
    let line = "#$nextline\n"
    var elps = newLineParts(codeStart = 0, codeLen = 0, prefix="#$", postfix="")
    check testParseCmdLine(line, expectedLineParts = elps)

  test "parseCmdLine middle 4":
    let line = "#$nextline"
    var elps = newLineParts(codeStart = 0, codeLen = 0, prefix =
          "#$", postfix = "", ending = "")
    check testParseCmdLine(line, expectedLineParts = elps)

  test "parseCmdLine middle 5":
    let line = r"#$ nextline +"
    var elps = newLineParts(codeStart = 0, codeLen = 0, prefix =
          "#$", postfix = "", ending = "", continuation = true)
    check testParseCmdLine(line, expectedLineParts = elps)

  test "parseCmdLine middle 6":
    let line = "<!--$nextline-->\n"
    var elps = newLineParts(codeStart = 0, codeLen = 0)
    check testParseCmdLine(line, expectedLineParts = elps)

  test "parseCmdLine middle 7":
    let line = "<!--$nextline -->\n"
    var elps = newLineParts(codeStart = 0, codeLen = 0)
    check testParseCmdLine(line, expectedLineParts = elps)

  test "parseCmdLine continue":
    let line = "<!--$ nextline +-->\n"
    var elps = newLineParts(continuation = true)
    check testParseCmdLine(line, expectedLineParts = elps)

  test "parseCmdLine last line":
    let line = "<!--$ nextline -->"
    var elps = newLineParts(ending = "")
    check testParseCmdLine(line, expectedLineParts = elps)

  test "parseCmdLine block":
    let line = "<!--$ block -->\n"
    var elps = newLineParts(command = "block")
    check testParseCmdLine(line, expectedLineParts = elps)

  test "parseCmdLine endblock":
    let line = "<!--$ endblock -->"
    var elps = newLineParts(command = "endblock", ending = "")
    check testParseCmdLine(line, expectedLineParts = elps)

  test "parseCmdLine comment":
    let line = "<!--$ # this is comment -->"
    var elps = newLineParts(command = "#", codeStart = 8, codeLen = 16, ending = "")
    check testParseCmdLine(line, expectedLineParts = elps)

  test "parseCmdLine prefix":
    let line = "#$ nextline \n"
    var elps = newLineParts(prefix = "#$", postfix = "")
    check testParseCmdLine(line, expectedLineParts = elps)

  test "parseCmdLine multiple":
    let line = "#$ block a = 5; b = 'hi'"
    var elps = newLineParts(prefix = "#$", command = "block",
      codeStart = 9, codeLen = 15, postfix = "", ending = "")
    check testParseCmdLine(line, expectedLineParts = elps)

  test "parseCmdLine endblock":
    let line = "#$ endblock\n"
    var elps = newLineParts(prefix = "#$", command = "endblock",
      codeStart = 0, codeLen = 0, postfix = "", ending = "\n")
    check testParseCmdLine(line, expectedLineParts = elps)

  test "no prefix":
    let line = " nextline -->\n"
    check parseCmdLineError(line, 0, newLinePartsOr(wSuccess))

  test "no command error":
    let line = "<!--$ -->\n"
    # template.html(12): w22: No command found at column 7, treating it as a non-command line.\n"
    check parseCmdLineError(line, 0, newLinePartsOr(wNoCommand, "", 7))

  test "no postfix error":
    let line = "<!--$ nextline \n"
    # template.html(16): w23: The matching closing comment postfix was not found, expected: "-->".
    check parseCmdLineError(line, 0, newLinePartsOr(wNoPostfix, "-->", 0))

  test "ExtraLine default":
    var extraLine: ExtraLine
    check extraLine.kind == elkNoLine
    check extraLine.line == ""

  test "newNormalLine":
    let extraLine = newNormalLine("hello")
    check extraLine.kind == elkNormalLine
    check extraLine.line == "hello"

  test "newExtraLineSpecial":
    var extraLine = newNoLine()
    check extraLine.kind == elkNoLine
    check extraLine.line == ""

    extraLine = newOutOfLines()
    check extraLine.kind == elkOutOfLines
    check extraLine.line == ""
