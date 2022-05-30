import std/unittest
import std/strutils
import statictea
import env
import version
import readlines

proc testMain(argv: seq[string],
    eRc: int,
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[],
    eResultLines: seq[string] = @[],
    eHelpLineCount: int = -1,
    echoLogLines = false
  ): bool =
  var env = openEnvTest("_testMain")

  main(env, argv)

  let rc = if env.warningsWritten > 0: 1 else: 0

  let (logLines, errLines, outLines, resultLines, _) = env.readCloseDeleteEnv()

  if echoLogLines:
    for line in logLines:
      stdout.write(line)

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
XXXX-XX-XX XX:XX:XX.XXX; statictea.nim(XX); Version: X.X.X
"""
    var eLogLines = splitNewLines(logLines)
    let eOutLines = @[staticteaVersion & "\n"]
    let argv = @["-v"]
    check testMain(argv, 0, eOutLines = eOutLines, eLogLines =
        eLogLines, echoLogLines = false)

  test "main help":
    let argv = @["-h"]
    check testMain(argv, 0, eHelpLineCount = 60)
