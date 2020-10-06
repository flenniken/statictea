
import unittest
import env
import logenv
import typetraits
import options

let testMsg1 = "testProc called"
let testMsg2 = "testProc done"

proc testProc(env: var Env) =
  env.log(testMsg1)
  env.log(testMsg2)

suite "env.nim":

  test "open close":
    var env = openEnv()
    check env.logEnv.filename == "statictea.log"
    env.close()

  test "log":
    let outMsg = "standard out line"
    let errMsg = "this is a warning"
    var env = openEnv("_test.log")
    testProc(env)
    env.writeLine(outMsg)
    env.warn(errMsg)
    var (logLines, errLines, outLines) = env.readCloseDelete()

    check logLines.len == 2
    var logLine = parseLine(logLines[0]).get()
    check logLine.message == testMsg1
    logLine = parseLine(logLines[1]).get()
    check logLine.message == testMsg2

    check errLines.len == 1
    check errLines[0] == errMsg

    check outLines.len == 1
    check outLines[0] == outMsg

