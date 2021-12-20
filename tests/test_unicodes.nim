import std/unittest
import std/options
import std/strutils
import std/os
import std/strformat
import unicodes
import regexes

const
  testIconv = false
  testNim = false
  testPython3 = false

when testNim:
  import std/unicode

when testIconv or testPython3:
  import std/osproc

const
  validStr = "valid:"
  validHexStr = "valid hex:"
  invalidStr = "invalid at "
  invalidHexStr = "invalid hex at "


type
  HexLine = object
    pos: int  # -1 means no position and the string is expected to be valid.
    comment: string
    str: string

func newHexLine(pos: int, comment: string, str: string): HexLine =
  result = HexLine(pos: pos, comment: comment, str: str)

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

func parseInvalidLine(line: string): Option[HexLine] =
  ## Parse line "invalid at nnn:[comment:] string".
  let pattern = r"invalid at ([0-9]+):([^:]*): (.*)$"
  let matchesO = matchPattern(line, pattern)
  if not matchesO.isSome:
    return
  let (strPos, comment, str) = matchesO.get().get3Groups()
  var pos: int
  try:
    pos = parseInt(strPos)
  except ValueError:
    return
  return some(newHexLine(pos, comment, str))

func parseInvalidHexLine(line: string): Option[HexLine] =
  ## Parse line "invalid hex at nnn:[comment:] hexString".

  let pattern = r"invalid hex at ([0-9]+):([^:]*): (.*)$"
  let matchesO = matchPattern(line, pattern)
  if not matchesO.isSome:
    return
  let (strPos, comment, hexString) = matchesO.get().get3Groups()
  var pos: int
  try:
    pos = parseInt(strPos)
  except ValueError:
    return
  let strO = hexToString(hexString)
  if not strO.isSome:
    return
  result = some(newHexLine(pos, comment, strO.get()))

func parseValidHexLine(line: string): Option[HexLine] =
  ## Parse line "valid hex:[comment:] hexString".

  let pattern = r"valid hex:([^:]*): (.*)$"
  let matchesO = matchPattern(line, pattern)
  if not matchesO.isSome:
    return
  let (comment, hexString) = matchesO.get().get2Groups()
  let strO = hexToString(hexString)
  if not strO.isSome:
    return
  result = some(newHexLine(-1, comment, strO.get()))

func parseValidLine(line: string): Option[HexLine] =
  ## Parse line "valid:[comment:] string".

  let pattern = r"valid:([^:]*): (.*)$"
  let matchesO = matchPattern(line, pattern)
  if not matchesO.isSome:
    return
  let (comment, str) = matchesO.get().get2Groups()
  result = some(newHexLine(-1, comment, str))

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
  ## valid: [(comment)]: string
  ## valid hex: [(comment)]: hexString
  ## invalid at pos: [(comment)]: string
  ## invalid hex at pos: [(comment)]: hexString

  if not fileExists(filename):
    return "The file does not exist: " & filename

  let unableToOpen = "Unable to open the file: $1"
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

  var lineNum = 0

  for line in lines(file):
    inc(lineNum)
    if line.len == 0:
      resultFile.write("\n")
      continue
    if line.startswith(validHexStr):
      let hexLineO = parseValidHexLine(line)
      if not hexLineO.isSome:
        return "Line $1: $2" % [$lineNum, "Incorrect line format."]
      let hexLine = hexLineO.get()
      resultFile.write("$1$2: $3\n" % [
        validStr, hexLine.comment, hexLine.str])

    elif line.startswith(invalidHexStr):
      let hexLineO = parseInvalidHexLine(line)
      if not hexLineO.isSome:
        return "Line $1: $2" % [$lineNum, "Incorrect line format."]
      let hexLine = hexLineO.get()
      resultFile.write("$1$2:$3: $4\n" % [
        invalidStr, $hexLine.pos, hexLine.comment, hexLine.str])

    else:
      var wroteLine = false
      for starts in ["#", validStr, invalidStr]:
        if line.startswith(starts):
          resultFile.write(line)
          resultFile.write("\n")
          wroteLine = true
          break
      if not wroteLine:
        return "Line $1: Not one of the expected lines types." % $lineNum

