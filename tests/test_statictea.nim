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

  var eTemplateLines: seq[string]
  result = env.readCloseDeleteCompare(eLogLines, eErrLines, eOutLines, eTemplateLines, eResultLines)
  if not expectedItem("rc", rc, eRc):
    result = false

suite "Test statictea.nim":

  test "main version":

    let logLines = """
2021-01-16 13:51:09.767; statictea.nim(33); ----- starting -----
2021-01-16 13:51:09.767; statictea.nim(34); argv: @["-v"]
2021-01-16 13:51:09.767; statictea.nim(35); version: 0.1.0
2021-01-16 13:51:09.767; statictea.nim(56); Done
"""
    var eLogLines = splitNewlines(logLines)
    let eOutLines = @["0.1.0"]
    let argv = @["-v"]
    check testMain(argv, 0, eOutLines = eOutLines, eLogLines = eLogLines)


  test "main help":
    let mainFilename = "statictea.nim"
    var env = openEnvTest("_logfile2.txt")

    let rc = main(env, @["-h"])
    check rc == 0

    let (logLines, errLines, outLines) = env.readCloseDelete()

    check outLines.len > 10
    let expected = """
NAME

     statictea - combines a template with data to produce a result

SYNOPSIS

     statictea [-h] [-n] [-v] [-u] [-s=server.json] [-j=shared.json]
         [-t=template.html] [-p="pre post"] [-r=result.html]"""

    let count = 7
    let firstFew = outLines[0..count].join("\n")
    if firstFew != expected:
      echo "----got----"
      echo outLines[0..count].join("\n")
      echo "----expected----"
      echo expected
      echo "----"
      fail()
