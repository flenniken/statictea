import unittest
import env
import typetraits
import options
import options

proc testProc(env: var Env) =
  env.log("testProc called")
  env.log("testProc done")

proc endsWith(line: string, str: string): bool =
  ## Return true when the given string ends the line.
  let strlen = str.len
  if line.len >= strlen:
    if line[^strlen..^1] == str:
      return true
  return false

suite "env.nim":

  test "open close":
    var env = openEnv()
    check env.logFilename == "statictea.log"
    env.close()

  test "log":
    var env = openEnvTest("_test.log")

    testProc(env)

    let logLines = """
2021-01-16 13:51:09.767; test_env.nim(8); testProc called
2021-01-16 13:51:09.767; test_env.nim(9); testProc done
"""
    var eLogLines = splitNewlines(logLines)
    check env.readCloseDeleteCompare(eLogLines = eLogLines)

  test "endsWith":
    check endsWith("123", "") == true
    check endsWith("123", "3") == true
    check endsWith("123", "23") == true
    check endsWith("123", "123") == true
    check endsWith("", "") == true

  test "endsWith false":
    check endsWith("123", "2") == false
    check endsWith("123", "0123") == false
    check endsWith("", "3") == false

  test "cannot open log":
    var env = openEnvTest("")
    check env.logFile == nil

    env.log("test line no log")
    env.log("test line no log2")

    let eErrLines = @[
      "template.html(0): w8: Unable to open log file: ''."
    ]
    let logLines = """
2021-01-16 13:51:09.767; test_env.nim(61); test line 1
2021-01-16 13:51:09.767; test_env.nim(61); test line 1
"""
    var eLogLines = splitNewlines(logLines)
    check env.readCloseDeleteCompare(eErrLines = eErrLines)

  test "parseTimeStamp":
    let dtOption = parseTimeStamp("2020-10-01 08:21:28.618")
    check dtOption.isSome
    let line = formatLine("filename", 44, "message", dtOption.get())
    let expected = "2020-10-01 08:21:28.618; filename(44); message"
    check line == expected

  test "parse time error":
    let dtOption = parseTimeStamp("not time stamp")
    check not dtOption.isSome

  test "parseFileLine":
    let filenameLineO = parseFileLine("statictea.nim(33)")
    check filenameLineO.isSome
    let fl = filenameLineO.get()
    check fl.filename == "statictea.nim"
    check fl.lineNum == 33

  test "parseLine":
    let logLineO = parseLine(
      "2020-10-01 08:21:28.618; statictea.nim(65); version: 0.1.0")
    check logLineO.isSome
    let logLine = logLineO.get()
    let dtString = formatDateTime(logLine.dt)
    check dtString == "2020-10-01 08:21:28.618"
    check logLine.filename == "statictea.nim"
    check logLine.lineNum == 65
    check logLine.message == "version: 0.1.0"

  test "normalizeLogTime":
    let logLines = @[
      """2022-01-16 11:32:09.111; statictea.nim(33); ----- starting -----""",
      """2023-11-10 01:51:04.432; statictea.nim(34); argv: @["-v"]""",
    ]
    let eLogLines = @[
      """2021-01-16 13:51:09.767; statictea.nim(33); ----- starting -----""",
      """2021-01-16 13:51:09.767; statictea.nim(34); argv: @["-v"]"""
    ]
    let nLogLines = normalizeLogTime(logLines)

    check expectedItems("logLines", nLogLines, eLogLines)
