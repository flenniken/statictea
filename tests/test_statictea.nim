import unittest
import statictea
import version
import streams
import strutils
import options
import env

proc readAndClose(stream: Stream): seq[string] =
  ## Read the stream's lines then close it.
  stream.setPosition(0)
  for line in stream.lines():
    result.add line
  stream.close()

suite "Test statictea.nim":

  test "main version":
    let mainFilename = "statictea.nim"
    var env = openEnvTest("_logfile1.txt")

    let rc = main(env, @["-v"])
    check rc == 0

    let (logLines, errLines, outLines) = env.readCloseDelete()

    check outLines.len == 1
    check outLines[0] == $staticteaVersion

    let expectedMessages = [
      "----- starting -----",
      """argv: @["-v"]""",
      "version: 0.1.0",
      "Done",
    ]
    check logLines.len >= 4
    for line in logLines:
      let logLineO = parseLine(line)
      check logLineO.isSome
      let logLine = logLineO.get()
      check logLine.filename == mainFilename
      check logLine.message in expectedMessages

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
