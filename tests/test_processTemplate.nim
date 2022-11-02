
import std/unittest
import std/os
import std/strutils
import std/streams
import std/options
import processTemplate
import env
import args
import readlines
import version
import variables
import vartypes
import tables
import sharedtestcode
import comparelines
import codefile
import matches
import parseCmdLine

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

  var cmdLines = collectCommand(env, lb, prepostTable, inOutExtraLine)

  result = env.readCloseDeleteCompare(eLogLines, eErrLines, eOutLines,
    eResultLines)

  if not expectedItems("cmdLines.lines", cmdLines.lines, eCmdLines):
    echo ""
    result = false

  if not expectedItem("eOutExtraLine", inOutExtraLine, eOutExtraLine):
    echo ""
    result = false

iterator yieldContentLine*(content: string): string =
  ## Yield one content line at a time and keep the line endings.
  var start = 0
  for pos in 0 ..< content.len:
    let ch = content[pos]
    if ch == '\n':
      yield(content[start .. pos])
      start = pos+1
  if start < content.len:
    yield(content[start ..< content.len])

proc testGetTeaArgs(args: Args, eVarRep: string): bool =
  let value = getTeaArgs(args)
  let varRep = dotNameRep(value.dictv)
  result = true
  if varRep != eVarRep:
    echo linesSideBySide(varRep, eVarRep)
    result = false

proc testProcessTemplate(templateContent: string = "",
    serverJson: string = "",
    sharedCode: string = "",
    eRc = 0,
    eResultLines: seq[string] = @[],
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[],
    showLog: bool = false
  ): bool =
  ## Test the processTemplate procedure.

  # Open err, out, template and log streams.
  var env = openEnvTest("_testProcessTemplate.log", templateContent)

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

  # Process the template and write out the result.
  processTemplate(env, args)

  let rc = if env.warningsWritten > 0: 1 else: 0

  result = env.readCloseDeleteCompare(eLogLines, eErrLines, eOutLines,
    eResultLines = eResultLines, showLog = showLog)

  if not expectedItem("rc", rc, eRc):
    result = false

  discard tryRemoveFile("server.json")
  discard tryRemoveFile("shared.tea")


proc testYieldcontentline(content: string, eLines: seq[string] = @[]): bool =
  var lines = newSeq[string]()
  for line in yieldContentLine(content):
    lines.add(line)
  result = expectedItems("lines", lines, eLines)

