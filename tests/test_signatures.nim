import std/unittest
import signatures
import env
import vartypes
import warnings
import funtypes
import options

suite "signatures.nim":

  test "test me":
    check 1 == 1

  test "checkParameters happy path":
    var parameters = @[newValue("hello")]
    let funResultO = checkParameters("(name: string) string", parameters)
    let eFunResultO = none(FunResult)
    check expectedItem("checkParameters", funResultO, eFunResultO)

  test "checkParameters":
    var parameters = @[newValue(3)]
    let funResultO = checkParameters("(name: string) string", parameters)
    let eFunResultO = some(newFunResultWarn(wExpectedString, 0))
    check expectedItem("checkParameters", funResultO, eFunResultO)

