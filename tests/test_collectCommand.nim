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

  var env = openEnvTest("_collectCommand.log")
  env.templateFilename = "template.html"
  let compiledMatchers = getCompiledMatchers()
  collectCommand(env, lb, compiledMatchers, resultStream, cmdLines, cmdLineParts)

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
    let content = "<--!$ nextline -->\n"
    let eCmdLines = @[content]
    let eCmdLineParts = @[newLineParts()]
    check testCollectCommand(content, eCmdLines, eCmdLineParts)

  test "two lines":
    let content = """
<--!$ nextline \-->
<--!$ : -->
"""
    let eCmdLines = splitNewLines(content)
    let eCmdLineParts = @[
      newLineParts(continuation = true),
      newLineParts(lineNum = 2, command = ":", middleStart = 8)
    ]
    check testCollectCommand(content, eCmdLines, eCmdLineParts)

  test "three lines":
    let content = """
<--!$ nextline \-->
<--!$ : a=5 \-->
<--!$ : var = "hello" -->
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
<--!$ nextline -->
the next line
"""
    let split = splitNewLines(content)
    let eCmdLines = @[split[1]]
    let eCmdLineParts = @[newLineParts(lineNum = 2)]
    check testCollectCommand(content, eCmdLines, eCmdLineParts,
      eResultStreamLines = @[split[0]])

  test "regular line not continuation line":
    let content = """
<--!$ nextline \-->
asdf
"""
    let warning = "template.html(2): w24: Missing the continuation line, " &
      "abandoning the command."
    check testCollectCommand(content, @[], @[],
                      eResultStreamLines = splitNewLines(content),
                      eErrLines = @[warning])

  test "block command not continuation command":
    let content = """
<--!$ nextline \-->
<--!$ block -->
asdf
"""
    let warning = "template.html(2): w24: Missing the continuation line, " &
      "abandoning the command."
    check testCollectCommand(content, @[], @[],
                      eResultStreamLines = splitNewLines(content),
                      eErrLines = @[warning])


  test "no more lines, need continuation":
    let content = """
<--!$ nextline \-->
"""
    let warning = "template.html(1): w24: Missing the continuation line, " &
      "abandoning the command."
    check testCollectCommand(content, @[], @[],
                      eResultStreamLines = splitNewLines(content),
                      eErrLines = @[warning])

  test "empty file":
    let content = ""
    check testCollectCommand(content, @[], @[])


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
    check testCollectCommand(content, @[], @[],
                      eResultStreamLines = splitNewLines(content),
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
    let eCmdLineParts = @[newLineParts(lineNum = 6)]
    let warning = "template.html(2): w24: Missing the continuation line, " &
      "abandoning the command."
    let p = splitNewLines(content)
    let eResultStreamLines = @[p[0], p[1], p[2], p[3], p[4]]
    check testCollectCommand(content, eCmdLines, eCmdLineParts,
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
    let eResultStreamLines = splitNewLines(content)
    check testCollectCommand(content, @[], @[],
                      eResultStreamLines = eResultStreamLines,
                      eErrLines = @[warning1, warning2])
