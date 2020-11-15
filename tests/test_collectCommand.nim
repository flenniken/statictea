import unittest
import env
import streams
import matches
import readlines
import options
import parseCmdLine
import collectCommand
import strutils

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
  var lineBufferO = newLineBuffer(inStream, filename="template.html")
  var lb = lineBufferO.get()
  var cmdLines: seq[string] = @[]
  var cmdLineParts: seq[LineParts] = @[]

  var env = openEnv("_collectCommand.log")

  collectCommand(env, lb, prepostTable, prefixMatcher,
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

suite "collectCommand.nim":

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
    let eCmdLineParts = @[newLineParts()]
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

  test "regular line not continuation line":
    let content = """
<--!$ nextline \-->
asdf
"""
    let warning = "template.html(2): w24: Missing the continuation line, " &
      "abandoning the command."
    check testProcess(content, @[], @[],
                      eResultStreamLines = splitLines(content),
                      eErrLines = @[warning])

  test "block command not continuation command":
    let content = """
<--!$ nextline \-->
<--!$ block -->
asdf
"""
    let warning = "template.html(2): w24: Missing the continuation line, " &
      "abandoning the command."
    check testProcess(content, @[], @[],
                      eResultStreamLines = splitLines(content),
                      eErrLines = @[warning])


  test "no more lines, need continuation":
    let content = """
<--!$ nextline \-->
"""
    let warning = "template.html(1): w24: Missing the continuation line, " &
      "abandoning the command."
    check testProcess(content, @[], @[],
                      eResultStreamLines = splitLines(content),
                      eErrLines = @[warning])

  test "empty file":
    let content = ""
    check testProcess(content, @[], @[])


  test "more lines after dumping":
    let content = """
<--!$ nextline \-->
<--!$ block -->
asdf
asdf
ttasdfasdf
"""
    let warning = "template.html(2): w24: Missing the continuation line, " &
      "abandoning the command."
    check testProcess(content, @[], @[],
                      eResultStreamLines = splitLines(content),
                      eErrLines = @[warning])

  test "another command after dumping":
    let content = """
<--!$ nextline \-->
<--!$ block -->
asdf
asdf
ttasdfasdf
<--!$ nextline -->
block
asdf
"""
    let eCmdLines = @["<--!$ nextline -->\n"]
    let eCmdLineParts = @[newLineParts()]
    let warning = "template.html(2): w24: Missing the continuation line, " &
      "abandoning the command."
    let p = splitLines(content)
    let eResultStreamLines = @[p[0], p[1], p[2], p[3], p[4]]
    check testProcess(content, eCmdLines, eCmdLineParts,
                      eResultStreamLines = eResultStreamLines,
                      eErrLines = @[warning])

  test "two warnings":
    let content = """
<--!$ nextline \-->
<--!$ block -->
asdf
asdf
ttasdfasdf
<--!$ nextline \-->
block
asdf
"""
    let warning1 = "template.html(2): w24: Missing the continuation line, " &
      "abandoning the command."
    let warning2 = "template.html(7): w24: Missing the continuation line, " &
      "abandoning the command."
    let eResultStreamLines = splitLines(content)
    check testProcess(content, @[], @[],
                      eResultStreamLines = eResultStreamLines,
                      eErrLines = @[warning1, warning2])