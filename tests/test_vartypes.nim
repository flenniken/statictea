import std/strutils
import std/tables
import std/unittest
import opresultwarn
import readjson
import vartypes
import messages
import sharedtestcode

proc testDotNameRep(json: string, eDotNameRep: string, top=false): bool =
  var valueOr = readJsonString(json)
  if valueOr.isMessage:
    echo valueOr.message
    return false
  let dotNameRep = dotNameRep(valueOr.value.dictv, top=top)
  if dotNameRep != eDotNameRep:
    echo "     got:\n$1" % dotNameRep
    echo ""
    echo "expected:\n$1" % eDotNameRep
    echo ""
    echo "     for:\n$1" % json
    return false
  return true

suite "vartypes":

  test "newValue string":
    let testString = "string"
    let jsonString = """"string""""
    let value = newValue(testString)
    let sameValue = newValue(testString)
    check $value == jsonString
    check value == sameValue
    check value != newValue("different string")
    check value.kind == vkString
    check $value.kind == testString
    check newValue("").stringv == ""
    check newValue("a").stringv == "a"
    # strings are utf8.
    let str = "añyóng"
    check str.len == 8
    check newValue(str).stringv == str

  test "newValue int":
    let testInt = 5
    let jsonString = "5"
    let value = newValue(testInt)
    let sameValue = newValue(testInt)
    let value64 = newValue((int64)5)
    check $value == jsonString
    check value == sameValue
    check value == value64
    check value != newValue(3)
    check value.kind == vkInt
    check $value.kind == "int"
    check newValue(2).intv == 2
    check newValue(0).intv == 0
    check newValue(-1).intv == -1

  test "newValue bool":
    let testBool = true
    let jsonString = "true"
    let value = newValue(testBool)
    let sameValue = newValue(testBool)
    check $value == jsonString
    check value == sameValue
    check value != newValue(false)
    check value != newValue(1)
    check value.kind == vkBool
    check $value.kind == "bool"
    check newValue(true).boolv == true
    check newValue(false).boolv == false

  test "newValue float":
    let testFloat = 0.123
    let jsonString = "0.123"
    let value = newValue(testFloat)
    let sameValue = newValue(testFloat)
    check $value == jsonString
    check value == sameValue
    check value != newValue(3.222)
    check value.kind == vkFloat
    check $value.kind == "float"
    check newValue(1.2).floatv == 1.2
    check newValue(0.0).floatv == 0.0
    check newValue(-1.6).floatv == -1.6

  test "newValue dict":
    var varsDict = newVarsDict()
    varsDict["string"] = newValue("a")
    varsDict["int"] = newValue(1)
    varsDict["float"] = newValue(5.5)

    var varsDict2 = newVarsDict()
    varsDict2["string"] = newValue("a")


  test "newEmptyListValue":
    var listValue = newEmptyListValue()
    check listValue.listv.len == 0
    listValue.listv.add(newValue("a"))
    listValue.listv.add(newValue(1))
    listValue.listv.add(newValue(5.5))
    check $listValue == """["a",1,5.5]"""

  test "VarsDict ref":
    ## Test VarsDict is a reference type.
    var varsDict = newVarsDict()
    check varsDict.len == 0
    varsDict["a"] = newValue(5)
    check varsDict.len == 1
    check "a" in varsDict

    let varsDict2 = varsDict
    check varsDict2.len == 1
    check "a" in varsDict2
    varsDict["b"] = newValue(8)

    check "b" in varsDict
    check "b" in varsDict2

  test "newValue from dict":
    ## Create a new value dict.
    var varsDict = newVarsDict()
    let value = newValue(varsDict)
    check value.dictv.len == 0
    check varsDict == value.dictv
    varsDict["a"] = newValue(5)
    check "a" in varsDict
    check "a" in value.dictv

  test "varsDict to string":
    var varsDict = newVarsDict()
    check $varsDict == "{}"
    varsDict["a"] = newValue(5)
    check $varsDict == """{"a":5}"""
    varsDict["tea"] = newValue("Eary Grey")
    check $varsDict == """{"a":5,"tea":"Eary Grey"}"""
    var varsDict2 = newVarsDict()
    varsDict["d"] = newValue(varsDict2)
    varsDict2["list"] = newValue(@[newValue(1), newValue("two"), newValue(3.0)])
    let str = """{"a":5,"tea":"Eary Grey","d":{"list":[1,"two",3.0]}}"""
    check valueToString(newValue(varsDict)) == str

  test "compare dict objects":
    var varsDict = newVarsDict()
    var varsDict2 = newVarsDict()
    check varsDict == varsDict2
    varsDict["a"] = newValue(5)
    check varsDict != varsDict2
    varsDict2["a"] = newValue(5)
    check varsDict == varsDict2

  test "newValue list":
    check $newValue([newValue(1), newValue("b")]) == """[1,"b"]"""
    check $newValue([1, 2, 3]) == "[1,2,3]"
    check $newValue(["a", "b", "c"]) == """["a","b","c"]"""

  test "newValue dict":
    check $newValue([("a", 1), ("b", 2), ("c", 3)]) == """{"a":1,"b":2,"c":3}"""
    check $newValue([("a", 1.1), ("b", 2.2), ("c", 3.3)]) == """{"a":1.1,"b":2.2,"c":3.3}"""
    check $newValue([("a", newValue(1)), ("b", newValue("c"))]) == """{"a":1,"b":"c"}"""

  test "dictToString":
    var varsDict = newVarsDict()
    var dictValue = newValue(varsDict)
    check $dictValue == "{}"
    varsDict["k"] = newValue("v")
    check $dictValue == """{"k":"v"}"""
    varsDict["a"] = newValue(2)
    check $dictValue == """{"k":"v","a":2}"""

  test "listToString":
    var listValue = newEmptyListValue()
    check listToString(listValue) == """[]"""
    listValue.listv.add(newValue("a"))
    check listToString(listValue) == """["a"]"""
    listValue.listv.add(newValue("b"))
    check listToString(listValue) == """["a","b"]"""
    listValue.listv.add(newValue(2))
    check listToString(listValue) == """["a","b",2]"""

  test "valueToString":
    let value = newValue(1)
    check valueToString(value) == "1"

  test "jsonStringRepr":
    check jsonStringRepr("") == """"""""
    check jsonStringRepr("a") == """"a""""
    check jsonStringRepr("abc") == """"abc""""
    check jsonStringRepr("\n") == """"\n""""
    check jsonStringRepr("\t") == """"\t""""
    check jsonStringRepr("\"") == """"\"""""
    check jsonStringRepr("\r") == """"\r""""
    check jsonStringRepr("\\") == """"\\""""
    check jsonStringRepr("\b") == """"\b""""
    check jsonStringRepr("\f") == """"\f""""
    check jsonStringRepr("/") == """"\/""""
    let str =     "\t\n\r\"\\ \b\f/ 9 😃"
    let eStr = """"\t\n\r\"\\ \b\f\/ 9 😃""""
    let got = jsonStringRepr(str)
    if got != eStr:
      echo "expected: " & eStr
      echo "     got: " & got
    check got == eStr

  test "dotNameRep empty":
    check testDotNameRep("{}", "")
    check testDotNameRep("""{"a":5}""", "a = 5")

  test "dotNameRep one var empty":
    check testDotNameRep("""{"a":{}}""", "a = {}")

  test "dotNameRep":
    let json = """
{
  "a":{
    "b":{
      "c":{
      }
    }
  }
}"""
    check testDotNameRep(json, """a.b.c = {}""")

  test "dotNameRep hide l":
    let json = """
{
  "l":{
    "b":{
      "c":{
      }
    }
  },
  "a": 5
}"""

    let expected = """
b.c = {}
a = 5"""
    check testDotNameRep(json, expected, top=true)

  test "dotNameRep empty l":
    let json = """
{
  "l":{},
  "a": 5
}"""

    let expected = """
l = {}
a = 5"""
    check testDotNameRep(json, expected)

  test "dotNameRep string":
    check testDotNameRep("""{"a":"string"}""", """a = "string"""")

  test "dotNameRep list":
    check testDotNameRep("""{"a":[]}""", "a = []")
    check testDotNameRep("""{"a":[1]}""", "a = [1]")
    check testDotNameRep("""{"a":[1,2]}""", "a = [1,2]")
    check testDotNameRep("""{"a":[1,2,"str"]}""", """a = [1,2,"str"]""")
    check testDotNameRep("""{"a":[1,{"b":5}]}""", """a = [1,{"b":5}]""")
    check testDotNameRep("""{"a":[1,{"b":5},{}]}""", """a = [1,{"b":5},{}]""")

  test "dotNameRep multiple 2":
    let json = """
{
  "a": 5,
  "b": 6,
}
"""
    let expected = """
a = 5
b = 6"""
    check testDotNameRep(json, expected)

  test "dotNameRep nested":
    let json = """{ "a": {"b": 5} }"""
    let expected = """a.b = 5"""
    check testDotNameRep(json, expected)

  test "dotNameRep nested 2":
    let json = """{ "a": {"b": 5}, "c": {"d": 7} }"""
    let expected = """a.b = 5
c.d = 7"""
    check testDotNameRep(json, expected)

  test "dotNameRep nested list":
    let json = """{ "a": {"b": []}, "c": {"d": [7]} }"""
    let expected = """a.b = []
c.d = [7]"""
    check testDotNameRep(json, expected)

  test "newFunResult":
    let funResult = newFunResult(newValue(1))
    check $funResult == "1"

  test "newFunResultWarn":
    let funResultWarn = newFunResultWarn(wSkippingExtraPrepost, 5, "p1")
    check $funResultWarn == """warning: wSkippingExtraPrepost p1="p1" pos=0: parameter 5"""

  test "newFunResult tea":
    let funResult = newFunResult(newValue("tea"))
    check $funResult == """"tea""""

  test "newFunResult not equal":
    let funResult = newFunResult(newValue("tea"))
    let funResultWarn = newFunResultWarn(wSkippingExtraPrepost, 5, "p1")
    check funResult != funResultWarn

  test "newFunResult equal":
    let funResult = newFunResult(newValue("tea"))
    let funResult2 = newFunResult(newValue("tea"))
    check funResult == funResult2

  test "new function":
    func abc(variables: Variables, parameters: seq[Value]): FunResult =
      result = newFunResult(newValue("hi"))
    let function = newFunc("abc", abc, "iis")
    check gotExpected($function, "\"abc(ii)s\"")

    let value = newValue(function)
    check function == value.funcv
