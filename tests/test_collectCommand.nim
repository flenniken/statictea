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
    eOutLines: seq[string] = @[]): bool =

  var inStream = newStringStream(content)
  var resultStream = newStringStream()
  var lineBufferO = newLineBuffer(inStream, filename="template.html")
  var lb = lineBufferO.get()
  var cmdLines: seq[string] = @[]
  var cmdLineParts: seq[LineParts] = @[]

  var env = openEnvTest("_collectCommand.log")

  let compiledMatchers = getCompiledMatchers()
  collectCommand(env, lb, compiledMatchers, resultStream, cmdLines, cmdLineParts)

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

  test "splitNewLinesNoEndings":
    check splitNewLinesNoEndings("").len == 0
    check splitNewLinesNoEndings("a") == @["a"]
    check splitNewLinesNoEndings("abc") == @["abc"]
    check splitNewLinesNoEndings("\n") == @[""]
    check splitNewLinesNoEndings("b\n") == @["b"]
    check splitNewLinesNoEndings("b\nc") == @["b", "c"]
    check splitNewLinesNoEndings("b\nlast") == @["b", "last"]
    check splitNewLinesNoEndings("b\nc\n") == @["b", "c"]
    check splitNewLinesNoEndings("b\nc\nd") == @["b", "c", "d"]

  test "one line":
    let content = "<!--$ nextline -->\n"
    let eCmdLines = @[content]
    let eCmdLineParts = @[newLineParts()]
    check testCollectCommand(content, eCmdLines, eCmdLineParts)

  test "two lines":
    let content = """
<!--$ nextline \-->
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
<!--$ nextline \-->
<!--$ : a=5 \-->
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
    check testCollectCommand(content, eCmdLines, eCmdLineParts,
      eResultStreamLines = @[split[0]])

  test "regular line not continuation line":
    let content = """
<!--$ nextline \-->
asdf
"""
    let warning = "template.html(2): w24: Missing the continuation command, " &
      "abandoning the previous command.\n"
    check testCollectCommand(content, @[], @[],
                      eResultStreamLines = splitNewLines(content),
                      eErrLines = @[warning])

  test "block command not continuation command":
    let content = """
<!--$ nextline \-->
<!--$ block -->
asdf
"""
    let warning = "template.html(2): w24: Missing the continuation command, " &
      "abandoning the previous command.\n"
    check testCollectCommand(content, @[], @[],
                      eResultStreamLines = splitNewLines(content),
                      eErrLines = @[warning])


  test "no more lines, need continuation":
    let content = """
<!--$ nextline \-->
"""
    let warning = "template.html(1): w24: Missing the continuation command, " &
      "abandoning the previous command.\n"
    check testCollectCommand(content, @[], @[],
                      eResultStreamLines = splitNewLines(content),
                      eErrLines = @[warning])

  test "empty file":
    let content = ""
    check testCollectCommand(content, @[], @[])


  test "more lines after dumping":
    let content = """
<!--$ nextline \-->
<!--$ block -->
asdf
asdf
ttasdfasdf
"""
    let warning = "template.html(2): w24: Missing the continuation command, " &
      "abandoning the previous command.\n"
    check testCollectCommand(content, @[], @[],
                      eResultStreamLines = splitNewLines(content),
                      eErrLines = @[warning])

  test "another command after dumping":
    let content = """
<!--$ nextline \-->
<!--$ block -->
asdf
asdf
ttasdfasdf
<!--$ nextline -->
block
asdf
"""
    let eCmdLines = @["<!--$ nextline -->\n"]
    let eCmdLineParts = @[newLineParts(lineNum = 6)]
    let warning = "template.html(2): w24: Missing the continuation command, " &
      "abandoning the previous command.\n"
    let p = splitNewLines(content)
    let eResultStreamLines = @[p[0], p[1], p[2], p[3], p[4]]
    check testCollectCommand(content, eCmdLines, eCmdLineParts,
                      eResultStreamLines = eResultStreamLines,
                      eErrLines = @[warning])

  test "two warnings":
    let content = """
<!--$ nextline \-->
<!--$ block -->
asdf
asdf
ttasdfasdf
<!--$ nextline \-->
block
asdf
"""
# todo: compare the start of the error lines: template.html(2): w24:
# Then you can change the wording without changing the tests.

    let warning1 = "template.html(2): w24: Missing the continuation command, " &
      "abandoning the previous command.\n"
    let warning2 = "template.html(7): w24: Missing the continuation command, " &
      "abandoning the previous command.\n"
    let eResultStreamLines = splitNewLines(content)
    check testCollectCommand(content, @[], @[],
                      eResultStreamLines = eResultStreamLines,
                      eErrLines = @[warning1, warning2])

  test "missing continue command":
    let content = """
#$ block \
#$ cond1 = cmp(4, 5); \
#$ cond2 = cmp(2, 2); \
#$ cond3 = cmp(5, 4)
cmp(4, 5) returns {cond1}
cmp(2, 2) returns {cond2}
cmp(5, 4) returns {cond3}
#$ endblock
"""
    let eErrLines = splitNewLines """
template.html(2): w22: No command found at column 4, treating it as a non-command line.
template.html(2): w24: Missing the continuation command, abandoning the previous command.
template.html(3): w22: No command found at column 4, treating it as a non-command line.
template.html(4): w22: No command found at column 4, treating it as a non-command line.
"""
    let eCmdLines = @["#$ endblock\n"]
    let eCmdLineParts = @[newLineParts(prefix = "#$", command =
        "endblock", lineNum = 8, middleStart = 11, postfix = "")]

    let p = splitNewLines(content)
    let eResultStreamLines = p[0 .. ^2]

    check testCollectCommand(content, eErrLines = eErrLines, eCmdLines = eCmdLines,
      eCmdLineParts = eCmdLineParts, eResultStreamLines = eResultStreamLines)
