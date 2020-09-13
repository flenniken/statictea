import unittest
import loggers
import os
import re
import options
import times


# Regex to match the log time format.
# 2020-09-12 11:45:24.369: first message
let logLineRegex = re"^(\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d.\d\d\d): (.*)$"

proc parseLogLine*(line: string): (string, string) =
  ## Parse a log line and return the datetime string and message
  ## string.

  var matches: array[2, string]
  if match(line, logLineRegex, matches):
    let dtString = matches[0]
    let message = matches[1]
    result = (dtString, message)


proc parseDateTime*(dtString: string): DateTime =
  result = parse(dtString, dtFormat)


func formatDateTime*(dt: DateTime): string =
  result = dt.format(dtFormat)


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

  test "test happy path":
    let filename = "_logger_test.log"
    var option = openLogger(filename)
    check option.isSome == true
    var logger = option.get()
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
    var option = openLogger(filename, truncateFile=true)
    check option.isSome == true
    var logger = option.get()
    logger.close()
    let numBytes = getFileSize(filename)
    check numBytes == 0
    discard tryRemoveFile(filename)

  test "test logger open close":
    let filename = "_logger_openclose.log"
    var logger: Logger
    var option: Option[Logger]

    option = openLogger(filename)
    check option.isSome == true
    logger = option.get()
    logger.log("open and close")
    logger.close()

    option = openLogger(filename)
    check option.isSome == true
    logger = option.get()
    logger.log("another log")
    logger.close()

    # Check that a closed logger doesn't log or crash.
    logger.log("closed logger")
    logger.close()

    var count = 0
    for line in lines(filename):
      count += 1
    check count == 2
    discard tryRemoveFile(filename)

  test "test cannot open":
    var option = openLogger("")
    check option.isSome == false

  test "test un-opened logger":
    var logger = Logger()
    logger.log("message")
    logger.close()
