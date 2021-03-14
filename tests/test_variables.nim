
import unittest
# import env
# import args
import variables
import tables
import vartypes

suite "variables.nim":

  test "getTestVariables":
    var variables = getTestVariables()
    # echoVariables(variables)
    check variables["server"].dictv.len == 1
    check variables["shared"].dictv.len == 1
    check variables["local"].dictv.len == 1
    check variables["global"].dictv.len == 1

  test "set var":
    var variables = getTestVariables()
    variables["repeat"] = Value(kind: vkInt, intv: 100)

  # test "echoVariables":
  #   var variables = getTestVariables()
  #   echoVariables(variables)

  test "newVariables":
    var emptyVarsDict: VarsDict
    var variables = newVariables(emptyVarsDict, emptyVarsDict)
    # echoVariables(variables)
    check variables.len == 6
    check "server" in variables
    check "shared" in variables
    check "local" in variables
    check "global" in variables
    check "row" in variables
    check "version" in variables
    check variables["row"] == newValue(0)

  test "getTeaVarString":
    var emptyVarsDict: VarsDict
    var variables = newVariables(emptyVarsDict, emptyVarsDict)
    check getTeaVarString(variables, "output") == "result"

  test "getTeaVarInt":
    var emptyVarsDict: VarsDict
    var variables = newVariables(emptyVarsDict, emptyVarsDict)
    check getTeaVarInt(variables, "row") == 0
    check getTeaVarInt(variables, "repeat") == 1
    check getTeaVarInt(variables, "maxLines") == 10
    check getTeaVarInt(variables, "maxRepeat") == 100

  test "resetVariables":
    var emptyVarsDict: VarsDict
    var variables = newVariables(emptyVarsDict, emptyVarsDict)
    resetVariables(variables)
    check variables.len == 6
    check "server" in variables
    check "shared" in variables
    check "local" in variables
    check "global" in variables
    check "row" in variables
    check "version" in variables
    check variables["row"] == newValue(0)
