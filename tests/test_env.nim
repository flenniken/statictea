import unittest
import env
import typetraits
import options
import times
import regexes
import strutils

type
  FileLine* = object
    filename*: string
    lineNum*: Natural

  LogLine* = object
    dt*: DateTime
    filename*: string
    lineNum*: Natural
    message*: string

proc parseTimeStamp*(str: string): Option[DateTime] =
  try:
    result = some(parse(str, dtFormat))
  except TimeParseError:
    result = none(DateTime)

proc parseFileLine*(line: string): Option[FileLine] =
  var matcher = newMatcher(r"^(.*)\(([0-9]+)\)$", 2)
  let matchesO = getMatches(matcher, line, 0)
  if matchesO.isSome:
    let matches = matchesO.get()
    let (filename, lineNumString) = matches.get2Groups()
    let lineNum = parseUInt(lineNumString)
    result = some(FileLine(filename: filename, lineNum: lineNum))

proc parseLine*(line: string): Option[LogLine] =
  var parts = split(line, "; ", 3)
  if parts.len != 3:
    return none(LogLine)
  let dtO = parseTimeStamp(parts[0])
  if not dtO.isSome:
    return none(LogLine)
  let fileLineO = parseFileLine(parts[1])
  if not fileLineO.isSome:
    return none(LogLine)
  let fileLine = fileLineO.get()
  result = some(LogLine(dt: dtO.get(), filename: fileLine.filename,
    lineNum: fileLine.lineNum, message: parts[2]))

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

    var eLogLines = splitNewlines("""
XXXX-XX-XX XX:XX:XX.XXX; test_env.nim(X*); testProc called
XXXX-XX-XX XX:XX:XX.XXX; test_env.nim(X*); testProc done
""")
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

  test "compareLogLine":
    check not compareLogLine("", "").isSome
    check not compareLogLine("a", "a").isSome
    check not compareLogLine("ab", "ab").isSome
    check not compareLogLine("a", "X").isSome
    check not compareLogLine("abc", "aXc").isSome
    let logLine  = "2020-10-01 08:21:28.618; statictea.nim(65); version: 0.1.0"
    let eLogLine = "XXXX-XX-XX 08:21:28.618; statictea.nim(XX); version: X.X.X"
    check not compareLogLine(logLine, eLogLine).isSome

  test "compareLogLine star":
    check not compareLogLine("(123)", "(*)").isSome
    check not compareLogLine("(123) tea", "(*) tea").isSome
    check not compareLogLine("(123) tea 123", "(*) tea 123").isSome
    check not compareLogLine("(123))) tea 123", "(*))) tea 123").isSome
    check not compareLogLine("1", "*").isSome
    # check not compareLogLine("", "*").isSome


  test "compareLogLine different":
    check compareLogLine("a", "").get() == (0, 0)
    check compareLogLine("", "a").get() == (0, 0)
    check compareLogLine("abc", "atc").get() == (1, 1)
    check compareLogLine("abc", "aXd").get() == (2, 2)
    check compareLogLine("abcd", "ab").get() == (2, 2)

  test "compareLogLinesMatches":
    let logLines = @[
      "2021-01-17 15:16:09.868; test_env.nim(8); testProc called",
      "2021-01-17 15:16:09.868; test_env.nim(9); testProc done",
    ]
    let eLogLines = @[
      "XXXX-XX-XX XX:XX:XX.XXX; test_env.nim(X); testProc called",
      "XXXX-XX-XX XX:XX:XX.XXX; test_env.nim(X); testProc done",
    ]
    var matches = compareLogLinesMatches(logLines, eLogLines)
    check matches == @[0, 1]

  test "compareLogLinesMatches 4":
    let logLines = @["a", "b", "c", "d"]
    let eLogLines = @["a", "b", "c", "d"]
    var matches = compareLogLinesMatches(logLines, eLogLines)
    check matches == @[0, 1, 2, 3]

  test "compareLogLinesMatches 5":
    let logLines = @["a", "b", "c", "d"]
    let eLogLines = @["a", "b", "d"]
    var matches = compareLogLinesMatches(logLines, eLogLines)
    check matches == @[0, 1, 2]

  test "compareLogLinesMatches 6":
    let logLines = @["a", "b", "c", "d"]
    let eLogLines = @["b", "d"]
    var matches = compareLogLinesMatches(logLines, eLogLines)
    check matches == @[0, 1]

  test "compareLogLinesMatches 7":
    let logLines = @["a", "b", "c", "d"]
    let eLogLines = @["t", "c"]
    var matches = compareLogLinesMatches(logLines, eLogLines)
    check matches == @[1]

  test "compareLogLinesMatches 8":
    let logLines = @["a", "b", "c", "d"]
    let eLogLines = @["t", "tc"]
    var matches = compareLogLinesMatches(logLines, eLogLines)
    check matches.len == 0

  # test "showLogLinesAndExpected":
  #   let logLines = @["a", "b", "c", "d"]
  #   let eLogLines = @["a", "b", "c", "d"]
  #   let matches = @[0, 1, 2, 3]
  #   showLogLinesAndExpected(logLines, eLogLines, matches)

  # test "showLogLinesAndExpected":
  #   let logLines = @["a", "b", "c", "d"]
  #   let eLogLines = @["a", "b", "ddc", "d"]
  #   let matches = @[0, 1, 3]
  #   showLogLinesAndExpected(logLines, eLogLines, matches)

