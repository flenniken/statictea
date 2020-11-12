
import unittest
import readlines
import strutils
import streams
import options

proc readContentTest(content: string, expected: seq[string],
    maxLineLen: int = defaultMaxLineLen,
    bufferSize: int = defaultBufferSize, showExpected: bool = false) =
  ## Call readline and check the result.

  var inStream = newStringStream(content)
  var outStream = newStringStream()

  var lineBufferO = newLineBuffer(inStream, maxLineLen, bufferSize)
  check lineBufferO.isSome

  var lines: seq[string]
  var asciiValues: seq[bool]
  while true:
    var line = lineBufferO.get().readline()
    if line == "":
      break
    lines.add(line)
    outStream.write(line)

  if showExpected:
    echo "    let expected = @["
    for ix in 0..<lines.len:
      var line = lines[ix]
      var fixedLine = line.multiReplace(("\r", r"\r"), ("\n", r"\n"))
      echo """      "$1"""" % [fixedLine]
    echo "    ]"
  inStream.close()

  outStream.setPosition(0)
  var output = outStream.readAll()
  outStream.close()
  check output == content

  check lines.len == expected.len
  for ix in 0..<lines.len:
    check lines[ix] == expected[ix]


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
    let expected = @["hello\n", "world"]
    readContentTest("hello\nworld", expected)

  test "readwrite crlf":
    # test crlf
    let expected = @["hello\r\n", "world"]
    readContentTest("hello\r\nworld", expected)

  test "readwrite line longer than max":
    # line longer than max
    let expected = @["hello wo", "rld\n"]
    readContentTest("hello world\n", expected,
                    maxLineLen=8, bufferSize = 24)

  test "readwrite non-ascii lines":
    # non-ascii lines
    let expected = @["\u2020asdf\n", "\n"]
    readContentTest("\u2020asdf\n\n", expected, maxLineLen=8, bufferSize = 24)

  test "readwrite empty file":
    # empty file
    let expected: seq[string] = @[]
    readContentTest("", expected, maxLineLen=8, bufferSize = 24)

  test "readwrite one line":
    # one line
    let expected = @["one"]
    readContentTest("one", expected, maxLineLen=8, bufferSize = 24)

  test "readwrite one character":
    # one character
    let expected = @["a"]
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
      "1234567\n",
      "12345678",
      "\n",
      "testing\n",
      "abc\n",
      "\n",
      "mixed\n",
      "\n",
      "hi\n",
      "another ",
      "long lin",
      "e\n",
      "asdf\n",
      "testing\n",
      "1 2 3\n",
      "4 5 6\n",
    ]
    readContentTest(content, expected,
      maxLineLen=8, bufferSize = 24, showExpected = false)

  test "getLineNum":
    let content = """
1234567
12345678long
testing
"""
    var inStream = newStringStream(content)
    var lineBufferO = newLineBuffer(inStream, 8, 24)
    check lineBufferO.isSome

    var lb = lineBufferO.get()
    check lb.getLineNum() == 0

    var line = lb.readline()
    check line == "1234567\n"
    check lb.getLineNum() == 1

    line = lb.readline()
    check line == "12345678"
    check lb.getLineNum() == 1

    line = lb.readline()
    check line == "long\n"
    check lb.getLineNum() == 2

    line = lb.readline()
    check line == "testing\n"
    check lb.getLineNum() == 3

  test "readlines":
    let content = """
line one
line two asdfadsf
and three
"""
    var inStream = newStringStream(content)
    var lineBufferO = newLineBuffer(inStream)
    check lineBufferO.isSome
    var lb = lineBufferO.get()
    let theLines = readLines(lb)
    let theLinesString = theLines.join("")
    if theLinesString != content:
      echo "---lines:"
      echo theLinesString
      echo "---expected lines:"
      echo content
      echo "---"
      check false


  test "readlines stream":
    let content = """
line one
line two asdfadsf
and three
"""
    var inStream = newStringStream(content)
    let theLines = readlines(inStream)
    let theLinesString = theLines.join("")
    if theLinesString != content:
      echo "---lines:"
      echo theLinesString
      echo "---expected lines:"
      echo content
      echo "---"
      check false
