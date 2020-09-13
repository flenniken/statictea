import unittest
import tea_logger
import streams
import testUtils
import args
import os

suite "Test tea_logger.nim":

  test "openStaticTeaLogger":
    log("logging before it's open")

    var logLines: seq[string]
    var warningLines: seq[string]

    var warningStream = newStringStream()
    defer: warningStream.close()

    # Open the statictea.log file truncated.
    var args: Args
    args.log = true
    openStaticTeaLogger(args, warningStream)

    check fileExists(staticteaLog)
    logLines = theLines(staticteaLog)
    check logLines.len == 0
    warningLines = warningStream.theLines()
    check warningLines.len == 0

    let firstLine = "this should be the first line"
    log(firstLine)

    check fileExists(staticteaLog)

    for line in lines(staticteaLog):
      echo line

    # logLines = theLines(staticteaLog)
    # check logLines.len == 1
    # check logLines[0] == firstLine
    # warningLines = warningStream.theLines()
    # check warningLines.len == 0
