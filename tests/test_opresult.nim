import std/unittest
import messages
import opresult

type
  MyObjTest = object
    name: string
    size: int

suite "opresult.nim":

  test "OpResult default":
    var strOr: OpResult[string, string]
    check strOr.isValue == false
    check strOr.isMessage == true
    check strOr.message == ""

  test "OpResult new value":
    var strOr = newOpResult[string, string]("hello")
    check strOr.isValue == true
    check strOr.value == "hello"
    check $strOr == "Value: hello"

  test "OpResult new message":
    var strOr = newOpResultMsg[string, string]("a message")
    check strOr.isValue == false
    check strOr.isMessage == true
    check strOr.message == "a message"
    check $strOr == "Message: a message"

  test "OpResult new value int":
    var intOr = newOpResult[int, string](3)
    check intOr.isValue == true
    check intOr.isMessage == false
    check intOr.value == 3
    check $intOr == "Value: 3"

  test "OpResult new message":
    var intOr = newOpResultMsg[int, string]("some msg")
    check intOr.isValue == false
    check intOr.isMessage == true
    check intOr.message == "some msg"
    check $intOr == "Message: some msg"

  test "newOpResult my obj":
    let myObj = MyObjTest(name: "test", size: 12)
    let myObjOr = newOpResult[MyObjTest, string](myObj)
    check myObjOr.isValue == true
    check myObjOr.isMessage == false
    check myObjOr.value == myObj

  test "newOpResult my obj message":
    let myObjOr = newOpResultMsg[MyObjTest, string]("msg")
    check myObjOr.isValue == false
    check myObjOr.isMessage == true
    check myObjOr.message == "msg"
