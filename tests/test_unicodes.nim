import std/unittest
import std/strformat
import std/strutils
import unicodes
import opresultid
import messages

func stringToHex*(str: string): string =
  ## Convert the string bytes to hex bytes like 34 a9 ff e2.
  var digits: seq[string]
  for ch in str:
    let abyte = uint8(ord(ch))
    digits.add(fmt"{abyte:02x}")
  result = digits.join(" ")

proc testParseHexUnicodeError(text: string, pos: Natural,
    ePos: Natural, eMessageId: MessageId): bool =
  var inOutPos = pos
  let numOrId = parseHexUnicode(text, inOutPos)
  if numOrId.isValue:
    echo "parseHexUnicode passed unexpectedly."
    return false
  result = true
  if numOrId.messageId != eMessageId:
    echo "got unexpected message id:"
    echo "expected: " & $eMessageId
    echo "     got: " & $numOrId.messageId
    result = false
  if inOutPos != ePos:
    echo "got unexpected pos:"
    echo "expected: " & $ePos
    echo "     got: " & $inOutPos
    result = false


proc testParseHexUnicode(text: string, pos: Natural,
    ePos: Natural, eCodePoint: int): bool =
  var inOutPos = pos
  let numOrId = parseHexUnicode(text, inOutPos)
  if numOrId.isMessageId:
    echo ""
    echo "parseHexUnicode failed for: " & text
    echo fmt"{numOrId.messageId}: {Messages[numOrId.messageId]}"
    return false
  result = true
  if numOrId.value != eCodePoint:
    echo "got unexpected string:"
    echo "expected: " & toHex(eCodePoint)
    echo "     got: " & toHex(numOrId.value)
    result = false
  if inOutPos != ePos:
    echo "got unexpected pos:"
    echo "expected: " & $ePos
    echo "     got: " & $inOutPos
    result = false

proc testParseHexUnicodeToString(text: string, pos: Natural,
    ePos: Natural, eString: string): bool =
  var inOutPos = pos
  let stringOrId = parseHexUnicodeToString(text, inOutPos)
  if stringOrId.isMessageId:
    echo ""
    echo "parseHexUnicodeToString failed for: " & text
    echo fmt"{stringOrId.messageId}: {Messages[stringOrId.messageId]}"
    return false
  result = true
  if stringOrId.value != eString:
    echo "got unexpected string:"
    echo "expected: $1, $2" % [stringToHex(eString), eString]
    echo "     got: $1, $2" % [stringToHex(stringOrId.value), stringOrId.value]
    result = false
  if inOutPos != ePos:
    echo "got unexpected pos:"
    echo "expected: " & $ePos
    echo "     got: " & $inOutPos
    result = false

