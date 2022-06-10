import std/unittest
import std/os
import std/strutils
import codefile
import variables
import env
import vartypes
import readlines
import sharedtestcode

proc testRunCodeFile(
    content: string = "",
    variables: var Variables,
    eVarRep: string = "",
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[],
    showLog: bool = false
  ): bool =
  ## Test the runCodeFile procedure.

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

  test "runCodeFile empty":
    let content = ""
    let eVarRep = ""
    var variables = emptyVariables()
    check testRunCodeFile(content, variables, eVarRep)

  test "runCodeFile a = 5":
    let content = "a = 5"
    let eVarRep = """
l.a = 5"""
    var variables = emptyVariables()
    check testRunCodeFile(content, variables, eVarRep)

  test "runCodeFile dup":
    let content = """
a = 5
a = 6
"""
    var variables = emptyVariables()
    let eVarRep = """
l.a = 5"""
    let eErrLines: seq[string] = splitNewLines """
testcode.txt(1): w95: You cannot assign to an existing variable.
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
l.a = 5
l.b = 3
l.c = "string"
l.d.x = 1
l.d.y = 2
l.e = 3.14159
l.ls = [1,2,3]"""
    var variables = emptyVariables()
    check testRunCodeFile(content, variables, eVarRep)
