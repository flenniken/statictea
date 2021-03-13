import unittest
import options
import strutils
import options
import env
import vartypes
import runFunction
import warnings
import tables

proc testFunction(functionName: string, parameters: seq[Value],
    eFunResult: FunResult,
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[]
  ): bool =

  var env = openEnvTest("_testFunction.log")
  let functionO = getFunction(functionName)
  let function = functionO.get()

  let funResult = function(parameters)

  result = env.readCloseDeleteCompare(eLogLines, eErrLines, eOutLines)

  if not expectedItem("funResult", funResult, eFunResult):
    result = false

proc testCmpFun[T](a: T, b: T, caseInsensitive: bool = false, expected: int = 0): bool =
  ## Test the cmpFun
  var parameters: seq[Value]
  if caseInsensitive:
    parameters = @[newValue(a), newValue(b), newValue(1)]
  else:
    parameters = @[newValue(a), newValue(b)]
  let eFunResult = newFunResult(newValue(expected))
  result = testFunction("cmp", parameters, eFunResult = eFunResult)

suite "runFunction.nim":

  test "getFunction":
    let function = getFunction("len")
    check isSome(function)

  test "getFunction not":
    let function = getFunction("notfunction")
    check not isSome(function)

  test "funConcat 2":
    var parameters = @[newValue("abc"), newValue(" def")]
    let eFunResult = newFunResult(newValue("abc def"))
    check testFunction("concat", parameters, eFunResult)

  test "funConcat 3":
    var parameters = @[newValue("abc"), newValue(""), newValue("def")]
    let eFunResult = newFunResult(newValue("abcdef"))
    check testFunction("concat", parameters, eFunResult)

  test "funConcat 0":
    var parameters = @[newValue(5)]
    let eFunResult = newFunResultWarn(wTwoOrMoreParameters)
    check testFunction("concat", parameters, eFunResult)

  test "funConcat 1":
    var parameters = @[newValue("abc")]
    let eFunResult = newFunResultWarn(wTwoOrMoreParameters)
    check testFunction("concat", parameters, eFunResult)

  test "funConcat not string":
    var parameters = @[newValue("abc"), newValue(5)]
    let eFunResult = newFunResultWarn(wExpectedString, 1)
    check testFunction("concat", parameters, eFunResult)

  test "runFunction":
    let parameters = @[newValue("Hello"), newValue(" World")]
    let eFunResult = newFunResult(newValue("Hello World"))
    check testFunction("concat", parameters, eFunResult)

  test "len string":
    var parameters = @[newValue("abc")]
    let eFunResult = newFunResult(newValue(3))
    check testFunction("len", parameters, eFunResult)

  test "len unicode string":
    # The byte length is different than the number of unicode characters.
    let str = "añyóng"
    check str.len == 8
    var parameters = @[newValue(str)]
    let eFunResult = newFunResult(newValue(6))
    check testFunction("len", parameters, eFunResult)

  test "len list":
    var parameters = @[newValue([5, 3])]
    let eFunResult = newFunResult(newValue(2))
    check testFunction("len", parameters, eFunResult)

  test "len dict":
    var parameters = @[newValue([("a", 5), ("b", 3)])]
    let eFunResult = newFunResult(newValue(2))
    check testFunction("len", parameters, eFunResult)

  test "len strings":
    var parameters = @[newValue(["5", "3", "hi"])]
    let eFunResult = newFunResult(newValue(3))
    check testFunction("len", parameters, eFunResult)

  test "len float":
    var parameters = @[newValue(3.4)]
    let eFunResult = newFunResultWarn(wStringListDict)
    check testFunction("len", parameters, eFunResult)

  test "len int":
    var parameters = @[newValue(3)]
    let eFunResult = newFunResultWarn(wStringListDict)
    check testFunction("len", parameters, eFunResult)

  test "len nothing":
    var parameters: seq[Value] = @[]
    let eFunResult = newFunResultWarn(wOneParameter)
    check testFunction("len", parameters, eFunResult)

  test "len 2":
    var parameters = @[newValue(3), newValue(2)]
    let eFunResult = newFunResultWarn(wOneParameter)
    check testFunction("len", parameters, eFunResult)

  test "get list item":
    var list = newValue([1, 2, 3, 4, 5])
    var parameters = @[list, newValue(0)]
    let eFunResult = newFunResult(newValue(1))
    check testFunction("get", parameters, eFunResult)

  test "get list default":
    var list = newValue([1, 2, 3, 4, 5])
    var parameters = @[list, newValue(5), newValue(100)]
    let eFunResult = newFunResult(newValue(100))
    check testFunction("get", parameters, eFunResult)

  test "get list invalid index":
    var list = newValue([1, 2, 3, 4, 5])
    var parameters = @[list, newValue(12)]
    let eFunResult = newFunResultWarn(wMissingListItem, 1, "12")
    check testFunction("get", parameters, eFunResult)

  test "get dict item":
    var dict = newValue([("a", 1), ("b", 2), ("c", 3), ("d", 4), ("e", 5)])
    var parameters = @[dict, newValue("b")]
    let eFunResult = newFunResult(newValue(2))
    check testFunction("get", parameters, eFunResult)

  test "get dict default":
    var dict = newValue([("a", 1), ("b", 2), ("c", 3), ("d", 4), ("e", 5)])
    var parameters = @[dict, newValue("t"), newValue("hi")]
    let eFunResult = newFunResult(newValue("hi"))
    check testFunction("get", parameters, eFunResult)

  test "get dict item missing":
    var dict = newValue([("a", 1), ("b", 2), ("c", 3), ("d", 4), ("e", 5)])
    var parameters = @[dict, newValue("p")]
    let eFunResult = newFunResultWarn(wMissingDictItem, 1, "p")
    check testFunction("get", parameters, eFunResult)

  test "get one parameter":
    var list = newValue([1, 2, 3, 4, 5])
    var parameters = @[list]
    let eFunResult = newFunResultWarn(wGetTakes2or3Params)
    check testFunction("get", parameters, eFunResult)

  test "get 4 parameters":
    var list = newValue([1, 2, 3, 4, 5])
    let p = newValue(1)
    var parameters = @[list, p, p, p]
    let eFunResult = newFunResultWarn(wGetTakes2or3Params)
    check testFunction("get", parameters, eFunResult)

  test "get parameter 2 wrong type":
    var list = newValue([1, 2, 3, 4, 5])
    var parameters = @[list, newValue("a")]
    let eFunResult = newFunResultWarn(wExpectedIntFor2, 1, "string")
    check testFunction("get", parameters, eFunResult)

  test "get parameter 2 wrong type dict":
    var dict = newValue([("a", 1), ("b", 2), ("c", 3), ("d", 4), ("e", 5)])
    var parameters = @[dict, newValue(3.5)]
    let eFunResult = newFunResultWarn(wExpectedStringFor2, 1, "float")
    check testFunction("get", parameters, eFunResult)

  test "get wrong first parameter":
    var parameters = @[newValue(2), newValue(3.5)]
    let eFunResult = newFunResultWarn(wExpectedListOrDict)
    check testFunction("get", parameters, eFunResult)

  test "get invalid index":
    var list = newValue([1, 2, 3, 4, 5])
    var parameters = @[list, newValue(-1)]
    let eFunResult = newFunResultWarn(wInvalidIndex, 1, "-1")
    check testFunction("get", parameters, eFunResult)

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
    let eFunResult = newFunResult(newValue("true"))
    check testFunction("if", parameters, eFunResult)

  test "if function false":
    var parameters = @[newValue(33), newValue("true"), newValue("false")]
    let eFunResult = newFunResult(newValue("false"))
    check testFunction("if", parameters, eFunResult)

  test "if wrong condition type":
    var parameters = @[newValue(3.4), newValue("true"), newValue("false")]
    let eFunResult = newFunResultWarn(wExpectedInteger)
    check testFunction("if", parameters, eFunResult)

  test "if wrong number of parameters":
    var parameters = @[newValue(2), newValue("false")]
    let eFunResult = newFunResultWarn(wThreeParameters)
    check testFunction("if", parameters, eFunResult)

  test "add function 2 int parameters":
    var parameters = @[newValue(1), newValue(2)]
    let eFunResult = newFunResult(newValue(3))
    check testFunction("add", parameters, eFunResult)

  test "add function 3 int parameters":
    var parameters = @[newValue(1), newValue(2), newValue(3)]
    let eFunResult = newFunResult(newValue(6))
    check testFunction("add", parameters, eFunResult)

  test "add function 2 float parameters":
    var parameters = @[newValue(2.0), newValue(3.5)]
    let eFunResult = newFunResult(newValue(5.5))
    check testFunction("add", parameters, eFunResult)

  test "add wrong number of parameters":
    var parameters = @[newValue(2)]
    let eFunResult = newFunResultWarn(wTwoOrMoreParameters)
    check testFunction("add", parameters, eFunResult)

  test "add wrong type of parameters":
    var parameters = @[newValue("hi"), newValue(4)]
    let eFunResult = newFunResultWarn(wAllIntOrFloat)
    check testFunction("add", parameters, eFunResult)

  test "add wrong type of parameters 2":
    var parameters = @[newValue(4), newValue("hi")]
    let eFunResult = newFunResultWarn(wAllIntOrFloat)
    check testFunction("add", parameters, eFunResult)

  test "add wrong type of parameters 3":
    var parameters = @[newValue(4), newValue(1.3)]
    let eFunResult = newFunResultWarn(wAllIntOrFloat)
    check testFunction("add", parameters, eFunResult)

  test "add int64 overflow":
    var parameters = @[newValue(high(int64)), newValue(1)]
    let eFunResult = newFunResultWarn(wOverflow)
    check testFunction("add", parameters, eFunResult)

  test "add int64 underflow":
    var parameters = @[newValue(low(int64)), newValue(-1)]
    let eFunResult = newFunResultWarn(wOverflow)
    check testFunction("add", parameters, eFunResult)

  test "add float64 overflow":
    var big = 1.7976931348623158e+308
    var parameters = @[newValue(big), newValue(big)]
    let eFunResult = newFunResultWarn(wOverflow)
    check testFunction("add", parameters, eFunResult)

  test "exists 1":
    var dict = newValue([("a", 1), ("b", 2), ("c", 3), ("d", 4), ("e", 5)])
    var parameters = @[dict, newValue("b")]
    let eFunResult = newFunResult(newValue(1))
    check testFunction("exists", parameters, eFunResult)

  test "exists 0":
    var dict = newValue([("a", 1), ("b", 2), ("c", 3), ("d", 4), ("e", 5)])
    var parameters = @[dict, newValue("z")]
    let eFunResult = newFunResult(newValue(0))
    check testFunction("exists", parameters, eFunResult)

  test "exists wrong number of parameters":
    var parameters = @[newValue("z")]
    let eFunResult = newFunResultWarn(wTwoParameters)
    check testFunction("exists", parameters, eFunResult)

  test "exists not dict":
    var parameters = @[newValue("z"), newValue("a")]
    let eFunResult = newFunResultWarn(wExpectedDictionary)
    check testFunction("exists", parameters, eFunResult)

  test "exists not string":
    var dict = newValue([("a", 1), ("b", 2), ("c", 3), ("d", 4), ("e", 5)])
    var parameters = @[dict, newValue(0)]
    let eFunResult = newFunResultWarn(wExpectedString, 1)
    check testFunction("exists", parameters, eFunResult)

  test "case int":
    var parameters = @[newValue(5), newValue(5), newValue("value"), newValue("else")]
    let eFunResult = newFunResult(newValue("value"))
    check testFunction("case", parameters, eFunResult = eFunResult)

  test "case int else":
    var parameters = @[newValue(5), newValue(6), newValue("value"), newValue("else")]
    let eFunResult = newFunResult(newValue("else"))
    check testFunction("case", parameters, eFunResult = eFunResult)

  test "case string":
    var parameters = @[newValue("test"), newValue("test"), newValue("value"), newValue("else")]
    let eFunResult = newFunResult(newValue("value"))
    check testFunction("case", parameters, eFunResult = eFunResult)

  test "case string else":
    var parameters = @[newValue("test"), newValue("asdf"), newValue("value"), newValue("else")]
    let eFunResult = newFunResult(newValue("else"))
    check testFunction("case", parameters, eFunResult = eFunResult)

  test "case int 6":
    var parameters = @[newValue(6), newValue(5), newValue("v5"), newValue(6), newValue("v6"), newValue("else")]
    let eFunResult = newFunResult(newValue("v6"))
    check testFunction("case", parameters, eFunResult = eFunResult)

  test "case int 12":
    var parameters = @[
      newValue(9),
      newValue(5), newValue("v5"),
      newValue(6), newValue("v6"),
      newValue(7), newValue("v7"),
      newValue(8), newValue("v8"),
      newValue(9), newValue("v9"),
      newValue("else"),
    ]
    let eFunResult = newFunResult(newValue("v9"))
    check testFunction("case", parameters, eFunResult = eFunResult)

  test "case dup":
    var parameters = @[
      newValue(5),
      newValue(5), newValue(8),
      newValue(5), newValue(9),
      newValue("else"),
    ]
    let eFunResult = newFunResult(newValue(8))
    check testFunction("case", parameters, eFunResult = eFunResult)

  test "case match with no else":
    var parameters = @[newValue(5), newValue(5), newValue("five")]
    let eFunResult = newFunResult(newValue("five"))
    check testFunction("case", parameters, eFunResult)

  test "case no match with no else":
    var parameters = @[newValue(5), newValue(1), newValue("five")]
    let eFunResult = newFunResultWarn(wMissingElse)
    check testFunction("case", parameters, eFunResult)

  test "case no match with no else 2":
    var parameters = @[newValue(5), newValue(1), newValue("five"), newValue(2), newValue("asdf")]
    let eFunResult = newFunResultWarn(wMissingElse)
    check testFunction("case", parameters, eFunResult)

  test "case multiple matches":
    var parameters = @[
      newValue(5),
      newValue(5), newValue(8),
      newValue(5), newValue("eight"),
    ]
    let eFunResult = newFunResult(newValue(8))
    check testFunction("case", parameters, eFunResult)

  test "case invalid main condition":
    var parameters = @[
      newValue(3.5),
      newValue(5), newValue(8),
      newValue(5), newValue(9),
      newValue("else")
    ]
    let eFunResult = newFunResultWarn(wInvalidMainType)
    check testFunction("case", parameters, eFunResult)

  test "case invalid condition":
    var parameters = @[
      newValue(5),
      newValue(5), newValue(8),
      newValue(3.5), newValue(9),
      newValue("else")
    ]
    let eFunResult = newFunResultWarn(wInvalidCondition, 3)
    check testFunction("case", parameters, eFunResult)

  test "case case different type":
    var parameters = @[
      newValue(1),
      newValue("abc"), newValue(33),
      newValue(1), newValue(22),
      newValue("else")
    ]
    let eFunResult = newFunResult(newValue(22))
    check testFunction("case", parameters, eFunResult)

  test "case optional else":
    var parameters = @[
      newValue(1),
      newValue("abc"), newValue(33),
      newValue(1), newValue(22),
    ]
    let eFunResult = newFunResult(newValue(22))
    check testFunction("case", parameters, eFunResult)

  test "to int happy":
    let testCases = [
      (newValue(2.34), "round", 2),
      (newValue(-2.34), "round", -2),
      (newValue(4.57), "floor", 4),
      (newValue(-4.57), "floor", -5),
      (newValue(6.3), "ceiling", 7),
      (newValue(-6.3), "ceiling", -6),
      (newValue(6.3456), "truncate", 6),
      (newValue(-6.3456), "truncate", -6),

      (newValue("2.34"), "round", 2),
      (newValue("-2.34"), "round", -2),
      (newValue("4.57"), "floor", 4),
      (newValue("-4.57"), "floor", -5),
      (newValue("6.3"), "ceiling", 7),
      (newValue("-6.3"), "ceiling", -6),
      (newValue("6.3456"), "truncate", 6),
      (newValue("-6.3456"), "truncate", -6),

      (newValue("2"), "round", 2),
      (newValue("-2"), "round", -2),
    ]
    for oneCase in testCases:
      var parameters = @[oneCase[0], newValue(oneCase[1])]
      let eFunResult = newFunResult(newValue(oneCase[2]))
      if not testFunction("int", parameters, eFunResult = eFunResult):
        echo $oneCase
        fail

  test "to int: default":
    var parameters = @[newValue(4.57)]
    let eFunResult = newFunResult(newValue(5))
    check testFunction("int", parameters, eFunResult = eFunResult)

  test "to int: wrong number of parameters":
    var parameters = @[newValue(4.57), newValue(1), newValue(2)]
    let eFunResult = newFunResultWarn(wOneOrTwoParameters)
    check testFunction("int", parameters, eFunResult = eFunResult)

  test "to int: not a number string":
    var parameters = @[newValue("hello"), newValue("round")]
    let eFunResult = newFunResultWarn(wFloatOrStringNumber)
    check testFunction("int", parameters, eFunResult = eFunResult)

  test "to int: not a float":
    var parameters = @[newValue(3), newValue("round")]
    let eFunResult = newFunResultWarn(wFloatOrStringNumber)
    check testFunction("int", parameters, eFunResult = eFunResult)

  test "to int: not round option":
    var parameters = @[newValue(3.4), newValue(5)]
    let eFunResult = newFunResultWarn(wExpectedRoundOption, 1)
    check testFunction("int", parameters, eFunResult = eFunResult)

  test "to int: not a float":
    var parameters = @[newValue(3.5), newValue("rounder")]
    let eFunResult = newFunResultWarn(wExpectedRoundOption, 1)
    check testFunction("int", parameters, eFunResult = eFunResult)

  test "to int: to big":
    var parameters = @[newValue(3.5e300), newValue("round")]
    let eFunResult = newFunResultWarn(wNumberOverFlow)
    check testFunction("int", parameters, eFunResult = eFunResult)

  test "to int: to small":
    var parameters = @[newValue(-3.5e300), newValue("round")]
    let eFunResult = newFunResultWarn(wNumberOverFlow)
    check testFunction("int", parameters, eFunResult = eFunResult)


  test "to float":
    var parameters = @[newValue(3)]
    let eFunResult = newFunResult(newValue(3.0))
    check testFunction("float", parameters, eFunResult = eFunResult)

  test "to float minus":
    var parameters = @[newValue(-3)]
    let eFunResult = newFunResult(newValue(-3.0))
    check testFunction("float", parameters, eFunResult = eFunResult)

  test "to float from string":
    var parameters = @[newValue("-3")]
    let eFunResult = newFunResult(newValue(-3.0))
    check testFunction("float", parameters, eFunResult = eFunResult)

  test "to float from string 2":
    var parameters = @[newValue("-3.5")]
    let eFunResult = newFunResult(newValue(-3.5))
    check testFunction("float", parameters, eFunResult = eFunResult)

  test "to float wrong number parameters":
    var parameters = @[newValue(4), newValue(3)]
    let eFunResult = newFunResultWarn(wOneParameter)
    check testFunction("float", parameters, eFunResult = eFunResult)

  test "to float warning":
    var parameters = @[newValue("abc")]
    let eFunResult = newFunResultWarn(wIntOrStringNumber)
    check testFunction("float", parameters, eFunResult = eFunResult)

  test "find":
    var parameters = @[newValue("Tea time at 4:00."), newValue("time")]
    let eFunResult = newFunResult(newValue(4))
    check testFunction("find", parameters, eFunResult = eFunResult)

  test "find start":
    var parameters = @[newValue("Tea time at 4:00."), newValue("Tea")]
    let eFunResult = newFunResult(newValue(0))
    check testFunction("find", parameters, eFunResult = eFunResult)

  test "find end":
    var parameters = @[newValue("Tea time at 4:00."), newValue("00.")]
    let eFunResult = newFunResult(newValue(14))
    check testFunction("find", parameters, eFunResult = eFunResult)

  test "find missing":
    var parameters = @[newValue("Tea time at 4:00."), newValue("party"), newValue("3:00")]
    let eFunResult = newFunResult(newValue("3:00"))
    check testFunction("find", parameters, eFunResult = eFunResult)

  test "find bigger":
    var parameters = @[newValue("big"), newValue("bigger"), newValue("smaller")]
    let eFunResult = newFunResult(newValue("smaller"))
    check testFunction("find", parameters, eFunResult = eFunResult)

  test "find nothing":
    var parameters = @[newValue("big"), newValue("")]
    let eFunResult = newFunResult(newValue(0))
    check testFunction("find", parameters, eFunResult = eFunResult)

  test "find from nothing":
    var parameters = @[newValue(""), newValue("")]
    let eFunResult = newFunResult(newValue(0))
    check testFunction("find", parameters, eFunResult = eFunResult)

  test "find from nothing 2":
    var parameters = @[newValue(""), newValue("2"), newValue(0)]
    let eFunResult = newFunResult(newValue(0))
    check testFunction("find", parameters, eFunResult = eFunResult)

  test "find missing no default":
    var parameters = @[newValue("Tea time at 4:00."), newValue("aTea")]
    let eFunResult = newFunResultWarn(wSubstringNotFound, 1)
    check testFunction("find", parameters, eFunResult = eFunResult)

  test "find 1 parameter":
    var parameters = @[newValue("big")]
    let eFunResult = newFunResultWarn(wTwoOrThreeParameters)
    check testFunction("find", parameters, eFunResult = eFunResult)

  test "find 1 not string":
    var parameters = @[newValue(1), newValue("bigger")]
    let eFunResult = newFunResultWarn(wExpectedString)
    check testFunction("find", parameters, eFunResult = eFunResult)

  test "find 2 not string":
    var parameters = @[newValue("at"), newValue(4.5)]
    let eFunResult = newFunResultWarn(wExpectedString, 1)
    check testFunction("find", parameters, eFunResult = eFunResult)

  test "substr Grey":
    var parameters = @[newValue("Earl Grey"), newValue(5)]
    let eFunResult = newFunResult(newValue("Grey"))
    check testFunction("substr", parameters, eFunResult = eFunResult)

  test "substr Earl":
    var parameters = @[newValue("Earl Grey"), newValue(0), newValue(4)]
    let eFunResult = newFunResult(newValue("Earl"))
    check testFunction("substr", parameters, eFunResult = eFunResult)

  test "substr 1 parameter":
    var parameters = @[newValue("big")]
    let eFunResult = newFunResultWarn(wTwoOrThreeParameters)
    check testFunction("substr", parameters, eFunResult = eFunResult)

  test "substr 1 not string":
    var parameters = @[newValue(4), newValue(4)]
    let eFunResult = newFunResultWarn(wExpectedString, 0)
    check testFunction("substr", parameters, eFunResult = eFunResult)

  test "substr 2 not int":
    var parameters = @[newValue("tasdf"), newValue("dsa")]
    let eFunResult = newFunResultWarn(wExpectedInteger, 1)
    check testFunction("substr", parameters, eFunResult = eFunResult)

  test "substr 3 not int":
    var parameters = @[newValue("tasdf"), newValue(0), newValue("tasdf")]
    let eFunResult = newFunResultWarn(wExpectedInteger, 2)
    check testFunction("substr", parameters, eFunResult = eFunResult)

  test "substr start < 0":
    var parameters = @[newValue("tasdf"), newValue(-2), newValue(0)]
    let eFunResult = newFunResultWarn(wInvalidPosition, 1, "-2")
    check testFunction("substr", parameters, eFunResult = eFunResult)

  test "substr finish > len":
    var parameters = @[newValue("tasdf"), newValue(0), newValue(10)]
    let eFunResult = newFunResultWarn(wInvalidPosition, 2, "10")
    check testFunction("substr", parameters, eFunResult = eFunResult)

  test "substr finish < start":
    var parameters = @[newValue("tasdf"), newValue(3), newValue(2)]
    let eFunResult = newFunResultWarn(wEndLessThenStart, 2)
    check testFunction("substr", parameters, eFunResult = eFunResult)

  test "substr nothing":
    var parameters = @[newValue("tasdf"), newValue(3), newValue(3)]
    let eFunResult = newFunResult(newValue(""))
    check testFunction("substr", parameters, eFunResult = eFunResult)

  test "dup":
    var parameters = @[newValue("-"), newValue(5)]
    let eFunResult = newFunResult(newValue("-----"))
    check testFunction("dup", parameters, eFunResult = eFunResult)

  test "dup 0":
    var parameters = @[newValue("-"), newValue(0)]
    let eFunResult = newFunResult(newValue(""))
    check testFunction("dup", parameters, eFunResult = eFunResult)

  test "dup 1":
    var parameters = @[newValue("abc"), newValue(1)]
    let eFunResult = newFunResult(newValue("abc"))
    check testFunction("dup", parameters, eFunResult = eFunResult)

  test "dup multiple":
    var parameters = @[newValue("123456789 "), newValue(2)]
    let eFunResult = newFunResult(newValue("123456789 123456789 "))
    check testFunction("dup", parameters, eFunResult = eFunResult)

  test "dup 1 parameter":
    var parameters = @[newValue("abc")]
    let eFunResult = newFunResultWarn(wTwoParameters, 0)
    check testFunction("dup", parameters, eFunResult = eFunResult)

  test "dup not valid string":
    var parameters = @[newValue(4.3), newValue(2)]
    let eFunResult = newFunResultWarn(wExpectedString, 0)
    check testFunction("dup", parameters, eFunResult = eFunResult)

  test "dup not valid count":
    var parameters = @[newValue("="), newValue("=")]
    let eFunResult = newFunResultWarn(wInvalidMaxCount, 1)
    check testFunction("dup", parameters, eFunResult = eFunResult)

  test "dup negative count":
    var parameters = @[newValue("="), newValue(-9)]
    let eFunResult = newFunResultWarn(wInvalidMaxCount, 1)
    check testFunction("dup", parameters, eFunResult = eFunResult)

  test "dup too long":
    var parameters = @[newValue("="), newValue(123_333)]
    let eFunResult = newFunResultWarn(wDupStringTooLong, 1, "123333")
    check testFunction("dup", parameters, eFunResult = eFunResult)

  test "dict":
    var parameters: seq[Value] = @[]
    var dict: VarsDict
    let eFunResult = newFunResult(newValue(dict))
    check testFunction("dict", parameters, eFunResult = eFunResult)

  test "dict 1 item":
    var parameters = @[newValue("a"), newValue(5)]
    var dict: VarsDict
    dict["a"] = newValue(5)
    let eFunResult = newFunResult(newValue(dict))
    check testFunction("dict", parameters, eFunResult = eFunResult)

  test "dict 2 items":
    var parameters = @[newValue("a"), newValue(5), newValue("b"), newValue("str")]
    var dict: VarsDict
    dict["a"] = newValue(5)
    dict["b"] = newValue("str")
    let eFunResult = newFunResult(newValue(dict))
    check testFunction("dict", parameters, eFunResult = eFunResult)

  test "dict 1 parameter":
    var parameters = @[newValue("a")]
    let eFunResult = newFunResultWarn(wPairParameters, 0)
    check testFunction("dict", parameters, eFunResult = eFunResult)

  test "dict 3 parameter":
    var parameters = @[newValue("a")]
    let eFunResult = newFunResultWarn(wPairParameters, 0)
    check testFunction("dict", parameters, eFunResult = eFunResult)

  test "dict not string key":
    var parameters = @[newValue("key"), newValue(1), newValue(2), newValue(1)]
    let eFunResult = newFunResultWarn(wExpectedString, 2)
    check testFunction("dict", parameters, eFunResult = eFunResult)
