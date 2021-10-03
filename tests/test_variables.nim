
import std/unittest
import std/options
import std/strutils
import std/tables
import variables
import vartypes
import env
import warnings
import readjson
import tostring
import args

proc testGetParentDict(variables: Variables, dotNameStr: string, eParentDict: ParentDict): bool =
  var names = split(dotNameStr, '.')
  var parentDict = getParentDict(variables, names)
  if expectedItem("parentDict:", parentDict, eParentDict):
    result = true

proc testAssignVariable(variables: var Variables, dotNameStr: string, value: Value,
    eWarningDataO: Option[WarningData] = none(WarningData)): bool =
  ## Assign a variable then fetch and verify it was set.
  let warningDataO = assignVariable(variables, dotNameStr, value)
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
  result = true

proc testAssignVariable(dotNameStr: string, value: Value,
    eWarningDataO: Option[WarningData] = none(WarningData)): bool =
  ## Assign a variable then fetch and verify it was set. Start with an
  ## empty dictionary.
  var variables = emptyVariables()
  result = testAssignVariable(variables, dotNameStr, value, eWarningDataO)

suite "variables.nim":

  test "emptyVariables":
    var variables = emptyVariables()
    check "l" in variables
    check "g" in variables
    check "s" in variables
    check "h" in variables
    check "row" in variables
    check "version" in variables
    check "args" in variables
    check variables["l"].dictv.len == 0
    check variables["g"].dictv.len == 0
    check variables["s"].dictv.len == 0
    check variables["h"].dictv.len == 0
    check variables["row"].intv == 0
    check variables["version"].kind == vkString
    check variables["args"].dictv.len == 0

  test "getParentDict":
    var variables = emptyVariables()
    check testGetParentDict(variables, "a", newParentDict(variables["l"].dictv))
    check testGetParentDict(variables, "g.test", newParentDict(variables["g"].dictv))
    check testGetParentDict(variables, "s.test", newParentDict(variables["s"].dictv))
    check testGetParentDict(variables, "h.test", newParentDict(variables["h"].dictv))
    check testGetParentDict(variables, "t.row", newParentDict(variables))

  test "getParentDict with list":
    var variables = emptyVariables()
    variables["teas"] = newEmptyListValue()
    check testGetParentDict(variables, "teas", newParentDict(variables["l"].dictv))

  test "getParentDict nested":
    let content = """
{
  "one": {
    "two": {
      "n": "nested"
    }
  }
}
"""
    var valueOrWarning = readJsonString(content)
    check valueOrWarning.kind == vwValue
    # var str = dictToString(valueOrWarning.value)
    # echo str
    var variables = emptyVariables()
    variables["l"] = valueOrWarning.value

    let local = variables["l"].dictv
    let one = local["one"].dictv
    let two = one["two"].dictv
    check testGetParentDict(variables, "one", newParentDict(local))
    check testGetParentDict(variables, "one.two", newParentDict(one))
    check testGetParentDict(variables, "one.two.n", newParentDict(two))

  test "getParentDict warnings":
    var variables = emptyVariables()
    let local = newParentDict(variables["l"].dictv)
    let global = newParentDict(variables["g"].dictv)
    let shared = newParentDict(variables["h"].dictv)
    let server = newParentDict(variables["s"].dictv)

    check testGetParentDict(variables, "g", global)
    check testGetParentDict(variables, "h", shared)
    check testGetParentDict(variables, "l", local)
    check testGetParentDict(variables, "s", server)
    check testGetParentDict(variables, "t", newParentDictWarn(wReservedNameSpaces))
    check testGetParentDict(variables, "f", newParentDictWarn(wReservedNameSpaces))

    check testGetParentDict(variables, "t.a.b.c", newParentDictWarn(wInvalidTeaVar, "t.a.b.c"))
    check testGetParentDict(variables, "t.server.a",
                            newParentDictWarn(wInvalidTeaVar, "t.server.a"))

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
    resetVariables(variables)
    check variables.len == 7
    check "s" in variables
    check "h" in variables
    check "l" in variables
    check "g" in variables
    check "row" in variables
    check "args" in variables
    check "version" in variables
    check variables["row"] == newValue(0)
    check variables["args"] == newEmptyDictValue()

  test "get t.args.help":
    var args: Args
    var argsVarDict = getTeaArgs(args).dictv
    var variables = emptyVariables(args = argsVarDict)
    echo "variables = " & $variables
    check getVariable(variables, "t.args.help") == newValueOrWarning(newValue(0))



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
 },
 "row": 5,
 "version": 10
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

  test "assignVariable":
    var variables = emptyVariables()
    var warningDataO = assignVariable(variables, "five", newValue(5))
    check warningDataO.isSome == false
    # echo "variables:"
    # echo valueToString(newValue(variables))

  test "assignVariable good":
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

  test "assignVariable wInvalidTeaVar server":
    let eWarningDataO = some(newWarningData(wInvalidTeaVar, "s"))
    check testAssignVariable("t.s", newValue(1), eWarningDataO)

  test "assignVariable wReadOnlyTeaVar version":
    let eWarningDataO = some(newWarningData(wReadOnlyTeaVar, "version"))
    check testAssignVariable("t.version", newValue(1), eWarningDataO)

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

  test "append to a list":
    var variables = emptyVariables()
    var warningDataO = assignVariable(variables, "teas", newValue(5), "&=")
    check not warningDataO.isSome
    warningDataO = assignVariable(variables, "teas", newValue(6), "&=")
    check not warningDataO.isSome
    warningDataO = assignVariable(variables, "teas", newValue(7), "&=")
    check not warningDataO.isSome
    check $variables["l"] == """{"teas":[5,6,7]}"""

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
