import std/options
import std/streams
import std/strutils
import std/unittest
import env
import matches
import readlines
import collectCommand
import comparelines

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
    if ix >= 0 and ix < split.len:
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
    replaceOnly: bool = false,
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

  var cmdLines: CmdLines
  if replaceOnly:
    cmdLines = collectReplaceCommand(env, lb, prepostTable, inOutExtraLine)
  else:
    cmdLines = collectCommand(env, lb, prepostTable, inOutExtraLine)

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

  test "ExtraLine default":
    var extraLine: ExtraLine
    check extraLine.kind == elkNoLine
    check extraLine.line == ""

  test "newNormalLine":
    let extraLine = newNormalLine("hello")
    check extraLine.kind == elkNormalLine
    check extraLine.line == "hello"

  test "newExtraLineSpecial":
    var extraLine = newNoLine()
    check extraLine.kind == elkNoLine
    check extraLine.line == ""

    extraLine = newOutOfLines()
    check extraLine.kind == elkOutOfLines
    check extraLine.line == ""

  test "zero lines":
    let inLine = newNoLine()
    let content = ""
    var eOutLine = newOutOfLines()
    check testCollectCommand(inLine, content, 0, 0, eOutLine)

  test "one line command":
    var inLine = newNoLine()
    let content = "<!--$ nextline -->\n"
    var eOutLine = newOutOfLines()
    check testCollectCommand(inLine, content, 0, 1, eOutLine)

  test "two line command":
    let inLine = newNoLine()
    let content = """
<!--$ nextline -->
<!--$ : -->
"""
    let eOutLine = newOutOfLines()
    check testCollectCommand(inLine, content, 0, 2, eOutLine)

  test "three line command":
    let inLine = newNoLine()
    let content = """
<!--$ nextline -->
<!--$ : a=5 -->
<!--$ : var = "hello" -->
"""
    var eOutLine = newOutOfLines()
    check testCollectCommand(inLine, content, 0, 3, eOutLine)

  test "fake comment":
    let inLine = newNoLine()
    let content = """
<!--$ nextline -->
<!--$ : a=5 -->
<!--$ # this is not really a comment -->
"""
    var eOutLine = newNormalLine("<!--$ # this is not really a comment -->\n")
    check testCollectCommand(inLine, content, 0, 2, eOutLine)

  test "one line non-command":
    let inLine = newNoLine()
    let content = "not a command\n"
    var eOutLine = newOutOfLines()
    check testCollectCommand(inLine, content, 0, 0, eOutLine, [0])

  test "multipe line non-command":
    let inLine = newNoLine()
    let content = """
not a command
still not
more stuff no newline at end
"""
    var eOutLine = newOutOfLines()
    check testCollectCommand(inLine, content, 0, 0, eOutLine, [0, 1, 2])

  test "comments":
    let inLine = newNoLine()
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
    var eOutLine = newNormalLine("hello\n")
    check testCollectCommand(inLine, content, 5, 2, eOutLine, [0, 2, 4])

  test "simple block command":
    let inLine = newNoLine()
    let content = """
<!--$ block -->
replacement block
<!--$ endblock -->
"""
    let eOutLine = newNormalLine("replacement block\n")
    check testCollectCommand(inLine, content, 0, 1, eOutLine)

  test "empty block command":
    let inLine = newNoLine()
    let content = """
<!--$ block -->
<!--$ endblock -->
"""
    let eOutLine = newNormalLine("<!--$ endblock -->\n")
    check testCollectCommand(inLine, content, 0, 1, eOutLine)

  test "simple replace command":
    let inLine = newNoLine()
    let content = """
<!--$ replace -->
replacement block
<!--$ endblock -->
"""
    let eOutLine = newNormalLine("replacement block\n")
    check testCollectCommand(inLine, content, 0, 1, eOutLine)

  test "$$ prefix":
    let inLine = newNoLine()
    let content = """
$$ block
replacement block
$$ endblock
"""
    let eOutLine = newNormalLine("replacement block\n")
    check testCollectCommand(inLine, content, 0, 1, eOutLine)

  test "no ending newline":
    let inLine = newNoLine()
    let content = """
$$ nextline
replacement block"""
    let eOutLine = newNormalLine("replacement block")
    check testCollectCommand(inLine, content, 0, 1, eOutLine)

  test "no replacement block":
    let inLine = newNoLine()
    let content = """
$$ nextline"""
    let eOutLine = newOutOfLines()
    check testCollectCommand(inLine, content, 0, 1, eOutLine)

  test "with starting extra line":
    let inLine = newNormalLine("this is extra\n")
    let content = """
$$ block
replacement block
$$ endblock
"""
    let eOutLine = newNormalLine("replacement block\n")
    check testCollectCommand(inLine, content, 1, 1, eOutLine, [0])

  test "bare continue command":
    let inLine = newNoLine()
    let content = """
$$ : bare naked
replacement block
"""
    let eOutLine = newOutOfLines()
    let eErrLines = @["template.html(1): w145: The continue command is not part of a command.\n"]
    check testCollectCommand(inLine, content, 0, 0, eOutLine, [0, 1],
      eErrLines = eErrLines)

  test "bare endblock command":
    let inLine = newNoLine()
    let content = """
$$ endblock
replacement block
"""
    let eOutLine = newOutOfLines()
    let eErrLines = @[
      "template.html(1): w144: The endblock command does not have a matching block command.\n",
    ]
    check testCollectCommand(inLine, content, 0, 0, eOutLine, [0, 1],
      eErrLines = eErrLines)

  test "bare endblock command in extra line":
    let inLine = newNormalLine("$$ endblock")
    let content = """
hello
hello
hello
"""
    let eOutLine = newOutOfLines()
    # Notice the line number is zero, this is expected.
    let eErrLines = @[
      "template.html(0): w144: The endblock command does not have a matching block command.\n",
    ]
    check testCollectCommand(inLine, content, 0, 0, eOutLine,
      [0, 1, 2, 3], eErrLines = eErrLines)

  test "in extra line without newline":
    let inLine = newNormalLine("binary file long line")
    let content = """
 the rest of the long line
$$ nextline
replacement block
"""
    let eOutLine = newNormalLine("replacement block\n")
    check testCollectCommand(inLine, content, 1, 1, eOutLine, [0])

  test "only extra line":
    let inLine = newNormalLine("hello")
    let content = ""
    let eOutLine = newOutOfLines()
    check testCollectCommand(inLine, content, 0, 0, eOutLine, [0])

  test "only extra line with command":
    let inLine = newNormalLine("$$ nextline")
    let content = ""
    let eOutLine = newOutOfLines()
    check testCollectCommand(inLine, content, 0, 1, eOutLine)

  test "collect replace":
    let inLine = newNoLine()
    let content = """
$$ replace
replacement block
$$ endblock
"""
    let eOutLine = newNormalLine("replacement block\n")
    check testCollectCommand(inLine, content, 0, 1, eOutLine, replaceOnly = true)

  test "collect replace but not others":
    let inLine = newNoLine()
    let content = """
others
$$ nextline
replacement block
$$ block
$$ endblock
$$ replace
replacement block
$$ endblock
end
"""
    let eOutLine = newNormalLine("replacement block\n")
    check testCollectCommand(inLine, content, 5, 1, eOutLine, [0,1,2,3,4], replaceOnly = true)

  test "collect replace out of lines":
    let inLine = newNoLine()
    let content = """
$$ block
replacement block
$$ endblock
"""
    let eOutLine = newOutOfLines()
    check testCollectCommand(inLine, content, 0, 0, eOutLine, [0,1,2], replaceOnly = true)

  test "collect replace again":
    let inLine = newNoLine()
    let content = """
$$ block
replacement block
$$ replace
$$ replace
$$ endblock
"""
    let eOutLine = newOutOfLines()
    check testCollectCommand(inLine, content, 0, 0, eOutLine, [0,1,2,3,4], replaceOnly = true)

