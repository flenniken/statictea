import std/unittest
import std/tables
import std/strutils
import repl
import variables
import sharedtestcode
import functions
import version
import comparelines
import unicodes

proc testHandleReplLine(
    line: string,
    eStop = false,
    eOut: string = "",
    eLog: string = "",
    eErr: string = "",
  ): bool =

  var env = openEnvTest("_handleReplLine.log")

  # Set up variables when not passed in.
  var variables = startVariables(funcs = funcsVarDict)

  let stop = handleReplLine(env, variables, line)

  let eOutLines = splitNewLines(eOut)
  let eLogLines = splitNewLines(eLog)
  let eErrLines = splitNewLines(eErr)
  result = env.readCloseDeleteCompare(eLogLines, eErrLines, eOutLines)

  if not gotExpected($stop, $eStop):
    result = false

proc testListInColumns(names: seq[string], width: Natural, expected: string): bool =
  let got = listInColumns(names, width)
  if got == expected:
    return true
  for line in names:
    echo line
  if expected == "":
    echo "---got:"
    for gotLine in splitNewLines(got):
      echo visibleControl(gotLine, spacesToo = true)
    echo "---"
    echo "---got2:"
    echo got
    echo "---"
  else:
    echo linesSideBySide(got, expected, spacesToo = true)
  return false

suite "repl.nim":

  test "handle repl line":
    check testHandleReplLine("", false)
    check testHandleReplLine(" ", false)
    check testHandleReplLine("", false)
    check testHandleReplLine("\t", false)
    check testHandleReplLine("q", true)
    check testHandleReplLine("q   ", true)

  test "help text":
    let eOut = """
You enter statements or commands at the prompt.

Available commands:
* h — this help text
* p dotname — print a variable as dot names
* ph dotname — print function's doc comment
* pj dotname — print a variable as json
* pr dotname — print a variable like in a replacement block
* v — show the number of top variables in the top level dictionaries
* q — quit
"""
    check testHandleReplLine("h", false, eOut)

  test "invalid syntax":
    let eErr = """
q asdf
  ^
Invalid REPL command syntax, unexpected text.
"""
    check testHandleReplLine("q asdf", false, eErr = eErr)

  test "show p t.row":
    check testHandleReplLine("p t.row", false, "0\n")

  test "show pr t.row":
    check testHandleReplLine("pr t.row", false, "0\n")

  test "show pj t.row":
    check testHandleReplLine("pj t.row", false, "0\n")

  test "show p t.version":
    let quotedVersion = "\"$1\"\n" % staticteaVersion
    check testHandleReplLine("p t.version", false, quotedVersion)
    check testHandleReplLine("pj t.version", false, quotedVersion)

  test "show pr t.version":
    let version = "$1\n" % staticteaVersion
    check testHandleReplLine("pr t.version", false, version)

  test "show p t.args":
    check testHandleReplLine("p s", false, "\n")

  test "show pj t.args":
    check testHandleReplLine("pj s", false, "{}\n")

  test "show pr t.args":
    check testHandleReplLine("pr s", false, "{}\n")

  test "show variables":
    let numFunctionKeys = funcsVarDict.len
    let eOut = "f={$1} g={} l={} o={} s={} t={3} u={}\n" % $numFunctionKeys
    check testHandleReplLine("v", false, eOut)

  test "run statement":
    check testHandleReplLine("a = 5", false)

  test "junk at end":
    let eErr = """
repl.tea(1): w31: Unused text at the end of the statement.
statement: a = 5 asdf
                 ^
"""
    check testHandleReplLine("a = 5 asdf", false, eErr = eErr)

  test "p len(a)":
    let eErr = """
p len(a)
     ^
Expected variable name not function call.
"""
    check testHandleReplLine("p len(a)", false, eErr = eErr)

  test "p len  abc":
    let eErr = """
p len  abc
       ^
Invalid REPL command syntax, unexpected text.
"""
    check testHandleReplLine("p len  abc", false, eErr = eErr)

  test "p missing":
    let eErr = """
p missing
  ^
The variable 'missing' does not exist.
"""
    check testHandleReplLine("p missing", false, eErr = eErr)

  test "ph f.cmp":
    let eOut = """
f.cmp[0] -- cmp(a: float, b: float) int
f.cmp[1] -- cmp(a: int, b: int) int
f.cmp[2] -- cmp(a: string, b: string, c: optional bool) int
"""
    check testHandleReplLine("ph f.cmp", eOut = eOut)

  test "listInColumns":
    let names = splitLines"""
o
tw
thr
four
fives
sevenn"""

    let expected = """
o    four
tw   fives
thr  sevenn
"""
    check testListInColumns(names, 16, expected)

  test "listInColumns empty":
    let abc = splitLines("")
    check abc.len == 1

    check testListInColumns(newSeq[string](), 16, "")

  test "listInColumns o":
    let names = @["o"]
    let expected = "o\n"
    check testListInColumns(names, 16, expected)

  test "listInColumns 1 2":
    let names = @["1", "2"]
    let expected = "1  2\n"
    check testListInColumns(names, 16, expected)

  test "listInColumns longername":
    let names = @["longername", "2"]
    let expected = """
longername
2
"""
    check testListInColumns(names, 16, expected)

  test "listInColumns aasdf":
    let names = splitLines"""
o
abc
de
r
t"""
    let expected = """
o    r
abc  t
de
"""
    check testListInColumns(names, 12, expected)

  test "listInColumns 4":
    let names = splitLines"""
o
abc
de
123456789 12
r
t"""
    let expected = """
o
abc
de
123456789 12
r
t
"""
    check testListInColumns(names, 12, expected)
