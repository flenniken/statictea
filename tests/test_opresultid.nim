import std/unittest
import messages
# import opresult
import opresultid

type
  MyObjTest2 = object
    name: string
    size: int

suite "optionrc.nim":
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

