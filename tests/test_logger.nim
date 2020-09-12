import unittest
import logger
import os

suite "Test logger.nim":

  test "test parseDateTime":
    let dtString = "2020-09-12 11:47:14.673"
    let dt = parseDateTime(dtString)
    check formatDateTime(dt) == dtString

  test "test parseLogLine":
    let (dtString, message) = parseLogLine("2020-09-12 11:47:14.673: first message")
    check dtString == "2020-09-12 11:47:14.673"
    check message == "first message"

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
