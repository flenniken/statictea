import std/unittest
import std/os
import std/json
import std/options
import std/strutils
import std/tables
import std/strformat
import env
import vartypes
import readjson
import messages
import tostring
import utf8decoder
import sharedtestcode

proc testParseJsonStr(text: string, start: Natural,
    eStr: string, eLength: Natural): bool =
  # Test parseJsonStr.

  let parsedString = parseJsonStr(text, start)
  if parsedString.messageId != MessageId(0):
    echo "Unexpected error: " & $parsedString.messageId
    return false
  let literal = parsedString.str
  let length = parsedString.pos - start

  result = true

  if literal != eStr:
    echo "expected str: $1" % [eStr]
    echo "     got str: $1" % [literal]
    result = false

  if length != eLength:
    echo "expected length: $1" % [$eLength]
    echo "     got length: $1" % [$length]
    result = false

  var pos = validateUtf8String(literal)
  if pos != -1:
    echo "Invalid UTF-8 bytes starting at $1." % $pos
    result = false

proc testParseJsonStrE(text: string, start: Natural,
    eMessageId: Messageid, ePos: Natural): bool =
  ## Test parseJsonStr for expected errors.

  result = true

  let parsedString = parseJsonStr(text, start)
  if parsedString.messageId == MessageId(0):
    echo "Unexpected value: " & $parsedString
    return false

  let messageId = parsedString.messageId
  if messageId != eMessageId:
    echo "expected message: $1" % [$eMessageId]
    echo "     got message: $1" % [$messageId]
    result = false

  let pos = parsedString.pos
  if pos != ePos:
    echo "expected pos: $1" % [$ePos]
    echo "     got pos: $1" % [$pos]
    result = false

proc testUnescapePopularChar(popular: char, eChar: char): bool =
  let ch = unescapePopularChar(popular)
  let got = int(ch)
  let expected = int(eChar)
  if ch != eChar:
    echo fmt"expected value: {expected:#X}"
    echo fmt"     got value: {got:#X}"
    result = false
  else:
    result = true

# proc testParsePopularCharsOk(str: string, start: Natural, eParsed: string): bool =



#   var pos = start
#   var parsed = ""
#   let message = parsePopularChars(str, pos, parsed)
#   if message != "":
#     echo "Error parsing:"
#     echo str
#     echo "Error message:"
#     echo message
#     return false
#   let ePos = start + 1
#   if pos != ePos or parsed != eParsed:
#     echo "Unexpected parsing result:"
#     if parsed == eParsed:
#       echo "     same: " & parsed
#     else:
#       echo " expected: " & eParsed
#       echo "      got: " & parsed
#     if pos == ePos:
#       echo " same pos: " & $pos
#     else:
#       echo " expected pos: " & $ePos
#       echo "      got pos: " & $pos
#     return false
#   result = true

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

  test "unescapePopularChar":
    # nr"t\bf/
    check testUnescapePopularChar('n', '\n')
    check testUnescapePopularChar('r', '\r')
    check testUnescapePopularChar('"', '"')
    check testUnescapePopularChar('t', '\t')
    check testUnescapePopularChar('\\', '\\')
    check testUnescapePopularChar('b', '\b')
    check testUnescapePopularChar('f', '\f')
    check testUnescapePopularChar('/', '/')

  test "unescapePopularChar error":
    check unescapePopularChar('a') == char(0)
    check unescapePopularChar('\'') == char(0)

  test "parseJsonStr":
    # Parsing starts after the start quote and ends after the
    # whitespace after the end quote.
    check testParseJsonStr(""""""", 0, "", 1)
    check testParseJsonStr(""" """", 1, "", 1)
    check testParseJsonStr(""" """"", 2, "", 1)
    check testParseJsonStr(""" "" """, 2, "", 2)
    check testParseJsonStr(""" ""  """, 2, "", 3)

    check testParseJsonStr(""" "t" """, 2, "t", 3)
    check testParseJsonStr(""" "tea" """, 2, "tea", 5)
    check testParseJsonStr(""" "tea" other""", 2, "tea", 5)

  test "parseJsonStr popular escape":
    check testParseJsonStr(""" "\b" """, 2, "\b", 4)
    check testParseJsonStr(""" "\f" """, 2, "\f", 4)
    check testParseJsonStr(""" "\n" """, 2, "\n", 4)
    check testParseJsonStr(""" "\r" """, 2, "\r", 4)
    check testParseJsonStr(""" "\t" """, 2, "\t", 4)

  test "parseJsonStr unicode escape":
    check testParseJsonStr(""" "\u0038" """, 2, "8", 8)
    check testParseJsonStr(""" "\u03A6" """, 2, "Φ", 8)
    check testParseJsonStr(""" "\u1E00" """, 2, "Ḁ", 8)
    check testParseJsonStr(""" "\u8336" """, 2, "茶", 8)
    check testParseJsonStr(""" "\uD834\uDD1E" """, 2, "\u{1D11E}", 14)

  test "parseJsonStr varying":
    check testParseJsonStr(""" "\u0038 39 40 \t 50" """, 2, "8 39 40 \t 50", 20)
    check testParseJsonStr(""" "\t\n\r\"\\ \b\f\/ \u0039 \uD83D\uDE03" """, 2,
      "\t\n\r\"\\ \b\f/ 9 😃", 39)

    check testParseJsonStr(""" "a"	""", 2, "a", 3)
    check testParseJsonStr(""" "a"	 """, 2, "a", 4)

  test "parseJsonStr utf8":
    var str = bytesToString([0x31u8, 0x32, 0x33, 0x34, uint8('"')])
    check testParseJsonStr(str, 0, "1234", 5)

    # valid: (U+00A9, C2 A9, COPYRIGHT SIGN"): ©
    str = bytesToString([0xc2u8, 0xa9, 0x33, 0x34, uint8('"')])
    check testParseJsonStr(str, 0, "\xc2\xa934", 5)

    # valid hex: (U+2010, HYPHEN): E2 80 90
    str = bytesToString([0xE2u8, 0x80, 0x90, 0x34, uint8('"')])
    check testParseJsonStr(str, 0, "\xe2\x80\x904", 5)

  test "parseJsonStr error":
    check testParseJsonStrE(""" "no ending quote """, 2, wNoEndingQuote, 18)
    check testParseJsonStrE(" \"\n newline not escaped \" ", 2, wControlNotEscaped, 2)

    check testParseJsonStrE(""" "\uDC00x""", 2, wLowSurrogateFirst, 3)
    check testParseJsonStrE(""" "\a" """, 2, wNotPopular, 3)

    let str = bytesToString([0x1u8, 0x02, 0x03, 0x04])
    check testParseJsonStrE(str, 0, wControlNotEscaped, 0)

  test "parseJsonStr invalid UTF-8":
    var str = bytesToString([0x22u8, 0x2f, 0x22])
    check testParseJsonStr(str, 1, "/", 2)

    str = bytesToString([0x31u8, 0x32, 0x33, 0xff, uint8('"')])
    check testParseJsonStrE(str, 0, wInvalidUtf8, 3)

    # overlong ASCII solidus /.
    str = "overlong solidus: \xe0\x80\xaf."
    check testParseJsonStrE(str, 0, wInvalidUtf8, 18)

    str = """a = "no ending quote. asdf"""
    check testParseJsonStrE(str, 5, wNoEndingQuote, 26)

    str = "control not escaped\x0a<-\""
    check testParseJsonStrE(str, 0, wControlNotEscaped, 19)

    str = r"no popular escaped\a abc"
    check testParseJsonStrE(str, 0, wNotPopular, 19)
