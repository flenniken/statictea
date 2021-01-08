import unittest
import vartypes
import tables

suite "vartypes":

  test "new dict":
    var varsDict: VarsDict
    check varsDict.len == 0
    let value = newValue(varsDict)
    check value.dictv.len == 0

  test "new with 1":
    var varsDict: VarsDict
    varsDict["a"] = newValue(1)
    check varsDict.len == 1
    let value = newValue(varsDict)
    check value.dictv.len == 1

    value.dictv["a"] = newValue(2)
    check $value.dictv["a"] == "2"
    check $varsDict["a"] == "1"
