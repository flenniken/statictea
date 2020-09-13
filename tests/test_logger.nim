import unittest
import logger
import os
import streams
import testUtils

suite "Test logger.nim":

  test "test default log name":
    check staticteaLog == "statictea.log"

  test "test parseDateTime":
    let dtString = "2020-09-12 11:47:14.673"
    let dt = parseDateTime(dtString)
    check formatDateTime(dt) == dtString

  test "test parseLogLine":
    let (dtString, message) = parseLogLine("2020-09-12 11:47:14.673: first message")
    check dtString == "2020-09-12 11:47:14.673"
    check message == "first message"

  test "test parseLogLine error":
    let (dtString, message) = parseLogLine("2020-09-12: first message")
    check dtString == ""
    check message == ""

  test "test basics":
    let filename = "_logger_test.log"
    var logger = openLogger(filename)
    logger.log("first message")
    logger.log("second message")
    logger.log("")
    logger.log("line with newline\nin it")
    logger.close()
    for line in lines(filename):
      let (dtString, message) = parseLogLine(line)
      if dtString == "":
        echo line
        doAssert(false, "invalid line")
    discard tryRemoveFile(filename)

  test "test truncate":
    let filename = "_logger_truncate.log"
    var fh = open(filename, fmWrite)
    fh.writeLine("logger test file")
    fh.close()
    var logger = openLogger(filename, truncateFile=true)
    logger.close()
    let numBytes = getFileSize(filename)
    check numBytes == 0
    discard tryRemoveFile(filename)

  test "test logger open close":
    let filename = "_logger_openclose.log"
    var logger: Logger
    logger = openLogger(filename)
    logger.log("open and close")
    logger.close()
    logger = openLogger(filename)
    logger.log("another log")
    logger.close()
    var count = 0
    for line in lines(filename):
      count += 1
    check count == 2
    discard tryRemoveFile(filename)

  test "test cannot open":
    var warn = newStringStream()
    defer: warn.close()
    var logger = openLogger("", warn=warn)
    let lines = warn.readLines()
    check lines.len == 1
    check lines[0] == "logger(0): w8: Unable to open log file: ''."
    logger.log("something")
    logger.close()

  test "test no warnings normally":
    var warn = newStringStream()
    defer: warn.close()
    let filename = "_logger_nowarning.log"
    var logger: Logger
    logger = openLogger(filename, warn=warn)
    logger.log("open and close")
    logger.close()
    logger = openLogger(filename, warn=warn)
    logger.log("another log")
    logger.close()
    var count = 0
    for line in lines(filename):
      count += 1
    check count == 2
    let lines = warn.readLines()
    check lines.len == 0
    discard tryRemoveFile(filename)