proc testValidateUtf8String(callback: proc(str: string): int ): bool =
  ## Validate the validateUtf8String method by processing all the the
  ## test cases in utf8tests.txt one by one.  The callback procedure
  ## is called for each test case. The callback returns -1 when the
  ## string is valid, else it is the position of the first invalid
  ## byte.

  # The utf8test.bin is created from the utftest.txt file by
  # rewriteUtf8TestFile.
  let filename = "testfiles/utf8tests.bin"
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
  var lineNum = 0
  result = true

  var hexLineO: Option[HexLine]
  for line in lines(file):
    inc(lineNum)
    if line.len == 0:
      continue
    elif line.startswith("#"):
      continue
    elif line.startswith(validStr):
      beValid = true
      hexLineO = parseValidLine(line)
      if not hexLineO.isSome:
        echo "Line $1: $2" % [$lineNum, "incorrect line format."]
        result = false
    elif line.startswith(invalidStr):
      beValid = false
      hexLineO = parseInvalidLine(line)
      if not hexLineO.isSome:
        echo "Line $1: $2" % [$lineNum, "incorrect line format."]
        result = false
    else:
      echo "Line $1: not one of the expected lines types." % $lineNum
      result = false

    let hexLine = hexLineO.get()

    let pos = callback(hexLine.str)

    if beValid:
      if pos != -1:
        echo "Line $1 is invalid but expected to be valid. $2" % [$lineNum, hexLine.comment]
        result = false
    else:
      if pos == -1:
        echo fmt"Line {lineNum}: Invalid string passed validation. {hexline.comment}"
        result = false
      elif pos != hexLine.pos:
        echo "Line $1: expected invalid pos: $2 $3" % [$lineNum, $hexLine.pos, $hexLine.comment]
        echo "Line $1:      got invalid pos: $2" % [$lineNum, $pos]
        result = false





    # var bytePos = hexLine.pos
    # if bytePos == -1:
    #   bytePos = 0
    # let str = utf8CharString(hexLine.str, bytePos)
    # if beValid:
    #   if str == "":
    #     echo "utf8CharString: Line $1 pos $2 is invalid but expected to be valid." % [
    #       $bytePos, $lineNum]
    #     result = false
    # else:
    #   if str != "":
    #     echo fmt"utf8CharString: Line {lineNum} pos {bytePos}: Expected invalid char but it passed validation."
    #     result = false

when testIconv:
  proc iconvValidateString(str: string): int =
    ## Validate the string using iconv. Return the position of the first
    ## invalid byte or -1.

    # Write the string to a temp file.
    let inFilename = "tempfile.txt"
    var inFile: File
    if not open(inFile, inFilename, fmWrite):
      echo "Unable to open the temp file: $1" % [inFilename]
      return 90
    inFile.write(str)
    inFile.close()
    defer:
      discard tryRemoveFile(inFilename)

    # Run iconv on the in file to generate the out file.
    let outFilename = "iconv-result.txt"
    discard tryRemoveFile(outFilename)
    discard execCmd("iconv --byte-subst='@' -f UTF-8 -t UTF-8 $1 >$2 2>/dev/null" % [
      inFilename, outFilename])
    if not fileExists(outFilename):
      echo "Iconv did not generate a result file."
      return 91
    defer:
      discard tryRemoveFile(outFilename)

    # Read the output file generated by iconv into memory.
    var outFile: File
    if not open(outFile, outFilename, fmRead):
      echo "Unable to open the file: $1" % [outFilename]
      return 92
    defer:
      outFile.close()
      discard tryRemoveFile(outFilename)
    let text = readFile(outFilename)

    # Return -1 when iconv considers the string valid.
    if str == text:
      return -1

    # Find the @ sign in the output file for the position of the first
    # invalid byte.
    let pos = text.find('@')
    if pos == -1:
      # Iconv considers the string invalid but it did not mark an invalid byte.
      echo "original: "
      echo " decoded: "
      return 99
    return pos

