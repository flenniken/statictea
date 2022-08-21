import std/unittest
import std/options
import std/strutils
import std/tables
import env
import vartypes
import runFunction
import messages
import funtypes
import variables

# Unicode strings in multiple languages good for test cases.
# https://www.cl.cam.ac.uk/~mgk25/ucs/examples/quickbrown.txt

proc testFunction(functionName: string, parameters: seq[Value],
    eFunResult: FunResult,
    variables: Variables = emptyVariables(),
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[]
  ): bool =

  let functionSpecO = getFunction(functionName, parameters)
  if not functionSpecO.isSome:
    echo "The function doesn't exist: " & functionName
    return false
  let functionSpec = functionSpecO.get()
  let funResult = functionSpec.functionPtr(variables, parameters)

  result = true
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

proc testGetFunctionExists(name: string, parameters: seq[Value],
    eSignatureCode: string): bool =

  let functionSpecO = getFunction(name, parameters)
  result = true
  if not isSome(functionSpecO):
    echo "No function with this name."
    return false
  let functionSpec = functionSpecO.get()
  if not expectedItem("eSignatureCode", functionSpec.signatureCode, eSignatureCode):
    result = false

proc testIntOk(num: Value, option: string, eIntNum: int): bool =
  var parameters = @[newValue(num), newValue(option)]
  let eFunResult = newFunResult(newValue(eIntNum))
  if testFunction("int", parameters, eFunResult):
    result = true

proc testStartsWith(str: string, prefix: string, eBool: bool): bool =
  var parameters = @[newValue(str), newValue(prefix)]
  let eFunResult = newFunResult(newValue(eBool))
  if testFunction("startsWith", parameters, eFunResult):
    result = true

