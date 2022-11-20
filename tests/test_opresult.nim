import std/unittest
import messages
import warnings
import opresult

type
  MyObjTest2 = object
    name: string
    size: int

  MyObjTest3 = object
    name: string
    size: int

suite "opresult.nim":

  test "OpResultWarn default":
    var opResultWarn: OpResultWarn[string]
    check opResultWarn.isValue == false
    check opResultWarn.isMessage == true
    check opResultWarn.message == newWarningData(wSuccess)
    check $opResultWarn == """Message: wSuccess p1="" pos=0"""

  test "OpResultWarn new value":
    var opResultWarn = opValueW[string]("hello")
    check opResultWarn.isValue == true
    check opResultWarn.value == "hello"
    check $opResultWarn == "Value: hello"

  test "OpResultWarn new message id":
    var opResultWarn = opMessageW[string](newWarningData(wSuccess))
    check opResultWarn.isMessage == true
    check $opResultWarn == """Message: wSuccess p1="" pos=0"""

  test "OpResultWarn new value int":
    var opResultWarn = opValueW[int](3)
    check opResultWarn.isValue == true
    check opResultWarn.value == 3
    check $opResultWarn == "Value: 3"

  test "OpResultWarn new message":
    var opResultWarn = opMessageW[int](newWarningData(wUnknownArg))
    check opResultWarn.isMessage == true
    check $opResultWarn == """Message: wUnknownArg p1="" pos=0"""

  test "opValueW my obj":
    let myObj = MyObjTest3(name: "test", size: 12)
    let opResultWarn = opValueW[MyObjTest3](myObj)
    check opResultWarn.isValue == true
    check opResultWarn.isMessage == false
    check opResultWarn.value == myObj



  test "one":
    var opResultId: OpResult[int, MessageId]
    check opResultId.isValue == false
    check opResultId.isMessage == true
    check opResultId.message == wSuccess
    check $opResultId == "Message: wSuccess"

  test "OpResultId default":
    var opResultId: OpResultId[string]
    check opResultId.isValue == false
    check opResultId.isMessage == true
    check opResultId.message == wSuccess
    check $opResultId == "Message: wSuccess"

  test "OpResultId new value":
    var opResultId = opValue[string]("hello")
    check opResultId.isValue == true
    check opResultId.value == "hello"
    check $opResultId == "Value: hello"

  test "OpResultId new message id":
    var opResultId = opMessage[string](wSuccess)
    check opResultId.isMessage == true
    check opResultId.message == wSuccess
    check $opResultId == "Message: wSuccess"

  test "OpResultId new value int":
    var opResultId = opValue[int](3)
    check opResultId.isValue == true
    check opResultId.value == 3
    check $opResultId == "Value: 3"

  test "OpResultId new message":
    var opResultId = opMessage[int](wUnknownArg)
    check opResultId.isMessage == true
    check opResultId.message == wUnknownArg
    check $opResultId == "Message: wUnknownArg"

  test "opValue my obj":
    let myObj = MyObjTest2(name: "test", size: 12)
    let opResultId = opValue[MyObjTest2](myObj)
    check opResultId.isValue == true
    check opResultId.isMessage == false
    check opResultId.value == myObj
