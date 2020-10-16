
import unittest
import readlines
import strutils
import streams
# import os

proc readContentTest(content: string, expected: seq[(string, bool)],
    maxLineLen: int = maxLineLen,
    bufferSize: int = bufferSize, showExpected: bool = false) =
  ## Call readline and check the result.

  var inStream = newStringStream(content)
  var outStream = newStringStream()

  var lines: seq[string]
  var asciiValues: seq[bool]
  for line, ascii in readline(inStream, maxLineLen, bufferSize):
    lines.add(line)
    asciiValues.add(ascii)
    outStream.write(line)

  if showExpected:
    echo "    let expected = @["
    for ix in 0..<lines.len:
      var line = lines[ix]
      var ascii = asciiValues[ix]
      var fixedLine = line.multiReplace(("\r", r"\r"), ("\n", r"\n"))
      echo """      ("$1", $2),""" % [fixedLine, $ascii]
    echo "    ]"
  inStream.close()

  outStream.setPosition(0)
  var output = outStream.readAll()
  outStream.close()
  check output == content

  check lines.len == expected.len
  for ix in 0..<lines.len:
    check lines[ix] == expected[ix][0]
  check asciiValues.len == expected.len
  for ix in 0..<asciiValues.len:
    check asciiValues[ix] == expected[ix][1]


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
    let expected = @[("hello\n", true), ("world", true)]
    readContentTest("hello\nworld", expected)

  test "readwrite crlf":
    # test crlf
    let expected = @[("hello\r\n", true), ("world", true)]
    readContentTest("hello\r\nworld", expected)

  test "readwrite line longer than max":
    # line longer than max
    let expected = @[("hello wo", true), ("rld\n", true)]
    readContentTest("hello world\n", expected,
                    maxLineLen=8, bufferSize = 24)

  test "readwrite non-ascii lines":
    # non-ascii lines
    let expected = @[("\u2020asdf\n", false), ("\n", true)]
    readContentTest("\u2020asdf\n\n", expected, maxLineLen=8, bufferSize = 24)

  test "readwrite empty file":
    # empty file
    let expected: seq[(string, bool)] = @[]
    readContentTest("", expected, maxLineLen=8, bufferSize = 24)

  test "readwrite one line":
    # one line
    let expected = @[("one", true)]
    readContentTest("one", expected, maxLineLen=8, bufferSize = 24)

  test "readwrite one character":
    # one character
    let expected = @[("a", true)]
    readContentTest("a", expected, maxLineLen=8, bufferSize = 24)

  test "readwrite two buffers":
    let content = """
1234567
12345678
testing
abc

mixed

hi
another long line
asdf
testing
1 2 3
4 5 6
"""
    let expected = @[
      ("1234567\n", true),
      ("12345678", true),
      ("\n", true),
      ("testing\n", true),
      ("abc\n", true),
      ("\n", true),
      ("mixed\n", true),
      ("\n", true),
      ("hi\n", true),
      ("another ", true),
      ("long lin", true),
      ("e\n", true),
      ("asdf\n", true),
      ("testing\n", true),
      ("1 2 3\n", true),
      ("4 5 6\n", true),
    ]
    readContentTest(content, expected,
      maxLineLen=8, bufferSize = 24, showExpected = false)