when testPython3:
  proc pythonValidateString(str: string): int =
    ## Validate the string using python 3. Return the position of the first
    ## invalid byte or -1.

    if str.len == 0:
      return -1

    # Write the string to a temp file.
    let inFilename = "tempfile.txt"
    var inFile: File
    if not open(inFile, inFilename, fmWrite):
      echo "Unable to open the temp file: $1" % [inFilename]
      return 90
    inFile.write(str)
    inFile.close()
    defer:
      discard tryRemoveFile(inFilename)

    # Run python on the in file to generate the out file.
    let outFilename = "python-results.txt"
    discard tryRemoveFile(outFilename)
    discard execCmd("python3 testfiles/bytesToUtf8.py $1 $2" % [
      inFilename, outFilename])
    if not fileExists(outFilename):
      echo "Python decode.py did not generate a result file."
      return 91
    defer:
      discard tryRemoveFile(outFilename)

    # Read the output file generated by python decode.py into memory.
    var outFile: File
    if not open(outFile, outFilename, fmRead):
      echo "Unable to open the file: $1" % [outFilename]
      return 92
    defer:
      outFile.close()
      discard tryRemoveFile(outFilename)
    let text = readFile(outFilename)

    if text.len == 0:
      return 0

    # Find the first byte difference between the input and output.
    for ix, ch in text:
      if ix >= str.len or ch != str[ix]:
        return ix
    return -1 # valid utf8



# todo: test Utf8CharString

# proc testUtf8CharString(text: string, start: Natural, eStr: string, ePos: Natural): bool =
#   var pos = start
#   let gotStr = utf8CharString(text, pos)
#   result = true
#   if gotStr != eStr:
#     echo "expected: " & eStr
#     echo "     got: " & gotStr
#     result = false
#   if pos != ePos:
#     echo "expected pos: " & $ePos
#     echo "     got pos: " & $pos
#     result = false

#   if result == false:
#     let rune = runeAt(text, start)
#     echo "rune = " & $rune
#     echo "rune hex = " & toHex(int32(rune))
#     echo "utf-8 hex = " & toHex(toUtf8(rune))

# proc testUtf8CharStringError(text: string, start: Natural, ePos: Natural): bool =
#   var pos = start
#   let gotStr = utf8CharString(text, pos)
#   result = true
#   if gotStr != "":
#     result = false
#   if pos != ePos:
#     result = false
#   if result == false:
#     echo "expected empty string"
#     echo ""
#     echo "input text: " & text
#     echo "input text as hex: " & toHex(text)
#     echo "start pos: " & $start
#     echo ""
#     echo "expected pos: " & $ePos
#     echo "     got pos: " & $pos
#     echo ""
#     echo "len: $1, got: '$2'" % [$gotStr.len, gotStr]
#     echo "got as hex: " & toHex(gotStr)

#     # validate the input text.
#     var invalidPos = validateUtf8(text)
#     if invalidPos != -1:
#       echo "validateUtf8 reports the text is valid."
#     else:
#       echo "validateUtf8 reports invalid pos: " & $invalidPos

#     # Run iconv on the character.
#     let filename = "tempfile.txt"
#     var file = open(filename, fmWrite)
#     file.write(text[start .. text.len-1])
#     file.close()
#     let rc = execCmd("iconv -f UTF-8 -t UTF-8 $1" % filename)
#     echo "iconv returns: " & $rc
#     discard tryRemoveFile(filename)

proc testParseLine(line: string, ePos: int = 0,
    eComment = "", eStr = ""): bool =

  result = true

  var hexLineO: Option[HexLine]
  if line.startsWith(validStr):
    hexLineO = parseValidLine(line)
  elif line.startsWith(invalidStr):
    hexLineO = parseInvalidLine(line)
  elif line.startsWith(validHexStr):
    hexLineO = parseValidHexLine(line)
  elif line.startsWith(invalidHexStr):
    hexLineO = parseInvalidHexLine(line)
  else:
    echo "The line doesn't start correctly."
    return false

  if not hexLineO.isSome:
    echo "Unable to parse the line."
    return false

  let hexLine = hexLineO.get()
  if hexLine.pos != ePos:
    echo "expected pos: '$1'" % $ePos
    echo "     got pos: '$1'" % $hexLine.pos
    result = false
  if hexLine.comment != eComment:
    echo "expected comment: '$1'" % eComment
    echo "     got comment: '$1'" % hexLine.comment
    result = false
  if hexLine.str != eStr:
    echo "expected str: '$1'" % eStr
    echo "     got str: '$1'" % hexLine.str
    result = false

