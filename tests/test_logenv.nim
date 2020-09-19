import unittest
import logenv
import streams
import testUtils
import os
import strutils
import random

randomize()


proc endswith(line: string, str: string): bool =
  let strlen = str.len
  if line.len >= strlen:
    if line[^strlen..^1] == str:
      return true
  return false


suite "Test logenv.nim":

  test "endswith":
    check endswith("123", "") == true
    check endswith("123", "3") == true
    check endswith("123", "23") == true
    check endswith("123", "123") == true
    check endswith("", "") == true

  test "endswith false":
    check endswith("123", "2") == false
    check endswith("123", "0123") == false
    check endswith("", "3") == false

  test "logenv":
    # test logging before during and after opening.

    log("logging before it's open")

    var logLines: seq[string]
    var warningLines: seq[string]

    var warningStream = newStringStream()
    defer: warningStream.close()

    let filename = "_logenvtest.txt"
    openStaticTeaLogger(filename, warningStream)
    warningLines = warningStream.theLines()
    check warningLines.len == 0

    check fileExists(filename)

    let testLine1 = "test line 1: $1" % $rand(100)
    log(testLine1)

    let testLine2 = "test line 2: $1" % $rand(100)
    log(testLine2)

    closeStaticTeaLogger()

    logLines = theLines(filename)
    check logLines.len >= 2
    check logLines[^2].endswith(testLine1)
    check logLines[^1].endswith(testLine2)

    # log after closing
    log("log after closing")
    check logLines == theLines(filename)
    discard tryRemoveFile(filename)

  test "open log twice":
    # Try to open twice. Should log a line.

    var logLines: seq[string]
    var warningLines: seq[string]
    var warningStream = newStringStream()
    defer: warningStream.close()

    let filename = "_opentwice.txt"
    openStaticTeaLogger(filename, warningStream)
    check warningStream.theLines().len == 0

    # open a second time
    openStaticTeaLogger(filename, warningStream)
    check warningStream.theLines().len == 0

    closeStaticTeaLogger()

    # Close a second time.
    closeStaticTeaLogger()

    discard tryRemoveFile(filename)

  test "cannot open":
    var warningStream = newStringStream()
    defer: warningStream.close()
    let filename = ""
    openStaticTeaLogger(filename, warningStream)
    let lines = warningStream.theLines()
    check lines.len == 1
    check lines[0] == "logger(0): w8: Unable to open log file: ''."
