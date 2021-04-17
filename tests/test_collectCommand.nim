import unittest
import env
import streams
import matches
import readlines
import options
import parseCmdLine
import collectCommand
import strutils

proc testCollectCommand(
    content: string,
    eCmdLines: seq[string] = @[],
    eCmdLineParts: seq[LineParts] = @[],
    eResultStreamLines: seq[string] = @[],
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[],
    eNextLine: string = ""
  ): bool =

  var inStream = newStringStream(content)
  var resultStream = newStringStream()
  var lineBufferO = newLineBuffer(inStream, filename="template.html")
  var lb = lineBufferO.get()
  var cmdLines: seq[string] = @[]
  var cmdLineParts: seq[LineParts] = @[]

  var env = openEnvTest("_collectCommand.log")

  let prepostTable = makeDefaultPrepostTable()
  var nextLine: string
  collectCommand(env, lb, prepostTable, resultStream, cmdLines, cmdLineParts, nextLine)

  result = env.readCloseDeleteCompare(eLogLines, eErrLines, eOutLines)

  resultStream.setPosition(0)
  var resultStreamLines = readXLines(resultStream)
  resultStream.close()

  if not expectedItems("cmdLines", cmdLines, eCmdLines):
    result = false
  if not expectedItems("cmdLineParts", cmdLineParts, eCmdLineParts):
    result = false
  if not expectedItems("resultStreamLines", resultStreamLines, eResultStreamLines):
    result = false
  if not expectedItem("nextLine", nextLine, eNextLine):
    result = false

suite "collectCommand.nim":

  test "splitNewLines":
    check splitNewLines("").len == 0
    check splitNewLines("a") == @["a"]
    check splitNewLines("abc") == @["abc"]
    check splitNewLines("\n") == @["\n"]
    check splitNewLines("b\n") == @["b\n"]
    check splitNewLines("b\nc") == @["b\n", "c"]
    check splitNewLines("b\nlast") == @["b\n", "last"]
    check splitNewLines("b\nc\n") == @["b\n", "c\n"]
    check splitNewLines("b\nc\nd") == @["b\n", "c\n", "d"]
    let content = """
line one
two
three
"""
    check splitNewLines(content) == @["line one\n", "two\n", "three\n"]

  test "one line":
    let content = "<!--$ nextline -->\n"
    let eCmdLines = @[content]
    let eCmdLineParts = @[newLineParts()]
    check testCollectCommand(content, eCmdLines, eCmdLineParts)

  test "two lines":
    let content = """
<!--$ nextline +-->
<!--$ : -->
"""
    let eCmdLines = splitNewLines(content)
    let eCmdLineParts = @[
      newLineParts(continuation = true),
      newLineParts(lineNum = 2, command = ":", middleStart = 8)
    ]
    check testCollectCommand(content, eCmdLines, eCmdLineParts)

  test "three lines":
    let content = """
<!--$ nextline +-->
<!--$ : a=5 +-->
<!--$ : var = "hello" -->
"""
    let eCmdLines = splitNewLines(content)
    let eCmdLineParts = @[
      newLineParts(continuation = true),
      newLineParts(lineNum = 2, command = ":", middleStart = 8,
        middleLen = 4, continuation = true),
      newLineParts(lineNum = 3, command = ":", middleStart = 8, middleLen = 14)
    ]
    check testCollectCommand(content, eCmdLines, eCmdLineParts)

  test "non command":
    let content = "not a command\n"
    let eCmdLines: seq[string] = @[]
    let eCmdLineParts: seq[LineParts] = @[]
    check testCollectCommand(content, eCmdLines, eCmdLineParts,
      eResultStreamLines = @[content])

  test "non command 2":
    let content = """
not a command
still not
more stuff no newline at end"""
    let eCmdLines: seq[string] = @[]
    let eCmdLineParts: seq[LineParts] = @[]
    check testCollectCommand(content, eCmdLines, eCmdLineParts,
                      eResultStreamLines = splitNewLines(content))

  test "command and non command":
    let content = """
not a command
<!--$ nextline -->
the next line
"""
    let split = splitNewLines(content)
    let eCmdLines = @[split[1]]
    let eCmdLineParts = @[newLineParts(lineNum = 2)]
    let eNextLine = "the next line\n"
    check testCollectCommand(content, eCmdLines, eCmdLineParts,
      eResultStreamLines = @[split[0]], eNextLine = eNextLine)

  test "empty file":
    let content = ""
    check testCollectCommand(content, @[], @[])

  test "command and non command":
    let content = """
not a command
<!--$ nextline -->
<!--$ : a = len("the next line") -->
last line {a}
more
"""
    let split = splitNewLines(content)
    let eCmdLines = @[split[1], split[2]]
    let eCmdLineParts = @[
      newLineParts(lineNum = 2, command = "nextline", middleStart = 15, middleLen = 0),
      newLineParts(lineNum = 3, command = ":", middleStart = 8, middleLen = 25),
    ]
    let eNextLine = "last line {a}\n"
    check testCollectCommand(content, eCmdLines, eCmdLineParts,
      eResultStreamLines = @[split[0]], eNextLine = eNextLine)


