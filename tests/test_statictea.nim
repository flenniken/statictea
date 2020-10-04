import unittest
import statictea
import version
import streams
import strutils
import logenv
import options

proc readAndClose(stream: Stream): seq[string] =
  ## Read the stream's lines then close it.
  stream.setPosition(0)
  for line in stream.lines():
    result.add line
  stream.close()

suite "Test statictea.nim":

  test "main version":
    let filename = "_logfile1.txt"
    let mainFilename = "statictea.nim"
    var stdoutStream = newStringStream()
    var env = openLogFile(filename)
    check env.isOpen
    check env.filename == filename

    let rc = main(env, @["-v"], 2000, stdoutStream)
    check rc == 0
    check env.isOpen
    check env.filename == filename

    let output = readAndClose(stdoutStream)
    check output.len == 1
    check output[0] == $staticteaVersion

    let expectedMessages = [
      "----- starting -----",
      """argv: @["-v"]""",
      "version: 0.1.0",
      "Done",
    ]
    var logLines = env.closeReadDelete(20)
    check logLines.len >= 4
    for line in logLines:
      let logLineO = parseLine(line)
      check logLineO.isSome
      let logLine = logLineO.get()
      check logLine.filename == mainFilename
      check logLine.message in expectedMessages

  test "main help":
    var stdoutStream = newStringStream()
    var env = openLogFile("_logfile2.txt")

    let rc = main(env, @["-h"], 2000, stdoutStream)
    check rc == 0

    let output = readAndClose(stdoutStream)
    check output.len > 10
    let expected = """
NAME
     statictea - combines a template with data to produce a result

SYNOPSIS
     statictea [-h] [-n] [-v] [-u] [-s=server.json] [-j=shared.json] [-t=template.html]
       [-p="pre post"] [-r=result.html]"""

    let firstFew = output[0..5].join("\n")
    if firstFew != expected:
      echo "----got----"
      echo output[0..5].join("\n")
      echo "----expected----"
      echo expected
      echo "----"
      fail()

    var logLines = env.closeReadDelete(20)
    # for line in logLines:
    #   echo line
