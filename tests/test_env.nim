
import unittest
import env
import typetraits
import options
import warnings
import random
import options
import strutils

let testMsg1 = "testProc called"
let testMsg2 = "testProc done"

randomize()

proc endsWith(line: string, str: string): bool =
  ## Return true when the given string ends the line.
  let strlen = str.len
  if line.len >= strlen:
    if line[^strlen..^1] == str:
      return true
  return false

proc testProc(env: var Env) =
  env.log(testMsg1)
  env.log(testMsg2)

suite "env.nim":

  test "open close":
    var env = openEnv()
    check env.logFilename == "statictea.log"
    env.close()

  test "log":
    let outMsg = "standard out line"
    var env = openEnvTest("_test.log")
    testProc(env)
    env.writeOut(outMsg)
    check env.warningWritten == 0
    env.warn(0, wNotEnoughMemoryForLB)
    check env.warningWritten == 1
    env.warn(0, wNotEnoughMemoryForLB)
    check env.warningWritten == 2
    var (logLines, errLines, outLines) = env.readCloseDelete()
    # echoLines(logLines, errLines, outLines)
    check logLines.len == 2
    var logLine = parseLine(logLines[0]).get()
    check logLine.message == testMsg1
    logLine = parseLine(logLines[1]).get()
    check logLine.message == testMsg2

    let errMsg = getWarning("initializing", 0, wNotEnoughMemoryForLB)
    check errLines.len == 2
    check errLines[0] == errMsg
    check errLines[1] == errMsg

    check outLines.len == 1
    check outLines[0] == outMsg

    # echoLines(logLines, errLines, outLines)


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

  test "log line":
    var env = openEnvTest("_logline.log")
    check env.logFile != nil
    check env.logFilename == "_logline.log"

    let testLine1 = "test line 1: $1" % $rand(100)
    env.log(testLine1)
    let testLine2 = "test line 2: $1" % $rand(100)
    env.log(testLine2)

    var (logLines, errLines, outLines) = env.readCloseDelete()
    # echoLines(logLines, errLines, outLines)
    check logLines.len == 2
    check logLines[0].endsWith(testLine1)
    check logLines[1].endsWith(testLine2)

    check env.logFile == nil

  test "cannot open log":
    var env = openEnvTest("")
    check env.logFile == nil

    let testLine1 = "test line 1: $1" % $rand(100)
    env.log(testLine1)
    let testLine2 = "test line 2: $1" % $rand(100)
    env.log(testLine2)

    var (logLines, errLines, outLines) = env.readCloseDelete()
    # echoLines(logLines, errLines, outLines)
    check logLines.len == 0
    check errLines.len == 1
    check errLines[0] == "initializing(0): w8: Unable to open log file: ''."
    check outLines.len == 0

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
