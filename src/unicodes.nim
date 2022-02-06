## Functions that deal with Unicode.

import std/unicode
import std/options
import std/strutils
import opresultid
import opresultwarn
import messages
import warnings
import utf8decoder

type
  Utf8ByteSeq* = object
    ## Holds one information about one UTF-8 byte sequence.
    str*: string
    ixStartChar*: int
    ixEndChar*: int
    codePoint*: uint32
    invalid*: bool

func newUtf8ByteSeq(str: string, ixStartChar: int, ixEndChar: int,
    codePoint: uint32): Utf8ByteSeq =
  result = Utf8ByteSeq(str: str, ixStartChar: ixStartChar,
    ixEndChar: ixEndChar, codePoint: codePoint, invalid: false)

func newUtf8ByteSeqInvalid(str: string, ixStartChar: int, ixEndChar: int): Utf8ByteSeq =
  result = Utf8ByteSeq(str: str, ixStartChar: ixStartChar,
    ixEndChar: ixEndChar, codePoint: 0, invalid: true)

iterator yieldUtf8Chars*(str: string): Utf8ByteSeq =
  ## Iterate through the UTF-8 character byte sequences of the string.
  ## @:
  ## @:A UTF-8 character is a one to four byte sequence.

  # Index in the string to the start of the current character.
  var ixStartChar = 0

  var codePoint: uint32 = 0
  var state: uint32 = 0
  var ix: int
  for ix, sByte in str:
    decode(state, codePoint, sByte)
    if state == 12:
      # Invalid UTF-8 byte sequence at position {ixStartChar}.
      yield newUtf8ByteSeqInvalid(str[ixStartChar .. ix], ixStartChar, ix)
      ixStartChar = ix + 1
      state = 0
      codePoint = 0
    elif state == 0:
      yield newUtf8ByteSeq(str[ixStartChar .. ix], ixStartChar, ix, codePoint)
      ixStartChar = ix + 1

  if state != 0:
    # Invalid UTF-8 byte sequence at position {ixStartChar}.
    yield newUtf8ByteSeqInvalid(str[ixStartChar .. ix], ixStartChar, ix)

func cmpString*(a, b: string, insensitive: bool = false): int =
  ## Compares two UTF-8 strings a and b.  When a equals b return 0,
  ## when a is greater than b return 1 and when a is less than b
  ## return -1. Optionally ignore case.
  var i = 0
  var j = 0
  var ar, br: Rune
  var ret: int
  while i < a.len and j < b.len:
    fastRuneAt(a, i, ar)
    fastRuneAt(b, j, br)
    if insensitive:
      ar = toLower(ar)
      br = toLower(br)
    ret = int(ar) - int(br)
    if ret != 0:
      break
  if ret == 0:
    ret = a.len - b.len
  if ret < 0:
    result = -1
  elif ret > 0:
    result = 1
  else:
    result = 0

func stringLen*(str: string): Natural =
  ## Return the number of unicode characters in the string (not
  ## bytes). If there are invalid byte sequences they are counted too.
  for _ in yieldUtf8Chars(str):
    inc(result)

func githubAnchor*(name: string): string =
  ## Convert the name to a github anchor name.

  # You can test how well it matches github's algorithm by
  # inspecting the html code it generates.  Inspect the headings.
  #
  # The code that creates the anchors is here:
  # https://github.com/jch/html-pipeline/blob/master/lib/html/pipeline/toc_filter.rb
  #
  # Rules:
  # * lowercase letters
  # * change whitespace to hyphens
  # * allow ascii digits or hyphens
  # * drop punctuation characters, not [a-zA-Z0-9_]

  var anchorRunes = newSeq[Rune]()
  for rune in runes(name):
    if isAlpha(rune): # letters
      anchorRunes.add(toLower(rune))
    elif isWhiteSpace(rune):
      anchorRunes.add(toRunes("-")[0])
    elif rune.uint32 < 128: # ascii
      let ch = toUTF8(rune)[0]
      if isDigit(ch) or ch == '-' or ch == '_':
        anchorRunes.add(rune)
  result = $anchorRunes

