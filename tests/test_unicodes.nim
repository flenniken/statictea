import std/unittest
import std/options
import std/strutils
import std/unicode
import std/osproc
import std/os
import unicodes
import regexes

func parseInvalidLine(line: string): Option[(int, string)] =
  ## Parse line "invalid at pos nnn: string".
  let pattern = r"invalid at pos ([0-9]+): (.*)$"
  let matchesO = matchPattern(line, pattern)
  if not matchesO.isSome:
    return
  let (strPos, str) = matchesO.get().get2Groups()
  var pos: int
  try:
    pos = parseInt(strPos)
  except ValueError:
    return
  result = some((pos, str))

proc testValidateUtf8String(filename: string): bool =
  ## Validate the validateUtf8String method by processing all the
  ## lines in the given file.

  ## Process all the lines in the file. There are four types of
  ## lines. The comment and blank lines are skipped.
  ##
  ## Line types:
  ## # comment line\n
  ## <blank line>
  ## valid: string\n
  ## invalid at pos 0: string\n

  if not fileExists(filename):
    echo "The file does not exist: " & filename
    return false

  var file: File
  if not open(file, filename, fmRead):
    echo "Unable to open the file: $1" % [filename]
    return false
  defer:
    file.close()

  var beValid: bool
  var ePos: int
  var str: string
  var lineNum = 0
  result = true

  for line in lines(file):
    inc(lineNum)
    if line.len == 0:
      continue
    elif line.startswith("#"):
      continue
    elif line.startswith("valid: "):
      beValid = true
      str = line[7 .. line.len-1]
    elif line.startswith("invalid at pos "):
      let posStrO = parseInvalidLine(line)
      if not posStrO.isSome:
        echo "Line $1 invalid integer position." % [$lineNum]
        result = false
        continue
      (ePos, str) = posStrO.get()
      beValid = false
    else:
      echo "Line $1 not one of the four expected lines types." % $lineNum
      result = false

    let pos = validateUtf8String(str)

    if beValid:
      if pos != -1:
        echo "Line $1 is invalid but expected to be valid." % $lineNum
        result = false
    else:
      if pos != ePos:
        echo "Line $1: expected invalid pos: $2" % [$lineNum, $ePos]
        echo "Line $1:      got invalid pos: $2" % [$lineNum, $pos]
        result = false


proc testUtf8CharString(text: string, start: Natural, eStr: string, ePos: Natural): bool =
  var pos = start
  let gotStr = utf8CharString(text, pos)
  result = true
  if gotStr != eStr:
    echo "expected: " & eStr
    echo "     got: " & gotStr
    result = false
  if pos != ePos:
    echo "expected pos: " & $ePos
    echo "     got pos: " & $pos
    result = false

  if result == false:
    let rune = runeAt(text, start)
    echo "rune = " & $rune
    echo "rune hex = " & toHex(int32(rune))
    echo "utf-8 hex = " & toHex(toUtf8(rune))

proc testUtf8CharStringError(text: string, start: Natural, ePos: Natural): bool =
  var pos = start
  let gotStr = utf8CharString(text, pos)
  result = true
  if gotStr != "":
    result = false
  if pos != ePos:
    result = false
  if result == false:
    echo "expected empty string"
    echo ""
    echo "input text: " & text
    echo "input text as hex: " & toHex(text)
    echo "start pos: " & $start
    echo ""
    echo "expected pos: " & $ePos
    echo "     got pos: " & $pos
    echo ""
    echo "len: $1, got: '$2'" % [$gotStr.len, gotStr]
    echo "got as hex: " & toHex(gotStr)

    # validate the input text.
    var invalidPos = validateUtf8(text)
    if invalidPos != -1:
      echo "validateUtf8 reports the text is valid."
    else:
      echo "validateUtf8 reports invalid pos: " & $invalidPos

    # Run iconv on the character.
    let filename = "tempfile.txt"
    var file = open(filename, fmWrite)
    file.write(text[start .. text.len-1])
    file.close()
    let rc = execCmd("iconv -f UTF-8 -t UTF-8 $1" % filename)
    echo "iconv returns: " & $rc
    discard tryRemoveFile(filename)

