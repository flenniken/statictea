import unittest
import options
import strutils
import options
import env
import vartypes
import runFunction
import variables

proc testFunction(functionName: string, parameters: seq[Value],
    eValueO: Option[Value] = none(Value),
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[]
  ): bool =

  var env = openEnvTest("_testFunction.log", "template.html")
  let lineNum = 1

  let functionO = getFunction(functionName)
  let function = functionO.get()
  let valueO = function(env, lineNum, parameters)

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

  test "getFunction":
    let function = getFunction("len")
    check isSome(function)

  test "getFunction not":
    let function = getFunction("notfunction")
    check not isSome(function)

  test "funConcat 0":
    var parameters: seq[Value] = @[]
    let eValueO = some(newValue(""))
    check testFunction("concat", parameters, eValueO = eValueO)

  test "funConcat 1":
    var parameters = @[newValue("abc")]
    let eValueO = some(newValue("abc"))
    check testFunction("concat", parameters, eValueO = eValueO)

  test "funConcat 2":
    var parameters = @[newValue("abc"), newValue(" def")]
    let eValueO = some(newValue("abc def"))
    check testFunction("concat", parameters, eValueO = eValueO)

  test "funConcat 3":
    var parameters = @[newValue("abc"), newValue(""), newValue("def")]
    let eValueO = some(newValue("abcdef"))
    check testFunction("concat", parameters, eValueO = eValueO)

  test "funConcat not string":
    var parameters = @[newValue(5)]
    let eValueO = none(Value)
    let eErrLines = @[
      "template.html(1): w47: Concat parameter 1 is not a string.",
    ]
    check testFunction("concat", parameters, eValueO = eValueO, eErrLines = eErrLines)

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

  test "len string":
    var parameters = @[newValue("abc")]
    let eValueO = some(newValue(3))
    check testFunction("len", parameters, eValueO = eValueO)

  test "len list":
    var parameters = @[newValue([5, 3])]
    let eValueO = some(newValue(2))
    check testFunction("len", parameters, eValueO = eValueO)

  test "len dict":
    var parameters = @[newValue([("a", 5), ("b", 3)])]
    let eValueO = some(newValue(2))
    check testFunction("len", parameters, eValueO = eValueO)

  test "len strings":
    var parameters = @[newValue(["5", "3", "hi"])]
    let eValueO = some(newValue(3))
    check testFunction("len", parameters, eValueO = eValueO)

  test "len float":
    let eErrLines = @["template.html(1): w50: Len takes a string, list or dict parameter."]
    var parameters = @[newValue(3.4)]
    check testFunction("len", parameters, eErrLines = eErrLines)

  test "len int":
    let eErrLines = @["template.html(1): w50: Len takes a string, list or dict parameter."]
    var parameters = @[newValue(3)]
    check testFunction("len", parameters, eErrLines = eErrLines)

  test "len nothing":
    let eErrLines = @["template.html(1): w49: Expected one parameter."]
    var parameters: seq[Value] = @[]
    check testFunction("len", parameters, eErrLines = eErrLines)

  test "len 2":
    let eErrLines = @["template.html(1): w49: Expected one parameter."]
    var parameters = @[newValue(3), newValue(2)]
    check testFunction("len", parameters, eErrLines = eErrLines)
