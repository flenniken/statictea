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

  var env = openEnvTest("_testFunction.log")
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

  var env = openEnvTest("_testRunFunction.log")

  var variables = getTestVariables()
  var functionO = getFunction(functionName)
  if not isSome(functionO):
    echo "Function doesn't exists: " & functionName
    return false
  var function = functionO.get()

  let valueO = function(env, statement.lineNum, parameters)

  result = env.readCloseDeleteCompare(eLogLines, eErrLines, eOutLines)
  if not expectedItem("value", valueO, eValueO):
    result = false

proc testCmpFun[T](a: T, b: T, caseInsensitive: bool = false, expected: int = 0): bool =
  ## Test the cmpFun
  var parameters: seq[Value]
  if caseInsensitive:
    parameters = @[newValue(a), newValue(b), newValue(1)]
  else:
    parameters = @[newValue(a), newValue(b)]
  let eValueO = some(newValue(expected))
  result = testFunction("cmp", parameters, eValueO = eValueO)

suite "runFunction.nim":

  test "getFunction":
    let function = getFunction("len")
    check isSome(function)

  test "getFunction not":
    let function = getFunction("notfunction")
    check not isSome(function)

  test "funConcat 2":
    var parameters = @[newValue("abc"), newValue(" def")]
    let eValueO = some(newValue("abc def"))
    check testFunction("concat", parameters, eValueO = eValueO)

  test "funConcat 3":
    var parameters = @[newValue("abc"), newValue(""), newValue("def")]
    let eValueO = some(newValue("abcdef"))
    check testFunction("concat", parameters, eValueO = eValueO)

  test "funConcat 0":
    var parameters = @[newValue(5)]
    let eValueO = none(Value)
    let eErrLines = @[
      "template.html(1): w66: The function takes two or more parameters.\n"
    ]
    check testFunction("concat", parameters, eValueO = eValueO, eErrLines = eErrLines)

  test "funConcat 1":
    var parameters = @[newValue("abc")]
    let eValueO = none(Value)
    let eErrLines = @[
      "template.html(1): w66: The function takes two or more parameters.\n"
    ]
    check testFunction("concat", parameters, eValueO = eValueO, eErrLines = eErrLines)

  test "funConcat not string":
    var parameters = @[newValue("abc"), newValue(5)]
    let eValueO = none(Value)
    let eErrLines = @[
      "template.html(1): w47: Concat parameter 2 is not a string.\n",
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
      "template.html(16): w47: Concat parameter 2 is not a string.\n",
    ]
    check testRunFunction("concat", parameters, statement, start, eValueO, eErrLines = eErrLines)

  test "len string":
    var parameters = @[newValue("abc")]
    let eValueO = some(newValue(3))
    check testFunction("len", parameters, eValueO = eValueO)

  test "len unicode string":
    # The byte length is different than the number of unicode characters.
    let str = "añyóng"
    check str.len == 8
    var parameters = @[newValue(str)]
    let eValueO = some(newValue(6))
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
    let eErrLines = @["template.html(1): w50: Len takes a string, list or dict parameter.\n"]
    var parameters = @[newValue(3.4)]
    check testFunction("len", parameters, eErrLines = eErrLines)

  test "len int":
    let eErrLines = @["template.html(1): w50: Len takes a string, list or dict parameter.\n"]
    var parameters = @[newValue(3)]
    check testFunction("len", parameters, eErrLines = eErrLines)

  test "len nothing":
    let eErrLines = @["template.html(1): w49: Expected one parameter.\n"]
    var parameters: seq[Value] = @[]
    check testFunction("len", parameters, eErrLines = eErrLines)

  test "len 2":
    let eErrLines = @["template.html(1): w49: Expected one parameter.\n"]
    var parameters = @[newValue(3), newValue(2)]
    check testFunction("len", parameters, eErrLines = eErrLines)

  test "get list item":
    var list = newValue([1, 2, 3, 4, 5])
    var parameters = @[list, newValue(0)]
    check testFunction("get", parameters, eValueO = some(newValue(1)))

  test "get list default":
    var list = newValue([1, 2, 3, 4, 5])
    var hi = newValue("hi")
    # Index below.
    var parameters = @[list, newValue(-1), hi]
    check testFunction("get", parameters, eValueO = some(hi))
    # Index above.
    parameters = @[list, newValue(5), newValue(100)]
    check testFunction("get", parameters, eValueO = some(newValue(100)))

  test "get list invalid index":
    var list = newValue([1, 2, 3, 4, 5])
    var parameters = @[list, newValue(12)]
    let eErrLines = @["template.html(1): w54: The list index 12 out of range.\n"]
    check testFunction("get", parameters, eErrLines = eErrLines)

  test "get dict item":
    var dict = newValue([("a", 1), ("b", 2), ("c", 3), ("d", 4), ("e", 5)])
    var parameters = @[dict, newValue("b")]
    let eValueO = some(newValue(2))
    check testFunction("get", parameters, eValueO = eValueO)

  test "get dict default":
    var dict = newValue([("a", 1), ("b", 2), ("c", 3), ("d", 4), ("e", 5)])
    var hi = newValue("hi")
    var parameters = @[dict, newValue("t"), hi]
    check testFunction("get", parameters, eValueO = some(hi))

  test "get dict item missing":
    var dict = newValue([("a", 1), ("b", 2), ("c", 3), ("d", 4), ("e", 5)])
    var parameters = @[dict, newValue("p")]
    let eErrLines = @["template.html(1): w56: The dictionary does not have an item with key p.\n"]
    check testFunction("get", parameters, eErrLines = eErrLines)

  test "get one parameter":
    var list = newValue([1, 2, 3, 4, 5])
    var parameters = @[list]
    let eErrLines = @["template.html(1): w52: The get function takes 2 or 3 parameters.\n"]
    check testFunction("get", parameters, eErrLines = eErrLines)

  test "get 4 parameters":
    var list = newValue([1, 2, 3, 4, 5])
    let p = newValue(1)
    var parameters = @[list, p, p, p]
    let eErrLines = @["template.html(1): w52: The get function takes 2 or 3 parameters.\n"]
    check testFunction("get", parameters, eErrLines = eErrLines)

  test "get parameter 2 wrong type":
    var list = newValue([1, 2, 3, 4, 5])
    var parameters = @[list, newValue("a")]
    let eErrLines = @["template.html(1): w53: Expected an int for the second parameter, got string.\n"]
    check testFunction("get", parameters, eErrLines = eErrLines)

  test "get parameter 2 wrong type dict":
    var dict = newValue([("a", 1), ("b", 2), ("c", 3), ("d", 4), ("e", 5)])
    var parameters = @[dict, newValue(3.5)]
    let eErrLines = @["template.html(1): w55: Expected a string for the second parameter, got float.\n"]
    check testFunction("get", parameters, eErrLines = eErrLines)

  test "get wrong first parameter":
    var parameters = @[newValue(2), newValue(3.5)]
    let eErrLines = @["template.html(1): w57: Expected a list or dictionary as the first parameter.\n"]
    check testFunction("get", parameters, eErrLines = eErrLines)

  test "cmpString":
    check cmpString("", "") == 0
    check cmpString("a", "a") == 0
    check cmpString("abc", "abc") == 0
    check cmpString("abc", "ab") == 1
    check cmpString("ab", "abc") == -1
    check cmpString("a", "b") == -1
    check cmpString("b", "a") == 1
    check cmpString("abc", "abd") == -1
    check cmpString("abd", "abc") == 1
    check cmpString("ABC", "abc") == -1
    check cmpString("abc", "ABC") == 1

  test "cmpString case insensitive":
    check cmpString("", "", true) == 0
    check cmpString("a", "a", true) == 0
    check cmpString("abc", "abc", true) == 0
    check cmpString("abc", "ABC", true) == 0
    check cmpString("aBc", "Abd", true) == -1
    check cmpString("Abd", "aBc", true) == 1

  test "cmp ints":
    check testCmpFun(1, 1, expected = 0)
    check testCmpFun(1, 2, expected = -1)
    check testCmpFun(2, 1, expected = 1)

  test "cmp floats":
    check testCmpFun(1.0, 1.0, expected = 0)
    check testCmpFun(1.2, 2.0, expected = -1)
    check testCmpFun(2.1, 1.3, expected = 1)

  test "cmp strings":
    check testCmpFun("abc", "abc", expected = 0)
    check testCmpFun("abc", "abd", expected = -1)
    check testCmpFun("abd", "abc", expected = 1)
    check testCmpFun("ab", "abc", expected = -1)
    check testCmpFun("ab", "a", expected = 1)

  test "cmp strings case insensitive":
    check testCmpFun("abc", "abc", true, expected = 0)
    check testCmpFun("abc", "abd", true, expected = -1)
    check testCmpFun("abd", "abc", true, expected = 1)
    check testCmpFun("ABC", "abc", true, expected = 0)
    check testCmpFun("abc", "ABD", true, expected = -1)
    check testCmpFun("ABD", "abc", true, expected = 1)

  test "if function true":
    var parameters = @[newValue(1), newValue("true"), newValue("false")]
    let eValueO = some(newValue("true"))
    check testFunction("if", parameters, eValueO = eValueO)

  test "if function false":
    var parameters = @[newValue(33), newValue("true"), newValue("false")]
    let eValueO = some(newValue("false"))
    check testFunction("if", parameters, eValueO = eValueO)

  test "if wrong condition type":
    var parameters = @[newValue(3.4), newValue("true"), newValue("false")]
    let eErrLines = @["template.html(1): w70: The parameter must be an integer.\n"]
    check testFunction("if", parameters, eErrLines = eErrLines)

  test "if wrong number of parameters":
    var parameters = @[newValue(2), newValue("false")]
    let eErrLines = @["template.html(1): w69: Expected three parameters.\n"]
    check testFunction("if", parameters, eErrLines = eErrLines)

  test "add function 2 int parameters":
    var parameters = @[newValue(1), newValue(2)]
    let eValueO = some(newValue(3))
    check testFunction("add", parameters, eValueO = eValueO)

  test "add function 3 int parameters":
    var parameters = @[newValue(1), newValue(2), newValue(3)]
    let eValueO = some(newValue(6))
    check testFunction("add", parameters, eValueO = eValueO)

  test "add function 2 float parameters":
    var parameters = @[newValue(2.0), newValue(3.5)]
    let eValueO = some(newValue(5.5))
    check testFunction("add", parameters, eValueO = eValueO)

  test "add wrong number of parameters":
    var parameters = @[newValue(2)]
    let eErrLines = @["template.html(1): w66: The function takes two or more parameters.\n"]
    check testFunction("add", parameters, eErrLines = eErrLines)

  test "add wrong type of parameters":
    var parameters = @[newValue("hi"), newValue(4)]
    let eErrLines = @["template.html(1): w71: The parameters must be all integers or all floats.\n"]
    check testFunction("add", parameters, eErrLines = eErrLines)

  test "add wrong type of parameters 2":
    var parameters = @[newValue(4), newValue("hi")]
    let eErrLines = @["template.html(1): w71: The parameters must be all integers or all floats.\n"]
    check testFunction("add", parameters, eErrLines = eErrLines)

  test "add wrong type of parameters 3":
    var parameters = @[newValue(4), newValue(1.3)]
    let eErrLines = @["template.html(1): w71: The parameters must be all integers or all floats.\n"]
    check testFunction("add", parameters, eErrLines = eErrLines)

  test "add int64 overflow":
    var parameters = @[newValue(high(int64)), newValue(1)]
    let eErrLines = @["template.html(1): w72: Overflow or underflow.\n"]
    check testFunction("add", parameters, eErrLines = eErrLines)

  test "add int64 underflow":
    var parameters = @[newValue(low(int64)), newValue(-1)]
    let eErrLines = @["template.html(1): w72: Overflow or underflow.\n"]
    check testFunction("add", parameters, eErrLines = eErrLines)

  test "add float64 overflow":
    var big = 1.7976931348623158e+308
    var parameters = @[newValue(big), newValue(big)]
    let eErrLines = @["template.html(1): w72: Overflow or underflow.\n"]
    check testFunction("add", parameters, eErrLines = eErrLines)
