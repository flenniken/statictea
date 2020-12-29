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

  test "processReplacementBlock":
    let line = "this is a test {s.test}."
    let eResultLines = @["this is a test hello."]
    check testReplaceLine(line, eResultLines = eResultLines)
