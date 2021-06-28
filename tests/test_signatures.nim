import std/unittest
import signatures
import env
import vartypes
import warnings
import funtypes
import options
import tostring

proc testYieldParam(signatureCode: string, eStrings: seq[string]): bool =
  var strings: seq[string]
  for paramO in yieldParam(signatureCode):
    if not paramO.isSome:
      return false
    strings.add($paramO.get())
  result = expectedItems("yieldParam", strings, eStrings)

proc testParamString(name: string, paramType: ParamType, optional: bool,
                     eString: string): bool =
  ## Test single arg cases.
  let param = newParam("hello", optional, false, @[paramType])
  result = expectedItem("param", $param, eString)

proc testParamString(name: string, paramTypes: seq[ParamType], optional: bool,
                     eString: string): bool =
  ## Test varargs cases.
  let param = newParam("hello", optional, true, paramTypes)
  result = expectedItem("param", $param, eString)

proc testGetParametersGood(parameters: seq[Value], start: int,
    count: int, eValues: seq[Value]): bool =
  var got = getParameters(parameters, start, count)
  if expectedItem("getParameters", got, some(eValues)):
    result = true

proc testGetParametersEmpty(parameters: seq[Value], start: int,
    count: int): bool =
  var got = getParameters(parameters, start, count)
  let eValuesO = none(seq[Value])
  if expectedItem("getParameters", got, eValuesO):
    result = true


suite "signatures.nim":

  test "test me":
    check 1 == 1

  test "getParameters empty":
    var parameters: seq[Value] = @[]
    check testGetParametersEmpty(parameters, 0, 0)
    check testGetParametersEmpty(parameters, 0, 1)
    check testGetParametersEmpty(parameters, 1, 0)
    check testGetParametersEmpty(parameters, 1, 1)

  test "getParameters one":
    var parameters = @[newValue("hello")]
    check testGetParametersEmpty(parameters, 0, 0)
    check testGetParametersGood(parameters, 0, 1, parameters)
    check testGetParametersEmpty(parameters, 0, 2)
    check testGetParametersEmpty(parameters, 1, 0)
    check testGetParametersEmpty(parameters, 1, 1)

  test "getParameters two":
    var parameters = @[newValue(1), newValue(2)]
    check testGetParametersEmpty(parameters, 0, 0)
    check testGetParametersGood(parameters, 0, 1, @[newValue(1)])
    check testGetParametersGood(parameters, 0, 2, parameters)
    check testGetParametersEmpty(parameters, 0, 3)
    check testGetParametersEmpty(parameters, 1, 0)
    check testGetParametersGood(parameters, 1, 1, @[newValue(2)])
    check testGetParametersEmpty(parameters, 1, 2)
    check testGetParametersEmpty(parameters, 2, 0)
    check testGetParametersEmpty(parameters, 2, 1)

  test "getParameters four":
    var parameters = @[newValue(1), newValue(2), newValue(3), newValue(4)]
    check testGetParametersGood(parameters, 0, 1, @[newValue(1)])
    check testGetParametersGood(parameters, 1, 1, @[newValue(2)])
    check testGetParametersGood(parameters, 2, 1, @[newValue(3)])
    check testGetParametersGood(parameters, 3, 1, @[newValue(4)])
    check testGetParametersGood(parameters, 0, 2, @[newValue(1), newValue(2)])
    check testGetParametersGood(parameters, 2, 2, @[newValue(3), newValue(4)])
    check testGetParametersGood(parameters, 0, 3, @[newValue(1), newValue(2), newValue(3)])
    check testGetParametersGood(parameters, 1, 3, @[newValue(2), newValue(3), newValue(4)])
    check testGetParametersGood(parameters, 0, 4, parameters)

  test "checkParameters happy path":
    var parameters = @[newValue("hello")]
    let funResultO = checkParameters("(name: string) string", parameters)
    let eFunResultO = none(FunResult)
    check expectedItem("checkParameters", funResultO, eFunResultO)

  test "checkParameters":
    var parameters = @[newValue(3)]
    let funResultO = checkParameters("(name: string) string", parameters)
    let eFunResultO = some(newFunResultWarn(wExpectedString, 0))
    check expectedItem("checkParameters", funResultO, eFunResultO)

  test "Param signal representation":
    check testParamString("hello", ptInt, false, "hello: int")
    check testParamString("hello", ptInt, true, "hello: optional int")

  test "Param varargs representation":
    check testParamString("hello", @[ptInt, ptString], false,
      "hello: varargs(int, string)")
    check testParamString("hello", @[ptInt, ptString], true,
      "hello: optional varargs(int, string)")

  test "codeToParamType":
    check codeToParamType('i') == ptInt
    check codeToParamType('a') == ptAny

  test "charDigit":
    check charDigit('0') == 0
    check charDigit('1') == 1
    check charDigit('9') == 9
    check charDigit('a') == 0

  test "getNextName":
    var names = Names()
    check getNextName(names) == "a"
    check getNextName(names) == "b"
    check getNextName(names) == "c"
    check getNextName(names) == "d"

  test "yieldParam":
    check testYieldParam("i", @["a: int"])
    check testYieldParam("ifslda",
      @["a: int", "b: float", "c: string", "d: list", "e: dict", "f: any"])
    check testYieldParam("oi", @["a: optional int"])

  test "yieldParam varargs":
    check testYieldParam("r1i", @["a: varargs(int)"])
    check testYieldParam("or1i", @["a: optional varargs(int)"])
    check testYieldParam("r2if", @["a: varargs(int, float)"])
    check testYieldParam("r2sa", @["a: varargs(string, any)"])
    check testYieldParam("or2sa", @["a: optional varargs(string, any)"])
    check testYieldParam("r3sai", @["a: varargs(string, any, int)"])

  test "yieldParam multiple":
    check testYieldParam("ir2ia", @["a: int", "b: varargs(int, any)"])
    check testYieldParam("ir2iaoa", @["a: int", "b: varargs(int, any)", "c: optional any"])
