import unittest
import warnLogger

proc someProc() =
  warn("running someProc")
  warn("asdf")
  warn("leaving someProc")

suite "Test warnLogger.nim":

  setup:
    openWarnLog(false)

  test "happy path":
    var lines: seq[string]
    let message = "tea tea tea"
    warn(message)

    lines = readWarnLines()
    check lines.len == 1
    check lines[0] == message

    clearWarnLog()
    lines = readWarnLines()
    check lines.len == 0

    someProc()

    lines = readWarnLines()
    check lines.len == 3

  test "test log":
    var lines: seq[string]
    clearWarnLog()
    lines = readWarnLines()
    check lines.len == 0

    someProc()

    lines = readWarnLines()
    check lines.len == 3
