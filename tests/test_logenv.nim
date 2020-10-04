import unittest
import logenv
import strutils
import random
import options

randomize()

proc endsWith(line: string, str: string): bool =
  ## Return true when the given string ends the line.
  let strlen = str.len
  if line.len >= strlen:
    if line[^strlen..^1] == str:
      return true
  return false

suite "logenv.nim":

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
    var env = openLogFile("_logenv.log")
    check env.isOpen
    check env.filename == "_logenv.log"

    let testLine1 = "test line 1: $1" % $rand(100)
    env.log(testLine1)
    let testLine2 = "test line 2: $1" % $rand(100)
    env.log(testLine2)

    var logLines = env.closeReadDelete(20)
    check env.isClosed
    check env.filename == ""

    # for line in logLines:
    #   echo line
    check logLines.len == 2
    check logLines[^2].endsWith(testLine1)
    check logLines[^1].endsWith(testLine2)

  test "logenv cannot open":
    var env = openLogFile("")
    check env.isClosed
    check env.filename == ""

    let testLine1 = "test line 1: $1" % $rand(100)
    env.log(testLine1)
    let testLine2 = "test line 2: $1" % $rand(100)
    env.log(testLine2)

    var logLines = env.closeReadDelete(20)
    check logLines.len == 0

  test "logenv file line":
    # todo: log from another procedure.
    discard

  test "parseTimeStamp":
    let dtOption = parseTimeStamp("2020-10-01 08:21:28.618")
    check dtOption.isSome
    let line = formatLine("filename", 44, "message", dtOption.get())
    let expected = "2020-10-01 08:21:28.618; filename(44); message"
    check line == expected

  test "parse time error":
    let dtOption = parseTimeStamp("not time stamp")
    check not dtOption.isSome

  test "parseFileLine":
    let filenameLineO = parseFileLine("statictea.nim(33)")
    check filenameLineO.isSome
    let fl = filenameLineO.get()
    check fl.filename == "statictea.nim"
    check fl.lineNum == 33

  test "parseLine":
    let logLineO = parseLine(
      "2020-10-01 08:21:28.618; statictea.nim(65); version: 0.1.0")
    check logLineO.isSome
    let logLine = logLineO.get()
    let dtString = formatDateTime(logLine.dt)
    check dtString == "2020-10-01 08:21:28.618"
    check logLine.filename == "statictea.nim"
    check logLine.lineNum == 65
    check logLine.message == "version: 0.1.0"
