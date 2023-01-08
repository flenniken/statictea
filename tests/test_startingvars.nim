import std/unittest
import std/tables
import startingvars
import sharedtestcode
import args
import vartypes
import comparelines
import variables
import readjson
import opresult

suite "startingvars.nim":

  test "argsPrepostList":
    # let prepostList = @[newPrepost("#$", "")]
    let prepostList = @[newPrepost("abc", "def")]
    check argsPrepostList(prepostList) == @[@["abc", "def"]]

  test "getStartVariables":
    var env = openEnvTest("_testGetStartingVariables.log")
    var args: Args
    var variables = getStartVariables(env, args)

    # echo dotNameRep(variables, top=true)
    check "f" in variables
    check "t" in variables
    check "g" in variables
    check "l" in variables
    check "o" in variables
    check "s" in variables

    let eLogLines: seq[string] = @[]
    let eErrLines: seq[string] = @[]
    let eOutLines: seq[string] = @[]

    check env.readCloseDeleteCompare(eLogLines, eErrLines, eOutLines)

  test "check the initial t.args":
    var args: Args
    var argsVarDict = getTeaArgs(args).dictv
    var variables = startVariables(args = argsVarDict)
    let targs = variables["t"].dictv["args"]
    let varRep = dotNameRep(targs.dictv)
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
    if varRep != eVarRep:
      echo linesSideBySide(varRep, eVarRep)
      fail

  test "resetVariables untouched":
    # Make sure the some variables are untouched after reset.
    let variablesJson = """
{
 "s": {
    "a": 2
 },
 "h": {
    "b": 3
 },
 "o": {
    "bb": 3.5
 },
 "g": {
    "c": 4
 },
 "l": {
 }
}
"""
    var valueOr = readJsonString(variablesJson)
    check valueOr.isValue
    var variables = valueOr.value.dictv
    let beforeJson = valueToString(valueOr.value)

    resetVariables(variables)
    let afterJson = valueToString(newValue(variables))
    check expectedItem("reset test", beforeJson, afterJson)

