import std/unittest
import std/strformat
import std/strutils
import unicodes
import opresultid
import opresultwarn
import messages
import warnings

func stringToHex(str: string): string =
  ## Convert the string bytes to hex bytes like 34 a9 ff e2.
  var digits: seq[string]
  for ch in str:
    let abyte = uint8(ord(ch))
    digits.add(fmt"{abyte:02x}")
  result = digits.join(" ")

proc testSlice(str: string, start: int, length: int, eString: string): bool =
  let stringOr = slice(str, start, length)
  if stringOr.isMessage:
    echo "Expected value got message: " & $stringOr.message
    return false
  if stringOr.value != eString:
    echo "expected: " & eString
    echo "     got: " & stringOr.value
    return false
  return true

proc testSliceWarn(str: string, start: int, length: int, eWarn: WarningData): bool =
  let stringOr = slice(str, start, length)
  if stringOr.isValue:
    echo "Expected message got value: " & $stringOr.value
    return false
  if stringOr.message != eWarn:
    echo "expected: " & $eWarn
    echo "     got: " & $stringOr.message
    return false
  return true

proc testCodePointToStringWarn(codePoint: uint32, eMessageId: MessageId): bool =
  let opResultId = codePointToString(codePoint)
  if opResultId.isValue:
    echo "expected message, got value: " & $opResultId
    return false
  if opResultId.message != eMessageId:
    echo "expected: " & $eMessageId
    echo "     got: " & $opResultId.message
    return false
  result = true

proc testCodePointsToString(codePoints: seq[uint32], eString: string): bool =
  let opResultId = codePointsToString(codePoints)
  if opResultId.isMessage:
    echo "expected value, got message: " & $opResultId
    return false
  if opResultId.value != eString:
    echo "expected: " & $eString
    echo "     got: " & $opResultId.value
    return false
  result = true

proc testCodePointsToStringWarn(codePoints: seq[uint32], eMessageId: MessageId): bool =
  let opResultId = codePointsToString(codePoints)
  if opResultId.isValue:
    echo "expected message, got value: " & $opResultId
    return false
  if opResultId.message != eMessageId:
    echo "expected: " & $eMessageId
    echo "     got: " & $opResultId.message
    return false
  result = true

proc testStringToCodePoints(str: string, eCodePoints: seq[uint32]): bool =
  let opResultWarn = stringToCodePoints(str)
  if opResultWarn.isMessage:
    echo "expected value, got message: " & $opResultWarn
    return false
  if opResultWarn.value != eCodePoints:
    echo "expected: " & $eCodePoints
    echo "     got: " & $opResultWarn.value
    return false
  result = true

proc testStringToCodePointsWarn(
    str: string,
    messageId: MessageId = wInvalidUtf8ByteSeq,
    p1: string = "",
    p2: string = ""): bool =
  let opResultWarn = stringToCodePoints(str)
  if opResultWarn.isValue:
    echo "expected warning got value: " & $opResultWarn
    return false
  result = true
  if opResultWarn.message.warning != messageId:
    echo "expected: " & $opResultWarn.message.warning
    echo "     got: " & $messageId
    result = false
  if opResultWarn.message.p1 != p1:
    echo "expected: " & $opResultWarn.message.p1
    echo "     got: " & $p1
    result = false
  if opResultWarn.message.p2 != p2:
    echo "expected: " & $opResultWarn.message.p2
    echo "     got: " & $p2
    result = false

proc testParseHexUnicodeError(text: string, pos: Natural,
    ePos: Natural, eMessageId: MessageId): bool =
  var inOutPos = pos
  let numOrId = parseHexUnicode(text, inOutPos)
  if numOrId.isValue:
    echo "parseHexUnicode passed unexpectedly."
    return false
  result = true
  if numOrId.message != eMessageId:
    echo "got unexpected message id:"
    echo "expected: " & $eMessageId
    echo "     got: " & $numOrId.message
    result = false
  if inOutPos != ePos:
    echo "got unexpected pos:"
    echo "expected: " & $ePos
    echo "     got: " & $inOutPos
    result = false


