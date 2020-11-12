import unittest
import env
import streams
import matches
import readlines
import options
import parseCmdLine
import processLinesReturnCmd
import strutils

proc splitLines(content: string): seq[string] =
  ## Split lines and keep the line endings.
  if content.len == 0:
    return
  var start = 0
  var pos: int
  for pos in 0 ..< content.len:
    let ch = content[pos]
    if ch == '\n':
      result.add(content[start .. pos])
      start = pos+1
  if start < content.len:
    result.add(content[start ..< content.len])



template notReturn(boolProc: untyped) =
  if not boolProc:
    return false

proc expectedItems[T](name: string, items: seq[T], expectedItems: seq[T]): bool =
  ## Compare the items with the expected items and show them when
  ## different. Return true when they are the same.

  if items == expectedItems:
    result = true
  else:
    if items.len != expectedItems.len:
      echo "~~~~~~~~~~ $1 ~~~~~~~~~~~:" % name
      for item in items:
        echo $item
      echo "~~~~~~ expected $1 ~~~~~~:" % name
      for item in expectedItems:
        echo $item
    else:
      echo "~~~~~~~~~~ $1 ~~~~~~~~~~~:" % name
      for ix in 0 ..< items.len:
        if items[ix] == expectedItems[ix]:
          echo "$1: same" % [$ix]
        else:
          echo "$1:      got: $2" % [$ix, $items[ix]]
          echo "$1: expected: $2" % [$ix, $expectedItems[ix]]
    result = false

proc testProcess(
    content: string,
    eCmdLines: seq[string],
    eCmdLineParts: seq[LineParts],
    eResultStreamLines: seq[string] = @[],
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[]): bool =

  var prepostTable = getPrepostTable()
  var prefixMatcher = getPrefixMatcher(prepostTable)
  var commandMatcher = getCommandMatcher()
  var inStream = newStringStream(content)
  var resultStream = newStringStream()
  var lineBufferO = newLineBuffer(inStream, templateFilename="template.html")
  var lb = lineBufferO.get()
  var cmdLines: seq[string] = @[]
  var cmdLineParts: seq[LineParts] = @[]

  var env = openEnv("_processLinesReturnCmd.log")

  processLinesReturnCmd(env, lb, prepostTable, prefixMatcher,
    commandMatcher, resultStream, cmdLines, cmdLineParts)

  let (logLines, errLines, outLines) = env.readCloseDelete()

  resultStream.setPosition(0)
  var resultStreamLines = readlines(resultStream)
  resultStream.close()

  notReturn expectedItems("cmdLines", cmdLines, eCmdLines)
  notReturn expectedItems("cmdLineParts", cmdLineParts, eCmdLineParts)
  notReturn expectedItems("resultStreamLines", resultStreamLines, eResultStreamLines)
  notReturn expectedItems("logLines", logLines, eLogLines)
  notReturn expectedItems("errLines", errLines, eErrLines)
  notReturn expectedItems("outLines", outLines, eOutLines)
  result = true

suite "processLinesReturnCmd.nim":

  test "splitLines":
    check splitLines("").len == 0
    check splitLines("a") == @["a"]
    check splitLines("abc") == @["abc"]
    check splitLines("\n") == @["\n"]
    check splitLines("b\n") == @["b\n"]
    check splitLines("b\nc") == @["b\n", "c"]
    check splitLines("b\nlast") == @["b\n", "last"]
    check splitLines("b\nc\n") == @["b\n", "c\n"]
    check splitLines("b\nc\nd") == @["b\n", "c\n", "d"]
    let content = """
line one
two
three
"""
    check splitLines(content) == @["line one\n", "two\n", "three\n"]

  test "one line":
    let content = "<--!$ nextline -->\n"
    let eCmdLines = @[content]
    let eLineParts = newLineParts()
    let eCmdLineParts = @[eLineParts]
    check testProcess(content, eCmdLines, eCmdLineParts)

  test "two lines":
    let content = """
<--!$ nextline \-->
<--!$ : -->
"""
    let eCmdLines = splitLines(content)
    let eCmdLineParts = @[
      newLineParts(continuation = true),
      newLineParts(command = ":", middleStart = 8)
    ]
    check testProcess(content, eCmdLines, eCmdLineParts)

  test "three lines":
    let content = """
<--!$ nextline \-->
<--!$ : a=5 \-->
<--!$ : var = "hello" -->
"""
    let eCmdLines = splitLines(content)
    let eCmdLineParts = @[
      newLineParts(continuation = true),
      newLineParts(command = ":", middleStart = 8, middleLen = 4, continuation = true),
      newLineParts(command = ":", middleStart = 8, middleLen = 14)
    ]
    check testProcess(content, eCmdLines, eCmdLineParts)

  test "non command":
    let content = "not a command\n"
    let eCmdLines: seq[string] = @[]
    let eCmdLineParts: seq[LineParts] = @[]
    check testProcess(content, eCmdLines, eCmdLineParts,
      eResultStreamLines = @[content])

  test "non command 2":
    let content = """
not a command
still not
more stuff no newline at end"""
    let eCmdLines: seq[string] = @[]
    let eCmdLineParts: seq[LineParts] = @[]
    check testProcess(content, eCmdLines, eCmdLineParts,
                      eResultStreamLines = splitLines(content))


  test "command and non command":
    let content = """
not a command
<--!$ nextline -->
the next line
"""
    let split = splitLines(content)
    let eCmdLines = @[split[1]]
    let eCmdLineParts = @[newLineParts()]
    check testProcess(content, eCmdLines, eCmdLineParts,
      eResultStreamLines = @[split[0]])
