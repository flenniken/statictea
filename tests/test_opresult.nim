import std/unittest
import opresult

type
  MyObj = object
    name: string
    size: int

suite "opresult.nim":

  test "opValue":
    let opResult = opValue[int](5)
    check opResult.isValue == true
    check opResult.isMessage == false
    check opResult.value == 5

  test "opMessage":
    let message = "unable to get the value"
    let opResult = opMessage[int](message)
    check opResult.isValue == false
    check opResult.isMessage == true
    check opResult.message == message

  test "opValue obj":
    let myObj = MyObj(name: "test", size: 12)
    let opResult = opValue[MyObj](myObj)
    check opResult.isValue == true
    check opResult.isMessage == false
    check opResult.value == myObj

  test "opMessage obj":
    let message = "no object"
    let opResult = opMessage[MyObj](message)
    check opResult.isValue == false
    check opResult.isMessage == true
    check opResult.message == message
