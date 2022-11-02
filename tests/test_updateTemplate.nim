
import std/unittest
import std/os
import std/strutils
import std/streams
import std/options
import env
import args
import sharedtestcode
import comparelines
import codefile
import updateTemplate
import matches
import readlines
import parseCmdLine

proc testCollectReplaceCommand(
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
  var env = openEnvTest("_collectReplaceCommand.log")
  let prepostTable = makeDefaultPrepostTable()

  let totalContent = inExtraLine.line & content
  let eCmdLines = splitContent(totalContent, eCmdStartLine, eCmdNumLines)
  let eResultLines = splitContentPick(totalContent, eResultPickedLines)
  var inOutExtraLine = inExtraLine

  var cmdLines = collectReplaceCommand(env, lb, prepostTable, inOutExtraLine)

  result = env.readCloseDeleteCompare(eLogLines, eErrLines, eOutLines,
    eResultLines)

  if not expectedItems("cmdLines.lines", cmdLines.lines, eCmdLines):
    echo ""
    result = false

  if not expectedItem("eOutExtraLine", inOutExtraLine, eOutExtraLine):
    echo ""
    result = false

proc testUpdateTemplate(templateContent: string = "",
    serverJson: string = "",
    sharedCode: string = "",
    eRc = 0,
    eResultLines: seq[string] = @[],
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[],
    eTemplateLines: seq[string] = @[],
    showLog: bool = false
  ): bool =
  ## Test the updateTemplate path.

  # Open err, out and log streams.
  var env = openEnvTest("_testUpdateTemplate.log", templateContent)

  var args: Args

  # Create the server json file.
  if serverJson != "":
    let serverFilename = "server.json"
    createFile(serverFilename, serverJson)
    args.serverList = @[serverFilename]

  # Create the shared code file.
  if sharedCode != "":
    let sharedFilename = "shared.tea"
    createFile(sharedFilename, sharedCode)
    args.codeList = @[sharedFilename]

  # Update the template and write out the result.
  updateTemplate(env, args)

  let rc = if env.warningsWritten > 0: 1 else: 0

  result = env.readCloseDeleteCompare(eLogLines, eErrLines, eOutLines,
    eResultLines = eResultLines, eTemplateLines = eTemplateLines, showLog = showLog)

  if not expectedItem("rc", rc, eRc):
    result = false

  discard tryRemoveFile("server.json")
  discard tryRemoveFile("shared.tea")

suite "updateTemplate.nim":

  test "update empty template":
    let templateContent = ""
    let eResultLines: seq[string] = @[]
    check testUpdateTemplate(templateContent = templateContent, eResultLines = eResultLines)

  test "update one line no lf":
    let templateContent = "hi there"
    let eResultLines = splitNewLines templateContent
    check testUpdateTemplate(templateContent = templateContent, eResultLines = eResultLines)

  test "update one line with lf":
    let templateContent = """
hi there
"""
    let eResultLines = splitNewLines templateContent
    check testUpdateTemplate(templateContent = templateContent, eResultLines = eResultLines)

  test "update multiple plain lines":
    let templateContent = """
hi there
update me
nothing special
here
"""
    let eResultLines = splitNewLines templateContent
    check testUpdateTemplate(templateContent = templateContent, eResultLines = eResultLines)

  test "update nextline":
    let templateContent = """
line
<!--$ nextline -->
replacement block
ending line
"""
    let eResultLines = splitNewLines templateContent
    check testUpdateTemplate(templateContent = templateContent, eResultLines = eResultLines)

  test "update block":
    let templateContent = """
line
<!--$ block -->
replacement block
<!--$ endblock -->
ending line
"""
    let eResultLines = splitNewLines templateContent
    check testUpdateTemplate(templateContent = templateContent, eResultLines = eResultLines)

  test "update replace":
    let sharedCode = """
o.header = "<html>\n"
"""
    let templateContent = """
line
<!--$ replace t.content = o.header -->
replacement block
<!--$ endblock -->
ending line
"""
    let eResultLines = splitNewLines """
line
<!--$ replace t.content = o.header -->
<html>
<!--$ endblock -->
ending line
"""
    check testUpdateTemplate(templateContent = templateContent,
      sharedCode = sharedCode, eResultLines = eResultLines)

  test "update replace 2":
    let sharedCode = """
o.header = "<html>\n"
"""
    let templateContent = """
line
<!--$ replace t.content = o.header -->
replacement block
<!--$ endblock -->
ending line
"""
    let eResultLines = splitNewLines """
line
<!--$ replace t.content = o.header -->
<html>
<!--$ endblock -->
ending line
"""
    check testUpdateTemplate(templateContent = templateContent,
      sharedCode = sharedCode, eResultLines = eResultLines)

  test "update replace two lines":

    let sharedCode = """
o.header = $1
<!doctype html>
<html lang="en">
$1
""" % tripleQuotes
    let templateContent = """
line
<!--$ replace t.content = o.header -->
replacement block
asdf
asdfasdf
<!--$ endblock -->
ending line
"""
    let eResultLines = splitNewLines """
line
<!--$ replace t.content = o.header -->
<!doctype html>
<html lang="en">
<!--$ endblock -->
ending line
"""
    check testUpdateTemplate(templateContent = templateContent,
      sharedCode = sharedCode, eResultLines = eResultLines)

  test "update replace multiple commands":

    let sharedCode = """
o.header = $1
<!doctype html>
<html lang="en">
$1
""" % tripleQuotes
    let templateContent = """
<!--$ nextline +-->
<!--$ : a = "b" +-->
<!--$ : b = "c" -->
{a}, {b}
<!--$ replace t.content = o.header -->
replacement block
asdf
asdfasdf
<!--$ endblock -->
<!--$ nextline -->
asdfasdfsdff
<!-- # last line -->
"""
    let eResultLines = splitNewLines """
<!--$ nextline +-->
<!--$ : a = "b" +-->
<!--$ : b = "c" -->
{a}, {b}
<!--$ replace t.content = o.header -->
<!doctype html>
<html lang="en">
<!--$ endblock -->
<!--$ nextline -->
asdfasdfsdff
<!-- # last line -->
"""
    check testUpdateTemplate(templateContent = templateContent,
      sharedCode = sharedCode, eResultLines = eResultLines)

  test "update no content":
    let templateContent = """
line
<!--$ replace  -->
replacement block
asdf
asdfasdf
<!--$ endblock -->
ending line
"""
    let eResultLines = splitNewLines templateContent
    let eErrLines = splitNewLines """
template.html(2): w68: The t.content variable is not set for the replace command, treating it like the block command.
"""
    check testUpdateTemplate(templateContent = templateContent,
      eResultLines = eResultLines, eErrLines = eErrLines, eRc = 1)

  test "update content no newline":
    let templateContent = """
<!--$ replace t.content = "no newline" -->
replacement block
asdf
asdfasdf
<!--$ endblock -->
"""
    let eResultLines = splitNewLines """
<!--$ replace t.content = "no newline" -->
no newline
<!--$ endblock -->
"""
    check testUpdateTemplate(templateContent = templateContent,
      eResultLines = eResultLines)

  test "collect replace":
    let inLine = newNoLine()
    let content = """
$$ replace
replacement block
$$ endblock
"""
    let eOutLine = newNormalLine("replacement block\n")
    check testCollectReplaceCommand(inLine, content, 0, 1, eOutLine)

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
    check testCollectReplaceCommand(inLine, content, 5, 1, eOutLine, [0,1,2,3,4])

  test "collect replace out of lines":
    let inLine = newNoLine()
    let content = """
$$ block
replacement block
$$ endblock
"""
    let eOutLine = newOutOfLines()
    check testCollectReplaceCommand(inLine, content, 0, 0, eOutLine, [0,1,2])

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
    check testCollectReplaceCommand(inLine, content, 0, 0, eOutLine, [0,1,2,3,4])

