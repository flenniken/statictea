import unittest
import testUtils
import streams
import os

suite "Test testUtils.nim":

  test "theLines stream":
    var stream = newStringStream("testing")
    defer: stream.close()
    let warningLines = stream.theLines()
    check(warningLines.len == 1)
    check(warningLines[0] == "testing")

  test "theLines stream again":
    var stream = newStringStream()
    defer: stream.close()
    stream.writeLine("this is a test")
    stream.writeLine("1 2 3")
    let warningLines = stream.theLines()
    check(warningLines.len == 2)
    check(warningLines[0] == "this is a test")
    check(warningLines[1] == "1 2 3")

  test "theLines for files":
    let filename = "_testUtils.txt"
    var fh = open(filename, fmWrite)
    let line1 = "testme.txt line 1"
    let line2 = "testme.txt line 2"
    fh.writeLine(line1)
    fh.writeLine(line2)
    fh.close()
    var lines = theLines(filename)
    check lines.len == 2
    check lines[0] == line1
    check lines[1] == line2
    discard tryRemoveFile(filename)
