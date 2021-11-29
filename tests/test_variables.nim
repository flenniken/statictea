
import std/unittest
import std/options
import std/strutils
import std/tables
import variables
import vartypes
import env
import messages
import warnings
import readjson
import tostring
import args

proc testGetVariableOk(variables: Variables, dotNameStr: string, eJson:
    string): bool =
  let valueOrWarning = getVariable(variables, dotNameStr)
  result = true
  if valueOrWarning.kind == vwWarning:
    echo "Unable to get the variable: " & $valueOrWarning
    return false
  if not expectedItem("value", $valueOrWarning.value, eJson):
    return false

proc testGetVariableWarning(variables: Variables, dotNameStr: string,
    eWarningData: WarningData): bool =
  let valueOrWarning = getVariable(variables, dotNameStr)
  result = true
  if valueOrWarning.kind != vwWarning:
    echo "Did not get a warning: " & $valueOrWarning
    return false
  if not expectedItem("warning", $valueOrWarning.warningData, $eWarningData):
    return false

proc testAssignVariable(variables: var Variables, dotNameStr: string, value: Value,
    eWarningDataO: Option[WarningData] = none(WarningData), operator = "="): bool =
  ## Assign a variable then fetch and verify it was set.
  let warningDataO = assignVariable(variables, dotNameStr, value, operator)
  result = true
  if not expectedItem("warningDataO", warningDataO, eWarningDataO):
    return false
  if warningDataO.isSome:
    return true
  let valueOrWarning = getVariable(variables, dotNameStr)
  if valueOrWarning.kind == vwWarning:
    echo "Unable to fetch the variable: " & $valueOrWarning
    return false
  if not expectedItem("fetched value", valueOrWarning.value, value):
    return false

proc testAssignVariable(dotNameStr: string, value: Value,
    eWarningDataO: Option[WarningData] = none(WarningData),
    operator: string = "="): bool =
  ## Assign a variable then fetch and verify it was set. Start with an
  ## empty dictionary.
  var variables = emptyVariables()
  result = testAssignVariable(variables, dotNameStr,
    value, eWarningDataO, operator)

