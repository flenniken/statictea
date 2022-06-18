import std/unittest
import std/os
import std/strutils
import std/options
import std/streams
import codefile
import variables
import env
import vartypes
import readlines
import sharedtestcode
import runCommand

proc testAddText*(beginning: string, ending: string, found: Found): bool =
  var text: string

  let line = beginning & ending
  addText(line, found, text)
  result = true
  var expected: string
  if found in [triple, triple_n, triple_crlf]:
    expected = beginning & tripleQuotes
  else:
    expected = beginning
  if not expectedItem("'$1, '" % [line, $found], text, expected):
    result = false

proc testMatchTripleOrPlusSign(line: string, eFound: Found = nothing): bool =
  let found = matchTripleOrPlusSign(line)
  result = true
  if not expectedItem("'$1'" % line, found, eFound):
    result = false

proc testReadStatement(
    content: string = "",
    eText: string = "",
    eLineNum: Natural = 1,
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[],
    showLog: bool = false
  ): bool =

  # Open err and log streams.
  var env = openEnvTest("_testReadStatement.log")

  # Create a LineBuffer for reading the file content.
  var inStream = newStringStream(content)
  var lineBufferO = newLineBuffer(inStream)
  check lineBufferO.isSome
  var lb = lineBufferO.get()

  # Read the statement.
  let statementO = readStatement(env, lb)

  result = true
  if not env.readCloseDeleteCompare(eLogLines, eErrLines, showLog = showLog):
    result = false

  var eStatementO: Option[Statement]
  if eText != "":
    eStatementO = some(newStatement(eText, eLineNum))

  if not expectedItem("content:\n" & content, statementO, eStatementO):
    return false

proc testRunCodeFile(
    content: string = "",
    variables: var Variables,
    eVarRep: string = "",
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[],
    showLog: bool = false
  ): bool =

  # Open err and log streams.
  var env = openEnvTest("_testRunCodeFile.log")

  let filename = "testcode.txt"
  createFile(filename, content)
  defer: discard tryRemoveFile(filename)

  runCodeFile(env, filename, variables)

  result = true
  if not env.readCloseDeleteCompare(eLogLines, eErrLines, showLog = showLog):
    result = false

  let varRep = dotNameRep(variables)

  # Remove the starting variables from the result.
  let startingVars = emptyVariables()
  let startingVarsRep = dotNameRep(startingVars)
  let startingLines = splitLines(startingVarsRep)
  let gotLines = splitLines(varRep)

  var newLines: seq[string]
  for line in gotLines:
    if not (line in startingLines):
      newLines.add(line)
  let newVarRep = newLines.join("\n")

  if newVarRep != eVarRep:
    echo "got:"
    echo newVarRep
    echo "expected:"
    echo eVarRep
    result = false

