import unittest
import env
import vartypes
import tables
import readjson
import os
import json
import options
import strutils

proc testReadJsonFile(filename: string, expectedVars: VarsDict,
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[] ): bool =

  var env = openEnvTest("_readJson.log")

  var vars = getEmptyVars()
  readJson(env, filename, vars)

  result = env.readCloseDeleteCompare(eLogLines, eErrLines, eOutLines)
  if not expectedItem("vars", vars, expectedVars):
    result = false


proc testReadJsonContent(jsonContent: string, expectedVars: VarsDict,
    eLogLines: seq[string] = @[],
    eErrLines: seq[string] = @[],
    eOutLines: seq[string] = @[] ): bool =

  var filename = "_readJson.json"
  createFile(filename, jsonContent)
  defer: discard tryRemoveFile(filename)
  result = testReadJsonFile(filename, expectedVars, eLogLines,
                   eErrLines, eOutLines)

suite "readjson.nim":

  test "readJson file not found":
    let eErrLines = @["template.html(0): w16: File not found: missing.\n"]
    var expectedValue = getEmptyVars()
    check testReadJsonFile("missing", expectedValue, eErrLines=eErrLines)

  test "readJson cannot open file":
    let eErrLines =
      @["template.html(0): w17: Unable to open file: _cannotopen.tmp.\n"]
    let expectedValue = getEmptyVars()
    let filename = "_cannotopen.tmp"
    defer: discard tryRemoveFile(filename)
    createFile(filename, "temp")
    setFilePermissions(filename, {fpUserWrite, fpGroupWrite})
    check testReadJsonFile(filename, expectedValue, eErrLines=eErrLines)

  test "readJson parse error":
    let eErrLines = @["template.html(0): w15: Unable to parse the json file. Skipping file: _readJson.json.\n"]
    let expectedValue = getEmptyVars()
    check testReadJsonContent("{", expectedValue, eErrLines=eErrLines)

  test "readJson no root object":
    let eErrLines = @["template.html(0): w14: The root json element must be an object. Skipping file: _readJson.json.\n"]
    let expectedValue = getEmptyVars()
    check testReadJsonContent("[5]", expectedValue, eErrLines=eErrLines)

  test "readJson a=5":
    var expectedValue = getEmptyVars()
    expectedValue["a"] = Value(kind: vkInt, intv: 5)
    check testReadJsonContent("""{"a": 5}""", expectedValue)

  test "jsonToValue int":
    let jsonNode = newJInt(5)
    let option = jsonToValue(jsonNode)
    let value = option.get()
    check value.intv == 5
    check $value == "5"

  test "jsonToValue string":
    let jsonNode = newJString("string")
    let option = jsonToValue(jsonNode)
    let value = option.get()
    check value.stringv == "string"
    check $value == "string"

  test "jsonToValue quote":
    let str = "this has \"quotes\" in it"
    let jsonNode = newJString(str)
    let option = jsonToValue(jsonNode)
    let value = option.get()
    check value.stringv == str
    check $value == str

  test "jsonToValue float":
    let jsonNode = newJFloat(1.5)
    let option = jsonToValue(jsonNode)
    let value = option.get()
    check value.floatv == 1.5

  test "jsonToValue bool true":
    let jsonNode = newJBool(true)
    let option = jsonToValue(jsonNode)
    let value = option.get()
    check value.intv == 1
    check $value == "1"

  test "jsonToValue bool false":
    let jsonNode = newJBool(false)
    let option = jsonToValue(jsonNode)
    let value = option.get()
    check value.intv == 0
    check $value == "0"

  test "jsonToValue null":
    let jsonNode = newJNull()
    let option = jsonToValue(jsonNode)
    let value = option.get()
    check value.intv == 0
    check $value == "0"

  test "jsonToValue list":
    let jsonNode = newJArray()
    let option = jsonToValue(jsonNode)
    let value = option.get()
    check value.listv.len == 0
    check $value == "[]"

  test "jsonToValue list null":
    var jsonNode = newJArray()
    jsonNode.add(newJNull())
    let option = jsonToValue(jsonNode)
    let value = option.get()
    check value.listv.len == 1
    check $value == "[...]"

  test "jsonToValue list items":
    var jsonNode = newJArray()
    jsonNode.add(newJNull())
    jsonNode.add(newJInt(5))
    jsonNode.add(newJString("string"))
    jsonNode.add(newJFloat(1.5))
    jsonNode.add(newJBool(true))
    jsonNode.add(newJBool(false))
    let option = jsonToValue(jsonNode)
    let value = option.get()
    check value.listv.len == 6
    # check $value == """[0, 5, "string", 1.5, 1, 0]"""
    # check $value == """[...]"""

  test "jsonToValue nested list":
    var jsonNode = newJArray()
    jsonNode.add(newJInt(5))
    jsonNode.add(newJInt(6))
    var nested = newJArray()
    nested.add(newJInt(8))
    jsonNode.add(nested)
    jsonNode.add(newJInt(7))
    let option = jsonToValue(jsonNode)
    let value = option.get()
    check value.listv.len == 4
    # check $value == "[5, 6, [8], 7]"
    check $value == "[...]"

  test "empty dict":
    var jsonNode = newJObject()
    let option = jsonToValue(jsonNode)
    let value = option.get()
    check value.dictv.len == 0
    check $value == "{}"

  test "tea list":
    let content = """
{
  "teaList": [
    {"tea": "Chamomile"},
    {"tea": "Chrysanthemum"},
    {"tea": "White"},
    {"tea": "Puer"}
  ]
}"""
    var expectedValue = getEmptyVars()
    var listValues: seq[Value]
    let teaList = ["Chamomile", "Chrysanthemum", "White", "Puer"]
    for tea in teaList:
      let value = Value(kind: vkString, stringv: tea)
      var dv: VarsDict
      dv["tea"] = value
      let listValue = Value(kind: vkDict, dictv: dv)
      listValues.add(listValue)
    expectedValue["teaList"] = Value(kind: vkList, listv: listValues)

    check testReadJsonContent(content, expectedValue)

  test "long string":
    let string256 = "123456789 123456789 123456789 123456789 123456789 " &
                 "123456789 123456789 123456789 123456789 123456789 " &
                 "123456789 123456789 123456789 123456789 123456789 " &
                 "123456789 123456789 123456789 123456789 123456789 " &
                 "123456789 123456789 123456789 123456789 123456789 123456"
    let content = """
{
  "longString": "$1"
}
""" % [string256]
    var expectedValue = getEmptyVars()
    expectedValue["longString"] = Value(kind: vkString, stringv: string256)
    check testReadJsonContent(content, expectedValue)

  test "longer string":

    let teaParty = """
CHAPTER VII.
A Mad Tea-Party

There was a table set out under a tree in front of the house, and the
March Hare and the Hatter were having tea at it: a Dormouse was
sitting between them, fast asleep, and the other two were using it as
a cushion, resting their elbows on it, and talking over its
head. “Very uncomfortable for the Dormouse,” thought Alice; “only, as
it’s asleep, I suppose it doesn’t mind.”

The table was a large one, but the three were all crowded together at
one corner of it: “No room! No room!” they cried out when they saw
Alice coming. “There’s plenty of room!” said Alice indignantly, and
she sat down in a large arm-chair at one end of the table.
"""

    let content = """
{
  "longString": "$1"
}
""" % [teaParty]
    var expectedValue = getEmptyVars()
    expectedValue["longString"] = Value(kind: vkString, stringv: teaParty)
    check testReadJsonContent(content, expectedValue)

  test "quoted strings":
    let content = """
{
  "str": "this is \"quoted\""
}
"""
    var expectedValue = getEmptyVars()
    expectedValue["str"] = Value(kind: vkString, stringv: """this is "quoted"""")

    check testReadJsonContent(content, expectedValue)