suite "variables.nim":

  test "emptyVariables":
    var variables = emptyVariables()
    # echo $variables
    let e = """{"s":{},"h":{},"l":{},"g":{},"t":{"row":0,"version":"0.1.0","args":{}}}"""
    check $variables == e

  test "getVariable":
    var variables = emptyVariables()
    check testGetVariableOk(variables, "t.row", "0")
    check testGetVariableOk(variables, "t.args", "{}")
    check testGetVariableOk(variables, "t.version", "\"0.1.0\"")
    check testGetVariableOk(variables, "s", "{}")
    check testGetVariableOk(variables, "h", "{}")
    check testGetVariableOk(variables, "l", "{}")
    check testGetVariableOk(variables, "g", "{}")
    let eTea = """{"row":0,"version":"0.1.0","args":{}}"""
    check testGetVariableOk(variables, "t", eTea)

  test "getVariable five":
    var variables = emptyVariables()
    variables["l"].dictv["five"] = newValue(5)
    check testGetVariableOk(variables, "l.five", "5")
    check testGetVariableOk(variables, "five", "5")

  test "getVariable nested":
    var variables = emptyVariables()
    let variablesJson = """
{
  "a":{
    "b":{
      "c":{
      }
    }
  }
}"""
    var valueOrWarning = readJsonString(variablesJson)
    check valueOrWarning.kind == vwValue
    variables["l"] = valueOrWarning.value

    check testGetVariableOk(variables, "l.a.b.c", "{}")
    check testGetVariableOk(variables, "l.a.b", """{"c":{}}""")
    check testGetVariableOk(variables, "l.a", """{"b":{"c":{}}}""")
    check testGetVariableOk(variables, "l", """{"a":{"b":{"c":{}}}}""")

    let wO = newWarningData(wMissingVarName, "hello")
    check testGetVariableWarning(variables, "hello", wO)


  test "getVariable not dict":
    var variables = emptyVariables()
    let variablesJson = """
{
  "a":{
    "b":5
  }
}"""
    var valueOrWarning = readJsonString(variablesJson)
    check valueOrWarning.kind == vwValue
    variables["l"] = valueOrWarning.value

    let wO = newWarningData(wNotDict, "b")
    check testGetVariableWarning(variables, "a.b.tea", wO)

  test "testGetVariableWarning wReservedNameSpaces":
    var variables = emptyVariables()
    let eWarningData = newWarningData(wReservedNameSpaces)
    check testGetVariableWarning(variables, "p", eWarningData)

  test "testGetVariableWarning wMissingVarName":
    var variables = emptyVariables()
    let eWarningData = newWarningData(wMissingVarName, "hello")
    check testGetVariableWarning(variables, "s.hello", eWarningData)

  test "testGetVariableWarning wMissingVarName 2":
    var variables = emptyVariables()
    let eWarningData = newWarningData(wMissingVarName, "d")
    check testGetVariableWarning(variables, "s.d.hello", eWarningData)

  test "testGetVariableWarning not dict":
    var variables = emptyVariables()
    let variablesJson = """{"d":"hello"}"""
    var valueOrWarning = readJsonString(variablesJson)
    check valueOrWarning.kind == vwValue
    variables["s"] = valueOrWarning.value

    let eWarningData = newWarningData(wNotDict, "d")
    check testGetVariableWarning(variables, "s.d.hello", eWarningData)


  test "getTeaVarStringDefault":
    var variables = emptyVariables()
    check getTeaVarStringDefault(variables, "output") == "result"

  test "getTeaVarIntDefault":
    var variables = emptyVariables()
    check getTeaVarIntDefault(variables, "row") == 0
    check getTeaVarIntDefault(variables, "repeat") == 1
    check getTeaVarIntDefault(variables, "maxLines") == 50
    check getTeaVarIntDefault(variables, "maxRepeat") == 100

  test "resetVariables":
    var variables = emptyVariables()
    let emptyVariables = $variables
    resetVariables(variables)
    if $variables != emptyVariables:
      echo "expected: " & emptyVariables
      echo "     got: " & $variables
      fail

  test "check the initial t.args":
    var args: Args
    var argsVarDict = getTeaArgs(args).dictv
    var variables = emptyVariables(args = argsVarDict)
    let targs = variables["t"].dictv["args"]
    # echo "targs = " & $targs
    let eTargs = """{"help":0,"version":0,"update":0,"log":0,"serverList":[],"sharedList":[],"resultFilename":"","templateList":[],"logFilename":"","prepostList":[]}"""
    if $targs != eTargs:
      echo "expected: " & eTargs
      echo "     got: " & $targs
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
 "g": {
    "c": 4
 },
 "l": {
 }
}
"""
    var valueOrWarning = readJsonString(variablesJson)
    check valueOrWarning.kind == vwValue
    var variables = valueOrWarning.value.dictv
    let beforeJson = valueToString(valueOrWarning.value)

    resetVariables(variables)
    let afterJson = valueToString(newValue(variables))
    check expectedItem("reset test", beforeJson, afterJson)

  test "resetVariables with server":
    # Make sure the server variables are untouched after reset.
    let server = """{"a": 2}"""
    var valueOrWarning = readJsonString(server)
    check valueOrWarning.kind == vwValue
    var variables = emptyVariables()
    variables["s"] = valueOrWarning.value
    resetVariables(variables)
    check getVariable(variables, "s.a") == newValueOrWarning(newValue(2))

  test "resetVariables with shared":
    # Make sure the shared variables are untouched after reset.
    let shared = """{"a": 2}"""
    var valueOrWarning = readJsonString(shared)
    check valueOrWarning.kind == vwValue
    var variables = emptyVariables()
    variables["h"] = valueOrWarning.value
    resetVariables(variables)
    check getVariable(variables, "h.a") == newValueOrWarning(newValue(2))

  test "resetVariables with global":
    # Make sure the global variables are untouched after reset.
    let global = """{"a": 2}"""
    var valueOrWarning = readJsonString(global)
    check valueOrWarning.kind == vwValue
    var variables = emptyVariables()
    variables["g"] = valueOrWarning.value
    resetVariables(variables)
    check getVariable(variables, "g.a") == newValueOrWarning(newValue(2))

  test "assignVariable good":
    check testAssignVariable("five", newValue(5))
    check testAssignVariable("tfive", newValue(5))
    check testAssignVariable("g.var", newValue(1))
    check testAssignVariable("t.maxLines", newValue(20))
    check testAssignVariable("t.maxRepeat", newValue(20))
    check testAssignVariable("t.content", newValue("asdf"))
    check testAssignVariable("t.output", newValue("stderr"))
    check testAssignVariable("t.repeat", newValue(20))

  test "assignVariable warning":
    check testAssignVariable("t.repeat", newValue("hello"), some(newWarningData(wInvalidRepeat)))

  test "assignVariable wReadOnlyDictionary":
    let eWarningDataO = some(newWarningData(wReadOnlyDictionary))
    check testAssignVariable("s.hello", newValue(1), eWarningDataO)
    check testAssignVariable("h.hello", newValue(1), eWarningDataO)

  test "assignVariable wImmutableVars":
    let eWarningDataO = some(newWarningData(wImmutableVars))
    check testAssignVariable("s", newValue(1), eWarningDataO)
    check testAssignVariable("h", newValue(1), eWarningDataO)
    check testAssignVariable("g", newValue(1), eWarningDataO)
    check testAssignVariable("l", newValue(1), eWarningDataO)
    check testAssignVariable("t", newValue(1), eWarningDataO)

  test "assignVariable wReservedNameSpaces":
    let eWarningDataO = some(newWarningData(wReservedNameSpaces))
    for letterVar in ["f", "i", "j", "k", "m", "n", "o", "p", "q", "r", "u"]:
      check testAssignVariable(letterVar, newValue(1), eWarningDataO)

  test "assignVariable not wReservedNameSpaces":
    for letterVar in ["a", "b", "c", "d", "e", "v", "w", "x", "y", "z"]:
      check testAssignVariable(letterVar, newValue(1))

  test "assignVariable wMissingVarName":
    let eWarningDataO = some(newWarningData(wMissingVarName, "w"))
    check testAssignVariable("w.hello", newValue(1), eWarningDataO)

  test "assignVariable wImmutableVars":
    ## Set variables then try to change them.
    var variables = emptyVariables()
    let eWarningDataO = some(newWarningData(wImmutableVars))

    check testAssignVariable(variables, "five", newValue(1))
    check testAssignVariable(variables, "five", newValue(2), eWarningDataO)

    check testAssignVariable(variables, "g.five", newValue(1))
    check testAssignVariable(variables, "g.five", newValue(2), eWarningDataO)

  test "assignVariable tea vars":
    ## Set tea variables then try to change them.
    var variables = emptyVariables()
    let eWarningDataO = some(newWarningData(wTeaVariableExists))

    check testAssignVariable(variables, "t.maxLines", newValue(1))
    check testAssignVariable(variables, "t.maxLines", newValue(2), eWarningDataO)

    check testAssignVariable(variables, "t.output", newValue("stderr"))
    check testAssignVariable(variables, "t.output", newValue("result"), eWarningDataO)

  test "assignVariable wReadOnlyTeaVar row":
    let eWarningDataO = some(newWarningData(wReadOnlyTeaVar, "row"))
    check testAssignVariable("t.row", newValue(1), eWarningDataO)

  test "assignVariable wReadOnlyTeaVar args":
    let eWarningDataO = some(newWarningData(wReadOnlyTeaVar, "args"))
    check testAssignVariable("t.args", newValue(1), eWarningDataO)

  test "assignVariable wInvalidTeaVar server":
    let eWarningDataO = some(newWarningData(wInvalidTeaVar, "s"))
    check testAssignVariable("t.s", newValue(1), eWarningDataO)

  test "assignVariable wReadOnlyTeaVar version":
    let eWarningDataO = some(newWarningData(wReadOnlyTeaVar, "version"))
    check testAssignVariable("t.version", newValue(1), eWarningDataO)

  test "assignVariable args help":
    let eWarningDataO = some(newWarningData(wReadOnlyTeaVar, "args"))
    check testAssignVariable("t.args.help", newValue(1), eWarningDataO)

  test "assignVariable maxLines not int":
    let eWarningDataO = some(newWarningData(wInvalidMaxCount, ""))
    check testAssignVariable("t.maxLines", newValue("max"), eWarningDataO)

  test "assignVariable maxLines less 0":
    let eWarningDataO = some(newWarningData(wInvalidMaxCount, ""))
    check testAssignVariable("t.maxLines", newValue(-1), eWarningDataO)

  test "assignVariable maxRepeat not int":
    let eWarningDataO = some(newWarningData(wInvalidMaxRepeat, ""))
    check testAssignVariable("t.maxRepeat", newValue("str"), eWarningDataO)

  test "assignVariable maxRepeat less 0":
    let eWarningDataO = some(newWarningData(wInvalidMaxRepeat, ""))
    check testAssignVariable("t.maxRepeat", newValue(-1), eWarningDataO)

  test "assignVariable content not string":
    let eWarningDataO = some(newWarningData(wInvalidTeaContent, ""))
    check testAssignVariable("t.content", newValue(1), eWarningDataO)

  test "assignVariable output not string":
    let eWarningDataO = some(newWarningData(wInvalidOutputValue, ""))
    check testAssignVariable("t.output", newValue(1), eWarningDataO)

  test "assignVariable output invalid":
    let eWarningDataO = some(newWarningData(wInvalidOutputValue, ""))
    check testAssignVariable("t.output", newValue("overthere"), eWarningDataO)

  test "assignVariable repeat less 0":
    let eWarningDataO = some(newWarningData(wInvalidRepeat, ""))
    check testAssignVariable("t.repeat", newValue(-1), eWarningDataO)

  test "assignVariable repeat not int":
    let eWarningDataO = some(newWarningData(wInvalidRepeat, ""))
    check testAssignVariable("t.repeat", newValue("tasf"), eWarningDataO)

  test "assignVariable repeat above max":
    let eWarningDataO = some(newWarningData(wInvalidRepeat, ""))
    check testAssignVariable("t.repeat", newValue(101), eWarningDataO)

  test "assignVariable invalid tea var":
    let eWarningDataO = some(newWarningData(wInvalidTeaVar, "oops"))
    check testAssignVariable("t.oops", newValue(1), eWarningDataO)

  test "assignVariable append to tea":
    let eWarningDataO = some(newWarningData(wImmutableVars))
    check testAssignVariable("t", newValue("hello"), eWarningDataO, "&=")

  test "assignVariable append to tea args":
    let eWarningDataO = some(newWarningData(wReadOnlyTeaVar, "args"))
    check testAssignVariable("t.args", newValue("hello"), eWarningDataO, "&=")
    check testAssignVariable("t.args.hello", newValue("hello"), eWarningDataO, "&=")

  test "assignVariable nested dict":
    var variables = emptyVariables()
    let variablesJson = """{"a":{"b2":"tea","b":{"c2":[],"c":{"d":"hello"}}}}"""
    var valueOrWarning = readJsonString(variablesJson)
    check valueOrWarning.kind == vwValue
    variables["l"] = valueOrWarning.value
    check testAssignVariable(variables, "l.a.b.c.tea", newValue(1))

    let warning1 = some(newWarningData(wAppendToList, "dict"))
    check testAssignVariable(variables, "l.a.b", newValue(1),
      warning1, "&=")

    let eWarningDataO = some(newWarningData(wMissingVarName, "missing"))
    check testAssignVariable(variables, "l.a.b.missing.tea",
                             newValue(1), eWarningDataO)

    let eWarningDataO2 = some(newWarningData(wNotDict, "b2"))
    check testAssignVariable(variables, "l.a.b2.missing.tea",
                             newValue(1), eWarningDataO2)


  test "append to a list":
    var variables = emptyVariables()
    var warningDataO = assignVariable(variables, "teas", newValue(5), "&=")
    check not warningDataO.isSome
    warningDataO = assignVariable(variables, "teas", newValue(6), "&=")
    check not warningDataO.isSome
    warningDataO = assignVariable(variables, "teas", newValue(7), "&=")
    check not warningDataO.isSome
    check $variables["l"] == """{"teas":[5,6,7]}"""

  test "append to a list2":
    var variables = emptyVariables()
    let variablesJson = """
{
 "a1":"hello",
 "a2":{
  "b1": [],
 },
 "a3":[]
}"""
    var valueOrWarning = readJsonString(variablesJson)
    check valueOrWarning.kind == vwValue
    variables["l"] = valueOrWarning.value

    var aO = assignVariable(variables, "l.teas", newValue(5), "&=")
    check not aO.isSome
    check $variables["l"] == """{"a1":"hello","a2":{"b1":[]},"a3":[],"teas":[5]}"""

    var bO = assignVariable(variables, "teas", newValue(6), "&=")
    check not bO.isSome
    check $variables["l"] == """{"a1":"hello","a2":{"b1":[]},"a3":[],"teas":[5,6]}"""

    var cO = assignVariable(variables, "a2.b1", newValue(7), "&=")
    check not cO.isSome
    check $variables["l"] == """{"a1":"hello","a2":{"b1":[7]},"a3":[],"teas":[5,6]}"""


  test "append nested dictionary":
    var variables = emptyVariables()
    let variablesJson = """{"a":{}}"""
    var valueOrWarning = readJsonString(variablesJson)
    check valueOrWarning.kind == vwValue
    variables["l"] = valueOrWarning.value

    var aO = assignVariable(variables, "l.a.tea", newValue(5), "&=")
    check not aO.isSome
    check $variables["l"] == """{"a":{"tea":[5]}}"""

  test "append nested dictionary2":
    var variables = emptyVariables()
    let variablesJson = """{"a":{"tea":2}}"""
    var valueOrWarning = readJsonString(variablesJson)
    check valueOrWarning.kind == vwValue
    variables["l"] = valueOrWarning.value

    var aO = assignVariable(variables, "l.a.sea", newValue(5), "&=")
    check not aO.isSome
    check $variables["l"] == """{"a":{"tea":2,"sea":[5]}}"""

  test "append list to a list":
    var variables = emptyVariables()
    var warningDataO = assignVariable(variables, "teas", newEmptyListValue(), "&=")
    check not warningDataO.isSome
    warningDataO = assignVariable(variables, "teas", newEmptyListValue(), "&=")
    check not warningDataO.isSome
    check $variables["l"] == """{"teas":[[],[]]}"""

  test "append to a non-list":
    var variables = emptyVariables()
    var warningDataO = assignVariable(variables, "a", newValue(5))
    check not warningDataO.isSome
    let eWarningDataO = some(newWarningData(wAppendToList, "int"))
    warningDataO = assignVariable(variables, "a", newValue(6), "&=")
    check warningDataO == eWarningDataO

  test "argsPrepostList":
    # let prepostList = @[newPrepost("#$", "")]
    let prepostList = @[newPrepost("abc", "def")]
    check argsPrepostList(prepostList) == @[@["abc", "def"]]
