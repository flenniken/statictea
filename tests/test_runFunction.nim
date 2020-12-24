import unittest
import options
import strutils
import options
import env
import vartypes
import runFunction

proc testFunConcat(parameters: seq[Value],
    eValueO: Option[Value] = none(Value),
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[]
  ): bool =

  var env = openEnvTest("_testFunConcat.log", "template.html")

  let valueO = funConcat(env, 1, parameters)

  result = env.readCloseDeleteCompare(eLogLines, eErrLines, eOutLines)
  if not expectedItem("value", valueO, eValueO):
    result = false

suite "runFunction.nim":

  test "funConcat 0":
    var parameters: seq[Value] = @[]
    let eValueO = some(newStringValue(""))
    check testFunConcat(parameters, eValueO = eValueO)

  test "funConcat 1":
    var parameters = @[newStringValue("abc")]
    let eValueO = some(newStringValue("abc"))
    check testFunConcat(parameters, eValueO = eValueO)

  test "funConcat 2":
    var parameters = @[newStringValue("abc"), newStringValue(" def")]
    let eValueO = some(newStringValue("abc def"))
    check testFunConcat(parameters, eValueO = eValueO)

  test "funConcat 3":
    var parameters = @[newStringValue("abc"), newStringValue(""), newStringValue("def")]
    let eValueO = some(newStringValue("abcdef"))
    check testFunConcat(parameters, eValueO = eValueO)