suite "unicodes.nim":

  test "cmpString":
    check cmpString("", "") == 0
    check cmpString("a", "a") == 0
    check cmpString("abc", "abc") == 0
    check cmpString("abc", "ab") == 1
    check cmpString("ab", "abc") == -1
    check cmpString("a", "b") == -1
    check cmpString("b", "a") == 1
    check cmpString("abc", "abd") == -1
    check cmpString("abd", "abc") == 1
    check cmpString("ABC", "abc") == -1
    check cmpString("abc", "ABC") == 1

  test "cmpString case insensitive":
    check cmpString("", "", true) == 0
    check cmpString("a", "a", true) == 0
    check cmpString("abc", "abc", true) == 0
    check cmpString("abc", "ABC", true) == 0
    check cmpString("ABC", "abc", true) == 0
    check cmpString("aBc", "Abd", true) == -1
    check cmpString("Abd", "aBc", true) == 1

  test "codePointToString":
    check codePointToString(0x00).value == "\x00"
    check codePointToString(0x31).value == "1"
    check codePointToString(0x80).value == "\xC2\x80"
    check codePointToString(0x2010).value == "\xE2\x80\x90"
    check codePointToString(0x2010).value == "\xE2\x80\x90"
    check codePointToString(0x8336).value == "\xE8\x8C\xB6"
    check codePointToString(0x1D49C).value == "\xF0\x9D\x92\x9C"
    check codePointToString(0x10ffff).value == "\xF4\x8F\xBF\xBF"

  test "codePointToString error":
    check codePointToString(0x110000).messageId == wCodePointTooBig

  test "parseHexUnicode16":
    check parseHexUnicode16("u1234", 0).value == 0x1234
    check parseHexUnicode16(r"test \u1234", 6).value == 0x1234
    check parseHexUnicode16("u0000", 0).value == 0x0
    check parseHexUnicode16("uffff", 0).value == 0xffff
    check parseHexUnicode16("uABCD", 0).value == 0xabcd
    # surrogates are fine here
    check parseHexUnicode16("uD800", 0).value == 0xD800
    check parseHexUnicode16("uDFFF", 0).value == 0xDFFF
    check parseHexUnicode16(r"\uD800\uDC00", 7).value == 0xDC00
    check parseHexUnicode16("u8336", 0).value == 0x8336

  test "parseHexUnicode16 error":
    check parseHexUnicode16("u123", 0).messageId == wFourHexDigits
    check parseHexUnicode16(r"testing \u123", 9).messageId == wFourHexDigits
    check parseHexUnicode16("u123G", 0).messageId == wFourHexDigits
    check parseHexUnicode16("u1234", 1).messageId == wFourHexDigits

  test "parseHexUnicode":
    check testParseHexUnicode("u0031", 0, 5, 0x31)
    check testParseHexUnicode("u0080", 0, 5, 0x80)
    check testParseHexUnicode("u0ff3", 0, 5, 0x0ff3)
    check testParseHexUnicode("uffff", 0, 5, 0xffff)
    check testParseHexUnicode(r"asdf \u0031", 6, 11, 0x31)
    check testParseHexUnicode("u8336", 0, 5, 0x8336)

    # High surrogate is from D800 to DBFF
    # Low surrogate is from DC00 to DFFF.

    check testParseHexUnicode(r"\uD800\uDC00", 1, 12, 0x10000)
    check testParseHexUnicode(r"\uD800\uDC01", 1, 12, 0x10001)
    check testParseHexUnicode(r"\uD800\uDFFF", 1, 12, 0x103FF)

    check testParseHexUnicode(r"\uD801\uDC00", 1, 12, 0x10400)
    check testParseHexUnicode(r"\uD801\uDC01", 1, 12, 0x10401)

    check testParseHexUnicode(r"\uDaaa\uDC00", 1, 12, 0xBA800)
    check testParseHexUnicode(r"\uDaaa\uDC01", 1, 12, 0xBA801)

    check testParseHexUnicode(r"\uDBFF\uDC00", 1, 12, 0x10FC00)
    check testParseHexUnicode(r"\uDBFF\uDC01", 1, 12, 0x10FC01)

    check testParseHexUnicode(r"\uDBFF\uDFFF", 1, 12, 0x10FFFF)

  test "test parseHexUnicode Error":
    check testParseHexUnicodeError("", 0, 0, wFourHexDigits)
    check testParseHexUnicodeError("uDC00", 0, 0, wLowSurrogateFirst)
    check testParseHexUnicodeError(r"tea \uDC00", 5, 5, wLowSurrogateFirst)

    check testParseHexUnicodeError("uD800", 0, 5, wMissingSurrogatePair)
    check testParseHexUnicodeError(r"tea \uD800", 5, 10, wMissingSurrogatePair)
    check testParseHexUnicodeError(r"tea \uD800 Earl Grey", 5, 10, wMissingSurrogatePair)
    check testParseHexUnicodeError(r"tea \uD800\nEarl Grey", 5, 10, wMissingSurrogatePair)

    check testParseHexUnicodeError(r"tea \uD800\u12VV Grey", 5, 11, wFourHexDigits)

    check testParseHexUnicodeError(r"tea \uD800\u1234 Grey", 5, 11, wInvalidLowSurrogate)

  test "parseHexUnicodeToString":
    check testParseHexUnicodeToString("u0031", 0, 5, "1")
    check testParseHexUnicodeToString("u00A9", 0, 5, "\u00A9")
    check testParseHexUnicodeToString("u00A9", 0, 5, "\u00A9")
    check testParseHexUnicodeToString("u2010", 0, 5, "\u2010")
    check testParseHexUnicodeToString("u2020", 0, 5, "\u2020")
    check testParseHexUnicodeToString(r"\uD835\uDC9C", 1, 12, "\xF0\x9D\x92\x9C") # U+1D49C
    check testParseHexUnicodeToString(r"\uD800\uDC00", 1, 12, "\xF0\x90\x80\x80") # U+10000
    check testParseHexUnicodeToString(r"1=\u0031", 3, 8, "1")
    # check testParseHexUnicodeToString("u8336", 0, 5, "茶")
    check testParseHexUnicodeToString("u8336", 0, 5, "\xE8\x8C\xB6")

  test "parseHexUnicodeToString error":
    var pos: Natural = 1
    check parseHexUnicodeToString(r"\uDC00 tea", pos).messageId == wLowSurrogateFirst
    check pos == 1