suite "unicodes.nim":

  test "test me":
    check 1 == 1

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

  test "parseInvalidLine":
    check parseInvalidLine("invalid at pos 0: abc") == some((0, "abc"))
    check parseInvalidLine("invalid at pos 2: abc") == some((2, "abc"))
    check parseInvalidLine("invalid at pos 12: abc") == some((12, "abc"))
    check parseInvalidLine("invalid at pos 123: abc") == some((123, "abc"))
    check parseInvalidLine("invalid at pos 0: a") == some((0, "a"))
    check parseInvalidLine("invalid at pos 0: \x31") == some((0, "1"))

  test "parseInvalidLine error":
    check parseInvalidLine("invalid pos 0: abc") == none((int, string))
    check parseInvalidLine("invalid at pos: abc") == none((int, string))
    check parseInvalidLine("invalid at pos x: abc") == none((int, string))

  test "testValidateUtf8String":
    let filename = "testfiles/utf8tests.txt"
    check testValidateUtf8String(filename)
    discard tryRemoveFile(filename)

  test "firstInvalidUtf8":
    check not firstInvalidUtf8("abc").isSome

  test "countCodePoints":
    var count = 0
    let ret = countCodePoints("abc", count)
    check count == 3
    check ret == 0

  test "countCodePoints Impossible bytes FE":
    var str = bytesToString([0xFEu8])
    var count = 0
    let ret = countCodePoints(str, count)
    check ret != 0

  test "countCodePoints over long ascii":
    var str = bytesToString([0xc0u8, 0xaf])
    var count = 0
    let ret = countCodePoints(str, count)
    check ret != 0

  test "countCodePoints ed a0 80":
    var str = bytesToString([0xedu8, 0xa0, 0x80])
    var count = 0
    let ret = countCodePoints(str, count)
    check ret != 0

  test "validateUtf8String":
    check validateUtf8String("abc") == -1

  test "validateUtf8String with fe in it":
    var str = bytesToString(['a', 'b', 'c', char(0xFE), 'd'])
    check validateUtf8String(str) == 3

  test "validateUtf8String Single UTF-16 surrogates":
    var str = bytesToString([0xedu8, 0xa0, 0x80])
    check validateUtf8String(str) == 1





#   test "utf8CharString abc":
#     check testUtf8CharString("a", 0, "a", 1)
#     check testUtf8CharString("ab", 0, "a", 1)
#     check testUtf8CharString("ab", 1, "b", 2)
#     check testUtf8CharString("abc", 0, "a", 1)
#     check testUtf8CharString("abc", 1, "b", 2)
#     check testUtf8CharString("abc", 2, "c", 3)

#   # w3c has a table of unicode characters ordered by codepoint number.
#   # https://www.w3.org/TR/xml-entity-names/bycodes.html

#   # The following page you can convert the codepoint number to utf-8.
#   # https://www.cogsci.ed.ac.uk/~richard/utf-8.cgi?input=a9&mode=hex

#   test "utf8CharString U+00A9, C2 A9, COPYRIGHT SIGN":
#     check testUtf8CharString("\u00A9", 0, "©", 2)

#   test "utf8CharString U+2010, E2 80 90, HYPHEN":
#     check testUtf8CharString("\u2010", 0, "\u2010", 3)

#   test "utf8CharString U+1D49C, F0 9D 92 9C, MATHEMATICAL SCRIPT CAPITAL A":
#     check testUtf8CharString("\u{1D49C}", 0, "\u{1D49C}", 4)

#   # 2  Boundary condition test cases

#   # 2.1  First possible sequence of a certain length

#   test "utf8CharString first":
#     check testUtf8CharString("\u{00000000}", 0, "\u{00000000}", 1) # 00
#     check testUtf8CharString("\u{00000080}", 0, "\u{00000080}", 2) # C2 80
#     check testUtf8CharString("\u{00000800}", 0, "\u{00000800}", 3) # E0 A0 80
#     check testUtf8CharString("\u{00010000}", 0, "\u{00010000}", 4) # F0 90 80 80


#   # 2.2  Last possible sequence of a certain length

#   test "utf8CharString last of a certain length":
#     check testUtf8CharString("\u{0000007F}", 0, "\u{0000007F}", 1) # 7F
#     check testUtf8CharString("\u{000007FF}", 0, "\u{000007FF}", 2) # DF BF
#     check testUtf8CharString("\u{0000FFFF}", 0, "\u{0000FFFF}", 3) # EF BF BF

#   # 2.3  Other boundary conditions

#   test "utf8CharString Other boundary conditions":
#     check testUtf8CharString("\u{0000D7FF}", 0, "\u{0000D7FF}", 3) # ED 9F BF
#     check testUtf8CharString("\u{0000E000}", 0, "\u{0000E000}", 3) # EE 80 80
#     check testUtf8CharString("\u{0000FFFD}", 0, "\u{0000FFFD}", 3) # EF BF BD
#     check testUtf8CharString("\u{0010FFFF}", 0, "\u{0010FFFF}", 4) # F4 8F BF BF

#   # 3  Malformed sequences

#   # 3.1  Unexpected continuation bytes

#   # Each unexpected continuation byte should be separately signalled as a
#   # malformed sequence of its own.

#   test "utf8CharString First continuation byte 0x80 and 0xBF":
#     discard
#     # todo: are these errors:?
#     # check testUtf8CharStringError("\u{80}", 0, 1) # C2 80
#     # check testUtf8CharStringError("\u{bf}", 0, 1) # C2 BF


# # 3.1.9  Sequence of all 64 possible continuation bytes (0x80-0xbf)

# # 3.2  Lonely start characters

