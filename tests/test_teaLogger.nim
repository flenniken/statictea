import unittest
import teaLogger
import streams
import testUtils
import args
import os
import strutils

suite "Test tea_logger.nim":

  test "staticteaLog":
    check staticteaLog == "statictea.log"

  test "openStaticTeaLogger":
    log("logging before it's open")

    var logLines: seq[string]
    var warningLines: seq[string]
    var args: Args

    var warningStream = newStringStream()
    defer: warningStream.close()

    # Open the statictea.log file truncated.
    args.log = true
    openStaticTeaLogger(args, warningStream)
    warningLines = warningStream.theLines()
    check warningLines.len == 0

    check fileExists(staticteaLog)

    let firstLine = "this should be the first line"
    log(firstLine)

    let secondLine = "second line"
    log(secondLine)

    closeStaticTeaLogger()

    logLines = theLines(staticteaLog)
    check logLines.len == 2
    check firstLine in logLines[0]
    check secondLine in logLines[1]

    # Open the statictea.log file without deleting it.
    args.log = true
    args.logFilename = staticteaLog
    openStaticTeaLogger(args, warningStream)
    warningLines = warningStream.theLines()
    check warningLines.len == 0

    # Try to open twice. Should log a line.
    openStaticTeaLogger(args, warningStream)
    warningLines = warningStream.theLines()
    check warningLines.len == 0

    let lineAgain = "logging after opening without truncate"
    log(lineAgain)

    closeStaticTeaLogger()

    logLines = theLines(staticteaLog)
    check logLines.len == 4
    check firstLine in logLines[0]
    check secondLine in logLines[1]
    # echo logLines[2]
    let expected = "Calling open for statictea log when it's already open."
    check expected in logLines[2]
    check lineAgain in logLines[3]

    # Close again should do nothing.
    closeStaticTeaLogger()
