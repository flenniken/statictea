import std/unittest
import std/tables
import tostring
import vartypes
import messages

suite "tostring.nim":

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

  test "ValueOrWarning string":
    check $newValueOrWarning(newValue(2)) == "2"
    check $newValueOrWarning(wInvalidJsonRoot) == "wInvalidJsonRoot(-):0"
