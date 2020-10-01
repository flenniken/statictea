import unittest
import statictea
import version
import streams

proc readAndClose(stream: Stream): seq[string] =
  ## Read the stream's lines then close it.
  stream.setPosition(0)
  for line in stream.lines():
    result.add line
  stream.close()

suite "Test statictea.nim":

  test "main version":
    var stream = newStringStream()
    let rc = main(@["-v"], stream)
    check rc == 0
    let output = readAndClose(stream)
    check output.len == 1
    check output[0] == $staticteaVersion
