import std/unittest
import messages
import opresultid

type
  MyObjTest2 = object
    name: string
    size: int

suite "optionrc.nim":

  test "OpResultId default":
    var opResultId: OpResultId[string]
    check opResultId.isValue == true
    check opResultId.value == ""
    check opResultId.isMessageId == false
    check $opResultId == "Value: "

  test "OpResultId new value":
    var opResultId = newOpResultId[string]("hello")
    check opResultId.isValue == true
    check opResultId.value == "hello"
    check $opResultId == "Value: hello"

  test "OpResultId new message id":
    var opResultId = newOpResultIdId[string](wSuccess)
    check opResultId.isMessageId == true
    check opResultId.messageId == wSuccess
    check $opResultId == "Message id: wSuccess"

  test "OpResultId new value int":
    var opResultId = newOpResultId[int](3)
    check opResultId.isValue == true
    check opResultId.value == 3
    check $opResultId == "Value: 3"

  test "OpResultId new message":
    var opResultId = newOpResultIdId[int](wUnknownArg)
    check opResultId.isMessageId == true
    check opResultId.messageId == wUnknownArg
    check $opResultId == "Message id: wUnknownArg"

  test "newOpResultId my obj":
    let myObj = MyObjTest2(name: "test", size: 12)
    let opResultId = newOpResultId[MyObjTest2](myObj)
    check opResultId.isValue == true
    check opResultId.isMessageId == false
    check opResultId.value == myObj

