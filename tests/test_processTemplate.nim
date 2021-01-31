
import unittest
import processTemplate
import env
import args
import os
import readlines

proc testProcessTemplate(templateContent: string = "",
    serverJson: string = "",
    sharedJson: string = "",
    eRc = 0,
    eResultLines: seq[string] = @[],
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[]
  ): bool =
  ## Test the processTemplate procedure.

  # Open err, out and log streams.
  var env = openEnvTest("_testProcessTemplate.log", templateContent)

  var args: Args

  # Create the server json file.
  if serverJson != "":
    let serverFilename = "server.json"
    createFile(serverFilename, serverJson)
    args.serverList = @[serverFilename]

  # Create the shared json file.
  if sharedJson != "":
    let sharedFilename = "shared.json"
    createFile(sharedFilename, sharedJson)
    args.sharedList = @[sharedFilename]

  # Process the template and write out the result.
  let rc = processTemplate(env, args)

  result = env.readCloseDeleteCompare(eLogLines, eErrLines, eOutLines,
    eResultLines = eResultLines)

  if not expectedItem("rc", rc, eRc):
    result = false

  discard tryRemoveFile("server.json")
  discard tryRemoveFile("shared.json")

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

  test "Hello World":
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

  test "Drink Tea":
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

  test "Shared Header":
    let templateContent = """
<!--$ replace t.content=h.header -->
<!--$ endblock -->
"""

    let sharedJson = """
{
  "header": "<!doctype html>\n<html lang=\"en\">\n"
}
"""

    let eResultLines = splitNewLines """
<!doctype html>
<html lang="en">
"""

    check testProcessTemplate(templateContent = templateContent, sharedJson =
        sharedJson, eResultLines = eResultLines)

  test "Shared Header2":
    let templateContent = """
<!--$ replace t.content=h.header -->
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

    let sharedJson = """
{
  "header": "<!DOCTYPE html>
<html lang=\"{s.languageCode}\" dir=\"{s.languageDirection}\">
<head>
<meta charset=\"UTF-8\"/>
<title>{s.title}</title>\n"
}
"""

    let eResultLines = splitNewLines """
<!DOCTYPE html>
<html lang="en" dir="ltr">
<head>
<meta charset="UTF-8"/>
<title>Teas in England</title>
"""
    check testProcessTemplate(templateContent = templateContent, serverJson = serverJson, sharedJson =
        sharedJson, eResultLines = eResultLines)

  test "Comment":

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

  test "Continuation":

    let templateContent = """
<!--$ nextline \-->
<!--$ : tea = 'Earl Grey'; \-->
<!--$ : tea2 = 'Masala chai' -->
{tea}, {tea2}
"""
    let eResultLines = @[
      "Earl Grey, Masala chai\n",
    ]
    check testProcessTemplate(templateContent = templateContent, eResultLines = eResultLines)

  test "Invalid statement":

    let templateContent = """
<!--$ nextline \-->
<!--$ : tea = 'Earl Grey' \-->
<!--$ : tea2 = 'Masala chai'-->
{tea}, {tea2}
"""
    let eResultLines = @[
      "{tea}, {tea2}\n"
    ]

    let eErrLines = splitNewLines """
template.html(1): w31: Unused text at the end of the statement.
statement: tea = 'Earl Grey' tea2 = 'Masala chai'
                             ^
template.html(4): w58: The replacement variable doesn't exist: tea.
template.html(4): w58: The replacement variable doesn't exist: tea2.
"""
    check testProcessTemplate(templateContent = templateContent, eRc = 1, eResultLines
          = eResultLines, eErrLines = eErrLines)

  test "commands in a replacement block":

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
<!--$ block \-->
<!--$ : serverElements = len(t.server); \-->
<!--$ : jsonElements = len(t.shared) -->
The server has {serverElements} elements
and the shared json has {jsonElements}.
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
and the shared json has 0.
"""
    check testProcessTemplate(templateContent = templateContent, serverJson = serverJson, eResultLines = eResultLines)

#   test "output admin var missing":

#     let templateContent = """
# <!--$ nextline \-->
# <!--$ : t.output = if( \-->
# <!--$ :   exists("s.admin"), "skip", \-->
# <!--$ :   "stderr"); \-->
# <!--$ : msg = concat( \-->
# <!--$ :   template(), "(", \-->
# <!--$ :   getLineNumber(), ")", \-->
# <!--$ :   "missing admin var") -->
# {msg}
# """
#     let eResultLines = @[
#       "template.html(45): missing admin var"
#     ]
#     check testProcessTemplate(templateContent = templateContent, eResultLines = eResultLines)

#   test "output no output":

#     let templateContent = """
# <!--$ nextline \-->
# <!--$ : t.output = if( \-->
# <!--$ :   exists("s.admin"), "skip", \-->
# <!--$ :   "stderr"); \-->
# <!--$ : msg = concat( \-->
# <!--$ :   template(), "(", \-->
# <!--$ :   getLineNumber(), ")", \-->
# <!--$ :   "missing admin var") -->
# {msg}
# """
#     check testProcessTemplate(templateContent = templateContent)

  test "not a command":

    let templateContent = """
#$ block \
#$ : cond1 = notfunction(4, 5); \
#$ : cond3 = hello(5, 4)
#$ endblock
"""
    let eErrLines = splitNewLines """
template.html(1): w51: Not a function: notfunction.
statement: cond1 = notfunction(4, 5)
                   ^
template.html(2): w51: Not a function: hello.
statement:  cond3 = hello(5, 4)
                    ^
"""
    check testProcessTemplate(templateContent = templateContent, eRc = 1, eErrLines = eErrLines)

# test "cmp example":

#     let templateContent = """
# #$ block \
# #$ : cond1 = cmp(4, 5); \
# #$ : cond2 = cmp(2, 2); \
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
<!--$ block t.repeat = 5; var = get(s.nums, t.row)-->
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
template.html(3): w54: The list index 2 out of range.
template.html(3): w48: Invalid statement, skipping it.
statement:  var = get(s.nums, t.row)
                      ^
template.html(5): w58: The replacement variable doesn't exist: var.
template.html(3): w54: The list index 3 out of range.
template.html(3): w54: The list index 4 out of range.
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
XXXX-XX-XX XX:XX:XX.XXX; replacement.nim(X*); hello world
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
template.html(1): w41: Invalid t.output value, use: "result", "stderr", "log", or "skip".
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
template.html(1): w39: You cannot change the server tea variable.
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
template.html(1): w35: The variable namespace 'y.' does not exist.
statement: y.var = "something"
           ^
"""
    check testProcessTemplate(templateContent = templateContent, serverJson =
        serverJson, eErrLines = eErrLines, eResultLines = eResultLines, eRc = 1)



# todo: when t.content is not set for a replace block.
# todo: readme examples
# todo: test maxLines
# todo: test maxRepeat
