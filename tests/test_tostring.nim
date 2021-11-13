import std/unittest
import std/tables
import tostring
import vartypes
import messages
import warnings

suite "tostring.nim":

  test "dictToString":
    var emptyVarsDict = newVarsDict()
    var emptyDictValue = newValue(emptyVarsDict)
    check $emptyDictValue == "{}"

  test "listToString":
    var listValue = newEmptyListValue()
    listValue.listv.add(newValue("a"))
    check listToString(listValue) == """["a"]"""

  test "valueToString":
    let value = newValue(1)
    check valueToString(value) == "1"

  test "shortValueToString":
    var varsDict = newVarsDict()
    let emptyDict = newValue(varsDict)
    check shortValueToString(emptyDict) == "{}"
    varsDict["a"] = newValue(5)
    let value = newValue(varsDict)
    check shortValueToString(value) == "{...}"
    check valueToString(value) == """{"a":5}"""

  test "ValueOrWarning string":
    check $newValueOrWarning(newValue(2)) == "2"
    check $newValueOrWarning(wInvalidJsonRoot) == "wInvalidJsonRoot(-, -)"
