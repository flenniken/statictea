
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
