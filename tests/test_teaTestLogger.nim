import unittest
import teaTestLogger

proc someProc() =
  log("running someProc")
  log("asdf")
  log("leaving someProc")

suite "Test statictea.nim":

  setup:
    openTestLog()

  test "happy path":
    var lines: seq[string]

    let message = "tea tea tea"
    log(message)
    lines = readTestLines()
    check lines.len == 1
    check lines[0] == message

    clearTestLog()
    lines = readTestLines()
    check lines.len == 0

    someProc()

    lines = readTestLines()
    check lines.len == 3

  test "test log":
    var lines: seq[string]
    clearTestLog()
    lines = readTestLines()
    check lines.len == 0

    someProc()

    lines = readTestLines()
    check lines.len == 3
