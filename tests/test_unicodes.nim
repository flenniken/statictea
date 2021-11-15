import std/unittest
import std/options
import std/strutils
import std/unicode
import std/osproc
import std/os
import std/strformat
import unicodes
import regexes

const
  unableToOpen = "Unable to open the file: $1"
  validStr = "valid"
  validHexStr = "valid hex"
  invalidStr = "invalid at "
  invalidHexStr = "invalid hex at "

type
  HexLine = object
    kind: string  # validHexStr or invalidHexStr
    strPos: string
    str: string
    comment: string
    message: string

func newHexLine(kind, strPos, comment, str: string): HexLine =
  result = HexLine(kind: kind, strPos: strPos, comment: comment,
    str: str, message: "")

func newHexLineMsg(kind: string, message: string): HexLine =
  result = HexLine(kind: kind, strPos: "", comment: "", str: "", message: message)

proc iconvValidateString(str: string): bool =
  ## Validate the string using iconv. Return the position of the first
  ## invalid byte or -1.

  let filename = "tempfile.txt"
  var file = open(filename, fmWrite)
  file.write(str)
  file.close()
  result = true
  let rc = execCmd("iconv -f UTF-8 -t UTF-8 $1" % filename)
  if rc != 0:
    echo "iconv returns: " & $rc
    result = false
  discard tryRemoveFile(filename)


func hexToString*(hexString: string): Option[string] =
  ## Convert the hexString to a string.
  ## "33 34 35" -> "345"

  var str: string
  var digit = 0u8
  var firstNimble = 0u8
  var count = 0
  for ch in hexString:
    case ch
    of ' ':
      continue
    of '0' .. '9':
      digit = uint8(ord(ch) - ord('0'))
    of 'a' .. 'f':
      digit = uint8(ord(ch) - ord('a') + 10)
    of 'A' .. 'F':
      digit = uint8(ord(ch) - ord('A') + 10)
    else:
      # Invalid hex digit.
      return
    # debugEcho fmt"digit = 0x{digit:x}"
    if count == 0:
      firstNimble = digit
      inc(count)
    else:
      let newNum = firstNimble shl 4 or digit
      # debugEcho fmt"newNum = 0x{newNum:x}"
      str.add(char(newNum))
      count = 0
  if count != 0:
    # Hex values come in pairs and we are missing the second one.
    return
  result = some(str)

func parseInvalidLine(line: string): HexLine =
  ## Parse line "invalid at nnn (comment): string".
  let pattern = r"invalid at ([0-9]+)(\s*\(.*\)){0,1}: (.*)$"
  let matchesO = matchPattern(line, pattern)
  if not matchesO.isSome:
    return newHexLineMsg(invalidStr, "Invalid line.")
  let (strPos, comment, str) = matchesO.get().get3Groups()
  return newHexLine(invalidStr, strPos, comment, str)

func parseInvalidHexLine(line: string): HexLine =
  ## Parse line "invalid hex at nnn (comment): hexString".

  let pattern = r"invalid hex at ([0-9]+)(\s*\([^:]*\)){0,1}: (.*)$"
  let matchesO = matchPattern(line, pattern)
  if not matchesO.isSome:
    return newHexLineMsg(invalidHexStr, "Invalid integer position.")
  let (strPos, comment, hexString) = matchesO.get().get3Groups()
  let strO = hexToString(hexString)
  if not strO.isSome:
    return newHexLineMsg(invalidHexStr, "Invalid hex string.")
  result = newHexLine(invalidHexStr, strPos, comment, strO.get())