func bytesToString*(buffer: openArray[uint8|char]): string =
  ## Create a string from bytes in a buffer. A nim string is UTF-8
  ## incoded but it isn't validated so it is just a string of bytes.
  if buffer.len == 0:
    return ""
  result = newStringOfCap(buffer.len)
  for ix in 0 .. buffer.len-1:
    result.add((char)buffer[ix])

func parseHexUnicode16*(text: string, start: Natural): OpResultId[uint32] =
  ## Return the unicode number given a 4 character unicode escape
  ## string like u1234. Start is pointing at the u. On error, return a
  ## message id telling what went wrong.

  if start + 5 > text.len:
    return opMessage[uint32](wFourHexDigits)

  var pos = start
  inc(pos)

  var num = 0
  for shift in [12, 8, 4, 0]:
    # 0000 0000 0000 0000
    #u   f    f    f    f
    let digit = text[pos]
    let digitOrd = int(ord(digit))
    case digit
    of '0'..'9':
      num = num or ((digitOrd - int(ord('0'))) shl shift)
    of 'a'..'f':
      num = num or ((digitOrd - int(ord('a')) + 10) shl shift)
    of 'A'..'F':
      num = num or ((digitOrd - int(ord('A')) + 10) shl shift)
    else:
      # A \u must be followed by 4 hex digits.
      return opMessage[uint32](wFourHexDigits)
    inc(pos)
  result = opValue[uint32](uint32(num))

func parseHexUnicode*(text: string, pos: var Natural): OpResultId[uint32] =
  ## Return the unicode number given a 4 or 8 character unicode escape
  ## string. For example like u1234 or u1234\u1234. Advance the pos
  ## past the end of the escape string. Pos is initially pointing at
  ## the u. On error, return the message id telling what went wrong
  ## and pos points at the error.

  # Get the hex value.
  let numOrc = parseHexUnicode16(text, pos)
  if numOrc.isMessage:
    return numOrc
  var num = numOrc.value

  # High surrogate is from D800 to DBFF
  # Low surrogate is from DC00 to DFFF.

  # The first 16 can be anything but a low surrogate.
  if num >= 0xDC00 and num <= 0xDFFF:
    # You cannot use a low surrogate by itself or first in a pair.
    return opMessage[uint32](wLowSurrogateFirst)
  pos += 5

  # If not a high surrogate character, return it.
  if num < 0xD800 or num > 0xDBFF:
    return opValue[uint32](num)

  # The value is a high surrogate, we needed a low surrogate to make a
  # pair.
  let highSurrogate = num

  if pos + 6 > text.len or text[pos] != '\\' or text[pos+1] != 'u':
    # Missing the low surrogate.
    return opMessage[uint32](wMissingSurrogatePair)

  inc(pos)

  let lowSurrogateOr = parseHexUnicode16(text, pos)
  if lowSurrogateOr.isMessage:
    return lowSurrogateOr
  var lowSurrogate = lowSurrogateOr.value

  # Make sure we got a low surrogate.
  if lowSurrogate < 0xDC00 or lowSurrogate > 0xDFFF:
    # Invalid low surrogate.
    return opMessage[uint32](wInvalidLowSurrogate)

  pos += 5
  let codePoint = 0x10000 + (((highSurrogate - 0xd800) shl 10) or (lowSurrogate - 0xdc00))
  result = opValue[uint32](codePoint)

