
import std/unittest
import std/options
import std/strutils
import std/tables
import variables
import vartypes
import sharedtestcode
import messages
import readjson
import opresult
import functions
import version

proc testGetVariableOk(variables: Variables, dotNameStr: string, eJson:
                       string, noPrefixDict: NoPrefixDict = npLocal): bool =
  ## Get a variable and verify its value matches the expected value.
  let valueOr = getVariable(variables, dotNameStr, noPrefixDict)
  result = true
  if valueOr.isMessage:
    echo "Unable to get the variable: " & $valueOr
    return false
  if not expectedItem("value", $valueOr.value, eJson):
    return false

proc testGetVariableWarning(variables: Variables, dotNameStr: string,
    eMessageId: MessageId, eP1 = "", ePos = 0): bool =
  let valueOr = getVariable(variables, dotNameStr, npLocal)
  if valueOr.isValue:
    echo "Did not get a warning: " & $valueOr
    return false
  let eMd = newWarningData(eMessageId, eP1, ePos)
  result = gotExpected($valueOr.message, $eMd)

proc testAssignVarWarn(
    dotNameStr: string,
    operator: Operator,
    value: Value,
    eMessageId: MessageId,
    eP1 = "",
    ePos = 0,
    inVars: string = "",
    dictName: string = "l",
  ): bool =
  ## Assign a variable and make sure the warning matches the expected warning.

  # Populate the variables dictionary when there are inVars.
  var variables = startVariables()
  if inVars != "":
    var valueOr = readJsonString(inVars)
    if valueOr.isMessage:
      echo $valueOr
      return false
    variables[dictName] = valueOr.value

  # Assign a variable.
  let warningDataO = assignVariable(variables, dotNameStr, value,
    operator)
  if not warningDataO.isSome:
    echo "Did not get a message. got:"
    echo $variables[dictName]
    return false
  let eWd = newWarningData(eMessageId, eP1, ePos)
  result = gotExpected($warningDataO.get(), $eWd)

proc testAssignVarFlex(
    dotNameStr: string,
    operator: Operator,
    value: Value,
    eVars: string,
    inVars: string = "",
    dictName: string = "l",
  ): bool =
  ## Test assignVariable.

  # Populate the variables dictionary when there are inVars.
  var variables = startVariables()
  if inVars != "":
    var valueOr = readJsonString(inVars, mutable = Mutable.append)
    if valueOr.isMessage:
      echo $valueOr
      return false
    variables[dictName] = valueOr.value

  let warningDataO = assignVariable(variables, dotNameStr, value,
    operator)
  if warningDataO.isSome:
    echo "got unexpected message."
    echo $warningDataO
    return false

  # let got = dotNameRep(variables, "", true)
  result = gotExpected($variables[dictName], eVars)

