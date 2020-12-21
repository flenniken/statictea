import unittest
import env
import vartypes
import tables
import readjson
import os
import json
import options

proc testReadJsonFile(filename: string, expectedVars: VarsDict,
    expectedLogLines: seq[string] = @[],
    expectedErrLines: seq[string] = @[],
    expectedOutLines: seq[string] = @[] ) =

  var env = openEnvTest("_readJson.log")

  var vars = getEmptyVars()
  readJson(env, filename, vars)

  let (logLines, errLines, outLines) = env.readCloseDelete()
  check expectedLogLines == logLines
  check expectedErrLines == errLines
  check expectedoutLines == outLines
  check $vars == $expectedVars


proc testReadJsonContent(jsonContent: string, expectedVars: VarsDict,
    expectedLogLines: seq[string] = @[],
    expectedErrLines: seq[string] = @[],
    expectedOutLines: seq[string] = @[] ) =

  var filename = "_readJson.json"
  createFile(filename, jsonContent)
  defer: discard tryRemoveFile(filename)
  testReadJsonFile(filename, expectedVars, expectedLogLines,
                   expectedErrLines, expectedOutLines)

suite "readjson.nim":

  test "readJson file not found":
    let expectedErrLines = @["read json(0): w16: File not found: missing."]
    var expectedValue = getEmptyVars()
    testReadJsonFile("missing", expectedValue, expectedErrLines=expectedErrLines)

  test "readJson cannot open file":
    let expectedErrLines =
      @["read json(0): w17: Unable to open file: _cannotopen.tmp."]
    let expectedValue = getEmptyVars()
    let filename = "_cannotopen.tmp"
    defer: discard tryRemoveFile(filename)
    createFile(filename, "temp")
    setFilePermissions(filename, {fpUserWrite, fpGroupWrite})
    testReadJsonFile(filename, expectedValue, expectedErrLines=expectedErrLines)

  test "readJson parse error":
    let expectedErrLines = @["read json(0): w15: Unable to parse the json file. Skipping file: _readJson.json."]
    let expectedValue = getEmptyVars()
    testReadJsonContent("{", expectedValue, expectedErrLines=expectedErrLines)

  test "readJson no root object":
    let expectedErrLines = @["read json(0): w14: The root json element must be an object. Skipping file: _readJson.json."]
    let expectedValue = getEmptyVars()
    testReadJsonContent("[5]", expectedValue, expectedErrLines=expectedErrLines)

  test "readJson a=5":
    var expectedValue = getEmptyVars()
    expectedValue["a"] = Value(kind: vkInt, intv: 5)
    testReadJsonContent("""{"a": 5}""", expectedValue)

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
    check $value == """"string""""

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

    testReadJsonContent(content, expectedValue)

# todo: test depth limit
# todo: test multiple json files
# todo: test long variable names
# todo: test variables dots
# todo: test long strings
# todo: test big ints
# todo: test big floats
# todo: test scientific notation floats
# todo: test duplicate variables
# todo: test long lists
# todo: test long dicts
# todo: test list with different types of values
