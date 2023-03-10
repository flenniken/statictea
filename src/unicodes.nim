## Functions that deal with Unicode.

import std/unicode
import std/strutils
import opresult
import messages
import utf8decoder
import vartypes

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
  ## bytes). If there are invalid byte sequences, they are counted too.
  var ixStartSeq: int
  var ixEndSeq: int
  var codePoint: uint32
  for _ in yieldUtf8Chars(str, ixStartSeq, ixEndSeq, codePoint):
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

  var ixStartSeq: int
  var ixEndSeq: int
  var codePoint: uint32
  for valid in yieldUtf8Chars(name, ixStartSeq, ixEndSeq, codePoint):
    if not valid:
      # Invalid UTF-8 name.
      break
    let rune = Rune(codePoint)
    if isAlpha(rune): # letters
      result.add(toLower(rune))
    elif isWhiteSpace(rune):
      result.add(toRunes("-")[0])
    elif rune.uint32 < 128: # ascii
      let str = name[ixStartSeq .. ixEndSeq]
      let ch = str[0]
      if isDigit(ch) or ch == '-' or ch == '_':
        result.add(ch)

func htmlAnchor*(name: string): string =
  ## Convert the name to a html anchor (class) name.

  # ID and NAME tokens must begin with a letter ([A-Za-z]) and may be
  # followed by any number of letters, digits ([0-9]), hyphens ("-"),
  # underscores ("_"), colons (":"), and periods (".").

  # Use letters, digits, hyphens and underscores but not the
  # troublesome : or dot.

  # Use the letters of the name and replace invalid characters with
  # underscore. Use an "a" for the first character if it doesn't start
  # with a letter.

  var firstNotLetter = true
  var ixStartSeq: int
  var ixEndSeq: int
  var codePoint: uint32
  for valid in yieldUtf8Chars(name, ixStartSeq, ixEndSeq, codePoint):
    if not valid:
      # Invalid UTF-8 name.
      break
    let rune = Rune(codePoint)

    var letter = '_'
    if rune.uint32 < 128:
      let ch = char(rune.uint32)
      case ch
      of 'a'..'z', 'A'..'Z':
        letter = ch
        firstNotLetter = false
      of '-', '_', '0'..'9':
        letter = ch
      else:
        letter = '_'

    if firstNotLetter:
      letter = 'a'
      firstNotLetter = false

    result.add(letter)

func parseHexUnicode16*(text: string, start: Natural): OpResultId[uint32] =
  ## Return the unicode code point given a 4 character unicode escape
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
  ## Return the unicode code point given a 4 or 8 character unicode escape
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
      # Unicode surrogate code points are invalid in UTF-8 strings.
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

# func stringToCodePoints*(str: string): OpResultWarn[seq[uint32]] =
#   ## Return the string as a list of code points.
#   var codePoints = newSeq[uint32]()
#   var ixStartSeq: int
#   var ixEndSeq: int
#   var codePoint: uint32
#   for valid in yieldUtf8Chars(str, ixStartSeq, ixEndSeq, codePoint):
#     if not valid:
#       # Invalid UTF-8 byte sequence at position $1.
#       return opMessageW[seq[uint32]](newWarningData(wInvalidUtf8ByteSeq,
#         $ixStartSeq, ixStartSeq))
#     codePoints.add(codePoint)
#   result = opValueW[seq[uint32]](codePoints)

func slice*(str: string, start: int, length: int): FunResult =
  ## Extract a substring from a string by its Unicode character
  ## position (not byte index). You pass the string, the substring's
  ## start index, and its length. If the length is negative, return
  ## all the characters from start to the end of the string. If the
  ## str is "" or the length is 0, return "".

  if str.len == 0 or length == 0:
    return newFunResult(newValue(""))

  # note: We are using the warning pos field to be the position of the
  # parameter with the problem.

  if start < 0:
    # The start position is less than 0.
    return newFunResultWarn(wStartPosTooSmall, 1)

  var charCount = 0 # Current number of Unicode characters.
  var ixStartSlice = 0 # Index to the start of the slice.

  var ixStartSeq: int
  var ixEndSeq: int
  var codePoint: uint32
  for valid in yieldUtf8Chars(str, ixStartSeq, ixEndSeq, codePoint):
    if not valid:
      # Invalid UTF-8 byte sequence at position $1.
      return newFunResultWarn(wInvalidUtf8ByteSeq, 0, $(charCount), charCount)
    else:
      if charCount == start:
        ixStartSlice = ixStartSeq
      inc(charCount)
      if length > 0 and charCount == start + length:
        return newFunResult(newValue(str[ixStartSlice .. ixEndSeq]))

  var messageId: MessageId
  var parameter: Natural
  if charCount <= start:
    # The start position is greater then the number of characters in the string.
    messageId = wStartPosTooBig
    parameter = 1
  elif length < 0:
    # Return from start to the end of the string.
    return newFunResult(newValue(str[ixStartSlice .. str.len - 1]))
  else:
    # The length is greater then the possible number of characters in the slice.
    messageId = wLengthTooBig
    parameter = 2
  return newFunResultWarn(messageId, parameter)

func visibleControl*(str: string, spacesToo=false): string =
  ## Return a new string with the tab and line endings and other
  ## control characters visible.

  var visibleRunes = newSeq[Rune]()
  for rune in runes(str):
    var num = uint(rune)
    # Show a special glyph for tab, carrage return and line feed and
    # other control characters.
    var top: uint
    if spacesToo:
      top = 0x20
    else:
      top = 0x1f
    if num <= top:
      num = 0x00002400 + num
    visibleRunes.add(Rune(num))
  result = $visibleRunes

func startColumn*(text: string, start: Natural, message: string = "^"): string =
  ## Return enough spaces to point at the start byte position of the
  ## given text.  This accounts for multibyte UTF-8 sequences that
  ## might be in the text.
  result = newStringOfCap(start + message.len)
  var ixFirst: int
  var ixLast: int
  var codePoint: uint32
  var byteCount = 0
  var charCount = 0
  for valid in yieldUtf8Chars(text, ixFirst, ixLast, codePoint):
    # Byte positions inside multibyte sequences except the first point
    # to the next start.
    if byteCount >= start:
      break
    byteCount += (ixLast - ixFirst + 1)
    inc(charCount)
    result.add(' ')
  result.add(message)
