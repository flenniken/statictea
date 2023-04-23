import std/unittest
import std/unittest
import std/strutils
import std/typetraits
import std/options
import std/times
import logger
import regexes
import matches
import comparelines
import sharedtestcode

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
  let matchesO = matchFileLine(line, 0)
  if matchesO.isSome:
    let (filename, lineNumString, _) = matchesO.get2GroupsLen()
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

suite "logger.nim":

  test "test me":
    check 1 == 1

  test "parseTimeStamp":
    let dtOption = parseTimeStamp("2020-10-01 08:21:28.618")
    check dtOption.isSome
    let line = formatLogLine("filename", 44, "message", dtOption.get())
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
    let dtString = formatLogDateTime(logLine.dt)
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



