import std/unittest
import signatures
import env
import vartypes
import funtypes
import options
import tostring
import warnings

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
    echo "warning: " & $funResult
    return false
  if not expectedItem("mapParameters", valueToString(funResult.value), eMapJson):
    echo "signatureCode: " & signatureCode
    return false
  result = true

proc testMapParametersW(signatureCode: string, args: seq[Value],
    eParameter: int, warning: Warning, p1: string = "", p2: string = ""): bool =

  var paramsO = signatureCodeToParams(signatureCode)
  if not paramsO.isSome:
    echo "Invalid signature: " & signatureCode
    return false
  let funResult = mapParameters(paramsO.get(), args)
  if not expectedItem("mapParameters", funResult.kind, frWarning):
    echo "no warning: " & $funResult
    return false
  let eFunResultWarn = newFunResultWarn(warning, eParameter, p1, p2)
  if not expectedItem("mapParameters", funResult, eFunResultWarn):
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

  test "signatureCodeToParams multiple varargs":
    check testSignatureCodeToParams("IIi", "(a: varargs(int, int)) int")
    check testSignatureCodeToParams("ISi", "(a: varargs(int, string)) int")
    check testSignatureCodeToParams("IFSi", "(a: varargs(int, float, string)) int")

  test "signatureCodeToParams optional multiple varargs":
    check testSignatureCodeToParams("oIIi", "(a: optional varargs(int, int)) int")
    check testSignatureCodeToParams("oISi", "(a: optional varargs(int, string)) int")
    check testSignatureCodeToParams("oIFSi", "(a: optional varargs(int, float, string)) int")

  test "signatureCodeToParams all":
    let e = "(a: int, b: string, c: float, d: optional varargs(int, int)) int"
    check testSignatureCodeToParams("isfoIIi", e)

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

  test "mapParameters i":
    var parameters: seq[Value] = @[]
    check testMapParametersOk("i", parameters, "{}")

  test "mapParameters ii":
    var parameters = @[newValue(1)]
    check testMapParametersOk("ii", parameters, """{"a":1}""")

  test "mapParameters iii":
    var parameters = @[newValue(1), newValue(2)]
    check testMapParametersOk("iii", parameters, """{"a":1,"b":2}""")

  test "mapParameters ifsldi":
    let listValue = newValue([1, 2, 3])
    let dictValue = newValue([("a", 1), ("b", 2), ("c", 3)])
    var parameters = @[newValue(1), newValue(2.2), newValue("tea"),
                       listValue, dictValue]
    let expected = """{"a":1,"b":2.2,"c":"tea","d":[1,2,3],"e":{"a":1,"b":2,"c":3}}"""
    check testMapParametersOk("ifsldi", parameters, expected)

  test "mapParameters oii":
    var parameters: seq[Value] = @[newValue(1)]
    check testMapParametersOk("oii", parameters, """{"a":1}""")

  test "mapParameters ioii":
    var parameters: seq[Value] = @[newValue(1),newValue(2)]
    check testMapParametersOk("ioii", parameters, """{"a":1,"b":2}""")

  test "mapParameters oii":
    var parameters: seq[Value] = @[]
    check testMapParametersOk("oii", parameters, """{}""")

  test "mapParameters ioii":
    var parameters: seq[Value] = @[newValue(1)]
    check testMapParametersOk("ioii", parameters, """{"a":1}""")

  test "mapParameters Ii":
    var parameters: seq[Value] = @[newValue(1)]
    check testMapParametersOk("Ii", parameters, """{"a":[1]}""")

  test "mapParameters IIi":
    var parameters: seq[Value] = @[newValue(1),newValue(2)]
    check testMapParametersOk("IIi", parameters, """{"a":[1,2]}""")

  test "mapParameters IIFi":
    var parameters: seq[Value] = @[newValue(1),newValue(2),newValue(3.3)]
    check testMapParametersOk("IIFi", parameters, """{"a":[1,2,3.3]}""")

  test "mapParameters iIi":
    var parameters: seq[Value] = @[newValue(1),newValue(2)]
    check testMapParametersOk("iIi", parameters, """{"a":1,"b":[2]}""")

  test "mapParameters iIi":
    var parameters: seq[Value] = @[newValue(1),newValue(2),newValue(3)]
    check testMapParametersOk("iIi", parameters, """{"a":1,"b":[2,3]}""")

    parameters = @[newValue(1),newValue(2),newValue(3),newValue(4)]
    check testMapParametersOk("iIi", parameters, """{"a":1,"b":[2,3,4]}""")

  test "mapParameters SIi":
    var parameters = @[newValue("tea"),newValue(1),newValue("water"),newValue(2)]
    check testMapParametersOk("SIi", parameters, """{"a":["tea",1,"water",2]}""")

  test "mapParameters iSIi":
    var parameters = @[newValue(1), newValue("tea"), newValue(1),
                       newValue("water"), newValue(2)]
    check testMapParametersOk("iSIi", parameters, """{"a":1,"b":["tea",1,"water",2]}""")

  test "mapParameters oIi":
    var parameters: seq[Value] = @[]
    check testMapParametersOk("oIi", parameters, """{}""")

  test "mapParameters oIi":
    var parameters: seq[Value] = @[newValue(1)]
    check testMapParametersOk("oIi", parameters, """{"a":[1]}""")

    parameters = @[newValue(1), newValue(2)]
    check testMapParametersOk("oIi", parameters, """{"a":[1,2]}""")

  test "mapParameters oIFi":
    var parameters: seq[Value] = @[]
    check testMapParametersOk("oIFi", parameters, """{}""")

    parameters = @[newValue(1), newValue(2.2)]
    check testMapParametersOk("oIFi", parameters, """{"a":[1,2.2]}""")

    parameters = @[newValue(1), newValue(2.2), newValue(3), newValue(4.4)]
    check testMapParametersOk("oIFi", parameters, """{"a":[1,2.2,3,4.4]}""")

  test "mapParameters ioIFi":
    var parameters = @[newValue(1)]
    check testMapParametersOk("ioIFi", parameters, """{"a":1}""")

    parameters = @[newValue(1),newValue(1),newValue(2.2)]
    check testMapParametersOk("ioIFi", parameters, """{"a":1,"b":[1,2.2]}""")

  test "mapParameters not enough args":
    var parameters: seq[Value] = @[]
    check testMapParametersW("ii", parameters, 0, kNotEnoughArgs, "1", "0")
    check testMapParametersW("Ii", parameters, 0, kNotEnoughArgs, "1", "0")

    parameters = @[newValue(1)]
    check testMapParametersW("iii", parameters, 0, kNotEnoughArgs, "2", "1")
    check testMapParametersW("iIi", parameters, 0, kNotEnoughArgs, "2", "1")

    parameters = @[newValue(1)]
    check testMapParametersW("IFi", parameters, 0, kNotEnoughArgs, "2", "1")

    parameters = @[newValue(1), newValue(1)]
    check testMapParametersW("iIFi", parameters, 0, kNotEnoughArgs, "3", "2")

    parameters = @[newValue(1), newValue(1)]
    check testMapParametersW("iiIFSi", parameters, 0, kNotEnoughArgs, "5", "2")

    parameters = @[newValue(1), newValue(1), newValue(1)]
    check testMapParametersW("iiIFSi", parameters, 0, kNotEnoughArgs, "5", "3")

    parameters = @[newValue(1), newValue(1), newValue(1), newValue(1.1)]
    check testMapParametersW("iiIFSi", parameters, 0, kNotEnoughArgs, "5", "4")

  test "mapParameters too many args":
    var parameters = @[newValue(1), newValue(2)]
    check testMapParametersW("ii", parameters, 0, kTooManyArgs, "1", "2")

    parameters = @[newValue(1), newValue(2), newValue(3)]
    check testMapParametersW("iii", parameters, 0, kTooManyArgs, "2", "3")

  test "mapParameters wrong kind":
    var parameters = @[newValue(1)]
    check testMapParametersW("fi", parameters, 0, kWrongType, "float", "int")
    check testMapParametersW("Fi", parameters, 0, kWrongType, "float", "int")

    parameters = @[newValue(1), newValue(2)]
    check testMapParametersW("ifi", parameters, 1, kWrongType, "float", "int")
    check testMapParametersW("IFi", parameters, 1, kWrongType, "float", "int")

    parameters = @[newValue(1)]
    check testMapParametersW("ofi", parameters, 0, kWrongType, "float", "int")
    check testMapParametersW("oFi", parameters, 0, kWrongType, "float", "int")

    parameters = @[newValue(1), newValue(2)]
    check testMapParametersW("oifi", parameters, 1, kWrongType, "float", "int")
    check testMapParametersW("oIFi", parameters, 1, kWrongType, "float", "int")
