import std/unittest
import funtypes
import vartypes

# todo: add some tests for funtypes

suite "funtypes.nim":

  test "newFunResult":
    let funResult = newFunResult(newValue(1))
    check $funResult == "1"
