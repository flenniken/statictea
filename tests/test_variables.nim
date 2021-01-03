
import unittest
import env
import args
import variables
import tables
import vartypes

suite "variables.nim":

  test "readJsonVariables":
    var env = openEnvTest("_readJsonVariables.log")

    var args: Args
    var variables = readJsonVariables(env, args)

    check env.readCloseDeleteCompare()

    check variables.server.len == 0
    check variables.shared.len == 0
    check variables.local.len == 0
    check variables.global.len == 0
    check variables.tea.len == 0



  test "getTestVariables":
    var variables = getTestVariables()
    # echo $variables
    check variables.server.len == 1
    check variables.shared.len == 1
    check variables.local.len == 1
    check variables.global.len == 1
    check variables.tea.len == 5

  test "set var":
    var variables = getTestVariables()
    variables.tea["repeat"] = Value(kind: vkInt, intv: 100)