func codePointToString*(codePoint: uint32): OpResultId[string] =
  ## Convert a code point to a one character UTF-8 string.
  let i = codePoint
  var str = ""
  if i < 0x80:
    str.add(chr(i))
  elif i < 0x800:
    # 110_x_xxxx
    str.add(chr((i shr 6) or 0b110_0_0000))
    # 10_xx_xxxx
    str.add(chr((i and 0b11_1111) or 0b10_00_0000))
  elif i < 0x1_0000:
    # High surrogate is from D800 to DBFF
    # Low surrogate is from DC00 to DFFF.
    if (i >= 0xD800 and i <= 0xDBFF) or (i >= 0xDC00 and i <= 0xDFFF):
      return opMessage[string](wUtf8Surrogate)
    # 1110_xxxx
    str.add(chr(i shr 12 or 0b1110_0000))
    # 10_xx_xxxx
    str.add(chr(i shr 6 and 0b11_1111 or 0b10_00_0000))
    # 10_xx_xxxx
    str.add(chr(i and 0b11_1111 or 0b10_00_0000))
  elif i < 0x11_0000:
    # 1111_0xxx
    str.add(chr(i shr 18 or 0b1111_0000))
    # 10_xx_xxxx
    str.add(chr(i shr 12 and 0b11_1111 or 0b10_0000_00))
    # 10_xx_xxxx
    str.add(chr(i shr 6 and 0b11_1111 or 0b10_0000_00))
    # 10_xx_xxxx
    str.add(chr(i and 0b11_1111 or 0b10_0000_00))
  else:
    # Code point too big.
    return opMessage[string](wCodePointTooBig)

  result = opValue[string](str)

func codePointsToString*(codePoints: seq[uint32]): OpResultId[string] =
  ## Convert a list of code points to a string.
  var str: string
  for codePoint in codePoints:
    let charStrOr = codePointToString(codePoint)
    if charStrOr.isMessage:
      return charStrOr
    str.add(charStrOr.value)
  result = opValue[string](str)

func parseHexUnicodeToString*(text: string, pos: var Natural): OpResultId[string] =
  ## Return a one character string given a 4 or 8 character unicode
  ## escape string. For example like u1234 or u1234\u1234. Advance the
  ## pos past the end of the escape string. Pos is initially pointing
  ## at the u. On error, return the message id telling what went wrong
  ## and pos points at the error.

  let numOrc = parseHexUnicode(text, pos)
  if numOrc.isMessage:
    return opMessage[string](numOrc.message)
  result = codePointToString(numOrc.value)

func stringToCodePoints*(str: string): OpResultWarn[seq[uint32]] =
  ## Return the string as a list of code points.
  var codePoints = newSeq[uint32]()
  for utf8Chars in yieldUtf8Chars(str):
    if utf8Chars.invalid:
      # Invalid UTF-8 byte sequence at position {utf8Chars.ixStartChar}.
      # todo use character position instead of byte positions here?
      return opMessageW[seq[uint32]](newWarningData(wInvalidUtf8ByteSeq,
        $(utf8Chars.ixStartChar)))
    codePoints.add(utf8Chars.codePoint)
  result = opValueW[seq[uint32]](codePoints)

func slice*(str: string, start: int, length: int): OpResultWarn[string] =
  ## Extract a substring from a string by its Unicode character
  ## position (not byte index). You pass the string, the substring's
  ## start index, and its length. If the length is negative, return all the
  ## characters from start to the end of the string.

  if length == 0:
    return opValueW[string]("")

  if start < 0:
    # The start position is less than 0.
    return opMessageW[string](newWarningData(wStartPosTooSmall))

  var charCount = 0 # Current number of Unicode characters.
  var ixStartSlice = 0 # Index to the start of the slice.

  for utf8Chars in yieldUtf8Chars(str):
    if utf8Chars.invalid:
      # Invalid UTF-8 byte sequence at position $1.
      return opMessageW[string](newWarningData(wInvalidUtf8ByteSeq, $(charCount)))
    else:
      if charCount == start:
        ixStartSlice = utf8Chars.ixStartChar
      inc(charCount)
      if length > 0 and charCount == start + length:
        return opValueW[string](str[ixStartSlice .. utf8Chars.ixEndChar])

  var messageId: MessageId
  if charCount < start:
    # The start position is greater then the number of characters in the string.
    messageId = wStartPosTooBig
  elif length < 0:
    # Return from start to the end of the string.
    return opValueW[string](str[ixStartSlice .. str.len - 1])
  else:
    # The length is greater then the possible number of characters in the slice.
    messageId = wLengthTooBig
  result = opMessageW[string](newWarningData(messageId))
