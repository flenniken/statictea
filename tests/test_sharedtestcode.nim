import std/unittest
import std/options
import sharedtestcode

proc testGotExpectedResult(eStr: string): bool =
  gotExpectedResult("expected", eStr)

proc testGotExpectedResult2(eStr: string): bool =
  result = true
  gotExpectedResult("expected", eStr)

suite "sharedtestcode.nim":

  test "gotExpectedResult":
    check testGotExpectedResult("expected") == false
    # check testGotExpectedResult("nasdf") == false

  test "gotExpectedResult2":
    check testGotExpectedResult2("expected") == true
    # check testGotExpectedResult2("nasdf") == false

  test "append sequences":
    let a = @[1, 2]
    let b = @[3, 4]
    let c = a & b
    check c == @[1, 2, 3, 4]
    var d = a
    d.add(b)
    check d == @[1, 2, 3, 4]

  test "splitContentPick":
    let content = """
hello
there
"""
    let split = splitContentPick(content, [0])
    require split.len == 1
    check split[0] == "hello\n"

  test "splitContentPick last":
    let content = """
hello
there
"""
    let split = splitContentPick(content, [1])
    require split.len == 1
    check split[0] == "there\n"

  test "splitContent":
    let content = "hello"
    let eCmdLines = splitContent(content, 0, 1)
    require eCmdLines.len == 1
    check eCmdLines[0] == "hello"

  test "splitContent 2":
    let content = """
hello
there
"""
    let eCmdLines = splitContent(content, 0, 2)
    require eCmdLines.len == 2
    check eCmdLines[0] == "hello\n"
    check eCmdLines[1] == "there\n"

  test "splitContent 3":
    let content = """
hello
there
tea
"""
    let eCmdLines = splitContent(content, 1, 1)
    require eCmdLines.len == 1
    check eCmdLines[0] == "there\n"


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

