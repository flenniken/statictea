import unittest
import logenv
import strutils
import random

randomize()

# todo: test logenv with real file.

proc endsWith(line: string, str: string): bool =
  let strlen = str.len
  if line.len >= strlen:
    if line[^strlen..^1] == str:
      return true
  return false


suite "Test logenv.nim":

  test "endsWith":
    check endsWith("123", "") == true
    check endsWith("123", "3") == true
    check endsWith("123", "23") == true
    check endsWith("123", "123") == true
    check endsWith("", "") == true

  test "endsWith false":
    check endsWith("123", "2") == false
    check endsWith("123", "0123") == false
    check endsWith("", "3") == false

  test "logenv":
    openLogFile("filename")

    let testLine1 = "test line 1: $1" % $rand(100)
    log(testLine1)

    let testLine2 = "test line 2: $1" % $rand(100)
    log(testLine2)

    var logLines = readTestLines()
    for line in logLines:
      echo line

    check logLines.len == 2
    check logLines[^2].endsWith(testLine1)
    check logLines[^1].endsWith(testLine2)

    closeLogFile()