suite "codefile.nim":

  test "addText":
    for beginning in ["", "a", "ab", "abc", "abcd", "abcde", "abcdef"]:
      check testAddText(beginning, "", nothing)
      check testAddText(beginning, "\n", newline)
      check testAddText(beginning, "\r\n", crlf)

      check testAddText(beginning, "+", plus)
      check testAddText(beginning, "+\n", plus_n)
      check testAddText(beginning, "+\r\n", plus_crlf)

      check testAddText(beginning, "$1" % tripleQuotes, triple)
      check testAddText(beginning, "$1\n" % tripleQuotes, triple_n)
      check testAddText(beginning, "$1\r\n" % tripleQuotes, triple_crlf)

  test "matchTripleOrPlusSign":
    let testTp = testMatchTripleOrPlusSign
    check testTp("")
    check testTp("\n", newline)
    check testTp("\r\n", crlf)

    check testTp("a = 5")
    check testTp("a = 5\n", newline)
    check testTp("a = 5\r\n", crlf)

    check testTp("a = $1" % tripleQuotes, triple)
    check testTp("a = $1\n" % tripleQuotes, triple_n)
    check testTp("a = $1\r\n" % tripleQuotes, triple_crlf)

    check testTp("a = +", plus)
    check testTp("a = +\n", plus_n)
    check testTp("a = +\r\n", plus_crlf)

    check testTp("+", plus)
    check testTp("+\n", plus_n)
    check testTp("+\r\n", plus_crlf)

    check testTp("""b = len("abc")""")
    check testTp("b = len(\"abc\")\"")
    check testTp("b = len(\"abc\")\"\"")

    check testTp("+ ")
    check testTp(" + ")
    check testTp(" $1 " % tripleQuotes)
    check testTp("$1 " % tripleQuotes)
    check testTp("abc\"")
    check testTp("abc\"\"")

  test "readStatement empty":
    check testReadStatement("", "")

  test "readStatement multiline":
    let content = """
a = $1
multiline
string
$1
b = 2
""" % tripleQuotes

    let eText = "a = $1multiline\nstring\n$1" % tripleQuotes
    check testReadStatement(content, eText, 4)

  test "readStatement no continue":
    check testReadStatement("one", "one")
    check testReadStatement("one\n", "one")
    check testReadStatement("one\r\n", "one")

  test "readStatement +":
    let content = """
a = +
5
"""
    check testReadStatement(content, "a = 5", 2)

  test "readStatement ++":
    let content = """
a = +
+
5
"""
    check testReadStatement(content, "a = 5", 3)

  test "readStatement multiline empty":
    let content = """
$1
$1
""" % tripleQuotes
    let eText = "$1$1" % tripleQuotes
    check testReadStatement(content, eText, 2)

  test "readStatement multiline a":
    let content = """
$1
a$1
""" % tripleQuotes
    let eText = "$1a$1" % tripleQuotes
    check testReadStatement(content, eText, 2)

  test "readStatement multiline a\\n":
    let content = """
$1
a
$1
""" % tripleQuotes
    let eText = "$1a\n$1" % tripleQuotes
    check testReadStatement(content, eText, 3)

  test "readStatement multiline 1":
    let content = """
a = $1
this is
a multiline+
string
$1""" % tripleQuotes
    let eText = "a = $1this is\na multiline+\nstring\n$1" % tripleQuotes
    check testReadStatement(content, eText, 5)

  test "readStatement multiline 2":
    let content = """
a = $1
this is
a multiline
string$1
""" % tripleQuotes
    let eText = "a = $1this is\na multiline\nstring$1" % tripleQuotes
    check testReadStatement(content, eText, 4)

  test "readStatement not multiline":
    let content = """
a = $1 multiline $1
b = 3
c = 4
d = 5
""" % tripleQuotes

    let eErrLines: seq[string] = splitNewLines """
template.html(1): w185: Triple quotes must always end the line.
"""
    check testReadStatement(content, eErrLines = eErrLines)

  test "readStatement multiline extra after 2":
    let content = """
a = $1 multiline
$1
""" % tripleQuotes

    let eText = "a = \"\"\" multiline"
    check testReadStatement(content, eText)

  test "runCodeFile empty":
    let content = ""
    let eVarRep = ""
    var variables = emptyVariables()
    check testRunCodeFile(content, variables, eVarRep)

  test "runCodeFile a = 5":
    let content = "a = 5"
    var variables = emptyVariables()
    check testRunCodeFile(content, variables, content)

  test "runCodeFile l.a = 5":
    let content = "l.a = 5"
    let eVarRep = """
a = 5"""
    var variables = emptyVariables()
    check testRunCodeFile(content, variables, eVarRep)

  test "runCodeFile dup":
    let content = """
a = 5
a = 6
"""
    var variables = emptyVariables()
    let eVarRep = """
a = 5"""
    let eErrLines: seq[string] = splitNewLines """
testcode.txt(2): w95: You cannot assign to an existing variable.
statement: a = 6
           ^
"""
    check testRunCodeFile(content, variables, eVarRep, eErrLines = eErrLines)

  test "runCodeFile variety":
    let content = """
a = 5
b = len("abc")
c = "string"
d = dict(["x", 1, "y", 2])
e = 3.14159
ls = [1, 2, 3]
"""
    let eVarRep = """
a = 5
b = 3
c = "string"
d.x = 1
d.y = 2
e = 3.14159
ls = [1,2,3]"""
    var variables = emptyVariables()
    check testRunCodeFile(content, variables, eVarRep)

  test "runCodeFile o.a = 5":
    let content = "o.a = 5"
    let eVarRep = """
o.a = 5"""
    var variables = emptyVariables()
    check testRunCodeFile(content, variables, eVarRep)

  test "runCodeFile append to list":
    let content = """
o.a = 5
o.l &= 1
o.l &= 2
o.l &= 3"""

    let eVarRep = """
o.a = 5
o.l = [1,2,3]"""
    var variables = emptyVariables()
    check testRunCodeFile(content, variables, eVarRep)

  test "runCodeFile +":
    let content = """
a = +
5
b = 1
"""
    let eVarRep = """
a = 5
b = 1"""
    var variables = emptyVariables()
    check testRunCodeFile(content, variables, eVarRep)

  test "runCodeFile +++":
    let content = """
a = +
5+
5+
5
b = 1
"""
    let eVarRep = """
a = 555
b = 1"""
    var variables = emptyVariables()
    check testRunCodeFile(content, variables, eVarRep)

  test "runCodeFile + at end":
    let content = """
a = +
"""
    var variables = emptyVariables()
    let eErrLines: seq[string] = splitNewLines """
template.html(2): w183: Out of lines looking for the plus sign line.
"""
    check testRunCodeFile(content, variables, eErrLines = eErrLines)

# a =     +
#      """
# this is a multiline
# string
#   """


  test "runCodeFile line number":
    let content = """
a = 5
b = 1
c = 3
d ~ 2
"""
    let eVarRep = """
a = 5
b = 1
c = 3"""
    var variables = emptyVariables()
    let eErrLines: seq[string] = splitNewLines """
template.html(4): w34: Missing operator, = or &=.
statement: d ~ 2
             ^
"""
    check testRunCodeFile(content, variables, eVarRep, eErrLines = eErrLines)

  test "runCodeFile bad triple":
    let content = """
len = 10
a = $1
 123
abc$1 q
c = 3
""" % tripleQuotes
    let eVarRep = """
len = 10
c = 3"""
    var variables = emptyVariables()

    # todo: handle multiline string error messages better. I expect ^
    # under " q".
    let eErrLines: seq[string] = splitNewLines """
template.html(4): w185: Triple quotes must always end the line.
template.html(4): w31: Unused text at the end of the statement.
statement: a = $1 123
abc$1 q

                 ^
""" % tripleQuotes
    check testRunCodeFile(content, variables, eVarRep, eErrLines = eErrLines)

# todo: test filename in warning messages.
# todo: test "skip":
# todo: test "stop":
# todo: test """ continue":
# todo: test "if":
# todo: test "multiline with ending quotes on same line":
# todo: test "no g access":
