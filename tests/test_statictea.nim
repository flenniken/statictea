import unittest
import statictea
import streams
import strutils
import env

proc readAndClose(stream: Stream): seq[string] =
  ## Read the stream's lines then close it.
  stream.setPosition(0)
  for line in stream.lines():
    result.add line
  stream.close()

proc testMain(argv: seq[string],
    eRc: int,
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[],
    eResultLines: seq[string] = @[],
  ): bool =
  var env = openEnvTest("_logfile1.txt")

  let rc = main(env, argv)

  let (logLines, errLines, outLines, templateLines, resultLines) = env.readCloseDelete2()

  result = true
  if not compareLogLines(logLines, eLogLines):
    result = false
  if not expectedItems("errLines", errLines, eErrLines):
    result = false
  # todo: compare that the number of help lines match.
  # if not expectedItems("outLines", outLines, eOutLines):
  #   result = false
  # if not expectedItems("templateLines", templateLines, eTemplateLines):
  #   result = false
  if not expectedItems("resultLines", resultLines, eResultLines):
    result = false

  if not expectedItem("rc", rc, eRc):
    result = false

suite "Test statictea.nim":

  test "main version":

    let logLines = """
XXXX-XX-XX XX:XX:XX.XXX; statictea.nim(XX); ----- starting -----
XXXX-XX-XX XX:XX:XX.XXX; statictea.nim(XX); argv: @["-v"]
XXXX-XX-XX XX:XX:XX.XXX; statictea.nim(XX); version: X.X.X
XXXX-XX-XX XX:XX:XX.XXX; statictea.nim(XX); Done
"""
    var eLogLines = splitNewlines(logLines)
    let eOutLines = @["0.1.0"]
    let argv = @["-v"]
    check testMain(argv, 0, eOutLines = eOutLines, eLogLines = eLogLines)

  test "main help":
    let logLines = """
XXXX-XX-XX XX:XX:XX.XXX; statictea.nim(XX); ----- starting -----
XXXX-XX-XX XX:XX:XX.XXX; statictea.nim(XX); argv: @["-h"]
XXXX-XX-XX XX:XX:XX.XXX; statictea.nim(XX); version: X.X.X
XXXX-XX-XX XX:XX:XX.XXX; statictea.nim(XX); Done
"""
    var eLogLines = splitNewlines(logLines)
    let eOutLines = @["hi"]

    let argv = @["-h"]
    check testMain(argv, 0, eOutLines = eOutLines, eLogLines = eLogLines)