suite "processTemplate":

  test "yieldContentLine empty":
    check testYieldcontentline("")

  test "yieldContentLine 1":
    check testYieldcontentline("1", @["1"])

  test "yieldContentLine 2":
    let content = "1\ntwo\r\n"
    check testYieldcontentline(content, @["1\n", "two\r\n"])

  test "yieldContentLine 3":
    let content = "1\ntwo\r\nthree"
    check testYieldcontentline(content, @["1\n", "two\r\n", "three"])

  test "yieldContentLine 4":
    check testYieldcontentline("\n", @["\n"])

  test "createFile":
    let filename = "template.html"
    createFile(filename, "Hello")
    defer: discard tryRemoveFile(filename)
    let lines = readXLines(filename)
    check lines.len == 1
    check lines[0] == "Hello"

  test "processTemplate empty":
    check testProcessTemplate()

  test "readme Hello World":
    let templateContent = """
<!--$ nextline -->
hello {s.name}
"""
    let serverJson = """
{"name": "world"}
"""
    let eResultLines = @[
      "hello world\n"
    ]
    check testProcessTemplate(templateContent = templateContent, serverJson =
        serverJson, eResultLines = eResultLines)

  test "readme Drink Tea":
    let templateContent = """
<!--$ nextline -->
Drink {s.drink} -- {s.drinkType} is my favorite.
"""
    let serverJson = """
{
  "drink": "tea",
  "drinkType": "Earl Grey"
}
"""
    let eResultLines = @[
      "Drink tea -- Earl Grey is my favorite.\n"
    ]
    check testProcessTemplate(templateContent = templateContent, serverJson =
        serverJson, eResultLines = eResultLines)

  test "readme shared header":
    let templateContent = """
<!--$ replace t.content=o.header -->
<!--$ endblock -->
"""

    let sharedCode = """
o.header = $1
<!doctype html>
<html lang="en">
$1
""" % tripleQuotes

    let eResultLines = splitNewLines """
<!doctype html>
<html lang="en">
"""

    check testProcessTemplate(templateContent = templateContent, sharedCode =
        sharedCode, eResultLines = eResultLines)

  test "readme shared header 2":
    let templateContent = """
<!--$ replace t.content=o.header -->
<!DOCTYPE html>
<html lang="{s.languageCode}" dir="{s.languageDirection}">
<head>
<meta charset="UTF-8"/>
<title>{s.title}</title>
<--$ endblock -->
"""

    let serverJson = """
{
"languageCode": "en",
"languageDirection": "ltr",
"title": "Teas in England"
}
"""
    let sharedCode = """
o.header = $1
<!DOCTYPE html>
<html lang="{s.languageCode}" dir="{s.languageDirection}">
<head>
<meta charset="UTF-8"/>
<title>{s.title}</title>
$1
""" % tripleQuotes

    let eResultLines = splitNewLines """
<!DOCTYPE html>
<html lang="en" dir="ltr">
<head>
<meta charset="UTF-8"/>
<title>Teas in England</title>
"""
    check testProcessTemplate(templateContent = templateContent,
      serverJson = serverJson, sharedCode = sharedCode,
      eResultLines = eResultLines)

  test "readme shared header 3":


    let templateContent = """
<!--$ replace t.content=o.header -->
<!DOCTYPE html>
<html lang="{s.languageCode}" dir="{s.languageDirection}">
<head>
<meta charset="UTF-8"/>
<title>{s.title}</title>
<--$ endblock -->
"""

    let serverJson = """
{
"languageCode": "en",
"languageDirection": "ltr",
"title": "Teas in England"
}
"""

    let sharedCode = """
o.header = $1
<!DOCTYPE html>
<html lang="{s.languageCode}" dir="{s.languageDirection}">
<head>
<meta charset="UTF-8"/>
<title>{s.title}</title>
$1
""" % tripleQuotes

    let eResultLines = splitNewLines """
<!DOCTYPE html>
<html lang="en" dir="ltr">
<head>
<meta charset="UTF-8"/>
<title>Teas in England</title>
"""
    check testProcessTemplate(templateContent = templateContent,
      serverJson = serverJson, sharedCode = sharedCode,
      eResultLines = eResultLines)

  test "readme comment":

    let templateContent = """
<!--$ # How you make tea. -->
There are five main groups of teas:
white, green, oolong, black, and pu'erh.
You make Oolong Tea in five time
intensive steps.
"""
    let eResultLines = splitNewLines """
There are five main groups of teas:
white, green, oolong, black, and pu'erh.
You make Oolong Tea in five time
intensive steps.
"""
    check testProcessTemplate(templateContent = templateContent, eResultLines = eResultLines)

  test "readme continuation":

    let templateContent = """
$$ nextline
$$ : tea = "Earl Grey"
$$ : tea2 = "Masala chai"
{tea}, {tea2}
"""
    let eResultLines = @[
      "Earl Grey, Masala chai\n",
    ]
    check testProcessTemplate(templateContent = templateContent, eResultLines = eResultLines)

  test "Invalid statement":

    let templateContent = """
<!--$ nextline +-->
<!--$ : tea = "Earl Grey" +-->
<!--$ : tea2 = "Masala chai"-->
{tea}, {tea2}
"""
    let eResultLines = @[
      "{tea}, {tea2}\n"
    ]

    let eErrLines = splitNewLines """
template.html(1): w31: Unused text at the end of the statement.
statement: tea = "Earl Grey" tea2 = "Masala chai"
                             ^
template.html(4): w58: The replacement variable doesn't exist: tea.
template.html(4): w58: The replacement variable doesn't exist: tea2.
"""
    check testProcessTemplate(templateContent = templateContent, eRc = 1, eResultLines
          = eResultLines, eErrLines = eErrLines)

  test "readme: commands in a replacement block":

    let templateContent = """
<!--$ block -->
<!--$ # this is not a comment, just text -->
fake nextline
<!--$ nextline -->
<!--$ endblock -->
"""
    let eResultLines = splitNewLines """
<!--$ # this is not a comment, just text -->
fake nextline
<!--$ nextline -->
"""
    check testProcessTemplate(templateContent = templateContent, eResultLines = eResultLines)

  test "json variables":

    let templateContent = """
<!--$ block -->
<!--$ : serverElements = len(s) -->
<!--$ : codeElements = len(o) -->
The server has {serverElements} elements
and the shared code has {codeElements}.
<!--$ endblock -->
"""
    let serverJson = """
{
 "tea1": "Black",
 "tea2": "Green",
 "tea3": "Oolong",
 "tea4": "Sencha",
 "tea5": "Herbal"
}
"""
    let eResultLines = splitNewLines """
The server has 5 elements
and the shared code has 0.
"""
    check testProcessTemplate(templateContent = templateContent,
      serverJson = serverJson, eResultLines = eResultLines)

