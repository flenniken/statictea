import std/unittest
import std/os
import std/json
import std/options
import std/strutils
import std/tables
import env
import vartypes
import readjson
import warnings
import tostring
import unicode



# proc testParseJsonStr(text: string, strLen: Natural,
#     expected: string, expectedLen: Natural, expectedPos: Natural): bool =
#   # Test parseJsonStr.

#   let stringPosO = parseJsonStr(text)
#   if not stringPosO.isSome:
#     echo "not a json string: " & text
#     return false
#   let stringPos = stringPosO.get()
#   let literal = stringPos.str
#   let pos = stringPos.pos
  
#   if literal != expected or pos != expectedPos:
#     echo "expected: $1" % [expected]
#     echo "     got: $1" % [literal]
#     echo "expected pos: $1" % [$expectedPos]
#     echo "     got pos: $1" % [$pos]

#     if runeLen(expected) == 1:
#       echo r"expected u: \u" & toHex(int32(toRunes(expected)[0]))
#     if runeLen(literal) == 1:
#       echo r"     got u: \u" & toHex(int32(toRunes(literal)[0]))
#     return false

#   if runeLen(text) != strLen:
#     echo "wrong number of characters:"
#     echo "     got str.len $1" % $runeLen(text)
#     echo "expected str.len $1" % $strLen

#   if runeLen(expected) != expectedLen:
#     echo "     got expected.len $1" % $runeLen(expected)
#     echo "expected expected.len $1" % $expectedLen
#     return false

#   return true

suite "readjson.nim":

  test "readJsonFile file not found":
    let filename = "missing"
    var valueOrWarning = readJsonFile(filename)
    check valueOrWarning == newValueOrWarning(wFileNotFound, filename)

  test "readJsonFile cannot open file":
    let filename = "_cannotopen.tmp"
    createFile(filename, "temp")
    defer: discard tryRemoveFile(filename)
    setFilePermissions(filename, {fpUserWrite, fpGroupWrite})
    var valueOrWarning = readJsonFile(filename)
    check valueOrWarning == newValueOrWarning(wUnableToOpenFile, filename)

  test "readJsonFile parse error":
    let content = "{"
    var valueOrWarning = readJsonString(content)
    check valueOrWarning == newValueOrWarning(wJsonParseError)

  test "readJsonFile no root object":
    let content = "[5]"
    var valueOrWarning = readJsonString(content)
    check valueOrWarning == newValueOrWarning(wInvalidJsonRoot)

  test "readJsonFile a=5":
    let content = """{"a":5}"""
    let valueOrWarning = readJsonString(content)
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
    let valueOrWarning = readJsonString(content)
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
    let valueOrWarning = readJsonString(content)
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
    let valueOrWarning = readJsonString(content)
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
    let valueOrWarning = readJsonString(content)
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
    var valueOrWarning = readJsonString(content)
    check valueOrWarning.kind == vwValue
    var str = dictToString(valueOrWarning.value)
    check expectedItem("read json mix", str, eStr)

  # test "parseJsonStr":
  #   check testParseJsonStr("""""""", 2, "", 0, 2)
  #   check testParseJsonStr(""""" """, 3, "", 0, 3)
  #   check testParseJsonStr("""  "" """, 5, "", 0, 5)
  #   check testParseJsonStr(""""t"""", 3, "t", 1, 3)
  #   check testParseJsonStr(""" "t" """, 5, "t", 1, 5)
  #   check testParseJsonStr("\"tea\"", 5, "tea", 3, 5)
  #   check testParseJsonStr(""" "tea" other """, 12, "tea", 3, 6)

  # test "parseJsonStr short escape":
  #   check testParseJsonStr(""""\b"""", 4, "\b", 1, 4)
  #   check testParseJsonStr(""""\f"""", 4, "\f", 1, 4)
  #   check testParseJsonStr(""""\n"""", 4, "\n", 1, 4)
  #   check testParseJsonStr(""""\r"""", 4, "\r", 1, 4)
  #   check testParseJsonStr(""""\t"""", 4, "\t", 1, 4)

  # test "parseJsonStr escape":
  #   check testParseJsonStr(""" "\"" """, 6, "\"", 1, 6)
  # #   check testParseJsonStr("\\\"", 2, "\"", 1)
  # #   check testParseJsonStr(r"\\", 2, "\\", 1)
  # #   check testParseJsonStr(r"\/", 2, "/", 1)
  # #   check testParseJsonStr(r"\b", 2, "\b", 1)
  # #   check testParseJsonStr(r"\f", 2, "\f", 1)
  # #   check testParseJsonStr(r"\n", 2, "\n", 1)
  # #   check testParseJsonStr(r"\r", 2, "\r", 1)
  # #   check testParseJsonStr(r"\t", 2, "\t", 1)

  # # test "parseJsonStr unicode escape":
  # #   check testParseJsonStr(r"\u0038", 6, "8", 1)
  # #   check testParseJsonStr(r"\u03A6", 6, "Φ", 1)
  # #   check testParseJsonStr(r"\u1E00", 6, "Ḁ", 1)
  # #   check testParseJsonStr(r"\u8336", 6, "茶", 1)
  # #   check testParseJsonStr(r"\uD834\uDD1E", 12, "\u{1D11E}", 1)

  # # todo: test error cases for parseJsonStr

  test "parsePopularChars":
    var pos: Natural = 3
    var parsed = ""
    check parsePopularChars(r"he\tllo", pos, parsed) == ""
    check pos == 4
    check parsed == "he\tllo"
    
