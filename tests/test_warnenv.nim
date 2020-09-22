import unittest
import warnenv
import warnings

proc someProc() =
  warn("filename", 2, wUnknownSwitch, "testing")
  warn("filename", 234, wUnknownSwitch, "tea time!")

suite "Test warnLogger.nim":

  test "happy path":
    openWarnStream()
    warn("filename", 2, wUnknownSwitch, "happy")
    var lines = readWarnLines()
    check lines.len == 1
    check lines[0] == "filename(2): w1: Unknown switch: happy."
    closeWarnStream()

  test "warn from proc":
    openWarnStream()
    someProc()
    var lines = readWarnLines()
    check lines.len == 2
    closeWarnStream()

  test "open close twice":
    openWarnStream()
    openWarnStream()
    closeWarnStream()
    closeWarnStream()

  test "read from stream":
    var lines = readWarnLines()
    check lines.len == 0

    openWarnStream()
    someProc()
    lines = readWarnLines()
    check lines.len == 2
    closeWarnStream()

    lines = readWarnLines()
    check lines.len == 0