suite "variables.nim":

  test "startVariables":
    var variables = startVariables()
    let expected = """
f = {}
g = {}
l = {}
o = {}
s = {}
t.args = {}
t.row = 0
t.version = "$1"
u = {}""" % staticteaVersion
    check dotNameRep(variables, top=true) == expected

  test "getVariable":
    var variables = startVariables(funcs = funcsVarDict)
    check testGetVariableOk(variables, "true", "true")
    check testGetVariableOk(variables, "false", "false")
    check testGetVariableOk(variables, "t.row", "0")
    check testGetVariableOk(variables, "t.args", "{}")
    check testGetVariableOk(variables, "t.version", "\"$1\"" % staticteaVersion)
    check testGetVariableOk(variables, "s", "{}")
    check testGetVariableOk(variables, "o", "{}")
    check testGetVariableOk(variables, "l", "{}")
    check testGetVariableOk(variables, "g", "{}")
    check testGetVariableOk(variables, "u", "{}")

    let eTea = """{"args":{},"row":0,"version":"$1"}""" % staticteaVersion
    check testGetVariableOk(variables, "t", eTea)
    let expected = """["cmp","cmp","cmp"]"""
    check testGetVariableOk(variables, "f.cmp", expected)

  test "getVariable five":
    var variables = startVariables()
    variables["l"].dictv.dict["five"] = newValue(5)
    check testGetVariableOk(variables, "l.five", "5")
    check testGetVariableOk(variables, "five", "5")

  test "getVariable u.a":
    var variables = startVariables()
    func abc(variables: Variables, parameters: seq[Value]): FunResult =
      result = newFunResult(newValue("hi"))
    let fn = newValue(newDummyFunctionSpec(builtIn = false,
      functionName = "abc", signatureCode = "iis", functionPtr = abc))
    variables["u"].dictv.dict["a"] = fn
    check testGetVariableOk(variables, "u.a", """"abc"""")

  test "getVariable nested":
    var variables = startVariables()
    let variablesJson = """
{
  "a":{
    "b":{
      "c":{
      }
    }
  }
}"""
    var valueOr = readJsonString(variablesJson)
    check valueOr.isValue
    variables["l"] = valueOr.value

    check testGetVariableOk(variables, "l.a.b.c", "{}")
    check testGetVariableOk(variables, "l.a.b", """{"c":{}}""")
    check testGetVariableOk(variables, "l.a", """{"b":{"c":{}}}""")
    check testGetVariableOk(variables, "l", """{"a":{"b":{"c":{}}}}""")

    check testGetVariableWarning(variables, "l.hello", wVariableMissing, "hello")


  test "getVariable not dict":
    var variables = startVariables()
    let variablesJson = """
{
  "a":{
    "b":5
  }
}"""
    var valueOr = readJsonString(variablesJson)
    check valueOr.isValue
    variables["l"] = valueOr.value
    check testGetVariableWarning(variables, "l.a.b.tea", wNotDict, "b")
    check testGetVariableWarning(variables, "a.b.tea", wNotInL, "a.b.tea")

  test "testGetVariableWarning wReservedNameSpaces":
    var variables = startVariables()
    check testGetVariableWarning(variables, "p", wReservedNameSpaces)

  test "testGetVariableWarning wVariableMissing":
    var variables = startVariables()
    check testGetVariableWarning(variables, "s.hello", wVariableMissing, "hello")

  test "testGetVariableWarning wVariableMissing 2":
    var variables = startVariables()
    check testGetVariableWarning(variables, "s.d.hello", wVariableMissing, "d")

  test "testGetVariableWarning not dict":
    var variables = startVariables()
    let variablesJson = """{"d":"hello"}"""
    var valueOr = readJsonString(variablesJson)
    check valueOr.isValue
    variables["s"] = valueOr.value
    check testGetVariableWarning(variables, "s.d.hello", wNotDict, "d")

  test "getTeaVarStringDefault":
    var variables = startVariables()
    check getTeaVarStringDefault(variables, "output") == "result"

  test "getTeaVarIntDefault":
    var variables = startVariables()
    check getTeaVarIntDefault(variables, "row") == 0
    check getTeaVarIntDefault(variables, "repeat") == 1
    check getTeaVarIntDefault(variables, "maxLines") == 50
    check getTeaVarIntDefault(variables, "maxRepeat") == 100

  test "resetVariables":
    var variables = startVariables()
    let startVariables = $variables
    resetVariables(variables)
    if $variables != startVariables:
      echo "expected: " & startVariables
      echo "     got: " & $variables
      fail

  test "resetVariables with server":
    # Make sure the server variables are untouched after reset.
    let server = """{"a": 2}"""
    var valueOr = readJsonString(server)
    check valueOr.isValue
    var variables = startVariables()
    variables["s"] = valueOr.value
    resetVariables(variables)
    check $getVariable(variables, "s.a", npLocal) == $newValueOr(newValue(2))

  test "resetVariables with shared":
    # Make sure the shared variables are untouched after reset.
    let shared = """{"a": 2}"""
    var valueOr = readJsonString(shared)
    check valueOr.isValue
    var variables = startVariables()
    variables["o"] = valueOr.value
    resetVariables(variables)
    check $getVariable(variables, "o.a", npLocal) == $newValueOr(newValue(2))

  test "resetVariables with shared":
    # Make sure the code variables are untouched after reset.
    let codeVars = """{"a": 2}"""
    var valueOr = readJsonString(codeVars)
    check valueOr.isValue
    var variables = startVariables()
    variables["o"] = valueOr.value
    resetVariables(variables)
    check $getVariable(variables, "o.a", npLocal) == $newValueOr(newValue(2))

  test "resetVariables with global":
    # Make sure the global variables are untouched after reset.
    let global = """{"a": 2}"""
    var valueOr = readJsonString(global)
    check valueOr.isValue
    var variables = startVariables()
    variables["g"] = valueOr.value
    resetVariables(variables)
    check $getVariable(variables, "g.a", npLocal) == $newValueOr(newValue(2))

  test "assignVariable good":

    let json1 = """{"five":5}"""
    check testAssignVarFlex("five", opEqual, newValue(5), json1)

    check testAssignVarFlex("o.five", opEqual, newValue(5), json1, dictName="o")

    let tkeys = """"args":{},"row":0,"version":"$1""""  % staticteaVersion
    let json2 = """{$1,"maxLines":5}""" % tkeys
    check testAssignVarFlex("t.maxLines", opEqual, newValue(5),
      json2, dictName="t")

    let json3 = """{$1,"maxRepeat":5}""" % tkeys
    check testAssignVarFlex("t.maxRepeat", opEqual, newValue(5),
      json3, dictName="t")

    let json4 = """{$1,"repeat":5}""" % tkeys
    check testAssignVarFlex("t.repeat", opEqual, newValue(5), json4, dictName="t")

    let json5 = """{$1,"content":"asdf"}""" % tkeys
    check testAssignVarFlex("t.content", opEqual, newValue("asdf"), json5, dictName="t")

    # Assign a user function variable to the u dictionary.
    let json6 = """{"a":"abc"}"""
    func abc(variables: Variables, parameters: seq[Value]): FunResult =
      result = newFunResult(newValue("hi"))
    let fn = newValue(newDummyFunctionSpec(builtIn = false,
      functionName = "abc", signatureCode = "iis", functionPtr = abc))
    check testAssignVarFlex("u.a", opEqual, fn, json6, dictName="u")

  test "assignVariable warning":
    check testAssignVarWarn("t.repeat", opEqual, newValue("hello"),
      wInvalidRepeat)

    check testAssignVarWarn("true", opEqual, newValue("hello"),
      wAssignTrueFalse)
    check testAssignVarWarn("l.true", opEqual, newValue("hello"),
      wAssignTrueFalse)

    check testAssignVarWarn("false", opEqual, newValue("hello"),
      wAssignTrueFalse)
    check testAssignVarWarn("l.false", opEqual, newValue("hello"),
      wAssignTrueFalse)

  test "assignVariable wReadOnlyDictionary":
    check testAssignVarWarn("s.hello", opEqual, newValue(1), wReadOnlyDictionary)

  test "assignVariable wImmutableVars":
    check testAssignVarWarn("s", opEqual, newValue(1), wReadOnlyDictionary)
    check testAssignVarWarn("o", opEqual, newValue(1), wImmutableVars)
    check testAssignVarWarn("g", opEqual, newValue(1), wNoGlobalInCodeFile)
    check testAssignVarWarn("l", opEqual, newValue(1), wImmutableVars)
    check testAssignVarWarn("t", opEqual, newValue(1), wImmutableVars)
    check testAssignVarWarn("m", opEqual, newValue(1), wReservedNameSpaces)
    check testAssignVarWarn("u", opEqual, newValue(1), wImmutableVars)

  test "assignVariable wReadOnlyFunctions":
    check testAssignVarWarn("f", opEqual, newValue(1), wReadOnlyFunctions)
    check testAssignVarWarn("f.a", opEqual, newValue(1), wReadOnlyFunctions)

  test "u.a = 1":
    check testAssignVarWarn("u.a", opEqual, newValue(1), wUserFunction)
    check testAssignVarWarn("u.a", opAppendList, newValue(1), wUserFunction)

  test "assignVariable wReservedNameSpaces":
    for letterVar in ["i", "j", "k", "n", "p", "q", "r"]:
      check testAssignVarWarn(letterVar, opEqual, newValue(1), wReservedNameSpaces)

  test "non wReservedNameSpaces in command":
    check testAssignVarFlex("a", opEqual, newValue(1), """{"a":1}""")
    check testAssignVarFlex("a", opEqual, newValue(1), """{"a":1}""")

    for letterVar in ["a", "b", "c", "d", "e", "v", "w", "x", "y", "z"]:
      check testAssignVarFlex(letterVar, opEqual, newValue(1),
        """{"$1":1}""" % letterVar, dictName="l")

  test "assignVariable wVariableMissing":
    check testAssignVarWarn("w.hello", opEqual, newValue(1),
      wVariableMissing, "w")

  test "assignVariable wImmutableVars2":
    ## Set variables then try to change them.
    let json1 = """{"five":1}"""
    check testAssignVarFlex("five", opEqual, newValue(1), json1)
    check testAssignVarWarn("five", opEqual, newValue(2),
      wImmutableVars, inVars=json1)

    check testAssignVarFlex("l.five", opEqual, newValue(1), json1)
    check testAssignVarWarn("l.five", opEqual, newValue(2),
      wImmutableVars, inVars=json1)

    check testAssignVarFlex("o.five", opEqual, newValue(1),
      json1, dictName="o")
    check testAssignVarWarn("o.five", opEqual, newValue(2),
      wReadOnlyCodeVars, inVars=json1, dictName="o")

    check testAssignVarWarn("o.five", opEqual, newValue(2),
      wReadOnlyCodeVars, inVars=json1, dictName="o")

  test "assignVariable tea vars":
    ## Set tea variables then try to change them.
    let tkeys = """"args":{},"row":0,"version":"$1""""  % staticteaVersion

    let json1 = """{$1,"maxLines":2}""" % tkeys
    check testAssignVarFlex("t.maxLines", opEqual, newValue(2),
      json1, dictName="t")
    check testAssignVarWarn("t.maxLines", opEqual, newValue(3),
      wTeaVariableExists, inVars = json1, dictName="t")

    let json2 = """{$1,"output":"stderr"}""" % tkeys
    check testAssignVarFlex("t.output", opEqual, newValue("stderr"),
      json2, dictName="t")
    check testAssignVarWarn("t.output", opEqual, newValue("result"),
      wTeaVariableExists, inVars = json2, dictName="t")

  test "assignVariable wReadOnlyTeaVar row":
    check testAssignVarWarn("t.row", opEqual, newValue(1),
      wReadOnlyTeaVar, "row")

  test "assignVariable wReadOnlyTeaVar args":
    check testAssignVarWarn("t.args", opEqual, newValue(1),
      wReadOnlyTeaVar, "args")

  test "assignVariable wInvalidTeaVar server":
    check testAssignVarWarn("t.s", opEqual, newValue(1),
      wInvalidTeaVar, "s")

  test "assignVariable wReadOnlyTeaVar version":
    check testAssignVarWarn("t.version", opEqual, newValue(1),
      wReadOnlyTeaVar, "version")

  test "assignVariable missing tea var":
    check testAssignVarWarn("t.missing", opEqual, newValue(1),
      wInvalidTeaVar, "missing")

  test "assignVariable args help":
    check testAssignVarWarn("t.args.help", opEqual, newValue(1),
      wReadOnlyTeaVar, "args")

  test "assignVariable maxLines not int":
    check testAssignVarWarn("t.maxLines", opEqual, newValue("max"),
      wInvalidMaxCount)

  test "assignVariable maxLines less 0":
    check testAssignVarWarn("t.maxLines", opEqual, newValue(-1),
      wInvalidMaxCount)

  test "assignVariable maxRepeat not int":
    check testAssignVarWarn("t.maxRepeat", opEqual, newValue("str"),
      wInvalidMaxRepeat)

  test "assignVariable maxRepeat less 0":
    check testAssignVarWarn("t.maxRepeat", opEqual, newValue(-1),
      wInvalidMaxRepeat)

  test "assignVariable content not string":
    check testAssignVarWarn("t.content", opEqual, newValue(1),
      wInvalidTeaContent)

  test "assignVariable output not string":
    check testAssignVarWarn("t.output", opEqual, newValue(1),
      wInvalidOutputValue)

  test "assignVariable output invalid":
    check testAssignVarWarn("t.output", opEqual, newValue("overthere"),
      wInvalidOutputValue)

  test "assignVariable repeat less 0":
    check testAssignVarWarn("t.repeat", opEqual, newValue(-1),
      wInvalidRepeat)

  test "assignVariable repeat not int":
    check testAssignVarWarn("t.repeat", opEqual, newValue("tasf"),
      wInvalidRepeat)

  test "assignVariable repeat above max":
    check testAssignVarWarn("t.repeat", opEqual, newValue(101),
      wInvalidRepeat)

  test "assignVariable invalid tea var":
    check testAssignVarWarn("t.oops", opEqual, newValue(1),
      wInvalidTeaVar, "oops")

  test "assignVariable append to tea":
    check testAssignVarWarn("t", opAppendList, newValue("hello"),
      wImmutableVars)

  test "assignVariable append to tea args":
    check testAssignVarWarn("t.args", opAppendList, newValue("hello"),
      wReadOnlyTeaVar, "args")
    check testAssignVarWarn("t.args.hello", opAppendList, newValue("hello"),
      wReadOnlyTeaVar, "args")

  test "assignVariable nested dict":
    let json1 = """{"a":{"b2":"tea","b":{"c2":[],"c":{"d":"hello"}}}}"""
    let json2 = """{"a":{"b2":"tea","b":{"c2":[],"c":{"d":"hello","tea":1}}}}"""
    check testAssignVarFlex("l.a.b.c.tea", opEqual, newValue(1),
      eVars=json2, inVars=json1)

    check testAssignVarWarn("l.a.b", opAppendList, newValue(1),
      wAppendToList, "dict", inVars=json2)

    check testAssignVarWarn("l.a.b.missing.tea", opEqual, newValue(1),
      wVariableMissing, "missing", inVars = json2)

    check testAssignVarWarn("l.a.b2.missing.tea", opEqual, newValue(1),
      wNotDict, "b2", inVars = json2)

  test "append to a list":
    let json1 = """{"teas":[5]}"""
    let json2 = """{"teas":[5,6]}"""
    let json3 = """{"teas":[5,6,7]}"""
    check testAssignVarFlex("teas", opAppendList, newValue(5), json1)
    check testAssignVarFlex("teas", opAppendList, newValue(6), json2, json1)
    check testAssignVarFlex("teas", opAppendList, newValue(7), json3, json2)
    check testAssignVarFlex("teas", opAppendList, newValue(5), json1)
    check testAssignVarFlex("teas", opAppendList, newValue(6), json2, json1)

  test "append to a list2":
    let json1 = """{"a1":"hello","a2":{"b1":[]},"a3":[]}"""
    let json2 = """{"a1":"hello","a2":{"b1":[]},"a3":[],"teas":[5]}"""
    check testAssignVarFlex("l.teas", opAppendList, newValue(5),
      json2, json1)

    let json3 = """{"a1":"hello","a2":{"b1":[]},"a3":[],"teas":[5,6]}"""
    check testAssignVarFlex("teas", opAppendList, newValue(6),
      json3, json2)

    let json4 = """{"a1":"hello","a2":{"b1":[7]},"a3":[],"teas":[5,6]}"""
    check testAssignVarFlex("a2.b1", opAppendList, newValue(7),
      json4, json3)

  test "append nested dictionary":
    check testAssignVarFlex("a", opEqual, newValue(5), """{"a":5}""")
    check testAssignVarFlex("a", opEqual, newValue(5), """{"a":5}""")
    check testAssignVarFlex("a", opAppendList, newValue(5), """{"a":[5]}""")

    check testAssignVarFlex("l.a.tea", opAppendList, newValue(5),
      """{"a":{"tea":[5]}}""", """{"a":{}}""")
    check testAssignVarFlex("a", opAppendList, newValue(6),
      """{"a":[5,6]}""", """{"a":[5]}""")
    check testAssignVarFlex("l.a.sea", opAppendList, newValue(5),
      """{"a":{"tea":2,"sea":[5]}}""", """{"a":{"tea":2}}""")

  test "append list to a list":
    var variables = startVariables()
    var warningDataO = assignVariable(variables, "teas", newEmptyListValue(), opAppendList)
    check not warningDataO.isSome
    warningDataO = assignVariable(variables, "teas", newEmptyListValue(), opAppendList)
    check not warningDataO.isSome

  test "append to a non-list":
    var variables = startVariables()
    var warningDataO = assignVariable(variables, "a", newValue(5))
    check not warningDataO.isSome
    let eWarningDataO = some(newWarningData(wAppendToList, "int"))
    warningDataO = assignVariable(variables, "a", newValue(6), opAppendList)
    check warningDataO == eWarningDataO

  test "ValueOr string":
    check $newValueOr(newValue(2)) == $newValueOr(newValue(2))
    check $newValueOr(wInvalidJsonRoot) == $newValueOr(wInvalidJsonRoot)
