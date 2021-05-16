import unittest
import env
import vartypes
import tables
import readjson
import os
import json
import options
import strutils
import warnings

suite "readjson.nim":

  test "readJson file not found":
    let filename = "missing"
    var valueOrWarning = readJson(filename)
    check valueOrWarning == newValueOrWarning(wFileNotFound, filename)

  test "readJson cannot open file":
    let filename = "_cannotopen.tmp"
    createFile(filename, "temp")
    defer: discard tryRemoveFile(filename)
    setFilePermissions(filename, {fpUserWrite, fpGroupWrite})
    var valueOrWarning = readJson(filename)
    check valueOrWarning == newValueOrWarning(wUnableToOpenFile, filename)

  test "readJson parse error":
    let content = "{"
    var valueOrWarning = readJsonContent(content)
    check valueOrWarning == newValueOrWarning(wJsonParseError)

  test "readJson no root object":
    let content = "[5]"
    var valueOrWarning = readJsonContent(content)
    check valueOrWarning == newValueOrWarning(wInvalidJsonRoot)

  test "readJson a=5":
    let content = """{"a":5}"""
    let valueOrWarning = readJsonContent(content)
    check valueOrWarning.kind == vwValue
    let str = dictToString(valueOrWarning.value)
    check expectedItem("json", str, content)

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

  test "jsonToValue quote":
    let str = "this has \"quotes\" in it"
    let jsonNode = newJString(str)
    let option = jsonToValue(jsonNode)
    let value = option.get()
    check value.stringv == str
    check $value == """"this has \"quotes\" in it""""

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
    check $value == "[0]"

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
    check $value == "[5,6,[8],7]"

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
    let eStr = """{"teaList":[{"tea":"Chamomile"},{"tea":"Chrysanthemum"},{"tea":"White"},{"tea":"Puer"}]}"""
    let valueOrWarning = readJsonContent(content)
    check valueOrWarning.kind == vwValue
    let str = dictToString(valueOrWarning.value)
    check expectedItem("read json", str, eStr)

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
    let eStr = """{"longString":"123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456"}"""
    let valueOrWarning = readJsonContent(content)
    check valueOrWarning.kind == vwValue
    let str = dictToString(valueOrWarning.value)
    check expectedItem("read json", str, eStr)

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
    let eStr = """{"longString":"CHAPTER VII.\nA Mad Tea-Party\n\nThere was a table set out under a tree in front of the house, and the\nMarch Hare and the Hatter were having tea at it: a Dormouse was\nsitting between them, fast asleep, and the other two were using it as\na cushion, resting their elbows on it, and talking over its\nhead. “Very uncomfortable for the Dormouse,” thought Alice; “only, as\nit’s asleep, I suppose it doesn’t mind.”\n\nThe table was a large one, but the three were all crowded together at\none corner of it: “No room! No room!” they cried out when they saw\nAlice coming. “There’s plenty of room!” said Alice indignantly, and\nshe sat down in a large arm-chair at one end of the table.\n"}"""
    let valueOrWarning = readJsonContent(content)
    check valueOrWarning.kind == vwValue
    let str = dictToString(valueOrWarning.value)
    check expectedItem("read json", str, eStr)

  test "quoted strings":
    let content = """
{
  "str": "this is \"quoted\""
}
"""
    let eStr = """{"str":"this is \"quoted\""}"""
    let valueOrWarning = readJsonContent(content)
    check valueOrWarning.kind == vwValue
    let str = dictToString(valueOrWarning.value)
    check expectedItem("read json", str, eStr)

  test "read json mix":
    let content = """
{
  "d": {
    "a": 45,
    "b": "banana",
    "f": 2.5,
  },
  "list": [1, 2, 3]
}"""
    let eStr = """{"d":{"a":45,"b":"banana","f":2.5},"list":[1,2,3]}"""
    var valueOrWarning = readJsonContent(content)
    check valueOrWarning.kind == vwValue
    var str = dictToString(valueOrWarning.value)
    check expectedItem("read json mix", str, eStr)
