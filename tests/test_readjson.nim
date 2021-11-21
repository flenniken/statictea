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
import warnings
import tostring
import unicodes
import opresultid

proc testParseHexUnicode(str: string, start: Natural, eNumber: int32, ePos: Natural): bool =
  var pos = start
  result = true
  let numOrc = parseHexUnicode(str, pos)
  if not numOrc.isValue:
    echo "unexpected error: " & $numOrc
    result = false
  if numOrc.value != eNumber:
    echo "expected num: $1" % $toHex(numOrc.value)
    echo "     got num: $1" % $toHex(eNumber)
    result = false
  if ePos != pos:
    echo "expected pos: $1" % $ePos
    echo "     got pos: $1" % $pos
    result = false

proc testParseHexUnicodeE(str: string, start: Natural, messageId: MessageId,
    ePos: Natural): bool =
  result = true
  var pos = start
  let numOrc = parseHexUnicode(str, pos)
  if not numOrc.isMessageId:
    echo "did not get the expected error: " & $numOrc
    result = false
  if numOrc.messageId != messageId:
    echo "expected message: $1" % getWarning("test", 0, messageId)
    echo "     got message: $1" % getWarning("test", 0, MessageId(numOrc.messageId))
    result = false
  if ePos != pos:
    echo "expected pos: $1" % $ePos
    echo "     got pos: $1" % $pos
    result = false

proc testParseHexUnicode16(str: string, start: Natural, eNumber: int32): bool =
  let numOrc = parseHexUnicode16(str, start)
  result = true
  if not numOrc.isValue:
    echo "unexpected error: " & $numOrc
    result = false
  if numOrc.value != eNumber:
    echo "expected num: $1" % $toHex(numOrc.value)
    echo "     got num: $1" % $toHex(eNumber)
    result = false

