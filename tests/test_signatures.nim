import std/unittest
import signatures
import env
import vartypes
import funtypes
import options
import messages

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
  if not expectedItem("mapParameters",
      valueToString(funResult.value), eMapJson):
    echo "signatureCode: " & signatureCode
    return false
  result = true

proc testMapParametersW(signatureCode: string, args: seq[Value],
    eParameter: int, warning: MessageId, p1: string = ""): bool =

  var paramsO = signatureCodeToParams(signatureCode)
  if not paramsO.isSome:
    echo "Invalid signature: " & signatureCode
    return false
  let funResult = mapParameters(paramsO.get(), args)
  if not expectedItem("mapParameters", funResult.kind, frWarning):
    echo "no warning: " & $funResult
    return false
  let eFunResultWarn = newFunResultWarn(warning, eParameter, p1)
  if not expectedItem("mapParameters", funResult, eFunResultWarn):
    echo "signatureCode: " & signatureCode
    return false
  result = true

proc testParamStringSingle(name: string, paramCode: ParamCode, optional: bool,
                     eString: string): bool =
  ## Test single arg cases.
  var paramKind: ParamKind
  if optional:
    paramKind = pkOptional
  else:
    paramKind = pkNormal
  let param = newParam("hello", paramKind, paramCode)
  result = expectedItem("param", $param, eString)

proc testParamStringReturn(paramCode: ParamCode, eString: string): bool =
  ## Test return parameter case.
  let param = newParam("result", pkReturn, paramCode)
  result = expectedItem("param", $param, eString)


suite "signatures.nim":

  test "test me":
    check 1 == 1

  test "paramCode string":
    check paramCodeString('i') == "int"
    check paramCodeString('f') == "float"
    check paramCodeString('s') == "string"
    check paramCodeString('l') == "list"
    check paramCodeString('d') == "dict"
    check paramCodeString('a') == "any"

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
    check testSignatureCodeToParams("lsosl",
      "(a: list, b: string, c: optional string) list")

  test "signatureCodeToParams all":
    let e = "(a: int, b: string, c: float, d: optional list) int"
    check testSignatureCodeToParams("isfoli", e)

  test "Single Param representation":
    check testParamStringSingle("hello", 'i', false, "hello: int")
    check testParamStringSingle("hello", 'i', true, "hello: optional int")

  test "Return Param representation":
    check testParamStringReturn('i', "int")

  test "shortName":
    check shortName(0) == "a"
    check shortName(1) == "b"
    check shortName(2) == "c"
    check shortName(25) == "z"
    check shortName(0+26) == "a1"
    check shortName(1+26) == "b1"
    check shortName(25+26) == "z1"
    check shortName(0+26+26) == "a2"
    check shortName(1+26+26) == "b2"
    check shortName(25+26+26) == "z2"

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

  test "mapParameters not enough args":
    var parameters: seq[Value] = @[]
    check testMapParametersW("ii", parameters, 0, wNotEnoughArgs, "1")

    parameters = @[newValue(1)]
    check testMapParametersW("iii", parameters, 0, wNotEnoughArgs, "2")

  test "mapParameters too many args":
    var parameters = @[newValue(1), newValue(2)]
    check testMapParametersW("ii", parameters, 1, wTooManyArgs, "1")

    parameters = @[newValue(1), newValue(2), newValue(3)]
    check testMapParametersW("iii", parameters, 2, wTooManyArgs, "2")

  test "mapParameters wrong kind":
    var parameters = @[newValue(1)]
    check testMapParametersW("fi", parameters, 0, wWrongType, "float")

    parameters = @[newValue(1), newValue(2)]
    check testMapParametersW("ifi", parameters, 1, wWrongType, "float")

    parameters = @[newValue(1)]
    check testMapParametersW("ofi", parameters, 0, wWrongType, "float")

    parameters = @[newValue(1), newValue(2)]
    check testMapParametersW("oifi", parameters, 1, wWrongType, "float")

  test "mapParameters sort int, float, string":
    var parameters = @[newEmptyListValue(), newValue("ascending")]
    check testMapParametersOk("lsosl", parameters, """{"a":[],"b":"ascending"}""")

    parameters = @[
      newEmptyListValue(), newValue("ascending"), newValue("insensitive")]
    check testMapParametersOk("lsosl", parameters,
      """{"a":[],"b":"ascending","c":"insensitive"}""")

  test "mapParameters sort lists":
    var parameters = @[
      newEmptyListValue(), newValue("ascending"), newValue("insensitive"), newValue(0)
    ]
    check testMapParametersOk("lssil", parameters,
      """{"a":[],"b":"ascending","c":"insensitive","d":0}""")

  test "mapParameters sort dictionaries":
    var parameters = @[
      newEmptyListValue(), newValue("ascending"), newValue("insensitive"), newValue("key")
    ]
    check testMapParametersOk("lsssl", parameters,
      """{"a":[],"b":"ascending","c":"insensitive","d":"key"}""")

  test "mapParameters oSs":
    var parameters: seq[Value] = @[]
    check testMapParametersOk("ols", parameters, """{}""")

  test "mapParameters loss":
    var parameters: seq[Value] = @[newEmptyListValue()]
    check testMapParametersOk("loss", parameters, """{"a":[]}""")
