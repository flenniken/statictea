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
  # * drop other characters

  var anchorRunes = newSeq[Rune]()
  for rune in runes(name):
    if isAlpha(rune): # letters
      anchorRunes.add(toLower(rune))
    elif isWhiteSpace(rune):
      anchorRunes.add(toRunes("-")[0])
    elif rune.uint32 < 128: # ascii
      let ch = toUTF8(rune)[0]
      if isDigit(ch) or ch == '-':
        anchorRunes.add(rune)
  result = $anchorRunes