suite "runFunction.nim":

  test "getFunction missing":
    var parameters = @[newValue(1)]
    let functionSpec = getFunction("notfunction", parameters)
    check not isSome(functionSpec)

  test "getFunction concat":
    var parameters = @[newValue(1), newValue(1)]
    check testGetFunctionExists("concat", parameters, "sss")

  test "getFunction cmp ints":
    var parameters = @[newValue(1), newValue(1)]
    check testGetFunctionExists("cmp", parameters, "iii")

  test "getFunction cmp floats":
    var parameters = @[newValue(1.0), newValue(1.0)]
    check testGetFunctionExists("cmp", parameters, "ffi")

  test "getFunction cmp strings":
    var parameters = @[newValue("a"), newValue("b")]
    check testGetFunctionExists("cmp", parameters, "ssoii")
    parameters = @[newValue("a"), newValue("b"), newValue(1)]
    check testGetFunctionExists("cmp", parameters, "ssoii")

  test "getFunction cmp miss match":
    var parameters = @[newValue(1), newValue(1.0)]
    check testGetFunctionExists("cmp", parameters, "iii")

  test "getFunction float":
    var parameters = @[newValue("1.0"), newValue("default")]
    check testGetFunctionExists("float", parameters, "saa")

  test "concat hello world":
    var parameters = newValue(["Hello", " World"]).listv
    let eFunResult = newFunResult(newValue("Hello World"))
    check testFunction("concat", parameters, eFunResult)

  test "concat empty string":
    var parameters = newValue(["abc", ""]).listv
    let eFunResult = newFunResult(newValue("abc"))
    check testFunction("concat", parameters, eFunResult)

  test "concat nothing":
    var parameters: seq[Value]
    let eFunResult = newFunResultWarn(wNotEnoughArgs, 0, "2")
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
    let eFunResult = newFunResultWarn(wWrongType, 0, "string")
    check testFunction("len", parameters, eFunResult)

  test "len int":
    var parameters = @[newValue(3)]
    let eFunResult = newFunResultWarn(wWrongType, 0, "string")
    check testFunction("len", parameters, eFunResult)

  test "len nothing":
    var parameters: seq[Value] = @[]
    let eFunResult = newFunResultWarn(wNotEnoughArgs, 0, "1")
    check testFunction("len", parameters, eFunResult)

  test "len 2":
    var parameters = newValue([3, 2]).listv
    let eFunResult = newFunResultWarn(wTooManyArgs, 1, "1")
    check testFunction("len", parameters, eFunResult)

  test "get list item":
    var list = newValue([1, 2, 3, 4, 5])
    var parameters = @[list, newValue(0)]
    let eFunResult = newFunResult(newValue(1))
    check testFunction("get", parameters, eFunResult)

  test "get list item -1":
    var list = newValue([1, 2, 3, 4, 5])
    var parameters = @[list, newValue(-1)]
    let eFunResult = newFunResult(newValue(5))
    check testFunction("get", parameters, eFunResult)

  test "get list item -2":
    var list = newValue([1, 2, 3, 4, 5])
    var parameters = @[list, newValue(-2)]
    let eFunResult = newFunResult(newValue(4))
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

  test "get list invalid -6":
    var list = newValue([1, 2, 3, 4, 5])
    var parameters = @[list, newValue(-6)]
    let eFunResult = newFunResultWarn(wMissingListItem, 1, "-6")
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
    let eFunResult = newFunResultWarn(wNotEnoughArgsOpt, 0, "2")
    check testFunction("get", parameters, eFunResult)

  test "get 4 parameters":
    var list = newValue([1, 2, 3, 4, 5])
    let p = newValue(1)
    var parameters = @[list, p, p, p]
    let eFunResult = newFunResultWarn(wTooManyArgsOpt, 3, "3")
    check testFunction("get", parameters, eFunResult)

  test "get parameter 2 wrong type":
    var list = newValue([1, 2, 3, 4, 5])
    var parameters = @[list, newValue("a")]
    let eFunResult = newFunResultWarn(wWrongType, 1, "int")
    check testFunction("get", parameters, eFunResult)

  test "get warning about best matching get":
    # Test the warning is about the function that makes it through the
    # most number of parameters. The second get function has a dict as
    # the first parameter so the warning should be about the wrong
    # second parameter.
    var dict = newValue([("a", 1), ("b", 2), ("c", 3), ("d", 4), ("e", 5)])
    var parameters = @[dict, newValue(3.5)]
    let eFunResult = newFunResultWarn(wWrongType, 1, "string")
    check testFunction("get", parameters, eFunResult)

  test "get wrong first parameter":
    var parameters = @[newValue(2), newValue(2)]
    let eFunResult = newFunResultWarn(wWrongType, 0, "list")
    check testFunction("get", parameters, eFunResult)

  test "get wrong second parameter":
    var list = newValue([1, 2, 3, 4, 5])
    var parameters = @[list, newValue("a")]
    let eFunResult = newFunResultWarn(wWrongType, 1, "int")
    check testFunction("get", parameters, eFunResult)

  test "get invalid index":
    var list = newValue([1, 2, 3, 4, 5])
    var parameters = @[list, newValue(5)]
    let eFunResult = newFunResultWarn(wMissingListItem, 1, "5")
    check testFunction("get", parameters, eFunResult)

  test "get invalid index 2":
    var list = newValue([1, 2, 3, 4, 5])
    var parameters = @[list, newValue(-6)]
    let eFunResult = newFunResultWarn(wMissingListItem, 1, "-6")
    check testFunction("get", parameters, eFunResult)

  test "get invalid index with default":
    var list = newValue([1, 2, 3, 4, 5])
    var parameters = @[list, newValue(5), newValue("hi")]
    let eFunResult = newFunResult(newValue("hi"))
    check testFunction("get", parameters, eFunResult)

  test "cmp ints":
    check testCmpFun(1, 1, expected = 0)
    check testCmpFun(1, 2, expected = -1)
    check testCmpFun(2, 1, expected = 1)

  test "cmp floats":
    check testCmpFun(1.0, 1.0, expected = 0)
    # check testCmpFun(1.2, 2.0, expected = -1)
    # check testCmpFun(2.1, 1.3, expected = 1)

  test "cmp bools":
    check testCmpFun(true, true, expected = 0)
    check testCmpFun(false, false, expected = 0)
    check testCmpFun(true, false, expected = 1)
    check testCmpFun(false, true, expected = -1)

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
    let eFunResult = newFunResultWarn(wNotEnoughArgs, 0, "2")
    check testFunction("cmp", parameters, eFunResult)

  test "cmp not same kind":
    var parameters = @[newValue(4), newValue(4.2)]
    let eFunResult = newFunResultWarn(wWrongType, 1, "int")
    check testFunction("cmp", parameters, eFunResult)

  test "cmp not int, float or string":
    var parameters = @[newEmptyDictValue(), newEmptyDictValue()]
    let eFunResult = newFunResultWarn(wWrongType, 0, "int")
    check testFunction("cmp", parameters, eFunResult)

  test "cmp case insensitive wrong type":
    var parameters = @[newValue(2), newValue(22), newValue("a")]
    let eFunResult = newFunResultWarn(wTooManyArgs, 2, "2")
    check testFunction("cmp", parameters, eFunResult)

  test "cmp case insensitive not 0 or 1":
    var parameters = @[newValue("tea"), newValue("Tea"), newValue(2)]
    let eFunResult = newFunResultWarn(wNotZeroOne, 2)
    check testFunction("cmp", parameters, eFunResult)

  test "if0 function 0":
    var parameters = @[newValue(0), newValue("then"), newValue("else")]
    let eFunResult = newFunResult(newValue("then"))
    check testFunction("if0", parameters, eFunResult)

  test "if0 function no else":
    var parameters = @[newValue(0), newValue("then")]
    let eFunResult = newFunResult(newValue("then"))
    check testFunction("if0", parameters, eFunResult)

  test "if0 function no else taken":
    var parameters = @[newValue(1), newValue("then")]
    let eFunResult = newFunResult(newValue(0))
    check testFunction("if0", parameters, eFunResult)

  test "if0 function not 0":
    var parameters = @[newValue(33), newValue("then"), newValue("else")]
    let eFunResult = newFunResult(newValue("else"))
    check testFunction("if0", parameters, eFunResult)

  test "if function true":
    var parameters = @[newValue(true), newValue("then"), newValue("else")]
    let eFunResult = newFunResult(newValue("then"))
    check testFunction("if", parameters, eFunResult)

  test "if function no else":
    var parameters = @[newValue(true), newValue("then")]
    let eFunResult = newFunResult(newValue("then"))
    check testFunction("if", parameters, eFunResult)

  test "if function no else taken":
    var parameters = @[newValue(false), newValue("then")]
    let eFunResult = newFunResult(newValue(0))
    check testFunction("if", parameters, eFunResult)

  test "if function not false":
    var parameters = @[newValue(false), newValue("then"), newValue("else")]
    let eFunResult = newFunResult(newValue("else"))
    check testFunction("if", parameters, eFunResult)

  test "add 1 + 2":
    var parameters = @[newValue(1), newValue(2)]
    let eFunResult = newFunResult(newValue(3))
    check testFunction("add", parameters, eFunResult)

  test "add 1 - 4":
    var parameters = @[newValue(1), newValue(-4)]
    let eFunResult = newFunResult(newValue(-3))
    check testFunction("add", parameters, eFunResult)

  test "add 1.5 + 2.3":
    var parameters = @[newValue(1.5), newValue(2.3)]
    let eFunResult = newFunResult(newValue(3.8))
    check testFunction("add", parameters, eFunResult)

  test "add 3.3 - 2.2 = 1.1":
    var parameters = @[newValue(3.5), newValue(-2.5)]
    let eFunResult = newFunResult(newValue(1.0))
    check testFunction("add", parameters, eFunResult)

  test "add no parameters":
    var parameters: seq[Value] = @[]
    let eFunResult = newFunResultWarn(wNotEnoughArgs, 0, "2")
    check testFunction("add", parameters, eFunResult)

  test "add string and int":
    var parameters = @[newValue("hi"), newValue(4)]
    let eFunResult = newFunResultWarn(wWrongType, 0, "int")
    check testFunction("add", parameters, eFunResult)

  test "add int and string":
    var parameters = @[newValue(4), newValue("hi")]
    let eFunResult = newFunResultWarn(wWrongType, 1, "int")
    check testFunction("add", parameters, eFunResult)

  test "add int and float":
    var parameters = @[newValue(4), newValue(1.3)]
    let eFunResult = newFunResultWarn(wWrongType, 1, "int")
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

  test "exists true":
    var dict = newValue([("a", 1), ("b", 2), ("c", 3), ("d", 4), ("e", 5)])
    var parameters = @[dict, newValue("b")]
    let eFunResult = newFunResult(newValue(true))
    check testFunction("exists", parameters, eFunResult)

  test "exists false":
    var dict = newValue([("a", 1), ("b", 2), ("c", 3), ("d", 4), ("e", 5)])
    var parameters = @[dict, newValue("z")]
    let eFunResult = newFunResult(newValue(false))
    check testFunction("exists", parameters, eFunResult)

  test "case int":
    var cases = newValue([
      newValue(5), newValue("v5"),
      newValue(6), newValue("v6"),
      newValue(7), newValue("v7"),
      newValue(8), newValue("v8"),
      newValue(9), newValue("v9"),
    ])
    var parameters = @[newValue(5), cases]
    var eFunResult = newFunResult(newValue("v5"))
    check testFunction("case", parameters, eFunResult)

  test "case int using else":
    var cases = newValue([
      newValue(5), newValue("v5"),
    ])
    var parameters = @[newValue(11), cases, newValue("else")]
    let eFunResult = newFunResult(newValue("else"))
    check testFunction("case", parameters, eFunResult)

  test "case empty list":
    let cases = newEmptyListValue()
    var parameters = @[newValue(11), cases, newValue("else")]
    let eFunResult = newFunResult(newValue("else"))
    check testFunction("case", parameters, eFunResult)

  test "case int else needed":
    var cases = newValue([
      newValue(5), newValue("v5"),
    ])
    var parameters = @[newValue(11), cases]
    let eFunResult = newFunResultWarn(wMissingElse, 2)
    check testFunction("case", parameters, eFunResult)

  test "case string":
    var cases = newValue([
      newValue("5"), newValue("v5"),
      newValue("9"), newValue("v9"),
    ])
    var parameters = @[newValue("5"), cases]
    var eFunResult = newFunResult(newValue("v5"))
    check testFunction("case", parameters, eFunResult)

  test "case multiple matches":
    var cases = newValue([
      newValue("3"), newValue("3"),
      newValue("5"), newValue("first5"),
      newValue("7"), newValue("v7"),
      newValue("5"), newValue("second5"),
      newValue("9"), newValue("v9"),
    ])
    var parameters = @[newValue("5"), cases]
    let eFunResult = newFunResult(newValue("first5"))
    check testFunction("case", parameters, eFunResult)

  test "case invalid main condition":
    var cases = newValue([
      newValue(7), newValue("v7"),
    ])
    var parameters = @[newValue(1.2), cases]
    let eFunResult = newFunResultWarn(wWrongType, 0, "int")
    check testFunction("case", parameters, eFunResult)

  test "case invalid condition":
    var cases = newValue([
      newValue(3.5), newValue(9),
      newValue(5), newValue(8),
    ])
    var parameters = @[newValue(5), cases]
    let eFunResult = newFunResultWarn(wCaseTypeMismatch)
    check testFunction("case", parameters, eFunResult)

  test "case main case different type":
    var cases = newValue([
      newValue(5), newValue(5),
      newValue(9), newValue(9),
    ])
    var parameters = @[newValue("a"), cases]
    let eFunResult = newFunResultWarn(wCaseTypeMismatch)
    check testFunction("case", parameters, eFunResult)

  test "case odd number of case items":
    var cases = newValue([
      newValue(5), newValue(5),
      newValue(9),
    ])
    var parameters = @[newValue(5), cases]
    let eFunResult = newFunResultWarn(wNotEvenCases, 1, "3")
    check testFunction("case", parameters, eFunResult)

  test "int() float to int":
    check testIntOk(newValue(2.34), "round", 2)
    check testIntOk(newValue(-2.34), "round", -2)
    check testIntOk(newValue(4.57), "floor", 4)
    check testIntOk(newValue(-4.57), "floor", -5)
    check testIntOk(newValue(6.3), "ceiling", 7)
    check testIntOk(newValue(-6.3), "ceiling", -6)
    check testIntOk(newValue(6.3456), "truncate", 6)
    check testIntOk(newValue(-6.3456), "truncate", -6)

  test "int() with default":
    var parameters = @[newValue("5"), newValue("round"), newValue("nan")]
    let eFunResult = newFunResult(newValue(5))
    check testFunction("int", parameters, eFunResult)

  test "int() with default 2":
    var parameters = @[newValue("5.4"), newValue("round"), newValue("nan")]
    let eFunResult = newFunResult(newValue(5))
    check testFunction("int", parameters, eFunResult)

  test "int() not a number":
    var parameters = @[newValue("notnum"), newValue("round"), newValue("nan")]
    let eFunResult = newFunResult(newValue("nan"))
    check testFunction("int", parameters, eFunResult)

  test "int() float number string to int":
    check testIntOk(newValue("2.34"), "round", 2)
    check testIntOk(newValue("-2.34"), "round", -2)
    check testIntOk(newValue("4.57"), "floor", 4)
    check testIntOk(newValue("-4.57"), "floor", -5)
    check testIntOk(newValue("6.3"), "ceiling", 7)
    check testIntOk(newValue("-6.3"), "ceiling", -6)
    check testIntOk(newValue("6.3456"), "truncate", 6)
    check testIntOk(newValue("-6.3456"), "truncate", -6)

  test "int() int number string to int":
    check testIntOk(newValue("2"), "round", 2)
    check testIntOk(newValue("-2"), "round", -2)

  test "int(): default":
    var parameters = @[newValue(4.57)]
    let eFunResult = newFunResult(newValue(5))
    check testFunction("int", parameters, eFunResult)

  test "int(): wrong number of parameters":
    var parameters = @[newValue(4.57), newValue(1), newValue(2)]
    let eFunResult = newFunResultWarn(wTooManyArgsOpt, 2, "2")
    check testFunction("int", parameters, eFunResult)

  test "int(): not a number string":
    var parameters = @[newValue("hello"), newValue("round")]
    let eFunResult = newFunResultWarn(wExpectedNumberString)
    check testFunction("int", parameters, eFunResult)

  test "int(): not a float":
    var parameters = @[newValue(3), newValue("round")]
    let eFunResult = newFunResultWarn(wWrongType, 0, "float")
    check testFunction("int", parameters, eFunResult)

  test "int(): not round option":
    var parameters = @[newValue(3.4), newValue(5)]
    let eFunResult = newFunResultWarn(wWrongType, 1, "string")
    check testFunction("int", parameters, eFunResult)

  test "int(): not a float":
    var parameters = @[newValue(3.5), newValue("rounder")]
    let eFunResult = newFunResultWarn(wExpectedRoundOption, 1)
    check testFunction("int", parameters, eFunResult)

  test "int(): to big":
    var parameters = @[newValue(3.5e300), newValue("round")]
    let eFunResult = newFunResultWarn(wNumberOverFlow)
    check testFunction("int", parameters, eFunResult)

  test "int(): to small":
    var parameters = @[newValue(-3.5e300), newValue("round")]
    let eFunResult = newFunResultWarn(wNumberOverFlow)
    check testFunction("int", parameters, eFunResult)

  test "to float":
    var parameters = @[newValue(3)]
    let eFunResult = newFunResult(newValue(3.0))
    check testFunction("float", parameters, eFunResult)

  test "to float with default":
    var parameters = @[newValue("3"), newValue("nan")]
    let eFunResult = newFunResult(newValue(3.0))
    check testFunction("float", parameters, eFunResult)

  test "to float not a number":
    var parameters = @[newValue("notnum"), newValue("nan")]
    let eFunResult = newFunResult(newValue("nan"))
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
    let eFunResult = newFunResultWarn(wTooManyArgs, 1, "1")
    check testFunction("float", parameters, eFunResult)

  test "to float warning":
    var parameters = @[newValue("abc")]
    let eFunResult = newFunResultWarn(wExpectedNumberString)
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
    let eFunResult = newFunResultWarn(wNotEnoughArgsOpt, 0, "2")
    check testFunction("find", parameters, eFunResult)

  test "find 1 not string":
    var parameters = @[newValue(1), newValue("bigger")]
    let eFunResult = newFunResultWarn(wWrongType, 0, "string")
    check testFunction("find", parameters, eFunResult)

  test "find 2 not string":
    var parameters = @[newValue("at"), newValue(4.5)]
    let eFunResult = newFunResultWarn(wWrongType, 1, "string")
    check testFunction("find", parameters, eFunResult)

  test "slice Grey":
    var parameters = @[newValue("Earl Grey"), newValue(5)]
    let eFunResult = newFunResult(newValue("Grey"))
    check testFunction("slice", parameters, eFunResult)

  test "slice Earl":
    var parameters = @[newValue("Earl Grey"), newValue(0), newValue(4)]
    let eFunResult = newFunResult(newValue("Earl"))
    check testFunction("slice", parameters, eFunResult)

  test "slice unicode":
    var parameters = @[newValue("añyóng"), newValue(1), newValue(1)]
    let eFunResult = newFunResult(newValue("ñ"))
    check testFunction("slice", parameters, eFunResult)

  test "slice 1 parameter":
    var parameters = @[newValue("big")]
    let eFunResult = newFunResultWarn(wNotEnoughArgsOpt, 0, "2")
    check testFunction("slice", parameters, eFunResult)

  test "slice 1 not string":
    var parameters = @[newValue(4), newValue(4)]
    let eFunResult = newFunResultWarn(wWrongType, 0, "string")
    check testFunction("slice", parameters, eFunResult)

  test "slice 2 not int":
    var parameters = @[newValue("tasdf"), newValue("dsa")]
    let eFunResult = newFunResultWarn(wWrongType, 1, "int")
    check testFunction("slice", parameters, eFunResult)

  test "slice 3 not int":
    var parameters = @[newValue("tasdf"), newValue(0), newValue("tasdf")]
    let eFunResult = newFunResultWarn(wWrongType, 2, "int")
    check testFunction("slice", parameters, eFunResult)

  test "slice start < 0":
    var parameters = @[newValue("tasdf"), newValue(-2), newValue(1)]
    let eFunResult = newFunResultWarn(wStartPosTooSmall, 1)
    check testFunction("slice", parameters, eFunResult)

  test "slice length too big":
    var parameters = @[newValue("tasdf"), newValue(0), newValue(10)]
    let eFunResult = newFunResultWarn(wLengthTooBig, 2)
    check testFunction("slice", parameters, eFunResult)

  test "slice nothing":
    var parameters = @[newValue("tasdf"), newValue(3), newValue(0)]
    let eFunResult = newFunResult(newValue(""))
    check testFunction("slice", parameters, eFunResult)

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

  test "dup nothing":
    var parameters = @[newValue(""), newValue(1)]
    let eFunResult = newFunResult(newValue(""))
    check testFunction("dup", parameters, eFunResult)

  test "dup 1 parameter":
    var parameters = @[newValue("abc")]
    let eFunResult = newFunResultWarn(wNotEnoughArgs, 0, "2")
    check testFunction("dup", parameters, eFunResult)

  test "dup not valid string":
    var parameters = @[newValue(4.3), newValue(2)]
    let eFunResult = newFunResultWarn(wWrongType, 0, "string")
    check testFunction("dup", parameters, eFunResult)

  test "dup not valid count":
    var parameters = @[newValue("="), newValue("=")]
    let eFunResult = newFunResultWarn(wWrongType, 1, "int")
    check testFunction("dup", parameters, eFunResult)

  test "dup negative count":
    var parameters = @[newValue("="), newValue(-9)]
    let eFunResult = newFunResultWarn(wInvalidMaxCount, 1)
    check testFunction("dup", parameters, eFunResult)

  test "dup too long":
    var parameters = @[newValue("="), newValue(123_333)]
    let eFunResult = newFunResultWarn(wDupStringTooLong, 1, "123333")
    check testFunction("dup", parameters, eFunResult)

  test "dict()":
    var parameters: seq[Value] = @[]
    let eFunResult = newFunResult(newEmptyDictValue())
    check testFunction("dict", parameters, eFunResult)

  test "dict(['a', 5])":
    let listValue = newValue([newValue("a"), newValue(5)])
    var parameters = @[listValue]
    var dict = newValue([("a", 5)])
    let eFunResult = newFunResult(dict)
    check testFunction("dict", parameters, eFunResult)

  test "dict(['a', 5, 'b', 3])":
    let listValue = newValue([newValue("a"), newValue(5), newValue("b"), newValue(3)])
    var parameters = @[listValue]
    let dict = newValue([("a", 5), ("b", 3)])
    let eFunResult = newFunResult(dict)
    check testFunction("dict", parameters, eFunResult)

  test "dict(['a'])":
    var parameters = @[newValue([newValue("a")])]
    let eFunResult = newFunResultWarn(wDictRequiresEven, 0)
    check testFunction("dict", parameters, eFunResult)

  test "dict(['a', 'b', 'c'])":
    let listValue = newValue([newValue("a"), newValue("b"), newValue("c")])
    var parameters = @[listValue]
    let eFunResult = newFunResultWarn(wDictRequiresEven, 0)
    check testFunction("dict", parameters, eFunResult)

  test "dict(['key', 1, 2, 1])":
    let listValue = newValue([newValue("key"), newValue(1), newValue(2), newValue(1)])
    var parameters = @[listValue]
    let eFunResult = newFunResultWarn(wDictStringKey, 0)
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
    let eFunResult = newFunResultWarn(wWrongType, 0, "string")
    check testFunction("replace", parameters, eFunResult)

  test "replace invalid param 2":
    var parameters: seq[Value] = @[newValue("Earl Grey"),
      newValue("a"), newValue(9), newValue("Eat the Sandwich")]
    let eFunResult = newFunResultWarn(wWrongType, 1, "int")
    check testFunction("replace", parameters, eFunResult)

  test "replace invalid p3":
    var parameters: seq[Value] = @[newValue("Earl Grey"),
      newValue(5), newValue("d"), newValue("Eat the Sandwich")]
    let eFunResult = newFunResultWarn(wWrongType, 2, "int")
    check testFunction("replace", parameters, eFunResult)

  test "replace invalid p4":
    var parameters: seq[Value] = @[newValue("Earl Grey"),
      newValue(5), newValue(4), newValue(4.3)]
    let eFunResult = newFunResultWarn(wWrongType, 3, "string")
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
    check testReplaceReGoodList("abc123abc", newValue(["abc", "456"]), "456123456")
    check testReplaceReGoodList("testFunResulthere FunResult FunResult",
      newValue([r"\bFunResult\b", "FunResult_"]),
      "testFunResulthere FunResult_ FunResult_")
    check testReplaceReGoodList("abc123abc", newValue(["^abc", "456"]), "456123abc")
    check testReplaceReGoodList("abc123abc", newValue(["abc$", "456"]), "abc123456")
    check testReplaceReGoodList("abc123abc", newValue(["abc", ""]), "123")
    check testReplaceReGoodList("abc123abc", newValue(["a", ""]), "bc123bc")
    check testReplaceReGoodList("", newValue(["", ""]), "")
    check testReplaceReGoodList("", newValue(["a", ""]), "")
    check testReplaceReGoodList("b", newValue(["a", ""]), "b")
    check testReplaceReGoodList("", newValue(["a", "b"]), "")
    check testReplaceReGoodList("abc123abc", newValue(["a", "x", "b", "y"]), "xyc123xyc")
    check testReplaceReGoodList("abc123abc",
      newValue(["a", "x", "b", "y", "c", "z"]), "xyz123xyz")
    check testReplaceReGoodList(" @:- p1\n @: 222", newValue([" @:[ ]*", ""]), "- p1\n222")
    check testReplaceReGoodList("value one @: @: ... @: @:- pn-2",
      newValue(["[ ]*@:[ ]*", "X"]), "value oneXX...XX- pn-2")
    let text = ":linkTargetBegin:Semantic Versioning:linkTargetEnd://semver.org/"
    check testReplaceReGoodList(text, newValue([":linkTargetBegin:", ".. _`",
      ":linkTargetEnd:", "`: https"]), ".. _`Semantic Versioning`: https//semver.org/")

    let textMd = "## @:StaticTea uses @{Semantic Versioning}@(https@@://semver.org/)"
    let eTextMd = "##\nStaticTea uses [Semantic Versioning](https://semver.org/)"
    check testReplaceReGoodList(textMd,
      newValue(["@@", "", r"@{", "[", r"}@", "]", "[ ]*@:", "\n"]), eTextMd)

  test "replaceRe brackets":
    check testReplaceReGoodList("newOpResultIdId@{int}@(wUnknownArg)",
      newValue(["@{", "[", "}@", "]"]), "newOpResultIdId[int](wUnknownArg)")

  test "replaceRe hide https":
    check testReplaceReGoodList("https@@:/something.com",
      newValue(["@@", ""]), "https:/something.com")

  test "replaceRe lower case":
    check testReplaceReGoodList("funReplace", newValue(["fun(.*)", "$1Fun"]), "ReplaceFun")

  test "replaceRe *":
    check testReplaceReGoodList("* test", newValue([r"^\*", "-"]), "- test")
    check testReplaceReGoodList("* test", newValue(["^\\*", "-"]), "- test")
    check testReplaceReGoodList("@:* test", newValue(["@:\\*", "-"]), "- test")
    check testReplaceReGoodList("""* "round""", newValue(["\\* \"", "- \""]), "- \"round")

  test "replaceRe runtime error":
    # check testReplaceReGoodList("* test", newValue([r"^*", "-"]), "- test")
    let eFunResult = newFunResultWarn(wReplaceMany, 1)
    var parameters = @[newValue("* test"), newValue([r"^*", "-"])]
    check testFunction("replaceRe", parameters, eFunResult)

  test "replaceRe good list":
    check testReplaceReGoodList("abc123abc", newValue(["abc", "456"]), "456123456")
    check testReplaceReGoodList("abc123abc", newValue(["a", "x", "b", "y", "c", "z"]),
                                "xyz123xyz")

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
    let eFunResult = newFunResultWarn(wTooManyArgsOpt, 2, "2")
    check testFunction("path", parameters, eFunResult)

  test "path: wrong number of parameters 2":
    var parameters: seq[Value] = @[newValue("Earl Grey"),
                                   newValue("a"), newValue("a"), newValue(2)]
    let eFunResult = newFunResultWarn(wTooManyArgsOpt, 2, "2")
    check testFunction("path", parameters, eFunResult)

  test "path: wrong kind p1":
    var parameters: seq[Value] = @[newValue(12)]
    let eFunResult = newFunResultWarn(wWrongType, 0, "string")
    check testFunction("path", parameters, eFunResult)

  test "path: wrong kind param 2":
    var parameters: seq[Value] = @[newValue("filename"), newValue(12)]
    let eFunResult = newFunResultWarn(wWrongType, 1, "string")
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
    let eFunResult = newFunResultWarn(wNotEnoughArgs, 0, "1")
    check testFunction("lower", parameters, eFunResult)

  test "lower: wrong kind of parameter":
    var parameters: seq[Value] = @[newValue(2)]
    let eFunResult = newFunResultWarn(wWrongType, 0, "string")
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
    let eFunResult = newFunResultWarn(wNotEnoughArgs, 0, "1")
    check testFunction("keys", parameters, eFunResult)

  test "keys: wrong kind of parameter":
    var parameters: seq[Value] = @[newValue(2)]
    let eFunResult = newFunResultWarn(wWrongType, 0, "dict")
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
    let eFunResult = newFunResultWarn(wNotEnoughArgs, 0, "1")
    check testFunction("values", parameters, eFunResult)

  test "values: wrong kind of parameter":
    var parameters: seq[Value] = @[newValue(2)]
    let eFunResult = newFunResultWarn(wWrongType, 0, "dict")
    check testFunction("values", parameters, eFunResult)

  test "sort empty":
    let emptyList = newEmptyListValue()
    check testFunction("sort", @[
      emptyList,
      newValue("ascending"),
      newValue("insensitive"),
    ], newFunResult(emptyList))

    check testFunction("sort", @[
      emptyList,
      newValue("ascending"),
    ], newFunResult(emptyList))

  test "sort empty lists":
    let emptyList = newEmptyListValue()
    check testFunction("sort", @[
      emptyList,
      newValue("ascending"),
      newValue("insensitive"),
      newValue(0)
    ], newFunResult(emptyList))

  test "sort empty dicts":
    let emptyList = newEmptyListValue()
    check testFunction("sort", @[
      emptyList,
      newValue("descending"),
      newValue("insensitive"),
      newValue("key")
    ], newFunResult(emptyList))

  test "sort one":
    let list = newValue([1])
    check testFunction("sort", @[list, newValue("ascending")], newFunResult(list))

  test "sort two":
    let list = newValue([2, 1])
    let eList = newValue([1, 2])
    check testFunction("sort", @[list, newValue("ascending")], newFunResult(eList))

  test "sort ascending":
    let list = newValue([2, 1])
    let eList = newValue([1, 2])
    check testFunction("sort", @[list, newValue("ascending")], newFunResult(eList))

  test "sort descending":
    let list = newValue([2, 3, 4, 4, 5, 5])
    let eList = newValue([5, 5, 4, 4, 3, 2])
    check testFunction("sort", @[list, newValue("descending")], newFunResult(eList))

  test "sort floats":
    let list = newValue([2.4, 1.6])
    let eList = newValue([1.6, 2.4])
    check testFunction("sort", @[list, newValue("ascending")], newFunResult(eList))

  test "sort strings":
    let list = newValue(["abc", "b", "aaa"])
    let eList = newValue(["aaa", "abc", "b"])
    check testFunction("sort", @[list, newValue("ascending")], newFunResult(eList))

  test "sort strings case sensitive":
    let list = newValue(["A", "a", "b", "B"])
    let eList = newValue(["A", "B", "a", "b"])
    check testFunction("sort", @[list, newValue("ascending")], newFunResult(eList))

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
    check testFunction("sort", @[
      list, newValue("ascending"), newValue("insensitive")
    ], newFunResult(eList))
    let eList2 = newValue([l1, l2])
    check testFunction("sort", @[
      list, newValue("descending"), newValue("insensitive")
    ], newFunResult(eList2))

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

    check testFunction("sort", @[
      list, newValue("ascending"), newValue("sensitive"), newValue("weight")
    ], newFunResult(list))

    check testFunction("sort", @[
      list, newValue("ascending"), newValue("sensitive"), newValue("name")
    ], newFunResult(list))

    check testFunction("sort", @[
      list, newValue("descending"), newValue("sensitive"), newValue("name")
    ], newFunResult(eList2))

    check testFunction("sort", @[
      list, newValue("descending"), newValue("sensitive"), newValue("weight")
    ], newFunResult(eList2))

    check testFunction("sort", @[
      list, newValue("descending"), newValue("sensitive"), newValue("weight")
    ], newFunResult(eList2))

    check testFunction("sort", @[
      list, newValue("descending"), newValue("insensitive"), newValue("name")
    ], newFunResult(eList2))

  test "sort: wrong number of parameters":
    var parameters: seq[Value] = @[]
    let eFunResult = newFunResultWarn(wNotEnoughArgsOpt, 0, "2")
    check testFunction("sort", parameters, eFunResult)

  test "sort: not list":
    var parameters: seq[Value] = @[newValue(0), newValue("ascending")]
    let eFunResult = newFunResultWarn(wWrongType, 0, "list")
    check testFunction("sort", parameters, eFunResult)

  test "sort: invalid order":
    let list = newValue([1])
    var parameters: seq[Value] = @[list, newValue(22)]
    let eFunResult = newFunResultWarn(wWrongType, 1, "string")
    check testFunction("sort", parameters, eFunResult)

  test "sort: invalid order spelling":
    let list = newValue([1])
    var parameters: seq[Value] = @[list, newValue("asc")]
    let eFunResult = newFunResultWarn(wExpectedSortOrder, 1)
    check testFunction("sort", parameters, eFunResult)

  test "sort: values not same kind":
    var parameters: seq[Value] = @[
      newValue([newValue(1), newValue(2.2)]),
      newValue("ascending"),
    ]
    let eFunResult = newFunResultWarn(wNotSameKind, 0)
    check testFunction("sort", parameters, eFunResult)

  test "sort: invalid sensitive option":
    let list = newValue(["abc", "b", "aaa"])
    var parameters: seq[Value] = @[list,
      newValue("ascending"),
      newValue(2.2),
    ]
    var eFunResult = newFunResultWarn(wWrongType, 2, "string")
    check testFunction("sort", parameters, eFunResult)

    parameters = @[
      list,
      newValue("ascending"),
      newValue("t")
    ]
    eFunResult = newFunResultWarn(wExpectedSensitivity, 2)
    check testFunction("sort", parameters, eFunResult)

  test "sort: none first dict key missing":
    let d1 = newValue([("a", 2), ("b", 3)])
    let d2 = newValue([("a3", 2), ("b3", 3)])
    let list = newValue([d1, d2])
    var parameters = @[
      list,
      newValue("ascending"),
      newValue("sensitive"),
      newValue("a")
    ]
    let eFunResult = newFunResultWarn(wDictKeyMissing, 0)
    check testFunction("sort", parameters, eFunResult)

  test "sort: dict key values different":
    let d1 = newValue([("a", 2), ("b", 3)])
    let d2 = newValue([("a", 2.2), ("b", 3.3)])
    let list = newValue([d1, d2])
    var parameters = @[
      list,
      newValue("ascending"),
      newValue("sensitive"),
      newValue("a")
    ]
    let eFunResult = newFunResultWarn(wKeyValueKindDiff, 0)
    check testFunction("sort", parameters, eFunResult)

  test "githubAnchor":
    check testAnchor("", "")
    check testAnchor("a_b", "a_b")
    check testAnchor("T", "t")
    check testAnchor("Tea", "tea")
    check testAnchor("t", "t")
    check testAnchor("TEA", "tea")
    check testAnchor("$", "")
    check testAnchor("==", "")
    check testAnchor("Eary Gray", "eary-gray")
    check testAnchor("Eary-Gray", "eary-gray")
    check testAnchor("1234567890", "1234567890")
    check testAnchor("1!2@3#4%5^6&7*8(9)0", "1234567890")
    let str = "Zwölf Boxkämpfer jagten Eva quer über den Sylter Deich"
    let eStr = "zwölf-boxkämpfer-jagten-eva-quer-über-den-sylter-deich"
    # (= Twelve boxing fighters hunted Eva across the dike of Sylt)
    check testAnchor(str, eStr)

  test "githubAnchor signatures":
    check testAnchor("funSort_lsssl", "funsort_lsssl")
    check testAnchor("sort_lsssl", "sort_lsssl")

  test "githubAnchor: wrong number of parameters":
    var parameters: seq[Value] = @[]
    let eFunResult = newFunResultWarn(wNotEnoughArgs, 0, "1")
    check testFunction("githubAnchor", parameters, eFunResult)

  test "githubAnchor: wrong kind of parameter":
    var parameters: seq[Value] = @[newValue(2)]
    let eFunResult = newFunResultWarn(wWrongType, 0, "string")
    check testFunction("githubAnchor", parameters, eFunResult)

  test "githubAnchor list":
    let list = newValue(["Tea", "Water", "tea"])
    let expected = newValue(["tea", "water", "tea-1"])
    let parameters = @[list]
    let eFunResult = newFunResult(expected)
    check testFunction("githubAnchor", parameters, eFunResult)

  test "githubAnchor wrong list item":
    let list = newValue([newValue("Tea"), newValue(5)])
    let parameters = @[list]
    let eFunResult = newFunResultWarn(wNotAllStrings, 0)
    check testFunction("githubAnchor", parameters, eFunResult)

  test "githubAnchor empty list":
    let emptyList = newEmptyListValue()
    let parameters = @[emptyList]
    let eFunResult = newFunResult(emptyList)
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
    let eFunResult = newFunResultWarn(wNotEnoughArgs, 0, "2")
    check testFunction("cmpVersion", parameters, eFunResult)

  test "cmdVersion: two many parameters":
    let parameters = @[newValue("1.2.3"), newValue("1.2.3"), newValue("1.2.3")]
    let eFunResult = newFunResultWarn(wTooManyArgs, 2, "2")
    check testFunction("cmpVersion", parameters, eFunResult)

  test "cmdVersion: invalid version a":
    let parameters = @[newValue("1.2.3a"), newValue("1.2.3")]
    let eFunResult = newFunResultWarn(wInvalidVersion, 0)
    check testFunction("cmpVersion", parameters, eFunResult)

  test "cmdVersion: invalid version b":
    let parameters = @[newValue("1.2.3"), newValue("1.2.3b")]
    let eFunResult = newFunResultWarn(wInvalidVersion, 1)
    check testFunction("cmpVersion", parameters, eFunResult)

  test "type":
    check testFunction("type", @[newValue(1)], newFunResult(newValue("int")))
    check testFunction("type", @[newValue(3.14159)], newFunResult(newValue("float")))
    check testFunction("type", @[newValue("Tea")], newFunResult(newValue("string")))
    let list = newValue(["Tea", "Water", "tea"])
    check testFunction("type", @[list], newFunResult(newValue("list")))
    var dict = newVarsDict()
    dict["a"] = newValue(1)
    check testFunction("type", @[newValue(dict)], newFunResult(newValue("dict")))

  test "joinPath":
    # let list = newValue(["Tea", "Water", "tea"])

    check testFunction("joinPath", @[newEmptyListValue()],
      newFunResult(newValue("")))

    check testFunction("joinPath", @[
        newValue([newValue("tea")])
      ], newFunResult(newValue("tea")))

    check testFunction("joinPath", @[
        newValue([newValue("images"), newValue("tea")])
      ], newFunResult(newValue("images/tea")))

    check testFunction("joinPath", @[
        newValue([newValue("images"), newValue("tea")]), newValue("/")
      ], newFunResult(newValue("images/tea")))

    check testFunction("joinPath", @[
        newValue([newValue("images"), newValue("tea")]), newValue(r"\")
      ], newFunResult(newValue(r"images\tea")))

    check testFunction("joinPath", @[
        newValue([newValue("images/"), newValue("tea")])
      ], newFunResult(newValue("images/tea")))

    check testFunction("joinPath", @[
        newValue([newValue("images"), newValue("/tea")])
      ], newFunResult(newValue("images/tea")))

    check testFunction("joinPath", @[
        newValue([newValue("images/green"), newValue("tea")])
      ], newFunResult(newValue("images/green/tea")))

    check testFunction("joinPath", @[
        newValue([newValue(""), newValue("tea")])
      ], newFunResult(newValue("/tea")))

    check testFunction("joinPath", @[
        newValue([newValue(""), newValue("tea"), newValue("")])
      ], newFunResult(newValue("/tea/")))

    check testFunction("joinPath", @[
        newValue([newValue("/"), newValue("tea"), newValue("/")])
      ], newFunResult(newValue("/tea/")))

    check testFunction("joinPath", @[
        newValue([newValue("/tea/")])
      ], newFunResult(newValue("/tea/")))

    check testFunction("joinPath", @[
        newValue([newValue("/")])
      ], newFunResult(newValue("/")))

    check testFunction("joinPath", @[
        newValue([newValue("/images"), newValue("tea")])
      ], newFunResult(newValue("/images/tea")))

    check testFunction("joinPath", @[
        newValue([newValue("/var/"), newValue("log/tea")])
      ], newFunResult(newValue("/var/log/tea")))

    check testFunction("joinPath", @[
        newValue([newValue("/var/"), newValue("log/tea/")])
      ], newFunResult(newValue("/var/log/tea/")))

    check testFunction("joinPath", @[
        newValue([newValue("/var/"), newValue("/log/tea/")])
      ], newFunResult(newValue("/var//log/tea/")))

  test "joinPath invalid separator":
    let parameters = @[newEmptyListValue(), newValue("h")]
    let eFunResult = newFunResultWarn(wExpectedSeparator, 0)
    check testFunction("joinPath", parameters, eFunResult)

  test "join nothing":
    let list = newEmptyListValue()
    check testFunction("join", @[
        newValue(list),
        newValue("|"),
      ], newFunResult(newValue("")))

  test "join a, b":
    let list = newValue(["a", "b"])
    check testFunction("join", @[
        newValue(list),
        newValue(", "),
      ], newFunResult(newValue("a, b")))

  test "join a, b empty separator":
    let list = newValue(["a", "b"])
    check testFunction("join", @[
        newValue(list),
        newValue(""),
      ], newFunResult(newValue("ab")))

  test "join a, b, c empty separator":
    let list = newValue(["apple", "banana", "cherry"])
    check testFunction("join", @[
        newValue(list),
        newValue(""),
      ], newFunResult(newValue("applebananacherry")))

  test "join a":
    let list = newValue(["a"])
    check testFunction("join", @[
        newValue(list),
        newValue(", "),
      ], newFunResult(newValue("a")))

  test "join ab":
    let list = newValue(["a", "b"])
    check testFunction("join", @[
        newValue(list),
        newValue(""),
      ], newFunResult(newValue("ab")))

  test "join a nothing b":
    let list = newValue(["a", "", "b"])
    check testFunction("join", @[
        newValue(list),
        newValue("|"),
      ], newFunResult(newValue("a||b")))

  test "join a nothing b skipping empty":
    let list = newValue(["a", "", "b"])
    check testFunction("join", @[
        newValue(list),
        newValue("|"),
        newValue(1),
      ], newFunResult(newValue("a|b")))

  test "warn":
    let message = "my warning"
    let parameters = @[newValue(message)]
    let eFunResult = newFunResultWarn(wUserMessage, 0, message)
    check testFunction("warn", parameters, eFunResult)

  test "return":
    check testFunction("return", @[newValue("")], newFunResult(newValue("")))
    check testFunction("return", @[newValue("skip")],
      newFunResult(newValue("skip")))
    check testFunction("return", @[newValue("stop")],
      newFunResult(newValue("stop")))

  test "string default":
    check testFunction("string", @[newValue(1)], newFunResult(newValue("1")))
    check testFunction("string", @[newValue(1.5)], newFunResult(newValue("1.5")))
    check testFunction("string", @[newValue("str")], newFunResult(newValue("str")))
    let list = newValue([newValue("a"), newValue(2), newValue(3.4)])
    check testFunction("string", @[list], newFunResult(newValue("""["a",2,3.4]""")))
    var dict = newVarsDict()
    dict["abc"] = newValue("str")
    dict["xyz"] = newValue(8)
    check testFunction("string", @[newValue(dict)],
      newFunResult(newValue("""{"abc":"str","xyz":8}""")))

  test "string rb":
    let stype = newValue("rb")
    check testFunction("string", @[newValue(1), stype],
      newFunResult(newValue("1")))
    check testFunction("string", @[newValue(1.5), stype],
      newFunResult(newValue("1.5")))
    check testFunction("string", @[newValue("str"), stype],
      newFunResult(newValue("str")))
    let list = newValue([newValue("a"), newValue(2), newValue(3.4)])
    check testFunction("string", @[list, stype],
      newFunResult(newValue("""["a",2,3.4]""")))
    var dict = newVarsDict()
    dict["abc"] = newValue("str")
    dict["xyz"] = newValue(8)
    check testFunction("string", @[newValue(dict), stype],
      newFunResult(newValue("""{"abc":"str","xyz":8}""")))

  test "string json":
    let stype = newValue("json")
    check testFunction("string", @[newValue("str"), stype],
      newFunResult(newValue("\"str\"")))

  test "string dot-names":
    let stype = newValue("dn")
    check testFunction("string", @[newValue("str"), stype],
      newFunResult(newValue("\"str\"")))

  test "string other":
    let stype = newValue("other")
    let eFunResult = newFunResultWarn(wInvalidStringType, 1)
    check testFunction("string", @[newValue("str"), stype],
      eFunResult)

  test "string dictionary":
    var dict = newVarsDict()
    dict["abc"] = newValue("str")
    dict["eight"] = newValue(8)
    var sub = newVarsDict()
    sub["x"] = newValue("tea")
    sub["y"] = newValue(4)
    dict["sub"] = newValue(sub)
    let expected = """
d.abc = "str"
d.eight = 8
d.sub.x = "tea"
d.sub.y = 4"""
    check testFunction("string", @[newValue("d"), newValue(dict)],
      newFunResult(newValue(expected)))

  test "format":
    let str = newValue("hello")
    check testFunction("format", @[str],
      newFunResult(newValue("hello")))

  test "format one":
    var variables = emptyVariables()
    variables["l"].dictv["name"] = newValue("world")
    let str = newValue("hello {name}")
    check testFunction("format", @[str],
      newFunResult(newValue("hello world")), variables)

  test "format warning":
    let str = newValue("hello {name}")
    let eFunResult = newFunResultWarn(wVariableMissing, 0, "name", 7)
    check testFunction("format", @[str], eFunResult)

  test "startsWith":
    check testStartsWith("hello", "he", true)
    check testStartsWith("hello", "ll", false)
    check testStartsWith("a", "a", true)
    check testStartsWith("a", "ab", false)
    check testStartsWith("ab", "a", true)
    check testStartsWith("ab", "ab", true)

    check testStartsWith("", "", true)
    check testStartsWith("abc", "", true)
    check testStartsWith("", "l", false)

  test "bool false":
    var parameters = @[newValue(0)]
    let eFunResult = newFunResult(newValue(false))
    check testFunction("bool", parameters, eFunResult)

  test "bool true":
    var parameters = @[newValue(3)]
    let eFunResult = newFunResult(newValue(true))
    check testFunction("bool", parameters, eFunResult)

  test "not false":
    var parameters = @[newValue(false)]
    let eFunResult = newFunResult(newValue(true))
    check testFunction("not", parameters, eFunResult)

  test "not true":
    var parameters = @[newValue(true)]
    let eFunResult = newFunResult(newValue(false))
    check testFunction("not", parameters, eFunResult)

