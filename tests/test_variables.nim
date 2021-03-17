
import unittest
import options
import variables
import tables
import vartypes
import env
import warnings

proc test_validateVariable(variables: Variables,
    nameSpace: string, varName: string, value: Value,
    eWarningDataPosO: Option[WarningDataPos] = none(WarningDataPos),
  ): bool =

  let warningDataPosO = validateVariable(variables, nameSpace, varName, value)

  if not expectedItem("warningDataPosO", warningDataPosO, eWarningDataPosO):
    result = false
  else:
    result = true

suite "variables.nim":

  test "emptyVariables":
    var variables = emptyVariables()
    # echoVariables(variables)
    check variables["local"].dictv.len == 0
    check variables["global"].dictv.len == 0
    check variables["row"].intv == 0
    check variables["version"].kind == vkString

  test "set var":
    var variables = emptyVariables()
    assignVariable(variables, "t.", "repeat", newValue(100))
    check variables["repeat"] == newValue(100)

  test "getTeaVarStringDefault":
    var variables = emptyVariables()
    check getTeaVarStringDefault(variables, "output") == "result"

  test "getTeaVarIntDefault":
    var variables = emptyVariables()
    check getTeaVarIntDefault(variables, "row") == 0
    check getTeaVarIntDefault(variables, "repeat") == 1
    check getTeaVarIntDefault(variables, "maxLines") == 10
    check getTeaVarIntDefault(variables, "maxRepeat") == 100

  test "resetVariables":
    var variables = emptyVariables()
    resetVariables(variables)
    check variables.len == 4
    check not ("server" in variables)
    check not ("shared" in variables)
    check "local" in variables
    check "global" in variables
    check "row" in variables
    check "version" in variables
    check variables["row"] == newValue(0)

  test "resetVariables with server and shared":
    var variables = emptyVariables()
    assignVariable(variables, "t.", "server", newValue(newVarsDict()))
    assignVariable(variables, "t.", "shared", newValue(newVarsDict()))
    resetVariables(variables)
    check variables.len == 6
    check "server" in variables
    check "shared" in variables
    check "local" in variables
    check "global" in variables
    check "row" in variables
    check "version" in variables
    check variables["row"] == newValue(0)

  test "assignVariable tea":
    var variables = emptyVariables()
    let value = newValue("99.0.8")
    assignVariable(variables, "t.", "version", value)
    check getVariable(variables, "t.", "version") == some(value)

  test "assignVariable global":
    var variables = emptyVariables()
    let value = newValue("99.0.8")
    assignVariable(variables, "g.", "version", value)
    check getVariable(variables, "g.", "version") == some(value)

  test "assignVariable local":
    var variables = emptyVariables()
    let value = newValue("99.0.8")
    assignVariable(variables, "", "version", value)
    check getVariable(variables, "", "version") == some(value)

  test "validateVariable":
    check test_validateVariable(emptyVariables(), "", "var", newValue(1))
    check test_validateVariable(emptyVariables(), "g.", "var", newValue(1))
    check test_validateVariable(emptyVariables(), "t.", "maxLines", newValue(20))
    check test_validateVariable(emptyVariables(), "t.", "maxRepeat", newValue(20))
    check test_validateVariable(emptyVariables(), "t.", "content", newValue("asdf"))
    check test_validateVariable(emptyVariables(), "t.", "output", newValue("stderr"))
    check test_validateVariable(emptyVariables(), "t.", "repeat", newValue(20))

  test "validateVariable wReadOnlyDictionary":
    let eWarningDataPosO = some(newWarningDataPos(wReadOnlyDictionary, warningSide = wsVarName))
    check test_validateVariable(emptyVariables(), "s.", "hello", newValue(1), eWarningDataPosO)
    check test_validateVariable(emptyVariables(), "h.", "hello", newValue(1), eWarningDataPosO)

  test "validateVariable wInvalidNameSpace":
    let eWarningDataPosO = some(newWarningDataPos(wInvalidNameSpace, "w.", warningSide = wsVarName))
    check test_validateVariable(emptyVariables(), "w.", "hello", newValue(1), eWarningDataPosO)

  test "validateVariable wImmutableVars":
    let eWarningDataPosO = some(newWarningDataPos(wImmutableVars, warningSide = wsVarName))
    var variables = emptyVariables()
    assignVariable(variables, "", "five", newValue(1))
    assignVariable(variables, "g.", "aboutfive", newValue(4.99))
    check test_validateVariable(variables, "", "five", newValue(1), eWarningDataPosO)
    check test_validateVariable(variables, "g.", "aboutfive", newValue(1), eWarningDataPosO)

  test "validateVariable wReadOnlyTeaVar row":
    let eWarningDataPosO = some(newWarningDataPos(wReadOnlyTeaVar, "row", warningSide = wsVarName))
    check test_validateVariable(emptyVariables(), "t.", "row", newValue(1), eWarningDataPosO)

  test "validateVariable wInvalidTeaVar server":
    let eWarningDataPosO = some(newWarningDataPos(wInvalidTeaVar, "server", warningSide = wsVarName))
    check test_validateVariable(emptyVariables(), "t.", "server", newValue(1), eWarningDataPosO)

  test "validateVariable wReadOnlyTeaVar server":
    let eWarningDataPosO = some(newWarningDataPos(wReadOnlyTeaVar, "server", warningSide = wsVarName))
    var variables = emptyVariables()
    assignVariable(variables, "t.", "server", newValue(newVarsDict()))
    check test_validateVariable(variables, "t.", "server", newValue(1), eWarningDataPosO)

  test "validateVariable wReadOnlyTeaVar version":
    let eWarningDataPosO = some(newWarningDataPos(wReadOnlyTeaVar, "version", warningSide = wsVarName))
    check test_validateVariable(emptyVariables(), "t.", "version", newValue(1), eWarningDataPosO)

  test "validateVariable maxLines not int":
    let eWarningDataPosO = some(newWarningDataPos(wInvalidMaxCount, "", warningSide = wsValue))
    check test_validateVariable(emptyVariables(), "t.", "maxLines", newValue("max"), eWarningDataPosO)

  test "validateVariable maxLines less 0":
    let eWarningDataPosO = some(newWarningDataPos(wInvalidMaxCount, "", warningSide = wsValue))
    check test_validateVariable(emptyVariables(), "t.", "maxLines", newValue(-1), eWarningDataPosO)

  test "validateVariable maxRepeat not int":
    let eWarningDataPosO = some(newWarningDataPos(wInvalidMaxRepeat, "", warningSide = wsValue))
    check test_validateVariable(emptyVariables(), "t.", "maxRepeat", newValue("str"), eWarningDataPosO)

  test "validateVariable maxRepeat less 0":
    let eWarningDataPosO = some(newWarningDataPos(wInvalidMaxRepeat, "", warningSide = wsValue))
    check test_validateVariable(emptyVariables(), "t.", "maxRepeat", newValue(-1), eWarningDataPosO)

  test "validateVariable content not string":
    let eWarningDataPosO = some(newWarningDataPos(wInvalidTeaContent, "", warningSide = wsValue))
    check test_validateVariable(emptyVariables(), "t.", "content", newValue(1), eWarningDataPosO)

  test "validateVariable output not string":
    let eWarningDataPosO = some(newWarningDataPos(wInvalidOutputValue, "", warningSide = wsValue))
    check test_validateVariable(emptyVariables(), "t.", "output", newValue(1), eWarningDataPosO)

  test "validateVariable output invalid":
    let eWarningDataPosO = some(newWarningDataPos(wInvalidOutputValue, "", warningSide = wsValue))
    check test_validateVariable(emptyVariables(), "t.", "output", newValue("overthere"), eWarningDataPosO)

  test "validateVariable repeat less 0":
    let eWarningDataPosO = some(newWarningDataPos(wInvalidRepeat, "", warningSide = wsValue))
    check test_validateVariable(emptyVariables(), "t.", "repeat", newValue(-1), eWarningDataPosO)

  test "validateVariable repeat not int":
    let eWarningDataPosO = some(newWarningDataPos(wInvalidRepeat, "", warningSide = wsValue))
    check test_validateVariable(emptyVariables(), "t.", "repeat", newValue("tasf"), eWarningDataPosO)

  test "validateVariable repeat above max":
    let eWarningDataPosO = some(newWarningDataPos(wInvalidRepeat, "", warningSide = wsValue))
    check test_validateVariable(emptyVariables(), "t.", "repeat", newValue(101), eWarningDataPosO)

  test "validateVariable invalid tea var":
    let eWarningDataPosO = some(newWarningDataPos(wInvalidTeaVar, "oops", warningSide = wsVarName))
    check test_validateVariable(emptyVariables(), "t.", "oops", newValue(1), eWarningDataPosO)
