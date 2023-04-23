import std/unittest
import std/strutils
import std/typetraits
import env
import sharedtestcode

suite "env.nim":

  test "open close":
    var env = openEnv()
    env.close()
    check env.logFilename == ""

  test "endsWith":
    check endsWith("123", "") == true
    check endsWith("123", "3") == true
    check endsWith("123", "23") == true
    check endsWith("123", "123") == true
    check endsWith("", "") == true

  test "endsWith false":
    check endsWith("123", "2") == false
    check endsWith("123", "0123") == false
    check endsWith("", "3") == false

  test "cannot open log":
    var env = openEnvTest("")

    let eErrLines = @[
      "nofile(0): w8: Unable to open log file: ''.\n"
    ]
    check env.readCloseDeleteCompare(eErrLines = eErrLines)
