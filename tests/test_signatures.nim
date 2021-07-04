import std/unittest
import signatures
import env
import vartypes
import funtypes
import options
import tostring

proc testSignatureCodeToParams(signatureCode: string, expected: string): bool =
  var params0 = signatureCodeToParams(signatureCode)
  if not params0.isSome:
    echo "Not a valid signature."
    result = false
  else:
    result = expectedItem("signatureCodeToParams",
      parmsToSignature(params0.get()), expected)

proc testMapParametersOk(signatureCode: string, args: seq[Value],
                       eMapJson: string): bool =
  var paramsO = signatureCodeToParams(signatureCode)
  if not paramsO.isSome:
    echo "Invalid signature: " & signatureCode
    return false
  let funResult = mapParameters(paramsO.get(), args)
  if not expectedItem("mapParameters", funResult.kind, frValue):
    return false
  if not expectedItem("mapParameters", valueToString(funResult.value), eMapJson):
    echo "signatureCode: " & signatureCode
    return false
  result = true

proc testYieldParam(signatureCode: string, eStrings: seq[string]): bool =
  var strings: seq[string]
  for paramO in yieldParam(signatureCode):
    if not paramO.isSome:
      return false
    strings.add($paramO.get())
  result = expectedItems("yieldParam", strings, eStrings)

proc testParamStringSingle(name: string, paramType: ParamType, optional: bool,
                     eString: string): bool =
  ## Test single arg cases.
  let param = newParam("hello", optional, false, false, @[paramType])
  result = expectedItem("param", $param, eString)

proc testParamStringVarargs(name: string, paramTypes: seq[ParamType], optional: bool,
                     eString: string): bool =
  ## Test varargs cases.
  let param = newParam("hello", optional, true, false, paramTypes)
  result = expectedItem("param", $param, eString)

proc testParamStringReturn(paramType: ParamType, eString: string): bool =
  ## Test return parameter case.
  let param = newParam("result", false, false, true, @[paramType])
  result = expectedItem("param", $param, eString)


suite "signatures.nim":

  test "test me":
    check 1 == 1

  test "paramType string":
    check paramTypeString('i') == "int"
    check paramTypeString('f') == "float"
    check paramTypeString('s') == "string"
    check paramTypeString('l') == "list"
    check paramTypeString('d') == "dict"
    check paramTypeString('a') == "any"

  test "sameType":
    check sameType('i', vkInt)
    check sameType('f', vkFloat)
    check sameType('s', vkString)
    check sameType('l', vkList)
    check sameType('d', vkDict)

  test "sameType any":
    check sameType('a', vkInt)
    check sameType('a', vkFloat)
    check sameType('a', vkString)
    check sameType('a', vkList)
    check sameType('a', vkDict)

  test "signatureCodeToParams":
    check testSignatureCodeToParams("s", "() string")
    check testSignatureCodeToParams("ss", "(a: string) string")
    check testSignatureCodeToParams("sss", "(a: string, b: string) string")
    check testSignatureCodeToParams("soss", "(a: string, b: optional string) string")

  test "signatureCodeToParams varargs":
    check testSignatureCodeToParams("Is", "(a: varargs(int)) string")
    check testSignatureCodeToParams("sIs", "(a: string, b: varargs(int)) string")
    check testSignatureCodeToParams("soIs", "(a: string, b: optional varargs(int)) string")

  test "Single Param representation":
    check testParamStringSingle("hello", 'i', false, "hello: int")
    check testParamStringSingle("hello", 'i', true, "hello: optional int")

  test "Varargs Param representation":
    check testParamStringVarargs("hello", @['i', 's'], false,
      "hello: varargs(int, string)")
    check testParamStringVarargs("hello", @['i', 's'], true,
      "hello: optional varargs(int, string)")

  test "Return Param representation":
    check testParamStringReturn('i', "int")

  test "getNextName":
    var shortName = ShortName()
    check shortName.next() == "a"
    check shortName.next() == "b"
    check shortName.next() == "c"
    check shortName.next() == "d"

  test "yieldParam":
    check testYieldParam("i", @["int"])
    check testYieldParam("ii", @["a: int", "int"])
    check testYieldParam("ifslda",
      @["a: int", "b: float", "c: string", "d: list", "e: dict", "any"])
    check testYieldParam("oii", @["a: optional int", "int"])

  test "yieldParam varargs":
    check testYieldParam("Is", @["a: varargs(int)", "string"])
    check testYieldParam("oIs", @["a: optional varargs(int)", "string"])
    check testYieldParam("IFs", @["a: varargs(int, float)", "string"])
    check testYieldParam("SAs", @["a: varargs(string, any)", "string"])
    check testYieldParam("oSAs", @["a: optional varargs(string, any)", "string"])
    check testYieldParam("SAIs", @["a: varargs(string, any, int)", "string"])

  test "yieldParam multiple":
    check testYieldParam("iIAi", @["a: int", "b: varargs(int, any)", "int"])
    check testYieldParam("ioIAFi", @["a: int", "b: optional varargs(int, any, float)", "int"])

  test "mapParameters ok":
    var parameters = @[newValue(1)]
    check testMapParametersOk("ii", parameters, """{"a":1}""")


  # test "checkParameters ss":
  #   # let funResultO = checkParameters("(name: string) string", parameters)
  #   var parameters = @[newValue("hello")]
  #   check testCheckParametersOk("ss", parameters)

  # test "checkParameters ii":
  #   var parameters = @[newValue(3)]
  #   check testCheckParametersOk("ii", parameters)

  # test "checkParameters Is":
  #   var parameters = @[newValue(1), newValue(2), newValue(3)]
  #   check testCheckParametersOk("Is", parameters)

  # test "checkParameters IFs":
  #   var parameters = @[newValue(1), newValue(1.1), newValue(2), newValue(2.2)]
  #   check testCheckParametersOk("IFs", parameters)

  # test "checkParameters dlIFs":
  #   var parameters = @[newValue(1), newValue(1.1), newValue(2), newValue(2.2)]
  #   check testCheckParametersOk("ifIFs", parameters)

  # test "checkParameters oii":
  #   var parameters = @[newValue(1)]
  #   check testCheckParametersOk("oii", parameters)

  # test "checkParameters optional missing":
  #   var parameters: seq[Value] = @[]
  #   check testCheckParametersOk("oii", parameters)

  # test "checkParameters optional missing 2":
  #   var parameters = @[newValue(2.2)]
  #   check testCheckParametersOk("aoii", parameters)

  # test "checkParameters Is":
  #   let parameters = @[newValue(1)]
  #   check testCheckParametersOk("Is", parameters)

  # test "checkParameters Is 2":
  #   let parameters = @[newValue(1), newValue(2), newValue(3), newValue(4)]
  #   for ix in countUp(0, 3):
  #     var p = parameters[0 .. ix]
  #     echo "p = " & $p
  #     check testCheckParametersOk("Is", p)

  # test "checkParameters oIs":
  #   let parameters = @[newValue(1), newValue(2), newValue(3), newValue(4)]
  #   for ix in countUp(-1, 3):
  #     var p = parameters[0 .. ix]
  #     # echo "p = " & $p
  #     check testCheckParametersOk("oIs", p)
