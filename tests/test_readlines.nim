
import unittest
import readlines
# import testUtils
import streams
# import os

proc readContentTest(content: string, expectedLines: seq[string],
    expectedAscii: seq[bool], maxLineLen: int = maxLineLen,
    bufferSize: int = bufferSize) =
  ## Call readline and check the result.

  var inStream = newStringStream(content)
  var outStream = newStringStream()

  var lines: seq[string]
  var asciiValues: seq[bool]
  for line, ascii in readline(inStream, maxLineLen, bufferSize):
    lines.add(line)
    asciiValues.add(ascii)
    outStream.write(line)

  inStream.close()

  outStream.setPosition(0)
  var output = outStream.readAll()
  outStream.close()
  check output == content
  check lines.len == expectedLines.len
  for ix in 0..<lines.len:
    check lines[ix] == expectedLines[ix]
  check asciiValues.len == expectedAscii.len
  for ix in 0..<asciiValues.len:
    check asciiValues[ix] == expectedAscii[ix]


suite "readlines.nim":

  test "setLen":
    var buffer: string
    buffer.setLen(24)
    check len(buffer) == 24

  # test "stringofcap":
  #   var line = newStringOfCap(32)
  #   check line.len == 0
  #   echo $line.getCap

  test "readwrite":
    let expectedLines = @["hello\n", "world"]
    let expectedAscii = @[true, true]
    readContentTest("hello\nworld", expectedLines, expectedAscii)