#   test "output admin var missing":

#     let templateContent = """
# <!--$ nextline +-->
# <!--$ : t.output = if( +-->
# <!--$ :   exists("s.admin"), "skip", +-->
# <!--$ :   "stderr"); +-->
# <!--$ : msg = concat( +-->
# <!--$ :   template(), "(", +-->
# <!--$ :   getLineNumber(), ")", +-->
# <!--$ :   "missing admin var") -->
# {msg}
# """
#     let eResultLines = @[
#       "template.html(45): missing admin var"
#     ]
#     check testProcessTemplate(templateContent = templateContent, eResultLines = eResultLines)

#   test "output no output":

#     let templateContent = """
# <!--$ nextline +-->
# <!--$ : t.output = if( +-->
# <!--$ :   exists("s.admin"), "skip", +-->
# <!--$ :   "stderr"); +-->
# <!--$ : msg = concat( +-->
# <!--$ :   template(), "(", +-->
# <!--$ :   getLineNumber(), ")", +-->
# <!--$ :   "missing admin var") -->
# {msg}
# """
#     check testProcessTemplate(templateContent = templateContent)

  test "not a command":

    let templateContent = """
#$ block +
#$ : cond1 = notfunction(4, 5)
#$ : cond3 = hello(5, 4)
#$ endblock
"""
    let eErrLines = splitNewLines """
template.html(1): w205: The variable 'notfunction' wasn't found in the l or f dictionaries.
statement: cond1 = notfunction(4, 5)
                               ^
template.html(3): w205: The variable 'hello' wasn't found in the l or f dictionaries.
statement: cond3 = hello(5, 4)
                         ^
"""
    check testProcessTemplate(templateContent = templateContent, eRc = 1, eErrLines = eErrLines)

  test "one line content":

    let templateContent = """
#$ block
content
#$ endblock
"""
    let eResultLines = splitNewLines """
content
"""
    check testProcessTemplate(templateContent = templateContent, eResultLines = eResultLines)

  test "zero line of content":
    let templateContent = """
#$ block
#$ endblock
"""
    check testProcessTemplate(templateContent = templateContent)

# test "cmp example":