proc testParseLineError(line: string): bool =
  var hexLineO: Option[HexLine]
  if line.startsWith(validStr):
    hexLineO = parseValidLine(line)
  elif line.startsWith(invalidStr):
    hexLineO = parseInvalidLine(line)
  elif line.startsWith(validHexStr):
    hexLineO = parseValidHexLine(line)
  elif line.startsWith(invalidHexStr):
    hexLineO = parseInvalidHexLine(line)
  else:
    return true
  if hexLineO.isSome:
    echo "Parsed the line when we expected not be able to."
    return false
  result = true

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

  test "parseValidLine":
    check testParseLine("valid:: 31", -1, "", "31")
    check testParseLine("valid: (hello): 31", -1, " (hello)", "31")
    check testParseLine("valid: (U+2010, E2 80 90, HYPHEN): asdf",
      -1, " (U+2010, E2 80 90, HYPHEN)", "asdf")
    check testParseLine("valid: : 31", -1, " ", "31")

  test "parseValidLineError":
    check testParseLineError("valid::31")
    check testParseLineError("valid::")
    check testParseLineError("valid: 33")
    check testParseLineError("valid fg")

  test "parseInvalidLine":
    check testParseLine("invalid at 0:: 31", 0, "", "31")
    check testParseLine("invalid at 1: (hello): 31", 1, " (hello)", "31")
    check testParseLine("invalid at 2: (U+2010, E2 80 90, HYPHEN): asdf",
      2, " (U+2010, E2 80 90, HYPHEN)", "asdf")
    check testParseLine("invalid at 0: : 31", 0, " ", "31")

  test "parseInvalidLineError":
    check testParseLineError("invalid at ss:: 31")
    check testParseLineError("invalid at 0")
    check testParseLineError("invalid at :abc: 33")
    check testParseLineError("invalid at 0::")
    check testParseLineError("invalid at 0: 55")

  test "parseValidHexLine":
    check testParseLine("valid hex: (U+00A9): C2 A9", -1, " (U+00A9)", "\xc2\xa9")
    check testParseLine("valid hex:: 31", -1, "", "1")
    check testParseLine("valid hex: (hello): 31", -1, " (hello)", "1")
    check testParseLine("valid hex: (U+2010, E2 80 90, HYPHEN): E2 80 90",
      -1, " (U+2010, E2 80 90, HYPHEN)", "\xe2\x80\x90")

  test "parseValidHexLineError":
    check testParseLineError("valid hex 31")
    check testParseLineError("valid hex:")
    check testParseLineError("valid hex (:: 33")
    check testParseLineError("valid hex:: fg")
    check testParseLineError("valid hex::00")

  test "parseInvalidHexLine":
    check testParseLine("invalid hex at 0:: 31", 0, "", "1")
    check testParseLine("invalid hex at 22:: 31 33 35", 22, "", "135")
    check testParseLine("invalid hex at 123:: 313335", 123, "", "135")
    check testParseLine("invalid hex at 0: (a comment): 31", 0, " (a comment)", "1")

  test "parseInvalidHexLine error":
    check testParseLineError("invalid hex at five: 2")
    check testParseLineError("invalid hex at 0:: 12 3")
    check testParseLineError("invalid hex at 0:: a2 g3")
    check testParseLineError("invalid hex at 0: 44")

  test "testValidateUtf8String":
    let testFilename = "testfiles/utf8tests.bin"
    let msg = rewriteUtf8TestFile("testfiles/utf8tests.txt", testFilename)
    check msg == ""

    proc callback(str: string): int =
      result = validateUtf8String(str)
    check testValidateUtf8String(callback)

  when testIconv:
    test "test iconv app with utf8tests.bin":
      # Pass the utf8 test cases to iconv.
      let testFilename = "testfiles/utf8tests.bin"
      let msg = rewriteUtf8TestFile("testfiles/utf8tests.txt", testFilename)
      check msg == ""

      proc callback(str: string): int =
        result = iconvValidateString(str)
      check testValidateUtf8String(callback)

  when testNim:
    test "testValidateUtf8":
      let testFilename = "testfiles/utf8tests.bin"
      let msg = rewriteUtf8TestFile("testfiles/utf8tests.txt", testFilename)
      check msg == ""

      proc callback(str: string): int =
        result = validateUtf8(str)
      check testValidateUtf8String(callback)

  when testPython3:
    test "test validate utf8 python":
      let testFilename = "testfiles/utf8tests.bin"
      let msg = rewriteUtf8TestFile("testfiles/utf8tests.txt", testFilename)
      check msg == ""

      proc callback(str: string): int =
        result = pythonValidateString(str)
      check testValidateUtf8String(callback)
