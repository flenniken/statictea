import std/unittest
import std/tables
import std/strutils
import repl
import variables
import sharedtestcode
import vartypes
import runfunction

proc testHandleReplLine(line: string, eStr = "", eStop = false, start: Natural = 5): bool =
  # Set up variables when not passed in.
  let funcsVarDict = createFuncDictionary().dictv
  var variables = emptyVariables(funcs = funcsVarDict)
  var stop = false
  let str = handleReplLine(line, start, variables, stop)
  result = true
  if not gotExpected($stop, $eStop):
    result = false
  if str != eStr:
    echo line
    echo "got:"
    echo str
    echo "expected:"
    echo eStr
    result = false

suite "repl.nim":

  test "handle repl line":
    check testHandleReplLine("tea> ", "")
    check testHandleReplLine("tea>  ", "")
    check testHandleReplLine("tea>\t", "")

    let eStr = """
You enter statements or commands at the prompt.

Available commands:
* h — this help text
* p dotname — print the value of a variable
* pd dotname — print a dictionary as dot names
* pj dotname — print a variable as json
* v — show the number of variables in the top level dictionaries
* q — quit"""
    check testHandleReplLine("tea> h", eStr)

    check testHandleReplLine("tea> q", "", eStop = true)
    check testHandleReplLine("tea> q   ", "", eStop = true)
    let eStr2 = """
       ^
Invalid REPL command syntax."""
    check testHandleReplLine("tea> q asdf", eStr2)
    check testHandleReplLine("tea> h asdf", eStr2)

  test "show t.row":
    check testHandleReplLine("tea> p t.row", "0")
    check testHandleReplLine("tea> pd t.row", "0")
    check testHandleReplLine("tea> pj t.row", "0")

  test "show t.version":
    let version = "0.1.0"
    let qversion = """"0.1.0""""
    check testHandleReplLine("tea> p t.version", version)
    check testHandleReplLine("tea> pd t.version", qversion)
    check testHandleReplLine("tea> pj t.version", qversion)

  test "show t.args":
    check testHandleReplLine("tea> p t.args", "{}")
    check testHandleReplLine("tea> pd t.args", "")
    check testHandleReplLine("tea> pj t.args", "{}")

  test "show variables":
    let funcsVarDict = createFuncDictionary().dictv
    let numFunctionKeys = funcsVarDict.len
    let str = "f={$1} g={} l={} o={} s={} t={3}" % $numFunctionKeys
    check testHandleReplLine("tea> v", str)

  test "run statement":
    check testHandleReplLine("tea> a = 5", "")

  test "junk at end":
    let eStr = """
           ^
Unused text at the end of the statement."""
    check testHandleReplLine("tea> a = 5 asdf", eStr)

  test "p len(a)":
    let eStr = """
          ^
Invalid variable or dot name."""
    check testHandleReplLine("tea> p len(a)", eStr)
  
  test "p len  abc":
    let eStr = """
            ^
Invalid REPL command syntax."""
    check testHandleReplLine("tea> p len  abc", eStr)

  test "p missing":
    let eStr = """
              ^
The variable 'missing' does not exist."""
    check testHandleReplLine("tea> p missing", eStr)


