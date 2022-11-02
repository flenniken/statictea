import std/unittest
import std/tables
import startingvars
import env
import args
import vartypes

suite "startingvars.nim":

  test "test me":
    check 1 == 1

  test "getStartingVariables":
    var env = openEnvTest("_testGetStartingVariables.log")
    var args: Args
    var variables = getStartingVariables(env, args)

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
