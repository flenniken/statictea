import unittest
import statictea
import version
import streams
import strutils
import logenv

proc readAndClose(stream: Stream): seq[string] =
  ## Read the stream's lines then close it.
  stream.setPosition(0)
  for line in stream.lines():
    result.add line
  stream.close()

suite "Test statictea.nim":

  test "main version":
    var stdoutStream = newStringStream()

    let rc = main(@["-v"], "_logfile1.txt", 2000, stdoutStream)
    check rc == 0

    let output = readAndClose(stdoutStream)
    check output.len == 1
    check output[0] == $staticteaVersion

    var logLines = logReadDelete(20)
    for line in logLines:
      echo line


  test "main help":
    var stdoutStream = newStringStream()
    let rc = main(@["-h"], "_logfile1.txt", 2000, stdoutStream)
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
