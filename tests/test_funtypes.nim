import std/unittest
import funtypes
import vartypes
import messages

suite "funtypes.nim":

  test "newFunResult":
    let funResult = newFunResult(newValue(1))
    check $funResult == "1"

  test "newFunResultWarn":
    let funResultWarn = newFunResultWarn(wSkippingExtraPrepost, 5, "p1")
    check $funResultWarn == "warning: wSkippingExtraPrepost(p1):0: 5"

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