proc rewriteUtf8TestFile(filename: string, resultFilename: string): string =
  ## Rewrite the given utf8 test file replacing the hexStrings with
  ## byte strings. Convert "valid hex" and "invalid hex" lines to
  ## "valid" and "invalid" lines. If there is an error, return a
  ## message telling what went wrong.
  ##
  ## Line types:
  ##
  ## # comment line
  ## <blank line>
  ##
  ## valid [(comment)]:: string
  ## valid hex [(comment)]: hexString
  ## invalid at pos [(comment)]: string
  ## invalid hex at pos [(comment)]: hexString

  if not fileExists(filename):
    return "The file does not exist: " & filename

  var resultfile: File
  if not open(resultfile, resultFilename, fmWrite):
    return unableToOpen % [resultFilename]
  defer:
    resultfile.close()

  var file: File
  if not open(file, filename, fmRead):
    return unableToOpen % [filename]
  defer:
    file.close()

  var str: string
  var lineNum = 0

  for line in lines(file):
    inc(lineNum)
    if line.len == 0:
      resultFile.write("\n")
      continue
    var wroteLine = false
    for starts in ["#", validStr, invalidStr]:
      if line.startswith(starts):
        resultFile.write(line)
        resultFile.write("\n")
        wroteLine = true
        break
    if wroteLine:
      continue
    if line.startswith(validHexStr):
      let colonPos = line.find(':')
      if colonPos == -1:
        return "Line $1: Missing colon." % [$lineNum]
      let firstPart = line[0 .. colonPos]
      let hexString = line[colonPos .. line.len-1]
      let strO = hexToString(hexString)
      if not strO.isSome:
        return "Line $1: Invalid hex string." % [$lineNum]
      str = strO.get()
      resultFile.write("$1 $2\n" % [firstPart, str])
    elif line.startswith(invalidHexStr):
      let hexLine = parseInvalidHexLine(line)
      if hexLine.message != "":
        return "Line $1: $2" % [$lineNum, hexLine.message]
      resultFile.write("$1$2$3: $4\n" % [
        invalidStr, hexLine.strPos, hexLine.comment, hexLine.str])
    else:
      return "Line $1: Not one of the expected lines types." % $lineNum

proc testValidateUtf8String(filename: string): bool =
  ## Validate the validateUtf8String method by processing all the
  ## lines in the given file.

  ## Process all the lines in the file.  The comment and blank lines
  ## are skipped.
  ##
  ## Line types:
  ##
  ## # comment line
  ## <blank line>
  ##
  ## valid: string
  ## valid hex: hexString
  ## invalid at 0: string
  ## invalid hex at 0: hexString

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
    elif line.startswith(validStr):
      beValid = true
      str = line[7 .. line.len-1]
    elif line.startswith(validHexStr):
      let hexString = line[11 .. line.len-1]
      let strO = hexToString(hexString)
      if not strO.isSome:
        # Invalid hex string.
        return
      beValid = true
      str = strO.get()
    elif line.startswith(invalidStr):
      let hexLine = parseInvalidLine(line)
      if hexLine.message != "":
        echo "Line $1: $2" % [$lineNum, hexLine.message]
        result = false
        continue
      ePos = parseInt(hexLine.strPos)
      str = hexLine.str
      beValid = false
    elif line.startswith(invalidHexStr):
      let hexLine = parseInvalidHexLine(line)
      if hexLine.message != "":
        echo "Line $1: $2" % [$lineNum, hexLine.message]
        result = false
        continue
      ePos = parseInt(hexLine.strPos)
      str = hexLine.str
      beValid = false
    else:
      echo "Line $1: not one of the expected lines types." % $lineNum
      result = false

    # let pos = iconvValidateString(str)

    let pos = validateUtf8String(str)

    if beValid:
      if pos != -1:
        echo "Line $1 is invalid but expected to be valid." % $lineNum
        result = false
    else:
      if pos == -1:
        echo fmt"Line {lineNum}: Expected invalid string but it passed validation."
        result = false
      elif pos != ePos:
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

