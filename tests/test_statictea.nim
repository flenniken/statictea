import unittest
import statictea
import strutils
import env
import version

proc testMain(argv: seq[string],
    eRc: int,
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[],
    eResultLines: seq[string] = @[],
    eHelpLineCount: int = -1
  ): bool =
  var env = openEnvTest("_testMain")

  let rc = main(env, argv)

  let (logLines, errLines, outLines, resultLines, _) = env.readCloseDeleteEnv()

  result = true
  if not compareLogLines(logLines, eLogLines):
    result = false
  if not expectedItems("errLines", errLines, eErrLines):
    result = false
  if eHelpLineCount != -1:
    if outLines.len < eHelpLineCount:
      echo "helpLineCount: expected at least $1 lines, got $2" % [$eHelpLineCount, $outLines.len]
      result = false
  else:
    if not expectedItems("outLines", outLines, eOutLines):
      result = false
  if not expectedItems("resultLines", resultLines, eResultLines):
    result = false

  if not expectedItem("rc", rc, eRc):
    result = false

suite "statictea.nim":

  test "main version":
    let eOutLines = @[staticteaVersion & "\n"]
    let argv = @["-v"]
    check testMain(argv, 0, eOutLines = eOutLines)

  test "main version logging":
    let logLines = """
XXXX-XX-XX XX:XX:XX.XXX; statictea.nim(XX); Starting: argv: @["-v"]
XXXX-XX-XX XX:XX:XX.XXX; statictea.nim(XX); version: X.X.X
XXXX-XX-XX XX:XX:XX.XXX; statictea.nim(XX); Done
"""
    var eLogLines = splitNewlines(logLines)
    let eOutLines = @[staticteaVersion & "\n"]
    let argv = @["-v"]
    check testMain(argv, 0, eOutLines = eOutLines, eLogLines = eLogLines)

  test "main help":
    let argv = @["-h"]
    check testMain(argv, 0, eHelpLineCount = 60)

# todo: test multiple json files
