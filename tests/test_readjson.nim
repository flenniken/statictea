# import strutils
import unittest
import warnenv
import logenv
import vartypes
import streams
import tables
import readjson
import os
import json

proc createFile(filename: string, content: string) =
  var file = open(filename, fmWrite)
  file.write(content)
  file.close()

proc testReadJson(filename: string, jsonContent: string, expectedVars: Table[string, Value],
      expectedWarnLines: seq[string] = @[], expectedLogLines: seq[string] = @[]) =
    openWarnStream(newStringStream())
    openLogFile("_readJson.log")

    var jsonFilename: string
    if filename == "":
      jsonFilename = "_readJson.json"
      createFile(jsonFilename, jsonContent)
    else:
      jsonFilename = filename
    var vars = initTable[string, Value]()
    readJson(jsonFilename, vars)
    discard tryRemoveFile(jsonFilename)

    let warnLines = readAndClose()
    check warnLines == expectedWarnLines
    var logLines = logReadDelete(20)
    check logLines == expectedLogLines

    check $vars == $expectedVars

    discard tryRemoveFile(jsonFilename)


suite "readjson.nim":

  test "readJson empty":
    let expectedVars = initTable[string, Value]()
    testReadJson("", "{}", expectedVars)

  test "readJson file not found":
    let expectedWarnLines = @["read json(0): w16: File not found: missing."]
    let expectedVars = initTable[string, Value]()
    testReadJson("missing", "{}", expectedVars, expectedWarnLines=expectedWarnLines)

  test "readJson cannot open file":
    let expectedWarnLines = @["read json(0): w17: Unable to open file: _cannotopen.tmp."]
    let expectedVars = initTable[string, Value]()
    let filename = "_cannotopen.tmp"
    createFile(filename, "temp")
    setFilePermissions(filename, {fpUserWrite, fpGroupWrite})
    testReadJson(filename, "{}", expectedVars, expectedWarnLines=expectedWarnLines)

  test "readJson parse error":
    let expectedWarnLines = @["read json(0): w15: Unable to parse the json file. Skipping file: _readJson.json."]
    let expectedVars = initTable[string, Value]()
    testReadJson("", "{", expectedVars, expectedWarnLines=expectedWarnLines)

  test "readJson not root object":
    let expectedWarnLines = @["read json(0): w14: The root json element must be an object. Skipping file: _readJson.json."]
    let expectedVars = initTable[string, Value]()
    testReadJson("", "[5]", expectedVars, expectedWarnLines=expectedWarnLines)

  test "readJson a=5":
    var expectedVars = initTable[string, Value]()
    let value = Value(kind: vkInt, intv: 5)
    expectedVars["a"] = value
    testReadJson("", """{"a": 5}""", expectedVars)

  test "jsonToValue int":
    let jsonNode = newJInt(5)
    let value = jsonToValue(jsonNode)
    check value.intv == 5

  test "jsonToValue string":
    let jsonNode = newJString("string")
    let value = jsonToValue(jsonNode)
    check value.stringv == "string"
    check $value == """"string""""

  test "jsonToValue float":
    let jsonNode = newJFloat(1.5)
    let value = jsonToValue(jsonNode)
    check value.floatv == 1.5

  test "jsonToValue bool true":
    let jsonNode = newJBool(true)
    let value = jsonToValue(jsonNode)
    check value.intv == 1

  test "jsonToValue bool false":
    let jsonNode = newJBool(false)
    let value = jsonToValue(jsonNode)
    check value.intv == 0

  test "jsonToValue null":
    let jsonNode = newJNull()
    let value = jsonToValue(jsonNode)
    check value.intv == 0

  test "jsonToValue list":
    let jsonNode = newJArray()
    let value = jsonToValue(jsonNode)
    check value.listv.len == 0
    check $value == "[]"

  test "jsonToValue list null":
    var jsonNode = newJArray()
    jsonNode.add(newJNull())
    let value = jsonToValue(jsonNode)
    check value.listv.len == 1
    check $value == "[0]"

  test "jsonToValue list items":
    var jsonNode = newJArray()
    jsonNode.add(newJNull())
    jsonNode.add(newJInt(5))
    jsonNode.add(newJString("string"))
    jsonNode.add(newJFloat(1.5))
    jsonNode.add(newJBool(true))
    jsonNode.add(newJBool(false))
    let value = jsonToValue(jsonNode)
    check value.listv.len == 6
    check $value == """[0, 5, "string", 1.5, 1, 0]"""

  test "jsonToValue nested list":
    var jsonNode = newJArray()
    jsonNode.add(newJInt(5))
    jsonNode.add(newJInt(6))
    var nested = newJArray()
    nested.add(newJInt(8))
    jsonNode.add(nested)
    jsonNode.add(newJInt(7))
    let value = jsonToValue(jsonNode)
    check value.listv.len == 4
    check $value == "[5, 6, [8], 7]"
