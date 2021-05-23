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
    if funResult.kind == frValue and funResult.value.kind == vkDict:
      echo "got:"
      for k, v in funResult.value.dictv.pairs:
        echo "  $1: '$2'" % [k, $v]
    if eFunResult.kind == frValue and eFunResult.value.kind == vkDict:
      echo "expected:"
      for k, v in eFunResult.value.dictv.pairs:
        echo "  $1: '$2'" % [k, $v]

proc testPathGood(path, filename, basename, ext, dir: string, separator = ""): bool =
    var parameters = @[newValue(path)]
    var dict = newVarsDict()
    dict["filename"] = newValue(filename)
    dict["basename"] = newValue(basename)
    dict["ext"] = newValue(ext)
    dict["dir"] = newValue(dir)
    let eFunResult = newFunResult(newValue(dict))
    if separator.len > 0:
      parameters.add(newValue(separator))
      result = testFunction("path", parameters, eFunResult = eFunResult)
    else:
      result = testFunction("path", parameters, eFunResult = eFunResult)

proc testCmpFun[T](a: T, b: T, caseInsensitive: bool = false, expected: int = 0): bool =
  ## Test the cmpFun
  var parameters: seq[Value]
  if caseInsensitive:
    parameters = @[newValue(a), newValue(b), newValue(1)]
  else:
    parameters = @[newValue(a), newValue(b)]
  let eFunResult = newFunResult(newValue(expected))
  result = testFunction("cmp", parameters, eFunResult = eFunResult)

proc testReplaceGood(str: string, start: int, length: int, replace: string, eResult: string): bool =
  var parameters: seq[Value] = @[newValue(str),
    newValue(start), newValue(length), newValue(replace)]
  let eFunResult = newFunResult(newValue(eResult))
  result = testFunction("replace", parameters, eFunResult = eFunResult)

proc testReplaceReGood(strs: varargs[string]): bool =
  if strs.len < 2:
    return false
  var parameters: seq[Value]
  for ix in countUp(0, strs.len-2, 1):
    parameters.add(newValue(strs[ix]))
  let eFunResult = newFunResult(newValue(strs[strs.len-1]))
  result = testFunction("replaceRe", parameters, eFunResult = eFunResult)

proc testReplaceReGoodList(str: string, list: Value, eString: string): bool =
  let eFunResult = newFunResult(newValue(eString))
  var parameters = @[newValue(str), list]
  result = testFunction("replaceRe", parameters, eFunResult = eFunResult)

