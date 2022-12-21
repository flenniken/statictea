import std/unittest
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
