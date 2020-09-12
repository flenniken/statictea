import unittest
import logger
import os
import streams
import testUtils

suite "Test logger.nim":

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

  test "test logger with filename":
    let filename = "test.log"
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

  test "test statictea log name":
    check staticteaLog == "statictea.log"

  test "test statictea logger":
    var logger = openLogger()
    logger.log("first message")
    logger.log("second message")
    logger.log("")
    logger.log("line with newline\nin it")
    logger.close()

    var lines = newSeq[string]()
    for line in lines(staticteaLog):
      # echo line
      lines.add(line)

    check lines.len == 5
    let expectedMessages = @[
      "first message",
      "second message",
      "",
      "line with newline",
      "in it",
    ]
    for ix, line in lines:
      let (dtString, message) = parseLogLine(lines[ix])
      check message == expectedMessages[ix]

    discard tryRemoveFile(staticteaLog)

  test "test statictea open close":
    var logger: Logger
    logger = openLogger()
    logger.log("open and close")
    logger.close()
    logger = openLogger()
    logger.log("another log")
    logger.close()
    var count = 0
    for line in lines(staticteaLog):
      count += 1
    check count == 1
    discard tryRemoveFile(staticteaLog)

  test "test logger open close":
    let filename = "openclose.log"
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
    let filename = ""
    var logger = openLogger(filename, warn)
    let lines = warn.readLines()
    check lines.len == 1
    check lines[0] == "logger(0): w8: Unable to open log file: ''."
    logger.log("something")
    logger.close()

  test "test logger open close no warn":
    var warn = newStringStream()
    defer: warn.close()
    let filename = "openclose.log"
    var logger: Logger
    logger = openLogger(filename, warn)
    logger.log("open and close")
    logger.close()
    logger = openLogger(filename, warn)
    logger.log("another log")
    logger.close()
    var count = 0
    for line in lines(filename):
      count += 1
    check count == 2
    discard tryRemoveFile(filename)
    let lines = warn.readLines()
    check lines.len == 0