proc testParseInvalidLine(line: string, eStrPos: string = "0",
    eComment = "", eStr = "", eMessage = ""): bool =

  let hexLine = parseInvalidLine(line)
  result = true
  if hexLine.kind != invalidStr:
    echo "expected kind: '$1'" % invalidStr
    echo "     got kind: '$1'" % hexLine.kind
    result = false
  if hexLine.strPos != eStrPos:
    echo "expected pos: '$1'" % eStrPos
    echo "     got pos: '$1'" % hexLine.strPos
    result = false
  if hexLine.comment != eComment:
    echo "expected comment: '$1'" % eComment
    echo "     got comment: '$1'" % hexLine.comment
    result = false
  if hexLine.str != eStr:
    echo "expected str: '$1'" % eStr
    echo "     got str: '$1'" % hexLine.str
    result = false
  if hexLine.message != eMessage:
    echo "expected message: '$1'" % eMessage
    echo "     got message: '$1'" % hexLine.message
    result = false



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
    check testParseInvalidLine("invalid at 0: abc", eStr = "abc")
    check testParseInvalidLine("invalid at 2: abc", eStrPos = "2", eStr = "abc")
    check testParseInvalidLine("invalid at 12: abc", eStrPos = "12", eStr = "abc")
    check testParseInvalidLine("invalid at 0: a", eStr = "a")
    check testParseInvalidLine("invalid at 0: \x31", eStr = "\x31")

  test "parseInvalidLine error":
    check testParseInvalidLine("invalid pos 0: abc", eStrPos = "",
      eMessage = "Invalid line.")
    check testParseInvalidLine("invalid at: abc", eStrPos = "",
      eMessage = "Invalid line.")
    check testParseInvalidLine("invalid at x: abc", eStrPos = "",
      eMessage = "Invalid line.")

  test "testValidateUtf8String":
    let filename = "testfiles/utf8tests.txt"
    check testValidateUtf8String(filename)

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
    check validateUtf8String(str) == 0

  test "hexToString":
    check hexToString("33 34 35") == some("345")
    check hexToString("01 14") == some("\x01\x14")
    check hexToString("ab") == some("\xab")
    check hexToString("cf") == some("\xcf")
    check hexToString("FF") == some("\xff")
    check hexToString("112233445566778899aabbccddeeff") == some(
      "\x11\x22\x33\x44\x55\x66\x77\x88\x99\xaa\xbb\xcc\xdd\xee\xff")
    check hexToString("0123456789abcdef") == some(
      "\x01\x23\x45\x67\x89\xab\xcd\xef")

  test "hexToString error":
    check hexToString("3") == none(string)
    check hexToString("123") == none(string)
    check hexToString("ag") == none(string)


  test "parseInvalidHexLine":
    check parseInvalidHexLine("invalid hex at 0: 31") == newHexLine(
      invalidHexStr, "0", "", "1")
    check parseInvalidHexLine("invalid hex at 22: 31 33 35") == newHexLine(
      invalidHexStr, "22", "", "135")
    check parseInvalidHexLine("invalid hex at 123: 313335") == newHexLine(
      invalidHexStr, "123", "", "135")
    check parseInvalidHexLine("invalid hex at 0 (a comment): 31") == newHexLine(
      invalidHexStr, "0", " (a comment)", "1")

  test "parseInvalidHexLine error":
    check parseInvalidHexLine("invalid hex at five: 2") == newHexLineMsg(
      invalidHexStr, "Invalid integer position.")
    check parseInvalidHexLine("invalid hex at 0: 12 3") == newHexLineMsg(
      invalidHexStr, "Invalid hex string.")
    check parseInvalidHexLine("invalid hex at 0: a2 g3") == newHexLineMsg(
      invalidHexStr, "Invalid hex string.")



#   test "utf8CharString abc":
#     check testUtf8CharString("a", 0, "a", 1)
#     check testUtf8CharString("ab", 0, "a", 1)
#     check testUtf8CharString("ab", 1, "b", 2)
#     check testUtf8CharString("abc", 0, "a", 1)
#     check testUtf8CharString("abc", 1, "b", 2)
#     check testUtf8CharString("abc", 2, "c", 3)
  test "rewriteUtf8TestFile":
    check rewriteUtf8TestFile("testfiles/utf8tests.txt", "testfiles/utf8tests.bin") == ""
