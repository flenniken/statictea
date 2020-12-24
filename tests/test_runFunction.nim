import unittest
import options
import strutils
import options
import env
import vartypes
import runFunction
import variables

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

proc testRunFunction(
    functionName: string,
    parameters: seq[Value],
    statement: Statement = newStatement(text="dummy statement", lineNum=16, 0),
    start: Natural = 0,
    eValueO: Option[Value],
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[]
  ): bool =
  ## Test run a function.

  var env = openEnvTest("_testRunFunction.log", "template.html")

  var variables = getTestVariables()
  let valueO = runFunction(env, functionName, statement, start, variables, parameters)

  result = env.readCloseDeleteCompare(eLogLines, eErrLines, eOutLines)

  if not expectedItem("value", valueO, eValueO):
    result = false

suite "runFunction.nim":

  test "funConcat 0":
    var parameters: seq[Value] = @[]
    let eValueO = some(newValue(""))
    check testFunConcat(parameters, eValueO = eValueO)

  test "funConcat 1":
    var parameters = @[newValue("abc")]
    let eValueO = some(newValue("abc"))
    check testFunConcat(parameters, eValueO = eValueO)

  test "funConcat 2":
    var parameters = @[newValue("abc"), newValue(" def")]
    let eValueO = some(newValue("abc def"))
    check testFunConcat(parameters, eValueO = eValueO)

  test "funConcat 3":
    var parameters = @[newValue("abc"), newValue(""), newValue("def")]
    let eValueO = some(newValue("abcdef"))
    check testFunConcat(parameters, eValueO = eValueO)

  test "funConcat not string":
    var parameters = @[newValue(5)]
    let eValueO = none(Value)
    let eErrLines = @[
      "template.html(1): w47: Concat parameter 1 is not a string.",
    ]
    check testFunConcat(parameters, eValueO = eValueO, eErrLines = eErrLines)


  test "runFunction":
    let parameters = @[newValue("Hello"), newValue(" World")]
    let eValueO = some(newValue("Hello World"))
    check testRunFunction("concat", parameters, eValueO = eValueO)

  test "runFunction concat error":
    let statement = newStatement(text="""tea = concat("hello", 5)""", lineNum=16, 0)
    let start = 13
    let parameters = @[
      newValue("Hello"),
      newValue(5),
    ]
    let eValueO = none(Value)
    let eErrLines = @[
      "template.html(16): w47: Concat parameter 2 is not a string.",
      "template.html(16): w48: Invalid statement, skipping it.",
      """statement: tea = concat("hello", 5)""",
        "                        ^",
    ]
    check testRunFunction("concat", parameters, statement, start, eValueO, eErrLines = eErrLines)
