import unittest
import warnLogger

proc someProc() =
  warn("running someProc")
  warn("testing warning logger")
  warn("leaving someProc")

suite "Test warnLogger.nim":

  test "happy path":
    openWarnLog(false)
    let message = "tea tea tea"
    warn(message)
    var lines = readWarnLines()
    check lines.len == 1
    check lines[0] == message
    closeWarnLog()

  test "warn from proc":
    openWarnLog(false)
    someProc()
    var lines = readWarnLines()
    check lines.len == 3
    closeWarnLog()

  test "open close twice":
    openWarnLog(false)
    openWarnLog(false)
    closeWarnLog()
    closeWarnLog()

  test "read from stream":
    var lines = readWarnLines()
    check lines.len == 0

    openWarnLog(false)
    someProc()
    lines = readWarnLines()
    check lines.len == 3
    closeWarnLog()

    lines = readWarnLines()
    check lines.len == 0

  test "stderr stream":
    openWarnLog(true)
    someProc()
    var lines = readWarnLines()
    check lines.len == 0
    closeWarnLog()
