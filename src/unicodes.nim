## Functions that deal with Unicode.

import std/unicode
import std/options
import std/strutils

func cmpString*(a, b: string, insensitive: bool = false): int =
  ## Compares two utf8 strings a and b.  When a equals b return 0,
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

func firstInvalidUtf8*(str: string): Option[int] =
  ## Return the position of the first invalid utf-8 byte in the string
  ## if any.
  var pos = validateUtf8(str)
  if pos != -1:
    result = some(pos)

func stringLen*(str: string): Natural =
  ## Return the number of unicode characters in the string (not
  ## bytes).
  result = runeLen(str)

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

# proc utf8CharString*(text: string, pos: var int): string =
#   ## Get the unicode character at pos and increment pos one past
#   ## it. Return a one character string. Return "" when not a utf-8
#   ## character.
#   let rune = runeAt(text, pos)
#   # echo "rune = " & $rune
#   # echo "rune = " & toHex(int32(rune))
#   if rune == Rune(0xfffd):
#     # 0xfffd replaces invalid characters but 0xfffd by itself is
#     # ok. 0xfffd in utf-8 is EFBFDB.
#     if not (text.len >= pos+2 and text[pos..pos+2] == "\xEF\xBF\xBD"):
#       # Invalid utf-8 unicode character.
#       return ""
#   result = toUtf8(rune)

#   pos += result.len

proc bytesToString*(buffer: openArray[uint8|char]): string =
  ## Create a string from bytes in a buffer. A nim string is utf-8
  ## incoded but it isn't validated so it is just a string of bytes.
  if buffer.len == 0:
    return ""
  result = newStringOfCap(buffer.len)
  for ix in 0 .. buffer.len-1:
    result.add((char)buffer[ix])



# http://bjoern.hoehrmann.de/utf-8/decoder/dfa/

# Copyright (c) 2008-2009 Bjoern Hoehrmann <bjoern@hoehrmann.de>

# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


#define UTF8_ACCEPT 0
#define UTF8_REJECT 12

const
  # The first part of the table maps bytes to character classes that
  # to reduce the size of the transition table and create bitmasks.
  utf8d = [
   0u8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,  9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
     7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,  7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
     8,8,2,2,2,2,2,2,2,2,2,2,2,2,2,2,  2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
    10,3,3,3,3,3,3,3,3,3,3,3,3,4,3,3, 11,6,6,6,5,8,8,8,8,8,8,8,8,8,8,8,

    # The second part is a transition table that maps a combination
    # of a state of the automaton and a character class to a state.
     0,12,24,36,60,96,84,12,12,12,48,72, 12,12,12,12,12,12,12,12,12,12,12,12,
    12, 0,12,12,12,12,12, 0,12, 0,12,12, 12,24,12,12,12,12,12,24,12,24,12,12,
    12,12,12,12,12,12,12,24,12,12,12,12, 12,24,12,12,12,12,12,12,12,24,12,12,
    12,12,12,12,12,12,12,36,12,36,12,12, 12,36,12,12,12,12,12,36,12,36,12,12,
    12,36,12,12,12,12,12,12,12,12,12,12,
  ]

proc decode(state: var uint32, codep: var uint32, sByte: char) =
  ## Interior part of a utf8 decoder.

  let ctype = uint32(utf8d[uint8(sByte)])
  if state != 0:
    codep = (uint32(sByte) and 0x3fu32) or (codep shl 6u32)
  else:
    codep = (0xffu32 shr ctype) and uint32(sByte)
  state = utf8d[256 + state + ctype]

proc countCodePoints*(str: string, count: var int): uint32 =
  ## Update the count parameter with the number of code points in the
  ## string.

  var codePoint: uint32
  var state: uint32 = 0

  count = 0
  for sByte in str:
    decode(state, codePoint, sByte)
    if state == 0:
      inc(count)

  result = state

proc validateUtf8String*(str: string): int =
  ## Return the position of the first invalid utf-8 byte in the string
  ## else return -1.

  var codePoint: uint32 = 0
  var state: uint32 = 0
  var byteCount = 0
  var ix: int

  for sByte in str:
    decode(state, codePoint, sByte)
    if state == 12:
      break
    if state == 0:
      byteCount = 0
    else:
      inc(byteCount)
    inc(ix)

  if state != 0:
    result = ix - byteCount
    assert result >= 0
  else:
    result = -1
