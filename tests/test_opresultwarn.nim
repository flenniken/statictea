import std/unittest
import messages
import warnings
import opresultwarn

type
  MyObjTest3 = object
    name: string
    size: int

suite "opresultwarn.nim":

  test "OpResultWarn default":
    var opResultWarn: OpResultWarn[string]
    check opResultWarn.isValue == false
    check opResultWarn.isMessage == true
    check opResultWarn.message == newWarningData(wSuccess)
    check $opResultWarn == "Message: wSuccess(-, -)"

  test "OpResultWarn new value":
    var opResultWarn = opValueW[string]("hello")
    check opResultWarn.isValue == true
    check opResultWarn.value == "hello"
    check $opResultWarn == "Value: hello"

  test "OpResultWarn new message id":
    var opResultWarn = opMessageW[string](newWarningData(wSuccess))
    check opResultWarn.isMessage == true
    check $opResultWarn == "Message: wSuccess(-, -)"

  test "OpResultWarn new value int":
    var opResultWarn = opValueW[int](3)
    check opResultWarn.isValue == true
    check opResultWarn.value == 3
    check $opResultWarn == "Value: 3"

  test "OpResultWarn new message":
    var opResultWarn = opMessageW[int](newWarningData(wUnknownArg))
    check opResultWarn.isMessage == true
    check $opResultWarn == "Message: wUnknownArg(-, -)"

  test "opValueW my obj":
    let myObj = MyObjTest3(name: "test", size: 12)
    let opResultWarn = opValueW[MyObjTest3](myObj)
    check opResultWarn.isValue == true
    check opResultWarn.isMessage == false
    check opResultWarn.value == myObj

