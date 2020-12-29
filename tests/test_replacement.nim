import unittest
import env
import replacement
import matches
import variables
import streams

proc testReplaceLine(line: string,
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[],
    eResultLines: seq[string] = @[],
  ): bool =

  var env = openEnvTest("_testReplaceLine.log", "template.html")

  var stream = newStringStream()
  let compiledMatchers = getCompiledMatchers()
  let variables = getTestVariables()
  let lineNum = 1
  replaceLine(env, compiledMatchers, variables, lineNum, line, stream)

  result = env.readCloseDeleteCompare(eLogLines, eErrLines, eOutLines)

  let resultLines = stream.readAndClose()
  if not expectedItems("result lines", resultLines, eResultLines):
    echo "    : 0123456789 123456789 123456789 123456789 123456789 123456789 123456789"
    echo "Line: " & line
    result = false


suite "processReplacementBlock":

  # s.test = "hello"
  # h.test = "there"
  # five = 5
  # t.five = 5
  # g.aboutfive = 5.11

  test "replaceLine empty":
    let line = ""
    check testReplaceLine(line)

  test "replaceLine no vars":
    let line = "this is a test."
    let eResultLines = @["this is a test."]
    check testReplaceLine(line, eResultLines = eResultLines)

  test "replaceLine one var":
    let line = "this is a test {s.test}."
    let eResultLines = @["this is a test hello."]
    check testReplaceLine(line, eResultLines = eResultLines)

  test "replaceLine two vars":
    let line = "this {s.test} is a test {s.test}."
    let eResultLines = @["this hello is a test hello."]
    check testReplaceLine(line, eResultLines = eResultLines)

  test "replaceLine hello":
    let line = "{s.test}"
    let eResultLines = @["hello"]
    check testReplaceLine(line, eResultLines = eResultLines)

  test "replaceLine { no var":
    let line = "{4s.test}"
    let eResultLines = @["{4s.test}"]
    check testReplaceLine(line, eResultLines = eResultLines)

  test "replaceLine no }":
    let line = "{s.test"
    let eResultLines = @["{s.test"]
    check testReplaceLine(line, eResultLines = eResultLines)

  test "replaceLine missing var":
    let line = "{s.missing}"
    let eResultLines = @["{s.missing}"]
    let eErrLines = @["template.html(1): w58: The replacement variable doesn't exist: s.missing."]
    check testReplaceLine(line, eErrLines = eErrLines, eResultLines = eResultLines)

  test "replaceLine multiple vars":
    let line = "{five}{s.missing}{h.test}"
    let eResultLines = @["5{s.missing}there"]
    let eErrLines = @["template.html(1): w58: The replacement variable doesn't exist: s.missing."]
    check testReplaceLine(line, eErrLines = eErrLines, eResultLines = eResultLines)

  test "replaceLine var space before":
    let line = "{ s.test}"
    let eResultLines = @["hello"]
    check testReplaceLine(line, eResultLines = eResultLines)

  test "replaceLine var space after":
    let line = "{s.test }"
    let eResultLines = @["hello"]
    check testReplaceLine(line, eResultLines = eResultLines)

  test "replaceLine var lots of space":
    let line = "{        s.test       }"
    let eResultLines = @["hello"]
    check testReplaceLine(line, eResultLines = eResultLines)
