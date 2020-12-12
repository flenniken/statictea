
import unittest
import env
import args
import variables
import tables

suite "variables.nim":

  test "readJsonVariables":
    var env = openEnvTest("_readJsonVariables.log")
    var args: Args
    var variables = readJsonVariables(env, args)
    check variables.server.len == 0
    check variables.shared.len == 0
    check variables.local.len == 0
    check variables.global.len == 0
    check variables.tea.len == 0

    let (logLines, errLines, outLines) = env.readCloseDelete()
    check logLines.len == 0
    check errLines.len == 0
    check outLines.len == 0

    env.close()