# # 3.2.1  All 32 first bytes of 2-byte sequences (0xc0-0xdf),
# #                              each followed by a space character

# # 3.2.2  All 16 first bytes of 3-byte sequences (0xe0-0xef)
# #        each followed by a space character

# # 3.2.3  All 8 first bytes of 4-byte sequences (0xf0-0xf7),
# #        each followed by a space character

# # 3.2.4  All 4 first bytes of 5-byte sequences (0xf8-0xfb),
# #        each followed by a space character

# # 3.2.5  All 2 first bytes of 6-byte sequences (0xfc-0xfd),
# #        each followed by a space character

# # 3.3  Sequences with last continuation byte missing

# # All bytes of an incomplete sequence should be signalled as a single
# # malformed sequence, i.e., you should see only a single replacement
# # character in each of the next 10 tests. (Characters as in section 2)

# # 2-byte sequence with last byte missing (U+0000)
# # 3-byte sequence with last byte missing (U+0000)
# # 4-byte sequence with last byte missing (U+0000)
# # 5-byte sequence with last byte missing (U+0000)
# # 6-byte sequence with last byte missing (U+0000)
# # 2-byte sequence with last byte missing (U-000007FF)
# # 3-byte sequence with last byte missing (U-0000FFFF)
# # 4-byte sequence with last byte missing (U-001FFFFF)
# # 5-byte sequence with last byte missing (U-03FFFFFF)
# # 6-byte sequence with last byte missing (U-7FFFFFFF)

# # 3.4  Concatenation of incomplete sequences

# # All the 10 sequences of 3.3 concatenated, you should see 10 malformed
# # sequences being signalled:

# # 3.5  Impossible bytes

#   test "utf8CharString Impossible bytes":
#     var str = bytesToString([0xFEu8])
#     check testUtf8CharStringError(str, 0, 1) #

# # fe
# # ff

# # 4.1  Examples of an overlong ASCII character

# # U+002F = c0 af
# # U+002F = e0 80 af
# # U+002F = f0 80 80 af
# # U+002F = f8 80 80 80 af
# # U+002F = fc 80 80 80 80 af

# # 4.2  Maximum overlong sequences

# # U-0000007F = c1 bf
# # U-000007FF = e0 9f bf
# # U-0000FFFF = f0 8f bf bf
# # U-001FFFFF = f8 87 bf bf bf
# # U-03FFFFFF = fc 83 bf bf bf bf

# # 4.3  Overlong representation of the NUL character

# # U+0000 = c0 80
# # U+0000 = e0 80 80
# # U+0000 = f0 80 80 80
# # U+0000 = f8 80 80 80 80
# # U+0000 = fc 80 80 80 80 80

# # 5.1 Single UTF-16 surrogates

# # U+D800 = ed a0 80
# # U+DB7F = ed ad bf
# # U+DB80 = ed ae 80
# # U+DBFF = ed af bf
# # U+DC00 = ed b0 80
# # U+DF80 = ed be 80
# # U+DFFF = ed bf bf

# # 5.2 Paired UTF-16 surrogates

# # U+D800 U+DC00 = ed a0 80 ed b0 80
# # U+D800 U+DFFF = ed a0 80 ed bf bf
# # U+DB7F U+DC00 = ed ad bf ed b0 80
# # U+DB7F U+DFFF = ed ad bf ed bf bf
# # U+DB80 U+DC00 = ed ae 80 ed b0 80
# # U+DB80 U+DFFF = ed ae 80 ed bf bf
# # U+DBFF U+DC00 = ed af bf ed b0 80
# # U+DBFF U+DFFF = ed af bf ed bf bf

# # 5.3 Noncharacter code positions

# # U+FFFE
# # U+FFFF

# # Other noncharacters:

# # U+FDD0
# # U+FDD1
# # U+FDD2
# # U+FDD3
# # U+FDD4
# # U+FDD5
# # U+FDD6
# # U+FDD7
# # U+FDD8
# # U+FDD9
# # U+FDDA
# # U+FDDB
# # U+FDDC
# # U+FDDD
# # U+FDDE
# # U+FDEF

# # U+1FFFE
# # U+2FFFE
# # U+3FFFE
# # U+4FFFE
# # U+5FFFE
# # U+6FFFE
# # U+7FFFE
# # U+8FFFE
# # U+9FFFE
# # U+AFFFE
# # U+BFFFE
# # U+CFFFE
# # U+DFFFE
# # U+EFFFE
# # U+FFFFE
# # U+10FFFE

# # U+1FFFF
# # U+2FFFF
# # U+3FFFF
# # U+4FFFF
# # U+5FFFF
# # U+6FFFF
# # U+7FFFF
# # U+8FFFF
# # U+9FFFF
# # U+AFFFF
# # U+BFFFF
# # U+CFFFF
# # U+DFFFF
# # U+EFFFF
# # U+FFFFF
# # U+10FFFF
