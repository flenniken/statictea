import std/unittest
import std/options
import std/strutils
import std/options
import std/tables
import env
import vartypes
import runFunction
import warnings
import tostring
import funtypes

# Unicode strings in multiple languages good for test cases.
# https://www.cl.cam.ac.uk/~mgk25/ucs/examples/quickbrown.txt

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

  # todo: remove env.
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
      result = testFunction("path", parameters, eFunResult)
    else:
      result = testFunction("path", parameters, eFunResult)

proc testCmpFun[T](a: T, b: T, caseInsensitive: bool = false, expected: int = 0): bool =
  ## Test the cmpFun
  var parameters: seq[Value]
  if caseInsensitive:
    parameters = @[newValue(a), newValue(b), newValue(1)]
  else:
    parameters = @[newValue(a), newValue(b)]
  let eFunResult = newFunResult(newValue(expected))
  result = testFunction("cmp", parameters, eFunResult)

proc testCmpVersionGood(versionA: string, versionB: string, eResult: int): bool =
  var parameters = @[newValue(versionA), newValue(versionB)]
  let eFunResult = newFunResult(newValue(eResult))
  result = testFunction("cmpVersion", parameters, eFunResult)

proc testReplaceGood(str: string, start: int, length: int, replace: string, eResult: string): bool =
  var parameters: seq[Value] = @[newValue(str),
    newValue(start), newValue(length), newValue(replace)]
  let eFunResult = newFunResult(newValue(eResult))
  result = testFunction("replace", parameters, eFunResult)

proc testReplaceReGood(strs: varargs[string]): bool =
  if strs.len < 2:
    return false
  var parameters: seq[Value]
  for ix in countUp(0, strs.len-2, 1):
    parameters.add(newValue(strs[ix]))
  let eFunResult = newFunResult(newValue(strs[strs.len-1]))
  result = testFunction("replaceRe", parameters, eFunResult)

proc testReplaceReGoodList(str: string, list: Value, eString: string): bool =
  let eFunResult = newFunResult(newValue(eString))
  var parameters = @[newValue(str), list]
  result = testFunction("replaceRe", parameters, eFunResult)

proc testLower(str: string, eStr: string): bool =
    var parameters = @[newValue(str)]
    let eFunResult = newFunResult(newValue(eStr))
    result = testFunction("lower", parameters, eFunResult)

proc testAnchor(str: string, eStr: string): bool =
    var parameters = @[newValue(str)]
    let eFunResult = newFunResult(newValue(eStr))
    result = testFunction("githubAnchor", parameters, eFunResult)

