import std/unittest
# import std/tables
import tostring
import vartypes
import messages

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

  test "ValueOrWarning string":
    check $newValueOrWarning(newValue(2)) == "2"
    check $newValueOrWarning(wInvalidJsonRoot) == "wInvalidJsonRoot(-)"
