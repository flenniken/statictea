import std/options
import std/streams
import std/strutils
import std/unittest
import env
import matches
import readlines
import collectCommand

func splitContent(content: string, startLine: Natural, numLines: Natural): seq[string] =
  ## Split the content string at newlines and return a range of the
  ## lines.  startLine is the index of the first line.
  let split = splitNewLines(content)
  let endLine = startLine + numLines - 1
  if startLine <= endLine and endLine < split.len:
     result.add(split[startLine .. endLine])

func splitContentPick(content: string, picks: openArray[int]): seq[string] =
  ## Split the content then return the picked lines by line index.
  let split = splitNewLines(content)
  for ix in picks:
    result.add(split[ix])

proc testCollectCommand(
    inExtraLine: ExtraLine,
    content: string,
    eCmdStartLine: Natural,
    eCmdNumLines: Natural,
    eOutExtraLine: ExtraLine,
    eResultPickedLines: openarray[int] = [],
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[],
  ): bool =

  var inStream = newStringStream(content)
  var lineBufferO = newLineBuffer(inStream, filename="template.html")
  var lb = lineBufferO.get()
  var env = openEnvTest("_collectCommand.log")
  let prepostTable = makeDefaultPrepostTable()

  let totalContent = inExtraLine.line & content
  let eCmdLines = splitContent(totalContent, eCmdStartLine, eCmdNumLines)
  let eResultLines = splitContentPick(totalContent, eResultPickedLines)
  var inOutExtraLine = inExtraLine

  let cmdLines = collectCommand(env, lb, prepostTable, inOutExtraLine)

  result = env.readCloseDeleteCompare(eLogLines, eErrLines, eOutLines,
    eResultLines)

  if not expectedItems("cmdLines.lines", cmdLines.lines, eCmdLines):
    echo ""
    result = false

  if not expectedItem("eOutExtraLine", inOutExtraLine, eOutExtraLine):
    echo ""
    result = false


suite "collectCommand.nim":

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

  test "zero lines":
    let inLine = newExtraLineSpecial("")
    let content = ""
    var eOutLine = newExtraLineSpecial("outOfLines")
    check testCollectCommand(inLine, content, 0, 0, eOutLine)

  test "one line command":
    var inLine = newExtraLineSpecial("")
    let content = "<!--$ nextline -->\n"
    var eOutLine = newExtraLineSpecial("outOfLines")
    check testCollectCommand(inLine, content, 0, 1, eOutLine)

  test "two line command":
    let inLine = newExtraLineSpecial("")
    let content = """
<!--$ nextline -->
<!--$ : -->
"""
    let eOutLine = newExtraLineSpecial("outOfLines")
    check testCollectCommand(inLine, content, 0, 2, eOutLine)

  test "three line command":
    let inLine = newExtraLineSpecial("")
    let content = """
<!--$ nextline -->
<!--$ : a=5 -->
<!--$ : var = "hello" -->
"""
    var eOutLine = newExtraLineSpecial("outOfLines")
    check testCollectCommand(inLine, content, 0, 3, eOutLine)

  test "fake comment":
    let inLine = newExtraLineSpecial("")
    let content = """
<!--$ nextline -->
<!--$ : a=5 -->
<!--$ # this is not really a comment -->
"""
    var eOutLine = newExtraLineNormal("<!--$ # this is not really a comment -->\n")
    check testCollectCommand(inLine, content, 0, 2, eOutLine)

  test "one line non-command":
    let inLine = newExtraLineSpecial("")
    let content = "not a command\n"
    var eOutLine = newExtraLineSpecial("outOfLines")
    check testCollectCommand(inLine, content, 0, 0, eOutLine, [0])

  test "multipe line non-command":
    let inLine = newExtraLineSpecial("")
    let content = """
not a command
still not
more stuff no newline at end
"""
    var eOutLine = newExtraLineSpecial("outOfLines")
    check testCollectCommand(inLine, content, 0, 0, eOutLine, [0, 1, 2])

  test "comments":
    let inLine = newExtraLineSpecial("")
    let content = """
stuff
<!--$ # comment line -->
more stuff
<!--$ # comment line 2 -->
more stuff
<!--$ nextline -->
<!--$ : var = "hello" -->
hello
"""
    var eOutLine = newExtraLineNormal("hello\n")
    check testCollectCommand(inLine, content, 5, 2, eOutLine, [0, 2, 4])

  test "simple block command":
    let inLine = newExtraLineSpecial("")
    let content = """
<!--$ block -->
replacement block
<!--$ endblock -->
"""
    let eOutLine = newExtraLineNormal("replacement block\n")
    check testCollectCommand(inLine, content, 0, 1, eOutLine)

  test "simple replace command":
    let inLine = newExtraLineSpecial("")
    let content = """
<!--$ replace -->
replacement block
<!--$ endblock -->
"""
    let eOutLine = newExtraLineNormal("replacement block\n")
    check testCollectCommand(inLine, content, 0, 1, eOutLine)

  test "$$ prefix":
    let inLine = newExtraLineSpecial("")
    let content = """
$$ block
replacement block
$$ endblock
"""
    let eOutLine = newExtraLineNormal("replacement block\n")
    check testCollectCommand(inLine, content, 0, 1, eOutLine)

  test "no ending newline":
    let inLine = newExtraLineSpecial("")
    let content = """
$$ nextline
replacement block"""
    let eOutLine = newExtraLineNormal("replacement block")
    check testCollectCommand(inLine, content, 0, 1, eOutLine)

  test "no replacement block":
    let inLine = newExtraLineSpecial("")
    let content = """
$$ nextline"""
    let eOutLine = newExtraLineSpecial("outOfLines")
    check testCollectCommand(inLine, content, 0, 1, eOutLine)

  test "with starting extra line":
    let inLine = newExtraLineNormal("this is extra\n")
    let content = """
$$ block
replacement block
$$ endblock
"""
    let eOutLine = newExtraLineNormal("replacement block\n")
    check testCollectCommand(inLine, content, 1, 1, eOutLine, [0])

  test "bare continue command":
    let inLine = newExtraLineSpecial("")
    let content = """
$$ : bare naked
replacement block
"""
    let eOutLine = newExtraLineSpecial("outOfLines")
    let eErrLines = @["template.html(1): w145: The continue command is not part of a command.\n"]
    check testCollectCommand(inLine, content, 0, 0, eOutLine, [0, 1],
      eErrLines = eErrLines)

  test "bare endblock command":
    let inLine = newExtraLineSpecial("")
    let content = """
$$ endblock
replacement block
"""
    let eOutLine = newExtraLineSpecial("outOfLines")
    let eErrLines = @[
      "template.html(1): w144: The endblock command does not have a matching block command.\n",
    ]
    check testCollectCommand(inLine, content, 0, 0, eOutLine, [0, 1],
      eErrLines = eErrLines)





    # Test in extra line without newline.  What would happen for
    # binary files.
