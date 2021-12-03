import std/options
import std/streams
import std/strutils
import std/unittest
import env
import matches
import readlines
import parseCmdLine
import collectCommand

proc testCollectCommand(
    content: string,
    extraLine: ExtraLine,
    eCmdLines: CmdLines,
    eExtraLine: ExtraLine,
    eResultStreamLines: seq[string] = @[],
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[],
  ): bool =

  var inStream = newStringStream(content)
  var resultStream = newStringStream()
  var lineBufferO = newLineBuffer(inStream, filename="template.html")
  var lb = lineBufferO.get()

  var env = openEnvTest("_collectCommand.log")

  let prepostTable = makeDefaultPrepostTable()
  var inOutExtraLine = extraLine
  let cmdLines = collectCommand(env, lb, prepostTable, inOutExtraLine)

  result = env.readCloseDeleteCompare(eLogLines, eErrLines, eOutLines)

  resultStream.setPosition(0)
  var resultStreamLines = readXLines(resultStream)
  resultStream.close()

  if not expectedItems("cmdLines.lines", cmdLines.lines, eCmdLines.lines):
    result = false
  if not expectedItems("cmdLines.lineParts", cmdLines.lineParts, eCmdLines.lineParts):
    result = false
  if not expectedItems("resultStreamLines", resultStreamLines, eResultStreamLines):
    result = false
  if not expectedItem("ExtraLine", inOutExtraLine, eExtraLine):
    result = false

suite "collectCommand.nim":

  test "ExtraLine default":
    var extraLine: ExtraLine
    check extraLine.kind == ""
    check extraLine.line == ""

  test "newExtraLineNormal":
    let extraLine = newExtraLineNormal("hello")
    check extraLine.kind == "normalLine"
    check extraLine.line == "hello"

  test "newExtraLineSpecial":
    var extraLine = newExtraLineSpecial("")
    check extraLine.kind == ""
    check extraLine.line == ""

    extraLine = newExtraLineSpecial("outOfLines")
    check extraLine.kind == "outOfLines"
    check extraLine.line == ""


  test "one line":
    let content = "<!--$ nextline -->\n"
    var eCmdLines: CmdLines
    eCmdLines.lines.add("<!--$ nextline -->\n")
    eCmdLines.lineParts.add(newLineParts())
    var extraLine = newExtraLineSpecial("")
    var eExtraLine = newExtraLineSpecial("outOfLines")
    check testCollectCommand(content, extraLine, eCmdLines, eExtraLine)

#   test "two lines":
#     let content = """
# <!--$ nextline +-->
# <!--$ : -->
# """
#     let eCmdLines = splitNewLines(content)
#     let eCmdLineParts = @[
#       newLineParts(continuation = true),
#       newLineParts(lineNum = 2, command = ":", middleStart = 8)
#     ]
#     check testCollectCommand(content, eCmdLines, eCmdLineParts)

#   test "three lines":
#     let content = """
# <!--$ nextline +-->
# <!--$ : a=5 +-->
# <!--$ : var = "hello" -->
# """
#     let eCmdLines = splitNewLines(content)
#     let eCmdLineParts = @[
#       newLineParts(continuation = true),
#       newLineParts(lineNum = 2, command = ":", middleStart = 8,
#         middleLen = 4, continuation = true),
#       newLineParts(lineNum = 3, command = ":", middleStart = 8, middleLen = 14)
#     ]
#     check testCollectCommand(content, eCmdLines, eCmdLineParts)

#   test "three lines and comments":
#     let content = """
# <!--$ nextline +-->
# <!--$ : a=5 +-->
# <!--$ # this is a comment -->
# <!--$ : var = "hello" -->
# """
#     let eContent = """
# <!--$ nextline +-->
# <!--$ : a=5 +-->
# """
#     let eNextLine = "<!--$ # this is a comment -->\n"

#     let eCmdLines = splitNewLines(eContent)
#     let eCmdLineParts = @[
#       newLineParts(continuation = true),
#       newLineParts(lineNum = 2, command = ":", middleStart = 8,
#         middleLen = 4, continuation = true),
#     ]
#     check testCollectCommand(content, eCmdLines, eCmdLineParts, eNextLine = eNextLine)

#   test "comments":
#     let content = """
# <!--$ nextline +-->
# <!--$ # comment with plus +-->
# <!--$ # -->
# <!--$ : a=5 +-->
# <!--$ # comment in middle -->
# <!--$ : var = "hello" -->
# <!--$ # comment at end-->
# """
#     let eContent = """
# <!--$ nextline +-->
# """
#     let eCmdLines = splitNewLines(eContent)
#     let eCmdLineParts = @[
#       newLineParts(lineNum = 1, command = "nextline", middleStart = 15,
#         middleLen = 0, continuation = true),
#     ]
#     let eNextLine = "<!--$ # comment with plus +-->\n"
#     check testCollectCommand(content, eCmdLines, eCmdLineParts, eNextLine=eNextLine)

#   test "non command":
#     let content = "not a command\n"
#     let eCmdLines: seq[string] = @[]
#     let eCmdLineParts: seq[LineParts] = @[]
#     check testCollectCommand(content, eCmdLines, eCmdLineParts,
#       eResultStreamLines = @[content])

#   test "non command 2":
#     let content = """
# not a command
# still not
# more stuff no newline at end"""
#     let eCmdLines: seq[string] = @[]
#     let eCmdLineParts: seq[LineParts] = @[]
#     check testCollectCommand(content, eCmdLines, eCmdLineParts,
#                       eResultStreamLines = splitNewLines(content))

#   test "command and non command":
#     let content = """
# not a command
# <!--$ nextline -->
# the next line
# """
#     let split = splitNewLines(content)
#     let eCmdLines = @[split[1]]
#     let eCmdLineParts = @[newLineParts(lineNum = 2)]
#     let eNextLine = "the next line\n"
#     check testCollectCommand(content, eCmdLines, eCmdLineParts,
#       eResultStreamLines = @[split[0]], eNextLine = eNextLine)

#   test "empty file":
#     let content = ""
#     check testCollectCommand(content, @[], @[])

#   test "command and non command":
#     let content = """
# not a command
# <!--$ nextline -->
# <!--$ : a = len("the next line") -->
# last line {a}
# more
# """
#     let split = splitNewLines(content)
#     let eCmdLines = @[split[1], split[2]]
#     let eCmdLineParts = @[
#       newLineParts(lineNum = 2, command = "nextline", middleStart = 15, middleLen = 0),
#       newLineParts(lineNum = 3, command = ":", middleStart = 8, middleLen = 25),
#     ]
#     let eNextLine = "last line {a}\n"
#     check testCollectCommand(content, eCmdLines, eCmdLineParts,
#       eResultStreamLines = @[split[0]], eNextLine = eNextLine)
