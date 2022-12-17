import std/unittest
import std/strutils
import signatures
import vartypes
import options
import messages
import sharedtestcode

proc testSignatureCodeToSignature(signatureCode: string, expected: string,
    functionName = "name"): bool =
  var signatureO = signatureCodeToSignature(functionName, signatureCode)
  if not signatureO.isSome:
    echo "Not a valid signature."
    result = false
  else:
    result = gotExpected($signatureO.get(), expected, "signatureCodeToSignature")

proc testMapParametersOk(signatureCode: string, args: seq[Value],
    eMapJson: string, functionName = "name"): bool =
  var signatureO = signatureCodeToSignature(functionName, signatureCode)
  if not signatureO.isSome:
    echo "Invalid signature: " & signatureCode
    return false
  let funResult = mapParameters(signatureO.get(), args)
  if not expectedItem("mapParameters", funResult.kind, frValue):
    echo "warning: " & $funResult
    return false
  if not expectedItem("mapParameters",
      valueToString(funResult.value), eMapJson):
    echo "signatureCode: " & signatureCode
    return false
  result = true

proc testMapParametersW(signatureCode: string, args: seq[Value],
    eParameter: int, warning: MessageId, p1: string = "",
    functionName = "name"): bool =
  var signatureO = signatureCodeToSignature(functionName, signatureCode)
  if not signatureO.isSome:
    echo "Invalid signature: " & signatureCode
    return false
  let funResult = mapParameters(signatureO.get(), args)
  if not expectedItem("mapParameters", funResult.kind, frWarning):
    echo "no warning: " & $funResult
    return false
  let eFunResult = newFunResultWarn(warning, eParameter, p1)
  let test = "$1 $2" % [signatureCode, $args]
  result = gotExpected($funResult, $eFunResult, test)

  if not result and eFunResult.kind == frWarning and funResult.kind == frWarning:
    echo ""
    echo "    got  message: $1" % getWarning(
      funResult.warningData.messageId, funResult.warningData.p1)
    echo "expected message: $1" % getWarning(
      eFunResult.warningData.messageId, eFunResult.warningData.p1)


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

  test "signatureCodeToSignature":
    check testSignatureCodeToSignature("s", "name() string")
    check testSignatureCodeToSignature("ss", "name(a: string) string")
    check testSignatureCodeToSignature("sss", "name(a: string, b: string) string")
    check testSignatureCodeToSignature("soss", "name(a: string, b: optional string) string")
    check testSignatureCodeToSignature("lsosl",
      "name(a: list, b: string, c: optional string) list")

  test "signatureCodeToSignature all":
    let e = "name(a: int, b: string, c: float, d: optional list) int"
    check testSignatureCodeToSignature("isfoli", e)

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

  test "mapParameters ll":
    var list = newValue([1, 2, 3, 4, 5])
    var parameters = @[list]
    check testMapParametersOk("ll", parameters, """{"a":[1,2,3,4,5]}""")

  test "ssoaa":
    var parameters: seq[Value] = @[newValue("tea"), newValue("beer")]
    check testMapParametersOk("ssoaa", parameters, """{"a":"tea","b":"beer"}""")

  test "ssoaa not enough":
    var parameters: seq[Value] = @[newValue("tea")]
    check testMapParametersW("ssoaa", parameters, 1, wNotEnoughArgsOpt, "2")

  test "ssoaa not enough2":
    var parameters: seq[Value] = @[]
    check testMapParametersW("ssoaa", parameters, 0, wNotEnoughArgsOpt, "2")

  test "mapParameters not enough args":
    var parameters: seq[Value] = @[]
    check testMapParametersW("ii", parameters, 0, wNotEnoughArgs, "1")

    parameters = @[newValue(1)]
    check testMapParametersW("iii", parameters, 1, wNotEnoughArgs, "2")

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

  test "mapParameters string compare senitive":
    var parameters = @[newValue("tea"), newValue("Tea"), newValue(true)]
    check testMapParametersOk("ssobi", parameters, """{"a":"tea","b":"Tea","c":true}""")
    parameters = @[newValue("tea"), newValue("Tea"), newValue(1)]
    check testMapParametersW("ssobi", parameters, 2, wWrongType, "bool")

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

  test "mapParameters saa":
    var parameters = @[newValue("3"), newValue("nan")]
    check testMapParametersOk("saa", parameters, """{"a":"3","b":"nan"}""")

  test "mapParameters lioaa":
    var list = newValue([1, 2, 3, 4, 5])
    let p = newValue(1)
    var parameters = @[list, p, p, p]
    check testMapParametersW("lioaa", parameters, 3, wTooManyArgsOpt, "3")