suite "runFunction.nim":

  test "getFunction":
    let function = getFunction("len")
    check isSome(function)

  test "getFunction not":
    let function = getFunction("notfunction")
    check not isSome(function)

  test "funConcat 2":
    var parameters = newValue(["abc", " def"]).listv
    let eFunResult = newFunResult(newValue("abc def"))
    check testFunction("concat", parameters, eFunResult)

  test "funConcat 3":
    var parameters = newValue(["abc","", "def"]).listv
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
    var parameters = newValue(["Hello", " World"]).listv
    let eFunResult = newFunResult(newValue("Hello World"))
    check testFunction("concat", parameters, eFunResult)

  test "len string":
    var parameters = newValue(["abc"]).listv
    let eFunResult = newFunResult(newValue(3))
    check testFunction("len", parameters, eFunResult)

  test "len unicode string":
    # The byte length is different than the number of unicode characters.
    let str = "añyóng"
    check str.len == 8
    var parameters = newValue([str]).listv
    let eFunResult = newFunResult(newValue(6))
    check testFunction("len", parameters, eFunResult)

  test "len list":
    var list = newValue([5, 3]).listv
    var parameters = @[newValue(list)]
    let eFunResult = newFunResult(newValue(2))
    check testFunction("len", parameters, eFunResult)

  test "len dict":
    var dict = newValue([("a", 5), ("b", 5)]).dictv
    var parameters = @[newValue(dict)]
    let eFunResult = newFunResult(newValue(2))
    check testFunction("len", parameters, eFunResult)

  test "len strings":
    var list = newValue(["5", "3", "hi"])
    var parameters = @[newValue(list)]
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
    var parameters = newValue([3, 2]).listv
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
    var parameters = newValue([2, 3]).listv
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
    var parameters = newValue(["test", "asdf", "value", "else"]).listv
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
    var parameters = @[
      newValue(5),
      newValue(1), newValue("five")
    ]
    let eFunResult = newFunResultWarn(wMissingElse)
    check testFunction("case", parameters, eFunResult)

  test "case no match with no else 2":
    var parameters = @[
      newValue(5),
      newValue(1), newValue("five"),
      newValue(2), newValue("asdf"),
    ]
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
    var parameters = newValue(["Tea time at 4:00.", "party", "3:00"]).listv
    let eFunResult = newFunResult(newValue("3:00"))
    check testFunction("find", parameters, eFunResult = eFunResult)

  test "find bigger":
    var parameters = newValue(["big", "bigger", "smaller"]).listv
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
    let eFunResult = newFunResult(newEmtpyDictValue())
    check testFunction("dict", parameters, eFunResult = eFunResult)

  test "dict 1 item":
    var parameters = @[newValue("a"), newValue(5)]
    var dict = newValue([("a", 5)])
    let eFunResult = newFunResult(dict)
    check testFunction("dict", parameters, eFunResult = eFunResult)

  test "dict 2 items":
    var parameters = @[newValue("a"), newValue(5), newValue("b"), newValue(3)]
    let dict = newValue([("a", 5), ("b", 3)])
    let eFunResult = newFunResult(dict)
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

  test "list empty":
    var parameters: seq[Value] = @[]
    var list: seq[Value]
    let eFunResult = newFunResult(newValue(list))
    check testFunction("list", parameters, eFunResult = eFunResult)

  test "list one item":
    var parameters: seq[Value] = @[newValue(1)]
    var list = parameters
    let eFunResult = newFunResult(newValue(list))
    check testFunction("list", parameters, eFunResult = eFunResult)

  test "list two kinds of items":
    var parameters: seq[Value] = @[newValue(1), newValue("a")]
    var list = parameters
    let eFunResult = newFunResult(newValue(list))
    check testFunction("list", parameters, eFunResult = eFunResult)

  test "replace":
    var parameters: seq[Value] = @[newValue("Earl Grey"),
      newValue(5), newValue(4), newValue("of Sandwich")]
    let eFunResult = newFunResult(newValue("Earl of Sandwich"))
    check testFunction("replace", parameters, eFunResult = eFunResult)

  test "replace good":
    check testReplaceGood("123", 0, 0, "abcd", "abcd123")
    check testReplaceGood("123", 0, 1, "abcd", "abcd23")
    check testReplaceGood("123", 0, 2, "abcd", "abcd3")
    check testReplaceGood("123", 0, 3, "abcd", "abcd")
    check testReplaceGood("123", 3, 0, "abcd", "123abcd")
    check testReplaceGood("123", 2, 1, "abcd", "12abcd")
    check testReplaceGood("123", 1, 2, "abcd", "1abcd")
    check testReplaceGood("123", 0, 3, "abcd", "abcd")
    check testReplaceGood("123", 1, 0, "abcd", "1abcd23")
    check testReplaceGood("123", 1, 1, "abcd", "1abcd3")
    check testReplaceGood("123", 1, 2, "abcd", "1abcd")
    check testReplaceGood("", 0, 0, "abcd", "abcd")
    check testReplaceGood("", 0, 0, "abc", "abc")
    check testReplaceGood("", 0, 0, "ab", "ab")
    check testReplaceGood("", 0, 0, "a", "a")
    check testReplaceGood("", 0, 0, "", "")
    check testReplaceGood("123", 0, 0, "", "123")
    check testReplaceGood("123", 0, 1, "", "23")
    check testReplaceGood("123", 0, 2, "", "3")
    check testReplaceGood("123", 0, 3, "", "")

  test "replace empty str":
    var parameters: seq[Value] = @[newValue(""),
      newValue(0), newValue(0), newValue("of Sandwich")]
    let eFunResult = newFunResult(newValue("of Sandwich"))
    check testFunction("replace", parameters, eFunResult = eFunResult)

  test "replace empty empty":
    var parameters: seq[Value] = @[newValue(""),
      newValue(0), newValue(0), newValue("")]
    let eFunResult = newFunResult(newValue(""))
    check testFunction("replace", parameters, eFunResult = eFunResult)

  test "replace whole thing":
    var parameters: seq[Value] = @[newValue("Earl Grey"),
      newValue(0), newValue(9), newValue("Eat the Sandwich")]
    let eFunResult = newFunResult(newValue("Eat the Sandwich"))
    check testFunction("replace", parameters, eFunResult = eFunResult)

  test "replace last char":
    var parameters: seq[Value] = @[newValue("Earl Grey"),
      newValue(8), newValue(1), newValue("of Sandwich")]
    let eFunResult = newFunResult(newValue("Earl Greof Sandwich"))
    check testFunction("replace", parameters, eFunResult = eFunResult)

  test "replace with nothing":
    var parameters: seq[Value] = @[newValue("Earl Grey"),
      newValue(8), newValue(1), newValue("")]
    let eFunResult = newFunResult(newValue("Earl Gre"))
    check testFunction("replace", parameters, eFunResult = eFunResult)

  test "replace with nothing 2":
    var parameters: seq[Value] = @[newValue("Earl Grey"),
      newValue(8), newValue(0), newValue("123")]
    let eFunResult = newFunResult(newValue("Earl Gre123y"))
    check testFunction("replace", parameters, eFunResult = eFunResult)

  test "replace invalid p1":
    var parameters: seq[Value] = @[newValue(4),
      newValue(0), newValue(9), newValue("Eat the Sandwich")]
    let eFunResult = newFunResultWarn(wExpectedString)
    check testFunction("replace", parameters, eFunResult = eFunResult)

  test "replace invalid p2":
    var parameters: seq[Value] = @[newValue("Earl Grey"),
      newValue("a"), newValue(9), newValue("Eat the Sandwich")]
    let eFunResult = newFunResultWarn(wExpectedInteger, 1)
    check testFunction("replace", parameters, eFunResult = eFunResult)

  test "replace invalid p3":
    var parameters: seq[Value] = @[newValue("Earl Grey"),
      newValue(5), newValue("d"), newValue("Eat the Sandwich")]
    let eFunResult = newFunResultWarn(wExpectedInteger, 2)
    check testFunction("replace", parameters, eFunResult = eFunResult)

  test "replace invalid p4":
    var parameters: seq[Value] = @[newValue("Earl Grey"),
      newValue(5), newValue(4), newValue(4.3)]
    let eFunResult = newFunResultWarn(wExpectedString, 3)
    check testFunction("replace", parameters, eFunResult = eFunResult)

  test "replace start to small":
    var parameters: seq[Value] = @[newValue("Earl Grey"),
      newValue(-1), newValue(4), newValue("of Sandwich")]
    let eFunResult = newFunResultWarn(wInvalidPosition, 1, "-1")
    check testFunction("replace", parameters, eFunResult = eFunResult)

  test "replace start too big":
    var parameters: seq[Value] = @[newValue("Earl Grey"),
      newValue(10), newValue(0), newValue("of Sandwich")]
    let eFunResult = newFunResultWarn(wInvalidPosition, 1, "10")
    check testFunction("replace", parameters, eFunResult = eFunResult)

  test "replace length too small":
    var parameters: seq[Value] = @[newValue("Earl Grey"),
      newValue(0), newValue(-4), newValue("of Sandwich")]
    let eFunResult = newFunResultWarn(wInvalidLength, 2, "-4")
    check testFunction("replace", parameters, eFunResult = eFunResult)

  test "replace length too big":
    var parameters: seq[Value] = @[newValue("Earl Grey"),
      newValue(0), newValue(10), newValue("of Sandwich")]
    let eFunResult = newFunResultWarn(wInvalidLength, 2, "10")
    check testFunction("replace", parameters, eFunResult = eFunResult)

  test "replaceRe good":
    check testReplaceReGood("abc123abc", "abc", "456", "456123456")
    check testReplaceReGood("testFunResulthere FunResult FunResult", r"\bFunResult\b", "FunResult_",
                            "testFunResulthere FunResult_ FunResult_")
    check testReplaceReGood("abc123abc", "^abc", "456", "456123abc")
    check testReplaceReGood("abc123abc", "abc$", "456", "abc123456")
    check testReplaceReGood("abc123abc", "abc", "", "123")
    check testReplaceReGood("abc123abc", "a", "", "bc123bc")
    check testReplaceReGood("", "", "", "")
    check testReplaceReGood("", "a", "", "")
    check testReplaceReGood("b", "a", "", "b")
    check testReplaceReGood("", "a", "b", "")
    check testReplaceReGood("abc123abc", "a", "x", "b", "y", "xyc123xyc")
    check testReplaceReGood("abc123abc", "a", "x", "b", "y", "c", "z", "xyz123xyz")
    check testReplaceReGood(" @:- p1\n @: 222", " @:[ ]*", "", "- p1\n222")
    check testReplaceReGood("value one @: @: ... @: @:- pn-2", "[ ]*@:[ ]*", "X", "value oneXX...XX- pn-2")
    let text = ":linkTargetBegin:Semantic Versioning:linkTargetEnd://semver.org/"
    check testReplaceReGood(text, ":linkTargetBegin:", ".. _`", ":linkTargetEnd:", "`: https", ".. _`Semantic Versioning`: https//semver.org/")

    let textMd = "## @:StaticTea uses @|Semantic Versioning|@(https@:://semver.org/)"
    let eTextMd = "##\nStaticTea uses [Semantic Versioning](https://semver.org/)"
    check testReplaceReGood(textMd, "@::", ":", r"@\|", "[", r"\|@", "]", "[ ]*@:", "\n", eTextMd)

  test "replaceRe lower case":
    check testReplaceReGood("funReplace", "fun(.*)", "$1Fun", "ReplaceFun")

  test "replaceRe *":
    check testReplaceReGood("* test", r"^\*", "-", "- test")
    check testReplaceReGood("* test", "^\\*", "-", "- test")
    check testReplaceReGood("@:* test", "@:\\*", "-", "- test")
    check testReplaceReGood("""* "round""", "\\* \"", "- \"", "- \"round")

  # todo: runtime error. catch all these type of runtime errors in replace.
  # test "replaceRe error":
  #   check testReplaceReGood("* test", r"^*", "-", "- test")

  test "replaceRe good list":
    check testReplaceReGoodList("abc123abc", newValue(["abc", "456"]), "456123456")
    check testReplaceReGoodList("abc123abc", newValue(["a", "x", "b", "y", "c", "z"]),
                                "xyz123xyz")

  test "replaceRe not enough parameters":
    var parameters: seq[Value] = @[newValue("Earl Grey")]
    let eFunResult = newFunResultWarn(wTwoOrMoreParameters, 0)
    check testFunction("replaceRe", parameters, eFunResult = eFunResult)

  test "replaceRe not right number of parameters":
    var parameters: seq[Value] = @[newValue("Earl Grey"), newValue("a"), newValue("b"), newValue("c")]
    let eFunResult = newFunResultWarn(wMissingReplacement, 0)
    check testFunction("replaceRe", parameters, eFunResult = eFunResult)

  test "replaceRe list wrong number of parameters":
    var parameters: seq[Value] = @[newValue("Earl Grey"), newValue(["a", "b", "c"])]
    let eFunResult = newFunResultWarn(wMissingReplacement, 0)
    check testFunction("replaceRe", parameters, eFunResult = eFunResult)

  test "path":
    check testPathGood("dir/basename.ext", "basename.ext", "basename", ".ext", "dir/")
    check testPathGood("", "", "", "", "")
    check testPathGood("/", "", "", "", "/")
    check testPathGood("f", "f", "f", "", "")
    check testPathGood(".", ".", "", ".", "")
    check testPathGood("/f", "f", "f", "", "/")
    check testPathGood("f/", "", "", "", "f/")
    check testPathGood("/.", ".", "", ".", "/")
    check testPathGood("./", "", "", "", "./")
    check testPathGood("/f/", "", "", "", "/f/")
    check testPathGood("/f/t", "t", "t", "", "/f/")
    check testPathGood("/f/.", ".", "", ".", "/f/")
    check testPathGood("/f/.e", ".e", "", ".e", "/f/")
    check testPathGood("/f/t.n", "t.n", "t", ".n", "/f/")
    check testPathGood("/full/path/image.jpg", "image.jpg", "image", ".jpg", "/full/path/")
    check testPathGood("/full/path/", "", "", "", "/full/path/")
    check testPathGood("/full/noext", "noext", "noext", "", "/full/")
    check testPathGood("/full/path.img/f.png", "f.png", "f", ".png", "/full/path.img/")
    check testPathGood("filename", "filename", "filename", "", "")
    check testPathGood("/var", "var", "var", "", "/")

  test "path with separator":
    check testPathGood("dir/basename.ext", "basename.ext", "basename", ".ext", "dir/", "/")
    check testPathGood(r"dir\basename.ext", "basename.ext", "basename", ".ext", r"dir\", r"\")

  test "path: wrong number of parameters":
    var parameters: seq[Value] = @[newValue("Earl Grey"), newValue("a"), newValue("a")]
    let eFunResult = newFunResultWarn(wOneOrTwoParameters, 0)
    check testFunction("path", parameters, eFunResult = eFunResult)

  test "path: wrong kind p1":
    var parameters: seq[Value] = @[newValue(12)]
    let eFunResult = newFunResultWarn(wExpectedString, 0)
    check testFunction("path", parameters, eFunResult = eFunResult)

  test "path: wrong kind p2":
    var parameters: seq[Value] = @[newValue("filename"), newValue(12)]
    let eFunResult = newFunResultWarn(wExpectedString, 1)
    check testFunction("path", parameters, eFunResult = eFunResult)

  test "path: wrong kind separator":
    var parameters: seq[Value] = @[newValue("filename"), newValue("a")]
    let eFunResult = newFunResultWarn(wExpectedSeparator, 1)
    check testFunction("path", parameters, eFunResult = eFunResult)