proc testParseHexUnicode(text: string, pos: Natural,
    ePos: Natural, eCodePoint: uint32): bool =
  var inOutPos = pos
  let numOrId = parseHexUnicode(text, inOutPos)
  if numOrId.isMessage:
    echo ""
    echo "parseHexUnicode failed for: " & text
    echo fmt"{numOrId.message}: {Messages[numOrId.message]}"
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
  if stringOrId.isMessage:
    echo ""
    echo "parseHexUnicodeToString failed for: " & text
    echo fmt"{stringOrId.message}: {Messages[stringOrId.message]}"
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

  test "cmpString unicode":
    # todo: test unicode
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
    check codePointToString(0xD7ff).value == "\ud7ff"

  test "codePointToString error":
    check codePointToString(0x110000).message == wCodePointTooBig

    # High surrogate is from D800 to DBFF
    # Low surrogate is from DC00 to DFFF.

    # surrogates are not valid in UTF-8
    check testCodePointToStringWarn(0xD800, wUtf8Surrogate)
    check testCodePointToStringWarn(0xDB00, wUtf8Surrogate)
    check testCodePointToStringWarn(0xDBFF, wUtf8Surrogate)
    check testCodePointToStringWarn(0xDC00, wUtf8Surrogate)
    check testCodePointToStringWarn(0xDC50, wUtf8Surrogate)
    check testCodePointToStringWarn(0xDFFF, wUtf8Surrogate)

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
    check parseHexUnicode16("u123", 0).message == wFourHexDigits
    check parseHexUnicode16(r"testing \u123", 9).message == wFourHexDigits
    check parseHexUnicode16("u123G", 0).message == wFourHexDigits
    check parseHexUnicode16("u1234", 1).message == wFourHexDigits

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

  test "parseHexUnicodeToString wLowSurrogateFirst":
    var pos: Natural = 1
    check parseHexUnicodeToString(r"\uDC00 tea", pos).message == wLowSurrogateFirst
    check pos == 1

  test "parseHexUnicodeToString missing surrogate":
    var pos: Natural = 5
    check parseHexUnicodeToString(r"tea \uD800", pos).message == wMissingSurrogatePair
    check pos == 10

  test "stringToCodePoints":
    check testStringToCodePoints("", newSeq[uint32]())
    check testStringToCodePoints("x", @[uint32(ord('x'))])
    check testStringToCodePoints("ab", @[uint32(ord('a')), ord('b')])
    check testStringToCodePoints("ab\u0080", @[uint32(ord('a')), ord('b'), 0x80])
    check testStringToCodePoints("ab\u2010", @[uint32(ord('a')), ord('b'), 0x2010])
    check testStringToCodePoints("\u{1D49C}", @[uint32(0x1D49C)])
    check testStringToCodePoints("\u{10ffff}", @[uint32(0x10ffff)])
    check testStringToCodePoints("añyóng", @[uint32(97), 241, 121, 243, 110, 103])

  test "stringToCodePoints warnings":
    check testStringToCodePointsWarn("\xff", p1 = "0")
    check testStringToCodePointsWarn("a\xffb", p1 = "1")
    check testStringToCodePointsWarn("01\xff", p1 = "2")
    # Invalid two byte sequence <e0 80>.
    check testStringToCodePointsWarn("01\xe0\x80", p1 = "2")
    # Invalid three byte sequence <f0 80 80>.
    check testStringToCodePointsWarn("01\xf0\x80\x80", p1 = "2")
    # Invalid four byte sequence <f1 80 bf 77>
    check testStringToCodePointsWarn("01\xf1\x80\xbf\x77", p1 = "2")

  test "codePointsToString":
    check testCodePointsToString(newSeq[uint32](), "")
    check testCodePointsToString(@[uint32(0x31)], "1")
    check testCodePointsToString(@[uint32(0x31), 0x32], "12")
    check testCodePointsToString(@[uint32(0x31), 0xff], "1\u00ff")

  test "codePointsToString warning":
    check testCodePointsToStringWarn(@[uint32(0x31), 0x110000], wCodePointTooBig)
    check testCodePointsToStringWarn(@[uint32(0x31), 0xD800], wUtf8Surrogate)

  test "slice":
    check testSlice("abc", 0, 0, "")
    check testSlice("abc", 0, 1, "a")
    check testSlice("abc", 0, 2, "ab")
    check testSlice("abc", 0, 3, "abc")
    check testSlice("abc", 0, -1, "abc")

    check testSlice("abc", 1, 0, "")
    check testSlice("abc", 1, 1, "b")
    check testSlice("abc", 1, 2, "bc")
    check testSlice("abc", 1, -1, "bc")

    check testSlice("abc", 2, 0, "")
    check testSlice("abc", 2, 1, "c")
    check testSlice("abc", 2, -1, "c")

    check testSlice("abc", 3, 0, "")

  test "slice length 0 or str empty":
    check testSlice("abc", 6, 0, "")
    check testSlice("", 5, 0, "")
    check testSlice("", 0, 6, "")

  test "slice warn":
    check testSliceWarn("abc", 0, 4, newWarningData(wLengthTooBig))
    check testSliceWarn("abc", 0, 4, newWarningData(wLengthTooBig))
    check testSliceWarn("abc", 1, 3, newWarningData(wLengthTooBig))
    check testSliceWarn("abc", 2, 2, newWarningData(wLengthTooBig))
    check testSliceWarn("abc", -1, 2, newWarningData(wStartPosTooSmall))

    check testSliceWarn("abc", 3, 2, newWarningData(wStartPosTooBig))

    check testSliceWarn("abc", 3, -1, newWarningData(wStartPosTooBig))
    check testSliceWarn("a", 1, -1, newWarningData(wStartPosTooBig))


  test "slice two byte":
    let str = "\xc2\xa9"
    check testSlice(str, 0, 1, str)

  test "slice three byte":
    let str = "\xe2\x80\x90"
    check testSlice(str, 0, 1, str)

  test "slice multi-byte":
    # Valid two byte character: <C2 A9>
    # Valid three byte character: <E2 80 90>
    # Valid four byte character: <F0 9D 92 9C>
    let str = "\xc2\xa9\xe2\x80\x90\xF0\x9D\x92\x9C" # 3 unicode characters

    check testSlice(str, 0, 1, "\xc2\xa9")
    check testSlice(str, 0, 2, "\xc2\xa9\xe2\x80\x90")
    check testSlice(str, 0, 3, str)
    check testSlice(str, 0, -1, str)

    check testSlice(str, 1, 1, "\xe2\x80\x90")
    check testSlice(str, 1, 2, "\xe2\x80\x90\xF0\x9D\x92\x9C")
    check testSlice(str, 1, -1, "\xe2\x80\x90\xF0\x9D\x92\x9C")

    check testSlice(str, 2, 1, "\xF0\x9D\x92\x9C")
    check testSlice(str, 2, -1, "\xF0\x9D\x92\x9C")

  test "slice before invalid":
    check testSlice("a\xff", 0, 1, "a")

  test "slice wInvalidUtf8ByteSeq":
    check testSliceWarn("\xff", 0, 1, newWarningData(wInvalidUtf8ByteSeq, "0"))
    check testSliceWarn("a\xff", 0, 2, newWarningData(wInvalidUtf8ByteSeq, "1"))
    check testSliceWarn("a\xff", 1, 1, newWarningData(wInvalidUtf8ByteSeq, "1"))

    var str = "\xc2\xa9\xe2\x80\x90\xF0\x9D\x92\x9C\xff"
    check testSliceWarn(str, 3, 1, newWarningData(wInvalidUtf8ByteSeq, "3"))

    str = "\xc2\xa9\xe2\x80\x90\xF0\x9D\x92\xc0a"
    check testSliceWarn(str, 0, 4, newWarningData(wInvalidUtf8ByteSeq, "2"))

    str = "\xc2\xa9\xe2\x80\x90\xF0\x9D\x92\xc0"
    check testSliceWarn(str, 0, 4, newWarningData(wInvalidUtf8ByteSeq, "2"))

  test "slice mult-byte warn pos":
    let str = "\xc2\xa9\xe2\x80\x90\xF0\x9D\x92\x9C" # 3 unicode characters
    check testSliceWarn(str, 0, 4, newWarningData(wLengthTooBig))
    check testSliceWarn(str, 4, 1, newWarningData(wStartPosTooBig))

  test "stringLen":
    check stringLen("") == 0
    check stringLen("a") == 1
    check stringLen("ab") == 2
    check stringLen("abc") == 3
    let str = "\xc2\xa9\xe2\x80\x90\xF0\x9D\x92\x9C" # 3 unicode characters
    check stringLen(str) == 3
    check stringLen("ab\xffc") == 4 # with one invalid