suite "runFunction.nim":

  test "getFunction":
    let function = getFunction("len")
    check isSome(function)

  test "getFunction not":
    let function = getFunction("notfunction")
    check not isSome(function)

  test "concat 1 string":
    var parameters = newValue(["abc"]).listv
    let eFunResult = newFunResult(newValue("abc"))
    check testFunction("concat", parameters, eFunResult)

  test "concat hello world":
    var parameters = newValue(["Hello", " World"]).listv
    let eFunResult = newFunResult(newValue("Hello World"))
    check testFunction("concat", parameters, eFunResult)

  test "concat empty string":
    var parameters = newValue(["abc","", "def"]).listv
    let eFunResult = newFunResult(newValue("abcdef"))
    check testFunction("concat", parameters, eFunResult)

  test "concat many":
    var parameters = newValue(["a", "b", "c", "d", "e", "f"]).listv
    let eFunResult = newFunResult(newValue("abcdef"))
    check testFunction("concat", parameters, eFunResult)

  test "concat nothing":
    var parameters: seq[Value]
    let eFunResult = newFunResultWarn(kNotEnoughArgs, 0, "1", "0")
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
    check testCmpFun("ABC", "abc", true, expected = 0)
    check testCmpFun("abc", "ABC", true, expected = 0)
    check testCmpFun("abc", "abd", true, expected = -1)
    check testCmpFun("abd", "abc", true, expected = 1)
    check testCmpFun("abc", "ABD", true, expected = -1)
    check testCmpFun("ABD", "abc", true, expected = 1)

  test "cmp wrong number parameters":
    var parameters = @[newValue(4)]
    let eFunResult = newFunResultWarn(wTwoOrThreeParameters)
    check testFunction("cmp", parameters, eFunResult)

  test "cmp not same kind":
    var parameters = @[newValue(4), newValue(4.2)]
    let eFunResult = newFunResultWarn(wNotSameKind)
    check testFunction("cmp", parameters, eFunResult)

  test "cmp not int, float or string":
    var parameters = @[newEmptyDictValue(), newEmptyDictValue()]
    let eFunResult = newFunResultWarn(wIntFloatString)
    check testFunction("cmp", parameters, eFunResult)

  test "cmp case insensitive wrong type":
    var parameters = @[newValue(2), newValue(22), newValue("a")]
    let eFunResult = newFunResultWarn(wNotZeroOne, 2)
    check testFunction("cmp", parameters, eFunResult)

  test "cmp case insensitive not 0 or 1":
    var parameters = @[newValue(2), newValue(22), newValue(2)]
    let eFunResult = newFunResultWarn(wNotZeroOne, 2)
    check testFunction("cmp", parameters, eFunResult)

  test "if function 1":
    var parameters = @[newValue(1), newValue("true"), newValue("false")]
    let eFunResult = newFunResult(newValue("true"))
    check testFunction("if", parameters, eFunResult)

  test "if function not 1":
    var parameters = @[newValue(33), newValue("true"), newValue("false")]
    let eFunResult = newFunResult(newValue("false"))
    check testFunction("if", parameters, eFunResult)

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

  test "case int":
    var parameters = @[newValue(5), newValue(5), newValue("value"), newValue("else")]
    let eFunResult = newFunResult(newValue("value"))
    check testFunction("case", parameters, eFunResult)

  test "case int else":
    var parameters = @[newValue(5), newValue(6), newValue("value"), newValue("else")]
    let eFunResult = newFunResult(newValue("else"))
    check testFunction("case", parameters, eFunResult)

  test "case string":
    var parameters = @[newValue("test"), newValue("test"), newValue("value"), newValue("else")]
    let eFunResult = newFunResult(newValue("value"))
    check testFunction("case", parameters, eFunResult)

  test "case string else":
    var parameters = newValue(["test", "asdf", "value", "else"]).listv
    let eFunResult = newFunResult(newValue("else"))
    check testFunction("case", parameters, eFunResult)

  test "case int 6":
    var parameters = @[newValue(6), newValue(5), newValue("v5"), newValue(6), newValue("v6"), newValue("else")]
    let eFunResult = newFunResult(newValue("v6"))
    check testFunction("case", parameters, eFunResult)

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
    check testFunction("case", parameters, eFunResult)

  test "case dup":
    var parameters = @[
      newValue(5),
      newValue(5), newValue(8),
      newValue(5), newValue(9),
      newValue("else"),
    ]
    let eFunResult = newFunResult(newValue(8))
    check testFunction("case", parameters, eFunResult)

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
      if not testFunction("int", parameters, eFunResult):
        echo $oneCase
        fail

  test "to int: default":
    var parameters = @[newValue(4.57)]
    let eFunResult = newFunResult(newValue(5))
    check testFunction("int", parameters, eFunResult)

  test "to int: wrong number of parameters":
    var parameters = @[newValue(4.57), newValue(1), newValue(2)]
    let eFunResult = newFunResultWarn(wOneOrTwoParameters)
    check testFunction("int", parameters, eFunResult)

  test "to int: not a number string":
    var parameters = @[newValue("hello"), newValue("round")]
    let eFunResult = newFunResultWarn(wFloatOrStringNumber)
    check testFunction("int", parameters, eFunResult)

  test "to int: not a float":
    var parameters = @[newValue(3), newValue("round")]
    let eFunResult = newFunResultWarn(wFloatOrStringNumber)
    check testFunction("int", parameters, eFunResult)

  test "to int: not round option":
    var parameters = @[newValue(3.4), newValue(5)]
    let eFunResult = newFunResultWarn(wExpectedRoundOption, 1)
    check testFunction("int", parameters, eFunResult)

  test "to int: not a float":
    var parameters = @[newValue(3.5), newValue("rounder")]
    let eFunResult = newFunResultWarn(wExpectedRoundOption, 1)
    check testFunction("int", parameters, eFunResult)

  test "to int: to big":
    var parameters = @[newValue(3.5e300), newValue("round")]
    let eFunResult = newFunResultWarn(wNumberOverFlow)
    check testFunction("int", parameters, eFunResult)

  test "to int: to small":
    var parameters = @[newValue(-3.5e300), newValue("round")]
    let eFunResult = newFunResultWarn(wNumberOverFlow)
    check testFunction("int", parameters, eFunResult)


  test "to float":
    var parameters = @[newValue(3)]
    let eFunResult = newFunResult(newValue(3.0))
    check testFunction("float", parameters, eFunResult)

  test "to float minus":
    var parameters = @[newValue(-3)]
    let eFunResult = newFunResult(newValue(-3.0))
    check testFunction("float", parameters, eFunResult)

  test "to float from string":
    var parameters = @[newValue("-3")]
    let eFunResult = newFunResult(newValue(-3.0))
    check testFunction("float", parameters, eFunResult)

  test "to float from string 2":
    var parameters = @[newValue("-3.5")]
    let eFunResult = newFunResult(newValue(-3.5))
    check testFunction("float", parameters, eFunResult)

  test "to float wrong number parameters":
    var parameters = @[newValue(4), newValue(3)]
    let eFunResult = newFunResultWarn(wOneParameter)
    check testFunction("float", parameters, eFunResult)

  test "to float warning":
    var parameters = @[newValue("abc")]
    let eFunResult = newFunResultWarn(wIntOrStringNumber)
    check testFunction("float", parameters, eFunResult)

  test "find":
    var parameters = @[newValue("Tea time at 4:00."), newValue("time")]
    let eFunResult = newFunResult(newValue(4))
    check testFunction("find", parameters, eFunResult)

  test "find start":
    var parameters = @[newValue("Tea time at 4:00."), newValue("Tea")]
    let eFunResult = newFunResult(newValue(0))
    check testFunction("find", parameters, eFunResult)

  test "find end":
    var parameters = @[newValue("Tea time at 4:00."), newValue("00.")]
    let eFunResult = newFunResult(newValue(14))
    check testFunction("find", parameters, eFunResult)

  test "find missing":
    var parameters = newValue(["Tea time at 4:00.", "party", "3:00"]).listv
    let eFunResult = newFunResult(newValue("3:00"))
    check testFunction("find", parameters, eFunResult)

  test "find bigger":
    var parameters = newValue(["big", "bigger", "smaller"]).listv
    let eFunResult = newFunResult(newValue("smaller"))
    check testFunction("find", parameters, eFunResult)

  test "find nothing":
    var parameters = @[newValue("big"), newValue("")]
    let eFunResult = newFunResult(newValue(0))
    check testFunction("find", parameters, eFunResult)

  test "find from nothing":
    var parameters = @[newValue(""), newValue("")]
    let eFunResult = newFunResult(newValue(0))
    check testFunction("find", parameters, eFunResult)

  test "find from nothing 2":
    var parameters = @[newValue(""), newValue("2"), newValue(0)]
    let eFunResult = newFunResult(newValue(0))
    check testFunction("find", parameters, eFunResult)

  test "find missing no default":
    var parameters = @[newValue("Tea time at 4:00."), newValue("aTea")]
    let eFunResult = newFunResultWarn(wSubstringNotFound, 1)
    check testFunction("find", parameters, eFunResult)

  test "find 1 parameter":
    var parameters = @[newValue("big")]
    let eFunResult = newFunResultWarn(kNotEnoughArgs, 0, "2", "1")
    check testFunction("find", parameters, eFunResult)

  test "find 1 not string":
    var parameters = @[newValue(1), newValue("bigger")]
    let eFunResult = newFunResultWarn(kWrongType, 0, "string", "int")
    check testFunction("find", parameters, eFunResult)

  test "find 2 not string":
    var parameters = @[newValue("at"), newValue(4.5)]
    let eFunResult = newFunResultWarn(kWrongType, 1, "string", "float")
    check testFunction("find", parameters, eFunResult)

  test "substr Grey":
    var parameters = @[newValue("Earl Grey"), newValue(5)]
    let eFunResult = newFunResult(newValue("Grey"))
    check testFunction("substr", parameters, eFunResult)

  test "substr Earl":
    var parameters = @[newValue("Earl Grey"), newValue(0), newValue(4)]
    let eFunResult = newFunResult(newValue("Earl"))
    check testFunction("substr", parameters, eFunResult)

  test "substr 1 parameter":
    var parameters = @[newValue("big")]
    let eFunResult = newFunResultWarn(kNotEnoughArgs, 0, "2", "1")
    check testFunction("substr", parameters, eFunResult)

  test "substr 1 not string":
    var parameters = @[newValue(4), newValue(4)]
    let eFunResult = newFunResultWarn(kWrongType, 0, "string", "int")
    check testFunction("substr", parameters, eFunResult)

  test "substr 2 not int":
    var parameters = @[newValue("tasdf"), newValue("dsa")]
    let eFunResult = newFunResultWarn(kWrongType, 1, "int", "string")
    check testFunction("substr", parameters, eFunResult)

  test "substr 3 not int":
    var parameters = @[newValue("tasdf"), newValue(0), newValue("tasdf")]
    let eFunResult = newFunResultWarn(kWrongType, 2, "int", "string")
    check testFunction("substr", parameters, eFunResult)

  test "substr start < 0":
    var parameters = @[newValue("tasdf"), newValue(-2), newValue(0)]
    let eFunResult = newFunResultWarn(wInvalidPosition, 1, "-2")
    check testFunction("substr", parameters, eFunResult)

  test "substr finish > len":
    var parameters = @[newValue("tasdf"), newValue(0), newValue(10)]
    let eFunResult = newFunResultWarn(wInvalidPosition, 2, "10")
    check testFunction("substr", parameters, eFunResult)

  test "substr finish < start":
    var parameters = @[newValue("tasdf"), newValue(3), newValue(2)]
    let eFunResult = newFunResultWarn(wEndLessThenStart, 2)
    check testFunction("substr", parameters, eFunResult)

  test "substr nothing":
    var parameters = @[newValue("tasdf"), newValue(3), newValue(3)]
    let eFunResult = newFunResult(newValue(""))
    check testFunction("substr", parameters, eFunResult)

  test "dup":
    var parameters = @[newValue("-"), newValue(5)]
    let eFunResult = newFunResult(newValue("-----"))
    check testFunction("dup", parameters, eFunResult)

  test "dup 0":
    var parameters = @[newValue("-"), newValue(0)]
    let eFunResult = newFunResult(newValue(""))
    check testFunction("dup", parameters, eFunResult)

  test "dup 1":
    var parameters = @[newValue("abc"), newValue(1)]
    let eFunResult = newFunResult(newValue("abc"))
    check testFunction("dup", parameters, eFunResult)

  test "dup multiple":
    var parameters = @[newValue("123456789 "), newValue(2)]
    let eFunResult = newFunResult(newValue("123456789 123456789 "))
    check testFunction("dup", parameters, eFunResult)

  test "dup 1 parameter":
    var parameters = @[newValue("abc")]
    let eFunResult = newFunResultWarn(kNotEnoughArgs, 0, "2", "1")
    check testFunction("dup", parameters, eFunResult)

  test "dup not valid string":
    var parameters = @[newValue(4.3), newValue(2)]
    let eFunResult = newFunResultWarn(kWrongType, 0, "string", "float")
    check testFunction("dup", parameters, eFunResult)

  test "dup not valid count":
    var parameters = @[newValue("="), newValue("=")]
    let eFunResult = newFunResultWarn(kWrongType, 1, "int", "string")
    check testFunction("dup", parameters, eFunResult)

  test "dup negative count":
    var parameters = @[newValue("="), newValue(-9)]
    let eFunResult = newFunResultWarn(wInvalidMaxCount, 1)
    check testFunction("dup", parameters, eFunResult)

  test "dup too long":
    var parameters = @[newValue("="), newValue(123_333)]
    let eFunResult = newFunResultWarn(wDupStringTooLong, 1, "123333")
    check testFunction("dup", parameters, eFunResult)

  test "dict":
    var parameters: seq[Value] = @[]
    let eFunResult = newFunResult(newEmptyDictValue())
    check testFunction("dict", parameters, eFunResult)

  test "dict 1 item":
    var parameters = @[newValue("a"), newValue(5)]
    var dict = newValue([("a", 5)])
    let eFunResult = newFunResult(dict)
    check testFunction("dict", parameters, eFunResult)

  test "dict 2 items":
    var parameters = @[newValue("a"), newValue(5), newValue("b"), newValue(3)]
    let dict = newValue([("a", 5), ("b", 3)])
    let eFunResult = newFunResult(dict)
    check testFunction("dict", parameters, eFunResult)

  test "dict 1 parameter":
    var parameters = @[newValue("a")]
    let eFunResult = newFunResultWarn(kNotEnoughVarargs, 0, "2", "1")
    check testFunction("dict", parameters, eFunResult)

  test "dict 3 parameter":
    var parameters = @[newValue("a")]
    let eFunResult = newFunResultWarn(kNotEnoughVarargs, 0, "2", "1")
    check testFunction("dict", parameters, eFunResult)

  test "dict not string key":
    var parameters = @[newValue("key"), newValue(1), newValue(2), newValue(1)]
    let eFunResult = newFunResultWarn(kWrongType, 2, "string", "int")
    check testFunction("dict", parameters, eFunResult)

  test "list empty":
    var parameters: seq[Value] = @[]
    var list: seq[Value]
    let eFunResult = newFunResult(newValue(list))
    check testFunction("list", parameters, eFunResult)

  test "list one item":
    var parameters: seq[Value] = @[newValue(1)]
    var list = parameters
    let eFunResult = newFunResult(newValue(list))
    check testFunction("list", parameters, eFunResult)

  test "list two kinds of items":
    var parameters: seq[Value] = @[newValue(1), newValue("a")]
    var list = parameters
    let eFunResult = newFunResult(newValue(list))
    check testFunction("list", parameters, eFunResult)

  test "replace":
    var parameters: seq[Value] = @[newValue("Earl Grey"),
      newValue(5), newValue(4), newValue("of Sandwich")]
    let eFunResult = newFunResult(newValue("Earl of Sandwich"))
    check testFunction("replace", parameters, eFunResult)

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
    check testFunction("replace", parameters, eFunResult)

  test "replace empty empty":
    var parameters: seq[Value] = @[newValue(""),
      newValue(0), newValue(0), newValue("")]
    let eFunResult = newFunResult(newValue(""))
    check testFunction("replace", parameters, eFunResult)

  test "replace whole thing":
    var parameters: seq[Value] = @[newValue("Earl Grey"),
      newValue(0), newValue(9), newValue("Eat the Sandwich")]
    let eFunResult = newFunResult(newValue("Eat the Sandwich"))
    check testFunction("replace", parameters, eFunResult)

  test "replace last char":
    var parameters: seq[Value] = @[newValue("Earl Grey"),
      newValue(8), newValue(1), newValue("of Sandwich")]
    let eFunResult = newFunResult(newValue("Earl Greof Sandwich"))
    check testFunction("replace", parameters, eFunResult)

  test "replace with nothing":
    var parameters: seq[Value] = @[newValue("Earl Grey"),
      newValue(8), newValue(1), newValue("")]
    let eFunResult = newFunResult(newValue("Earl Gre"))
    check testFunction("replace", parameters, eFunResult)

  test "replace with nothing 2":
    var parameters: seq[Value] = @[newValue("Earl Grey"),
      newValue(8), newValue(0), newValue("123")]
    let eFunResult = newFunResult(newValue("Earl Gre123y"))
    check testFunction("replace", parameters, eFunResult)

  test "replace invalid p1":
    var parameters: seq[Value] = @[newValue(4),
      newValue(0), newValue(9), newValue("Eat the Sandwich")]
    let eFunResult = newFunResultWarn(kWrongType, 0, "string", "int")
    check testFunction("replace", parameters, eFunResult)

  test "replace invalid p2":
    var parameters: seq[Value] = @[newValue("Earl Grey"),
      newValue("a"), newValue(9), newValue("Eat the Sandwich")]
    let eFunResult = newFunResultWarn(kWrongType, 1, "int", "string")
    check testFunction("replace", parameters, eFunResult)

  test "replace invalid p3":
    var parameters: seq[Value] = @[newValue("Earl Grey"),
      newValue(5), newValue("d"), newValue("Eat the Sandwich")]
    let eFunResult = newFunResultWarn(kWrongType, 2, "int", "string")
    check testFunction("replace", parameters, eFunResult)

  test "replace invalid p4":
    var parameters: seq[Value] = @[newValue("Earl Grey"),
      newValue(5), newValue(4), newValue(4.3)]
    let eFunResult = newFunResultWarn(kWrongType, 3, "string", "float")
    check testFunction("replace", parameters, eFunResult)

  test "replace start to small":
    var parameters: seq[Value] = @[newValue("Earl Grey"),
      newValue(-1), newValue(4), newValue("of Sandwich")]
    let eFunResult = newFunResultWarn(wInvalidPosition, 1, "-1")
    check testFunction("replace", parameters, eFunResult)

  test "replace start too big":
    var parameters: seq[Value] = @[newValue("Earl Grey"),
      newValue(10), newValue(0), newValue("of Sandwich")]
    let eFunResult = newFunResultWarn(wInvalidPosition, 1, "10")
    check testFunction("replace", parameters, eFunResult)

  test "replace length too small":
    var parameters: seq[Value] = @[newValue("Earl Grey"),
      newValue(0), newValue(-4), newValue("of Sandwich")]
    let eFunResult = newFunResultWarn(wInvalidLength, 2, "-4")
    check testFunction("replace", parameters, eFunResult)

  test "replace length too big":
    var parameters: seq[Value] = @[newValue("Earl Grey"),
      newValue(0), newValue(10), newValue("of Sandwich")]
    let eFunResult = newFunResultWarn(wInvalidLength, 2, "10")
    check testFunction("replace", parameters, eFunResult)

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

    let textMd = "## @:StaticTea uses @|Semantic Versioning|@(https@@://semver.org/)"
    let eTextMd = "##\nStaticTea uses [Semantic Versioning](https://semver.org/)"
    check testReplaceReGood(textMd, "@@", "", r"@\|", "[", r"\|@", "]", "[ ]*@:", "\n", eTextMd)

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
    check testFunction("replaceRe", parameters, eFunResult)

  test "replaceRe not right number of parameters":
    var parameters: seq[Value] = @[newValue("Earl Grey"), newValue("a"), newValue("b"), newValue("c")]
    let eFunResult = newFunResultWarn(wMissingReplacement, 0)
    check testFunction("replaceRe", parameters, eFunResult)

  test "replaceRe list wrong number of parameters":
    var parameters: seq[Value] = @[newValue("Earl Grey"), newValue(["a", "b", "c"])]
    let eFunResult = newFunResultWarn(wMissingReplacement, 0)
    check testFunction("replaceRe", parameters, eFunResult)

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
    let eFunResult = newFunResultWarn(kTooManyArgs, 0, "1", "3")
    check testFunction("path", parameters, eFunResult)

  test "path: wrong kind p1":
    var parameters: seq[Value] = @[newValue(12)]
    let eFunResult = newFunResultWarn(kWrongType, 0, "string", "int")
    check testFunction("path", parameters, eFunResult)

  test "path: wrong kind p2":
    var parameters: seq[Value] = @[newValue("filename"), newValue(12)]
    let eFunResult = newFunResultWarn(kWrongType, 1, "string", "int")
    check testFunction("path", parameters, eFunResult)

  test "path: wrong kind separator":
    var parameters: seq[Value] = @[newValue("filename"), newValue("a")]
    let eFunResult = newFunResultWarn(wExpectedSeparator, 1)
    check testFunction("path", parameters, eFunResult)

  test "lower":
    check testLower("", "")
    check testLower("T", "t")
    check testLower("Tea", "tea")
    check testLower("t", "t")
    check testLower("TEA", "tea")

    # Ā is letter 256, A with macron, Latvian, Unicode (hex) 0100
    # ā is the same, lower-case, 0101
    check testLower("TEĀ", "teā")

  test "lower: wrong number of parameters":
    var parameters: seq[Value] = @[]
    let eFunResult = newFunResultWarn(kNotEnoughArgs, 0, "1", "0")
    check testFunction("lower", parameters, eFunResult)

  test "lower: wrong kind of parameter":
    var parameters: seq[Value] = @[newValue(2)]
    let eFunResult = newFunResultWarn(kWrongType, 0, "string", "int")
    check testFunction("lower", parameters, eFunResult)

  test "keys empty":
    let dictValue = newEmptyDictValue()
    let listValue = newEmptyListValue()
    check testFunction("keys", @[dictValue], newFunResult(listValue))

  test "keys one":
    let dictValue = newValue([("a", 1)])
    let listValue = newValue(["a"])
    check testFunction("keys", @[dictValue], newFunResult(listValue))

  test "keys three":
    let dictValue = newValue([("a", 1), ("b", 2), ("c", 3)])
    let listValue = newValue(["a", "b", "c"])
    check testFunction("keys", @[dictValue], newFunResult(listValue))

  test "keys: wrong number of parameters":
    var parameters: seq[Value] = @[]
    let eFunResult = newFunResultWarn(kNotEnoughArgs, 0, "1", "0")
    check testFunction("keys", parameters, eFunResult)

  test "keys: wrong kind of parameter":
    var parameters: seq[Value] = @[newValue(2)]
    let eFunResult = newFunResultWarn(kWrongType, 0, "dict", "int")
    check testFunction("keys", parameters, eFunResult)

  test "values empty":
    let dictValue = newEmptyDictValue()
    let listValue = newEmptyListValue()
    check testFunction("values", @[dictValue], newFunResult(listValue))

  test "values one":
    let dictValue = newValue([("a", 1)])
    let listValue = newValue([1])
    check testFunction("values", @[dictValue], newFunResult(listValue))

  test "values three":
    let dictValue = newValue([("a", 1), ("b", 2), ("c", 3)])
    let listValue = newValue([1, 2, 3])
    check testFunction("values", @[dictValue], newFunResult(listValue))

  test "values: wrong number of parameters":
    var parameters: seq[Value] = @[]
    let eFunResult = newFunResultWarn(kNotEnoughArgs, 0, "1", "0")
    check testFunction("values", parameters, eFunResult)

  test "values: wrong kind of parameter":
    var parameters: seq[Value] = @[newValue(2)]
    let eFunResult = newFunResultWarn(kWrongType, 0, "dict", "int")
    check testFunction("values", parameters, eFunResult)

  test "sort empty":
    let emptyList = newEmptyListValue()
    check testFunction("sort", @[emptyList], newFunResult(emptyList))
    check testFunction("sort", @[
      emptyList,
      newValue("descending"),
      newValue("insensitive"),
      newValue("dummyKey")
    ], newFunResult(emptyList))

  test "sort one":
    let list = newValue([1])
    check testFunction("sort", @[list], newFunResult(list))

  test "sort two":
    let list = newValue([2, 1])
    let eList = newValue([1, 2])
    check testFunction("sort", @[list], newFunResult(eList))

  test "sort ascending":
    let list = newValue([2, 1])
    let eList = newValue([1, 2])
    check testFunction("sort", @[list, newValue("ascending")], newFunResult(eList))

  test "sort descending":
    let list = newValue([1, 2])
    let eList = newValue([2, 1])
    check testFunction("sort", @[list, newValue("descending")], newFunResult(eList))

  test "sort descending":
    let list = newValue([2, 3, 4, 4, 5, 5])
    let eList = newValue([5, 5, 4, 4, 3, 2])
    check testFunction("sort", @[list, newValue("descending")], newFunResult(eList))

  test "sort floats":
    let list = newValue([2.4, 1.6])
    let eList = newValue([1.6, 2.4])
    check testFunction("sort", @[list], newFunResult(eList))

  test "sort strings":
    let list = newValue(["abc", "b", "aaa"])
    let eList = newValue(["aaa", "abc", "b"])
    check testFunction("sort", @[list], newFunResult(eList))

  test "sort strings case sensitive":
    let list = newValue(["A", "a", "b", "B"])
    let eList = newValue(["A", "B", "a", "b"])
    check testFunction("sort", @[list], newFunResult(eList))

  test "sort strings case insensitive":
    # Sort is order preserving.
    let list = newValue(["a", "A", "A", "a", "A", "a", "A"])
    check testFunction("sort", @[list, newValue("ascending"),
      newValue("insensitive")], newFunResult(list))

  test "sort list of lists":
    let l1 = newValue([4, 3, 1])
    let l2 = newValue([2, 3, 0])
    let list = newValue([l1, l2])
    let eList = newValue([l2, l1])
    check testFunction("sort", @[list, newValue("ascending")], newFunResult(eList))
    let eList2 = newValue([l1, l2])
    check testFunction("sort", @[list, newValue("descending")], newFunResult(eList2))

  test "sort dicts":
    var d1 = newValue([
      ("name", newValue("Earl Gray")),
      ("weight", newValue(1.2)),
    ])
    var d2 = newValue([
      ("name", newValue("teapot")),
      ("weight", newValue(3.5)),
    ])

    let list = newValue([d1, d2])
    let eList2 = newValue([d2, d1])

    check testFunction("sort", @[list, newValue("ascending"),
      newValue("sensitive"), newValue("weight")], newFunResult(list))

    check testFunction("sort", @[list, newValue("ascending"),
      newValue("sensitive"), newValue("name")], newFunResult(list))

    check testFunction("sort", @[list, newValue("descending"),
      newValue("sensitive"), newValue("name")], newFunResult(eList2))

    check testFunction("sort", @[list, newValue("descending"),
      newValue("sensitive"), newValue("weight")], newFunResult(eList2))

    check testFunction("sort", @[list, newValue("descending"),
      newValue("sensitive"), newValue("weight")], newFunResult(eList2))

    check testFunction("sort", @[list, newValue("descending"),
      newValue("insensitive"), newValue("name")], newFunResult(eList2))

  test "sort: wrong number of parameters":
    var parameters: seq[Value] = @[]
    let eFunResult = newFunResultWarn(wOneToFourParameters, 0)
    check testFunction("sort", parameters, eFunResult)

  test "sort: not list":
    var parameters: seq[Value] = @[newValue(0)]
    let eFunResult = newFunResultWarn(wExpectedList, 0)
    check testFunction("sort", parameters, eFunResult)

  test "sort: invalid order":
    let list = newValue([1])
    var parameters: seq[Value] = @[list, newValue(22)]
    let eFunResult = newFunResultWarn(wExpectedSortOrder, 1)
    check testFunction("sort", parameters, eFunResult)

  test "sort: invalid order spelling":
    let list = newValue([1])
    var parameters: seq[Value] = @[list, newValue("asc")]
    let eFunResult = newFunResultWarn(wExpectedSortOrder, 1)
    check testFunction("sort", parameters, eFunResult)

  test "sort: values not same kind":
    var parameters: seq[Value] = @[newValue([newValue(1), newValue(2.2)])]
    let eFunResult = newFunResultWarn(wNotSameKind, 0)
    check testFunction("sort", parameters, eFunResult)

  test "sort: first dict missing key":
    let dict = newValue([("a", 2)])
    let list = newValue([dict, dict, dict])
    var parameters: seq[Value] = @[list]
    let eFunResult = newFunResultWarn(wExpectedKey, 3)
    check testFunction("sort", parameters, eFunResult)

  test "sort: invalid sensitive option":
    let list = newValue(["abc", "b", "aaa"])
    var parameters: seq[Value] = @[list, newValue("ascending"), newValue(2.2)]
    let eFunResult = newFunResultWarn(wExpectedSensitivity, 2)
    check testFunction("sort", parameters, eFunResult)

    parameters = @[list, newValue("ascending"), newValue("t")]
    check testFunction("sort", parameters, eFunResult)

  test "sort: none first dict key missing":
    let d1 = newValue([("a", 2), ("b", 3)])
    let d2 = newValue([("a3", 2), ("b3", 3)])
    let list = newValue([d1, d2])
    var parameters = @[list, newValue("ascending"), newValue("sensitive"), newValue("a")]
    let eFunResult = newFunResultWarn(wDictKeyMissing, 0)
    check testFunction("sort", parameters, eFunResult)

  test "sort: dict key values different":
    let d1 = newValue([("a", 2), ("b", 3)])
    let d2 = newValue([("a", 2.2), ("b", 3.3)])
    let list = newValue([d1, d2])
    var parameters = @[list, newValue("ascending"), newValue("sensitive"), newValue("a")]
    let eFunResult = newFunResultWarn(wKeyValueKindDiff, 0)
    check testFunction("sort", parameters, eFunResult)

  test "githubAnchor":
    check testAnchor("", "")
    check testAnchor("T", "t")
    check testAnchor("Tea", "tea")
    check testAnchor("t", "t")
    check testAnchor("TEA", "tea")
    check testAnchor("$", "")
    check testAnchor("==", "")
    check testAnchor("Eary Gray", "eary-gray")
    check testAnchor("Eary-Gray", "eary-gray")
    check testAnchor("1234567890", "1234567890")
    check testAnchor("_1!2@3#4%5^6&7*8(9)0", "1234567890")
    let str = "Zwölf Boxkämpfer jagten Eva quer über den Sylter Deich"
    let eStr = "zwölf-boxkämpfer-jagten-eva-quer-über-den-sylter-deich"
    # (= Twelve boxing fighters hunted Eva across the dike of Sylt)
    check testAnchor(str, eStr)

  test "githubAnchor: wrong number of parameters":
    var parameters: seq[Value] = @[]
    let eFunResult = newFunResultWarn(kNotEnoughArgs, 0, "1", "0")
    check testFunction("githubAnchor", parameters, eFunResult)

  test "githubAnchor: wrong kind of parameter":
    var parameters: seq[Value] = @[newValue(2)]
    let eFunResult = newFunResultWarn(kWrongType, 0, "string", "int")
    check testFunction("githubAnchor", parameters, eFunResult)

  test "cmdVersion":
    check testCmpVersionGood("0.0.0", "0.0.0", 0)
    check testCmpVersionGood("0.0.0", "0.0.1", -1)
    check testCmpVersionGood("0.0.1", "0.0.0", 1)

    check testCmpVersionGood("1.2.3", "1.2.3", 0)
    check testCmpVersionGood("1.2.3", "1.4.3", -1)
    check testCmpVersionGood("1.2.3", "1.1.3", 1)

    check testCmpVersionGood("555.444.666", "555.444.666", 0)
    check testCmpVersionGood("555.444.666", "555.444.667", -1)
    check testCmpVersionGood("555.444.666", "555.444.665", 1)

    check testCmpVersionGood("555.444.666", "555.444.666", 0)
    check testCmpVersionGood("555.443.666", "555.444.777", -1)
    check testCmpVersionGood("555.445.666", "555.444.111", 1)

    check testCmpVersionGood("1.56.2", "1.56.2", 0)
    check testCmpVersionGood("1.56.2", "2.0.0", -1)
    check testCmpVersionGood("1.56.2", "1.1.1", 1)

    check testCmpVersionGood("000.000.000", "0.0.0", 0)
    check testCmpVersionGood("00.00.00", "0.0.0", 0)
    check testCmpVersionGood("0.00.000", "0.0.0", 0)

  test "cmdVersion: two few parameters":
    let parameters = @[newValue("1.2.3")]
    let eFunResult = newFunResultWarn(kNotEnoughArgs, 0, "2", "1")
    check testFunction("cmpVersion", parameters, eFunResult)

  test "cmdVersion: two many parameters":
    let parameters = @[newValue("1.2.3"), newValue("1.2.3"), newValue("1.2.3")]
    let eFunResult = newFunResultWarn(kTooManyArgs, 0, "2", "3")
    check testFunction("cmpVersion", parameters, eFunResult)

  test "cmdVersion: invalid version a":
    let parameters = @[newValue("1.2.3a"), newValue("1.2.3")]
    let eFunResult = newFunResultWarn(wInvalidVersion, 0)
    check testFunction("cmpVersion", parameters, eFunResult)

  test "cmdVersion: invalid version b":
    let parameters = @[newValue("1.2.3"), newValue("1.2.3b")]
    let eFunResult = newFunResultWarn(wInvalidVersion, 1)
    check testFunction("cmpVersion", parameters, eFunResult)