#     let templateContent = """
# #$ block +
# #$ : cond1 = cmp(4, 5); +
# #$ : cond2 = cmp(2, 2); +
# #$ : cond3 = cmp(5, 4)
# cmp(4, 5) returns {cond1}
# cmp(2, 2) returns {cond2}
# cmp(5, 4) returns {cond3}
# #$ endblock
# """
#     let eResultLines = @[
#       "cmp(4, 5) returns -1",
#       "cmp(2, 2) returns 0",
#       "cmp(5, 4) returns 1",
#     ]
#     check testProcessTemplate(templateContent = templateContent, eResultLines = eResultLines)

  test "repeat of 0":
    let templateContent = """
before
<!--$ block t.repeat = 0 -->
My test block
with a few lines
of text.
<!--$ endblock -->
after
"""
    let eResultLines = splitNewLines """
before
after
"""
    check testProcessTemplate(templateContent = templateContent, eResultLines = eResultLines)

  test "repeat with warning":
    let templateContent = """
before
asdf
<!--$ block t.repeat = 5 -->
<!--$ : var = get(s.nums, t.row)-->
line one test replacement block.
line two: {var}
<!--$ endblock -->
after
"""
    let serverJson = """{"nums": [5, 6]}"""

    let eResultLines = splitNewLines """
before
asdf
line one test replacement block.
line two: 5
line one test replacement block.
line two: 6
line one test replacement block.
line two: {var}
line one test replacement block.
line two: {var}
line one test replacement block.
line two: {var}
after
"""

    let eErrLines = splitNewLines """
template.html(4): w54: The list index 2 is out of range.
statement: var = get(s.nums, t.row)
                             ^
template.html(6): w58: The replacement variable doesn't exist: var.
template.html(4): w54: The list index 3 is out of range.
statement: var = get(s.nums, t.row)
                             ^
template.html(6): w58: The replacement variable doesn't exist: var.
template.html(4): w54: The list index 4 is out of range.
statement: var = get(s.nums, t.row)
                             ^
template.html(6): w58: The replacement variable doesn't exist: var.
"""
    check testProcessTemplate(templateContent = templateContent, eRc = 1,
      serverJson = serverJson, eResultLines = eResultLines, eErrLines = eErrLines)

  test "output to log":
    let templateContent = """
<!--$ nextline t.output = "log" -->
hello {s.name}
"""
    let serverJson = """
{"name": "world"}
"""

    let eLogLines = splitNewLines """
XXXX-XX-XX XX:XX:XX.XXX; startingvars.nim(X*); Json filename: server.json
XXXX-XX-XX XX:XX:XX.XXX; startingvars.nim(X*); Json file size: 18
XXXX-XX-XX XX:XX:XX.XXX; template.html(X*); hello world
"""
    check testProcessTemplate(templateContent = templateContent, serverJson =
        serverJson, eLogLines = eLogLines)

  test "output to stderr":
    let templateContent = """
<!--$ nextline t.output = "stderr" -->
Hello {s.name}!
"""
    let serverJson = """
{"name": "World"}
"""
    let eErrLines = splitNewLines """
Hello World!
"""
    check testProcessTemplate(templateContent = templateContent, serverJson =
        serverJson, eErrLines = eErrLines)

  test "output to result":
    let templateContent = """
<!--$ nextline t.output = "result" -->
Hello {s.name}!
"""
    let serverJson = """
{"name": "World"}
"""
    let eResultLines = splitNewLines """
Hello World!
"""
    check testProcessTemplate(templateContent = templateContent, serverJson =
        serverJson, eResultLines = eResultLines)

  test "output to skip":
    let templateContent = """
<!--$ nextline t.output = "skip" -->
Hello {s.name}!
"""
    let serverJson = """
{"name": "World"}
"""
    check testProcessTemplate(templateContent = templateContent, serverJson =
        serverJson)

  test "output to something":
    let templateContent = """
<!--$ nextline t.output = "something"-->
Hello {s.name}!
"""
    let serverJson = """
{"name": "World"}
"""

    let eResultLines = splitNewLines """
Hello World!
"""

    let eErrLines = splitNewLines """
template.html(1): w41: Invalid t.output value, use: "result", "stdout", "stderr", "log", or "skip".
statement: t.output = "something"
           ^
"""
    check testProcessTemplate(templateContent = templateContent, serverJson =
        serverJson, eErrLines = eErrLines, eResultLines = eResultLines, eRc = 1)

  test "assign to server":
    let templateContent = """
<!--$ nextline t.server = "something"-->
Hello {s.name}!
"""
    let serverJson = """
{"name": "World"}
"""
    let eResultLines = splitNewLines """
Hello World!
"""
    let eErrLines = splitNewLines """
template.html(1): w40: Invalid tea variable: server.
statement: t.server = "something"
           ^
"""
    check testProcessTemplate(templateContent = templateContent, serverJson =
        serverJson, eErrLines = eErrLines, eResultLines = eResultLines, eRc = 1)

  test "invalid namespace":
    let templateContent = """
<!--$ nextline y.var = "something"-->
Hello {s.name}!
"""
    let serverJson = """
{"name": "World"}
"""
    let eResultLines = splitNewLines """
Hello World!
"""
    let eErrLines = splitNewLines """
template.html(1): w36: The variable 'y' does not exist.
statement: y.var = "something"
           ^
"""
    check testProcessTemplate(templateContent = templateContent, serverJson =
        serverJson, eErrLines = eErrLines, eResultLines = eResultLines, eRc = 1)

  test "assign repeat more than maxRepeat":
    # Test that you cannot assign t.repeat more than maxRepeat.
    let templateContent = """
<!--$ nextline t.repeat = 200-->
{t.row}
"""
    let eResultLines = splitNewLines """
0
"""
    let eErrLines = splitNewLines """
template.html(1): w44: The variable t.repeat must be an integer between 0 and t.maxRepeat.
statement: t.repeat = 200
           ^
"""
    check testProcessTemplate(templateContent = templateContent,
        eErrLines = eErrLines, eResultLines = eResultLines, eRc = 1)

  test "assign maxRepeat less than repeat":
    # Test that you cannot assign t.maxRepeat less than repeat.

    let templateContent = """
<!--$ nextline t.repeat = 4 -->
<!--$ : t.maxRepeat=3-->
{t.row}
"""
    let eResultLines = splitNewLines """
0
1
2
3
"""
    let eErrLines = splitNewLines """
template.html(2): w67: The maxRepeat value must be greater than or equal to t.repeat.
statement: t.maxRepeat=3
           ^
template.html(2): w67: The maxRepeat value must be greater than or equal to t.repeat.
statement: t.maxRepeat=3
           ^
template.html(2): w67: The maxRepeat value must be greater than or equal to t.repeat.
statement: t.maxRepeat=3
           ^
template.html(2): w67: The maxRepeat value must be greater than or equal to t.repeat.
statement: t.maxRepeat=3
           ^
"""
    check testProcessTemplate(templateContent = templateContent,
        eErrLines = eErrLines, eResultLines = eResultLines, eRc = 1)

  test "content not set for replace block":
    let templateContent = """
<!--$ replace -->
Replace command with t.content set
should behave like a block command with
a warning message.
<!--$ endblock -->
"""
    let eResultLines = splitNewLines """
Replace command with t.content set
should behave like a block command with
a warning message.
"""
    let eErrLines = splitNewLines """
template.html(1): w68: The t.content variable is not set for the replace command, treating it like the block command.
"""
    check testProcessTemplate(templateContent = templateContent,
        eErrLines = eErrLines, eResultLines = eResultLines, eRc = 1)


  test "readme join tea party":
    let templateContent = """
<!--$ block -->
Join our tea party on
{s.weekday} at {s.name}'s
house at {s.time}.
<!--$ endblock -->
"""

    let serverJson = """
{
  "weekday": "Friday",
  "name": "John",
  "time": "5:00 pm"
}
"""

    let eResultLines = splitNewLines """
Join our tea party on
Friday at John's
house at 5:00 pm.
"""
    check testProcessTemplate(templateContent = templateContent,
        serverJson = serverJson, eResultLines = eResultLines, eRc = 0)

  test "readme repeat example":
    let templateContent = """
<!--$ nextline t.repeat = len(s.tea_list) -->
<!--$ : tea = get(s.tea_list, t.row) -->
* {tea}
"""

    let serverJson = """
{
"tea_list": [
  "Black",
  "Green",
  "Oolong",
  "Sencha",
  "Herbal"
]
}
"""

    let eResultLines = splitNewLines """
* Black
* Green
* Oolong
* Sencha
* Herbal
"""
    check testProcessTemplate(templateContent = templateContent,
        serverJson = serverJson, eResultLines = eResultLines, eRc = 0)

  test "readme repeat = 0":
    let templateContent = """
<h3>Tea</h3>
<ul>
<!--$ nextline t.repeat = len(s.teaList) -->
<!--$ : tea = get(s.teaList, t.row) -->
<li>{tea}</li>
<!--$ block t.repeat = 0 -->
<li>Black</li>
<li>Green</li>
<li>Oolong</li>
<li>Sencha</li>
<li>Herbal</li>
<!--$ endblock -->
</ul>
"""

    let serverJson = """
{
"teaList": [
  "Chamomile",
  "Chrysanthemum",
  "White",
  "Puer"
]
}
"""

    let eResultLines = splitNewLines """
<h3>Tea</h3>
<ul>
<li>Chamomile</li>
<li>Chrysanthemum</li>
<li>White</li>
<li>Puer</li>
</ul>
"""
    check testProcessTemplate(templateContent = templateContent,
        serverJson = serverJson, eResultLines = eResultLines, eRc = 0)

  test "readme undefined variable":
    let templateContent = """
<!--$ block -->
You're a {s.webmaster},
I'm a {s.teaMaster}!
<!--$ endblock -->
"""

    let serverJson = """
{
 "webmaster": "html wizard"
}
"""

    let eErrLines = splitNewLines """
template.html(3): w58: The replacement variable doesn't exist: s.teaMaster.
"""

    let eResultLines = splitNewLines """
You're a html wizard,
I'm a {s.teaMaster}!
"""

    check testProcessTemplate(templateContent = templateContent, eErrLines = eErrLines,
      serverJson = serverJson, eResultLines = eResultLines, eRc = 1)

  test "show version number":
    let templateContent = """
<!--$ nextline -->
statictea version number: {t.version}
"""
    let eResultLines = @[
      "statictea version number: 0.1.0\n" % staticteaVersion
    ]
    check testProcessTemplate(templateContent = templateContent, eResultLines = eResultLines)

  test "missing slash":
    let templateContent = """
$$ nextline
$$ : num = len(case(5,
$$ :  5, "five", "one"))
{num}
"""
    let eResultLines = splitNewLines """
{num}
"""
    let eErrLines = splitNewLines """
template.html(2): w33: Expected a string, number, variable, list or condition.
statement: num = len(case(5,
                            ^
template.html(3): w29: Statement does not start with a variable name.
statement: 5, "five", "one"))
           ^
template.html(4): w58: The replacement variable doesn't exist: num.
"""
    check testProcessTemplate(templateContent = templateContent, eErrLines = eErrLines,
      eResultLines = eResultLines, eRc = 1)


  test "ending blank lines":
    let templateContent = """
hello
$$ block t.repeat = 2
$$ : tea = "Black"

* {tea}
$$ endblock
"""
    let eResultLines = splitNewLines """
hello

* Black

* Black
"""
    check testProcessTemplate(templateContent = templateContent,
        eResultLines = eResultLines, eRc = 0)

  test "overwrite global variable":
    let templateContent = """
$$ block
$$ : t.repeat = 2
$$ : g.var = t.row
{g.var}
$$ endblock
"""
    let eResultLines = splitNewLines """
0
0
"""
    let eErrLines = splitNewLines """
template.html(3): w95: You cannot assign to an existing variable.
statement: g.var = t.row
           ^
"""
    check testProcessTemplate(templateContent = templateContent, eErrLines = eErrLines,
      eResultLines = eResultLines, eRc = 1)

  test "append to a list":
    let templateContent = """
$$ block
$$ : teas &= "black"
$$ : teas &= "green"
$$ : a = get(teas, 0)
$$ : b = get(teas, 1)
teas => ["{a}","{b}"]
$$ endblock
"""
    let eResultLines = splitNewLines """
teas => ["black","green"]
"""
    check testProcessTemplate(templateContent = templateContent,
      eResultLines = eResultLines, eRc = 0)

  test "getTeaArgs empty":
    var args: Args
    let eVarRep = """
help = false
version = false
update = false
log = false
repl = false
serverList = []
codeList = []
resultFilename = ""
templateFilename = ""
logFilename = ""
prepostList = []"""
    check testGetTeaArgs(args, eVarRep)

  test "getTeaArgs multiple":
    var args: Args
    args.serverList = @["server.json"]
    args.codeList = @["shared.tea"]
    args.templateFilename = "template.html"
    args.resultFilename = "result.html"
    let value = getTeaArgs(args)
    let targs = value.dictv
    let serverList = targs["serverList"]
    let templateFilename = targs["templateFilename"]
    let resultFilename = targs["resultFilename"]
    check serverList == newValue(@["server.json"])
    check resultFilename == newValue("result.html")
    check templateFilename == newValue("template.html")


  test "t variables":
    let templateContent = """
$$ block
$$ : args = t.args
$$ : help = get(args, "help")
$$ : help2 = args.help
$$ : help3 = t.args.help
help => {help}
help2 => {help2}
help3 => {help3}
$$ endblock
"""
    let serverJson = """
{
}
"""

    let eResultLines = splitNewLines """
help => false
help2 => false
help3 => false
"""
    check testProcessTemplate(templateContent = templateContent,
        serverJson = serverJson, eResultLines = eResultLines, eRc = 0)

  test "access l dictionary":
    let templateContent = """
$$ nextline e = exists(l, "x")
e => {e}
"""
    let eResultLines = @[
      "e => false\n"
    ]
    check testProcessTemplate(templateContent = templateContent,
        eResultLines = eResultLines)

  test "access l dictionary 2":
    let templateContent = """
$$ nextline
$$ : x = 5
$$ : e = exists(l, "x")
e => {e}
"""
    let eResultLines = @[
      "e => true\n"
    ]
    check testProcessTemplate(templateContent = templateContent,
        eResultLines = eResultLines)

  test "0 maxLines":
    let templateContent = """
$$ block t.maxLines = 0
one
two
$$ endblock
"""
    let eResultLines = @[
      "one\n",
      "two\n",
    ]

    let eErrLines = splitNewLines """
template.html(1): w42: MaxLines must be an integer greater than 1.
statement: t.maxLines = 0
           ^
"""
    check testProcessTemplate(templateContent = templateContent, eErrLines = eErrLines,
      eResultLines = eResultLines, eRc = 1)



  test "more than maxLines":
    let templateContent = """
$$ block t.maxLines = 2
{t.row} one
{t.row} two
{t.row} three
$$ endblock
end of file
"""
    let eResultLines = @[
      "0 one\n",
      "0 two\n",
      "{t.row} three\n",
      "$$ endblock\n",
      "end of file\n",
    ]

    let eErrLines = @[
      "template.html(4): w60: Read t.maxLines replacement block lines without finding the endblock.\n",
      "template.html(5): w144: The endblock command does not have a matching block command.\n",
    ]

    check testProcessTemplate(templateContent = templateContent,
      eErrLines = eErrLines, eResultLines = eResultLines, eRc = 1)

  test "one more than maxLines":
    let templateContent = """
$$ block t.maxLines = 2
one
two
three
$$ endblock
"""
    let eResultLines = @[
      "one\n",
      "two\n",
      "three\n",
      "$$ endblock\n",
    ]

    let eErrLines = @[
      "template.html(4): w60: Read t.maxLines replacement block lines without finding the endblock.\n",
      "template.html(5): w144: The endblock command does not have a matching block command.\n",
    ]

    check testProcessTemplate(templateContent = templateContent,
      eResultLines = eResultLines, eErrLines = eErrLines, eRc = 1)

  test "one less than maxLines":
    let templateContent = """
$$ block t.maxLines = 2
one
$$ endblock
"""
    let eResultLines = @[
      "one\n",
    ]
    check testProcessTemplate(templateContent = templateContent,
        eResultLines = eResultLines)

  test "match maxLines":
    let templateContent = """
$$ block t.maxLines = 2
one
two
$$ endblock
"""
    let eResultLines = @[
      "one\n",
      "two\n",
    ]
    check testProcessTemplate(templateContent = templateContent,
        eResultLines = eResultLines)

  test "Continue a string":
    let templateContent = """
$$ block str = "This is a long+
$$ : string."
str => {str}
$$ endblock
"""
    let eResultLines = @[
      "str => This is a longstring.\n",
    ]
    check testProcessTemplate(templateContent = templateContent,
        eResultLines = eResultLines)

  test "Continue a string ending spaces":
    let templateContent = """
$$ block str = "This is a long   +
$$ : string."
str => {str}
$$ endblock
"""
    let eResultLines = @[
      "str => This is a long   string.\n",
    ]
    check testProcessTemplate(templateContent = templateContent,
        eResultLines = eResultLines)

  test "Continue a string leading spaces":
    let templateContent = """
$$ block str = "This is a long+
$$ :    string."
str => {str}
$$ endblock
"""
    let eResultLines = @[
      "str => This is a long   string.\n",
    ]
    check testProcessTemplate(templateContent = templateContent,
        eResultLines = eResultLines)


  test "repeat 0 short circuit":
    let templateContent = """
$$ block t.repeat = 0
$$ : a = warn("not hit")
repeat short circuit
$$ endblock
"""
    check testProcessTemplate(templateContent = templateContent)

  test "return short circuit":
    let templateContent = """
$$ block a = return("stop")
$$ : a = warn("not hit")
repeat short circuit
$$ endblock
"""
    check testProcessTemplate(templateContent = templateContent)

  test "return short circuit 2":
    let templateContent = """
$$ block a = return("")
$$ : a = warn("not hit")
return short circuit 2
$$ endblock
"""
    let eResultLines = @[
      "return short circuit 2\n",
    ]
    check testProcessTemplate(templateContent = templateContent,
      eResultLines = eResultLines)

  test "return short circuit 3":
    let templateContent = """
$$ block t.repeat = 2
$$ : if0(t.row, return("skip"))
return short circuit
$$ endblock
"""
    let eResultLines = @[
      "return short circuit\n",
    ]
    check testProcessTemplate(templateContent = templateContent,
      eResultLines = eResultLines)

  test "return short circuit 4":
    let templateContent = """
$$ block t.repeat = 3
$$ : if0(cmp(1,t.row), return("stop"))
{t.row}) return short circuit
$$ endblock
"""
    let eResultLines = @[
      "0) return short circuit\n",
    ]
    check testProcessTemplate(templateContent = templateContent,
      eResultLines = eResultLines)

  test "return short circuit 5":
    let templateContent = """
$$ block t.repeat = 3
$$ : if0(cmp(1,t.row), return("skip"))
{t.row}) return short circuit
$$ endblock
"""
    let eResultLines = @[
      "0) return short circuit\n",
      "2) return short circuit\n",
    ]
    check testProcessTemplate(templateContent = templateContent,
      eResultLines = eResultLines)

  test "return short circuit 6":
    let templateContent = """
$$ block t.repeat = 3
$$ : if0(t.row, return(""))
$$ : if0(t.row, warn("not hit"))
{t.row}) return short circuit
$$ endblock
"""
    let eResultLines = @[
      "0) return short circuit\n",
      "1) return short circuit\n",
      "2) return short circuit\n",
    ]
    check testProcessTemplate(templateContent = templateContent,
      eResultLines = eResultLines)

  test "return short circuit 7":
    let templateContent = """
$$ block t.repeat = 3
$$ : if((t.row == 1), return("skip"))
$$ : if((t.row == 2), warn("row 2 warning"))
{t.row}
$$ endblock
"""
    let eResultLines = @[
      "0\n",
      "2\n"
    ]
    let eErrLines = @[
      "template.html(3): row 2 warning\n"
    ]
    check testProcessTemplate(templateContent = templateContent,
      eResultLines = eResultLines, eErrLines = eErrLines, eRc = 1)

  test "replace with empty string":
    let templateContent = """
<!--$ replace t.content="" -->
abc
<!--$ endblock -->
after
"""
    let eResultLines = splitNewLines """
after
"""
    check testProcessTemplate(templateContent = templateContent,
        eResultLines = eResultLines)

  test "run function variable":
    let templateContent = """
$$ block
$$ : myCmp = cmp
$$ : b = myCmp(3, 2)
$$ : myCmp2 = get(cmp, 0)
$$ : d = myCmp2(1.1, 2.2)
{b}
{d}
<!--$ endblock -->
"""
    let eResultLines = splitNewLines """
1
-1
"""
    check testProcessTemplate(templateContent = templateContent,
        eResultLines = eResultLines)

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
