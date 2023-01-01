import std/unittest
import std/tables
import std/strutils
import repl
import variables
import sharedtestcode
import vartypes
import functions
import version
import comparelines

proc testHandleReplLine(
    line: string,
    eStop = false,
    eOut: string = "",
    eLog: string = "",
    eErr: string = "",
  ): bool =

  var env = openEnvTest("_handleReplLine.log")

  # Set up variables when not passed in.
  let funcsVarDict = createFuncDictionary().dictv
  var variables = startVariables(funcs = funcsVarDict)

  let stop = handleReplLine(env, variables, line)

  let eOutLines = splitNewLines(eOut)
  let eLogLines = splitNewLines(eLog)
  let eErrLines = splitNewLines(eErr)
  result = env.readCloseDeleteCompare(eLogLines, eErrLines, eOutLines)

  if not gotExpected($stop, $eStop):
    result = false

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
* p variable — print a variable as dot names
* pj variable — print a variable as json
* pr variable — print a variable like in a replacement block
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
    let funcsVarDict = createFuncDictionary().dictv
    let numFunctionKeys = funcsVarDict.len
    let eOut = "f={$1} g={} l={} o={} s={} t={3}\n" % $numFunctionKeys
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
