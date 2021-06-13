import std/unittest
import std/tables
import vartypes

suite "vartypes":

  test "startColumn":
    check startColumn(0) == "^"
    check startColumn(1) == " ^"
    check startColumn(2) == "  ^"
    check startColumn(3) == "   ^"

  test "newValue string":
    let testString = "string"
    let jsonString = """"string""""
    let value = newValue(testString)
    let sameValue = newValue(testString)
    check $value == jsonString
    check shortValueToString(value) == testString
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
    check shortValueToString(value) == jsonString
    check value == sameValue
    check value == value64
    check value != newValue(3)
    check value.kind == vkInt
    check $value.kind == "int"
    check newValue(2).intv == 2
    check newValue(0).intv == 0
    check newValue(-1).intv == -1
    
  test "newValue float":
    let testFloat = 0.123
    let jsonString = "0.123"
    let value = newValue(testFloat)
    let sameValue = newValue(testFloat)
    check $value == jsonString
    check shortValueToString(value) == jsonString
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

    let jsonString = """{"string":"a","int":1,"float":5.5}"""
    let value = newValue(varsDict)
    let sameValue = newValue(varsDict)
    check $value == jsonString
    check shortValueToString(value) == "{...}"
    check value == sameValue
    check value != newValue(varsDict2)
    check value.kind == vkDict
    check $value.kind == "dict"

    var emptyVarsDict = newVarsDict()
    var emptyDictValue = newValue(emptyVarsDict)
    check $emptyDictValue == "{}"
    check shortValueToString(emptyDictValue) == "{}"

  test "newListValue":
    check $newListValue("a", "b", "c") == """["a","b","c"]"""
    check $newListValue(1, 2, 3) == "[1,2,3]"
    let listValue = newListValue(newValue(1), newValue("a"))
    check $listValue == """[1,"a"]"""

  # test "newListValue emtpy":
  #   check $newListValue() = "[]"

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

    check $newListValue(1, 2, 3) == "[1,2,3]"
    check $newListValue("a", "b", "c") == """["a","b","c"]"""
    check $newListValue(newValue(1), newValue("b")) == """[1,"b"]"""

  test "newValue dict":
    check $newValue([("a", 1), ("b", 2), ("c", 3)]) == """{"a":1,"b":2,"c":3}"""
    check $newValue([("a", 1.1), ("b", 2.2), ("c", 3.3)]) == """{"a":1.1,"b":2.2,"c":3.3}"""
    check $newValue([("a", newValue(1)), ("b", newValue("c"))]) == """{"a":1,"b":"c"}"""

    check $newDictValue(("a", 1), ("b", 2), ("c", 3)) == """{"a":1,"b":2,"c":3}"""
    check $newDictValue(("a", 1.1), ("b", 2.2), ("c", 3.3)) == """{"a":1.1,"b":2.2,"c":3.3}"""
    check $newDictValue(("a", newValue(1)), ("b", newValue("c"))) == """{"a":1,"b":"c"}"""