proc testParseHexUnicode16E(str: string, start: Natural, messageId: MessageId): bool =
  let numOrc = parseHexUnicode16(str, start)
  result = true
  if not numOrc.isMessageId:
    echo "did not get the expected error: " & $numOrc
    result = false
  if numOrc.messageId != messageId:
    echo "expected message: $1" % getWarning("test", 0, messageId)
    echo "     got message: $1" % getWarning("test", 0, MessageId(numOrc.messageId))
    result = false

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

  var posO = firstInvalidUtf8(literal)
  if posO.isSome:
    echo "Invalid utf-8 bytes starting at $1." % $posO.get()
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

  test "parseHexUnicode16":
    check testParseHexUnicode16("u0000", 0, 0x00)
    check testParseHexUnicode16("u0030", 0, 0x30)
    check testParseHexUnicode16("u1234", 0, 0x1234)
    check testParseHexUnicode16("uffff", 0, 0xffff)
    check testParseHexUnicode16("uABCD", 0, 0xabcd)
    check testParseHexUnicode16("""\u0038" """, 1, 0x38)

    check testParseHexUnicode16(r"abc\u0030def", 4, 0x30)

  test "parseHexUnicode16 error":
    check testParseHexUnicode16E("", 0, wFourHexDigits)
    check testParseHexUnicode16E("u", 0, wFourHexDigits)
    check testParseHexUnicode16E("uv", 0, wFourHexDigits)
    check testParseHexUnicode16E("u0v", 0, wFourHexDigits)
    check testParseHexUnicode16E("u00v", 0, wFourHexDigits)
    check testParseHexUnicode16E("u000v", 0, wFourHexDigits)
    check testParseHexUnicode16E("au000v", 0, wFourHexDigits)
    check testParseHexUnicode16E("abu000v", 0, wFourHexDigits)

  test "parseHexUnicode":
    # You can generate the surrogate pair for a unicode code point.
    # http://russellcottrell.com/greek/utilities/SurrogatePairCalculator.htm
    check testParseHexUnicode("u0000", 0, 0, 5)
    check testParseHexUnicode(""" "\u0038" """, 3, 0x38, 8)
    check testParseHexUnicode(r"u0030\u0031", 0, 0x30, 5)
    check testParseHexUnicode(r"uD841\uDF0E", 0, 0x2070E, 11) # 𠜎
    check testParseHexUnicode(r"uD867\uDD98", 0, 0x29D98, 11) # 𩶘
    check testParseHexUnicode(r"uD83D\uDE03", 0, 0x1F603, 11) # 😃

  test "parseHexUnicode error":
    check testParseHexUnicodeE("u000", 0, wFourHexDigits, 0)
    check testParseHexUnicodeE(r"uD83Dabc", 0, wMissingSurrogatePair, 5)
    check testParseHexUnicodeE(r"uD83D\tabc", 0, wMissingSurrogatePair, 5)
    check testParseHexUnicodeE(r"uD83D\u0030", 0, wNotMatchingSurrogate, 6)

    # The test cases below come from this site:
    # https://www.w3.org/2001/06/utf-8-wrong/UTF-8-test.html

    # 5.1 Single UTF-16 surrogates
    check testParseHexUnicodeE(r"uD800x", 0, wMissingSurrogatePair, 5)
    check testParseHexUnicodeE(r"uDb7fx", 0, wMissingSurrogatePair, 5)
    check testParseHexUnicodeE(r"uDb80x", 0, wMissingSurrogatePair, 5)
    check testParseHexUnicodeE(r"uDC00x", 0, wLowSurrogateFirst, 0)
    check testParseHexUnicodeE(r"uDF80x", 0, wLowSurrogateFirst, 0)
    check testParseHexUnicodeE(r"uDfffx", 0, wLowSurrogateFirst, 0)

    # 5.2 Paired UTF-16 surrogates                                                  |
    check testParseHexUnicodeE(r"uD800\uDC00", 0, wPairedSurrogate, 6)
    check testParseHexUnicodeE(r"uD800\uDfff", 0, wPairedSurrogate, 6)
    check testParseHexUnicodeE(r"uDB7F\uDC00", 0, wPairedSurrogate, 6)
    check testParseHexUnicodeE(r"uDB7F\uDFFF", 0, wPairedSurrogate, 6)
    check testParseHexUnicodeE(r"uDB80\uDFFF", 0, wPairedSurrogate, 6)
    check testParseHexUnicodeE(r"uDBFF\uDC00", 0, wPairedSurrogate, 6)
    check testParseHexUnicodeE(r"uDBFF\uDFFF", 0, wPairedSurrogate, 6)

    # 3.5  Impossible bytes
    check testParseHexUnicodeE(r"u00fe", 0, wInvalidUtf8, 0)
    check testParseHexUnicodeE(r"u00ff", 0, wInvalidUtf8, 0)

    # 5.3 Other illegal code positions
    check testParseHexUnicodeE(r"ufffe", 0, wInvalidUtf8, 0)
    check testParseHexUnicodeE(r"uffff", 0, wInvalidUtf8, 0)

    # Not enough characters.
    check testParseHexUnicodeE(r"uD800", 0, wMissingSurrogatePair, 5)
    check testParseHexUnicodeE(r"uD800\", 0, wMissingSurrogatePair, 5)
    check testParseHexUnicodeE(r"uD800\u", 0, wMissingSurrogatePair, 5)

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

  test "parseJsonStr invalid utf-8":
    var str = bytesToString([0x22u8, 0x2f, 0x22])
    check testParseJsonStr(str, 1, "/", 2)

    str = bytesToString([0x31u8, 0x32, 0x33, 0xff, uint8('"')])
    check testParseJsonStrE(str, 0, wInvalidUtf8, 3)

    # String is not validated by the parse function.  It is validated
    # afterwards.

    # # 4.1  Examples of an overlong ASCII character /.
    # str = bytesToString([0x22u8, 0xc0, 0xaf, 0x22])
    # check testParseJsonStr(str, 1, "/", 1) # wNoEndingQuote

    # str = bytesToString([0x22u8, 0xe0, 0x80, 0xaf, 0x22])
    # check testParseJsonStr(str, 1, "/", 1) # wNoEndingQuote

    # str = bytesToString([0x22u8, 0xf0, 0x80, 0x80, 0xaf, 0x22])
    # check testParseJsonStr(str, 1, "/", 1) # wNoEndingQuote

    # str = bytesToString([0x22u8, 0xf8, 0x80, 0x80, 0x80, 0xaf, 0x22])
    # check testParseJsonStr(str, 1, "/", 1) # wNoEndingQuote

    # str = bytesToString([0x22u8, 0xfc, 0x80, 0x80, 0x80, 0x80, 0xaf, 0x22])
    # check testParseJsonStr(str, 1, "/", 1) # wNoEndingQuote
