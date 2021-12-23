import std/unittest
import std/options
import std/strutils
import std/os
import std/strformat
import unicodes
import regexes
import std/unicode
import std/osproc

const
  testCases = "testfiles/utf8tests.txt"
  binTestCases = "testfiles/utf8tests.bin"
  expectedSkip = "testfiles/utf8tests-skip.txt"
  expectedFffd = "testfiles/utf8tests-fffd.txt"

const
  testIconv = false
  testNim = false
  testPython3 = true

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

# todo: parse both valid and invalid line types with one routine.
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

  if not fileExists(binTestCases):
    echo "Missing test file: " & binTestCases
    return false

  # The utf8test.bin is created from the utftest.txt file by
  # rewriteUtf8TestFile.
  let filename = binTestCases
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

proc writeValidUtf8FileTea(inFilename: string, outFilename: string, skipInvalid: bool): int =
  ## Read the binary file input file, which might contain invalid
  ## UTF-8 bytes, then write valid UTF-8 bytes to the output file
  ## either skipping the invalid bytes or replacing them with U-FFFD.
  ##
  ## When there is an error, display the error message to standard out
  ## and return 1, else return 0.  The input file must be under 50k.

  if not fileExists(inFilename):
    echo "The input file is missing."
    return 1
  if getFileSize(inFilename) > 50 * 1024:
    echo "The input file must be under 50k."
    return 1

  # Read the file into memory.
  var inData: string
  try:
    inData = readFile(inFilename)
  except:
    echo "Unable to open and read the input file."
    return 1

  # Process the input data assuming it is UTF-8 encoded but it contains
  # some invalid bytes. Return valid UTF-8 encoded bytes.
  let outData = sanitizeUtf8(inData, skipInvalid)

  # Write the valid UTF-8 data to the output file.
  try:
    writeFile(outFilename, outData)
  except:
    echo "Unable to open and write the output file."
    return 1

  result = 0 # success


proc sanitizeUtf8Nim*(str: string, skipInvalid: bool): string =
  ## Sanitize and return the UTF-8 string. The skipInvalid parameter
  ## determines whether to skip or replace invalid bytes.  When
  ## replacing the U-FFFD character is used.

  # Reserve space for the result string the same size as the input string.
  result = newStringOfCap(str.len)

  var ix = 0
  while true:
    if ix >= str.len:
      break
    var pos = validateUtf8(str[ix .. str.len - 1])
    if pos == -1:
      result.add(str[ix .. str.len - 1])
      break
    assert pos >= 0
    var endPos = ix + pos
    if endPos > 0:
      result.add(str[ix .. endPos - 1])
    if not skipInvalid:
      result.add("\ufffd")
    ix = endPos + 1

func hexString(str: string): string =
  ## Convert the str bytes to hex bytes like 34 a9 ff e2.
  var digits: seq[string]
  for ch in str:
    let abyte = uint8(ord(ch))
    digits.add(fmt"{abyte:02x}")
  result = digits.join(" ")

func formatGotLine(gotLine: string): string =
  ## Show the gotLine comment part followed by hex.
  ##invalid at 0: 6.0, too big U-001FFFFF, F7 BF BF BF: ????
  ##6.0, too big U-001FFFFF, (F7 BF BF BF): xx xx xx xx

  # Find the two colons.
  let firstColon = gotLine.find(':')
  assert firstColon >= 0
  let start = firstColon + 2
  assert start < gotLine.len
  let secondColon = gotLine[start .. ^1].find(':') + start
  assert secondColon >= start

  let comment = gotLine[start .. secondColon - 1]
  let bytesStart = secondColon + 2
  assert bytesStart <= gotLine.len
  let hexString = hexString(gotLine[bytesStart .. ^1])

  result = fmt"{comment}: {hexString}"

proc compareUtf8TestFiles(expectedFilename: string, gotFilename: string): bool =
  ## Return true when the two files are the same. When different, show
  ## the line differences.

  let expectedData = readFile(expectedFilename)
  let gotData = readFile(gotFilename)

  if expectedData.len != gotData.len:
    result = false
  else:
    result = true

  let expectedLines = splitLines(expectedData)
  let gotLines = splitLines(gotData)

  # Compare the file generated with the expected output line by line.
  var ix = 0
  while true:
    if ix >= expectedLines.len and ix >= gotLines.len:
      break

    var expectedLine: string
    if ix < expectedLines.len:
      expectedLine = expectedLines[ix]
    else:
      expectedLine = ""

    var gotLine: string
    if ix < gotLines.len:
      gotLine = gotLines[ix]
    else:
      gotLine = ""

    if expectedLine != gotLine:
      # echo "expected: " & expectedLine
      # echo "     got: " & gotLine
      echo formatGotLine(gotLine)

      result = false

    inc(ix)



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

proc testSanitizeutf8Empty(str: string): bool =
  ## Test that the string does not have any valid UTF-8 bytes.

  result = true
  let empty = sanitizeUtf8(str, true)
  if empty != "":
    echo "expected nothing, got: " & empty
    result = false

  let rchars = sanitizeUtf8(str, false)
  if rchars.len != str.len * 3 or rchars.len mod 3 != 0:
    echo "expected all replace characters, got: " & rchars
    result = false
  else:
    # check at all the bytes are U-FFFD (EF BF BD)
    for ix in countUp(0, rchars.len-3, 3):
      if rchars[ix] != '\xEF' or rchars[ix+1] != '\xBF' or
         rchars[ix+2] != '\xBD':
        echo "expected all replace characters, got: " & rchars
        result = false
        break

proc testSanitizeutf8(str: string, expected: string, skipInvalid = true): bool =
  ## Test that sanitizeUtf8 returns the expected string when skipping.

  result = true
  let sanitized = sanitizeUtf8(str, skipInvalid)
  if sanitized != expected:
    echo "     got: " & sanitized
    echo "expected: " & expected
    result = false



proc fileExistsAnd50kEcho(filename: string): int =
  ## Return 0 when the file exists and it is less than 50K. Otherwise
  ## echo the problem and return 1.

  if not fileExists(filename):
    echo "The input file is missing."
    return 1
  if getFileSize(filename) > 50 * 1024:
    echo "The input file must be under 50k."
    return 1
  result = 0

proc writeValidUtf8FileNim(inFilename: string, outFilename: string,
                           skipInvalid: bool): int =
  ## Read the binary file input file, which might contain invalid
  ## UTF-8 bytes, then write valid UTF-8 bytes to the output file
  ## either skipping the invalid bytes or replacing them with U-FFFD.
  ##
  ## When there is an error, display the error message to standard out
  ## and return 1, else return 0.  The input file must be under 50k.

  if fileExistsAnd50kEcho(inFilename) != 0:
    return 1

  # Read the file into memory.
  var inData: string
  try:
    inData = readFile(inFilename)
  except:
    echo "Unable to open and read the input file."
    return 1

  # Process the input data assuming it is UTF-8 encoded but it contains
  # some invalid bytes. Return valid UTF-8 encoded bytes.
  let outData = sanitizeUtf8Nim(inData, skipInvalid)

  # Write the valid UTF-8 data to the output file.
  try:
    writeFile(outFilename, outData)
  except:
    echo "Unable to open and write the output file."
    return 1

  result = 0 # success

proc writeValidUtf8FileIconv(inFilename: string, outFilename: string,
                           skipInvalid: bool): int =
  ## Read the binary file input file, which might contain invalid
  ## UTF-8 bytes, then write valid UTF-8 bytes to the output file
  ## either skipping the invalid bytes or replacing them with U-FFFD.
  ##
  ## When there is an error, display the error message to standard out
  ## and return 1, else return 0.  The input file must be under 50k.

  ## This is the version of iconv and how to get the version number:
  ## iconv --version | head -1
  ## iconv (GNU libiconv 1.11)

  if fileExistsAnd50kEcho(inFilename) != 0:
    return 1

  # Run iconv on the input file to generate the output file.
  var option: string
  if skipInvalid:
    option = "-c"
  else:
    option = "--byte-subst='(%x!)'"
    # option = "--byte-subst='\xff\xfd'"

  discard execCmd("iconv $1 -f UTF-8 -t UTF-8 $2 >$3 2>/dev/null" % [
    option, inFilename, outFilename])
  if not fileExists(outFilename) or getFileSize(outFilename) == 0:
    echo "Iconv did not generate a result file."
    result = 1
  else:
    result = 0

proc writeValidUtf8FilePython3(inFilename: string, outFilename: string,
                           skipInvalid: bool): int =
  ## Read the binary file input file, which might contain invalid
  ## UTF-8 bytes, then write valid UTF-8 bytes to the output file
  ## either skipping the invalid bytes or replacing them with U-FFFD.
  ##
  ## When there is an error, display the error message to standard out
  ## and return 1, else return 0.  The input file must be under 50k.

  if fileExistsAnd50kEcho(inFilename) != 0:
    return 1

  var option: string
  if skipInvalid:
    option = "-s"
  else:
    option = ""

  # Run a python 3 script on the input file to generate the output
  # file.
  let cmd = "python3 testfiles/writeValidUtf8.py $1 $2 $3" % [
    option, inFilename, outFilename]
  discard execCmd(cmd)

  if not fileExists(outFilename) or getFileSize(outFilename) == 0:
    echo "Python did not generate a result file."
    result = 1
  else:
    result = 0

proc generateExpectedFiles(): bool =
  ## Generate the expected files from the utf8test.txt file.

  discard tryRemoveFile(binTestCases)
  discard tryRemoveFile(expectedSkip)
  discard tryRemoveFile(expectedFffd)

  # Generate the utf8test.bin file.
  let msg = rewriteUtf8TestFile(testCases, binTestCases)
  if msg != "":
    echo msg
    return false

  check fileExists(binTestCases)

  # Generate the two expected files from the utf8test.bin file.
  result = true
  var rc: int
  rc = writeValidUtf8FileTea(binTestCases, expectedSkip, true)
  if rc != 0:
    result = false
  check fileExists(expectedSkip)

  rc = writeValidUtf8FileTea(binTestCases, expectedFffd, false)
  if rc != 0:
    result = false
  check fileExists(expectedFffd)

type
  WriteValidUtf8File = proc (inFilename, outFilename: string, skipInvalid: bool): int

proc testWriteValidUtf8File(testProc: WriteValidUtf8File, option: string = "both"): bool =
  ## Test a WriteValidUtf8File procedure.  The option parameter
  ## determines which tests get run, pass "skip", "replace", or
  ## "both".

  let binTestCases = "testfiles/utf8tests.bin"
  let expectedSkip = "testfiles/utf8tests-skip.txt"
  let expectedFffd = "testfiles/utf8tests-fffd.txt"

  if not fileExists(binTestCases):
    echo "Missing test file: " & binTestCases
    return false

  result = true
  var rc: int
  var passed: bool

  if option == "both" or option == "skip":
    # Call the write procedure with skipInvalid true.
    let gotSkipFile = "tempSkip.txt"
    rc = testProc(binTestCases, gotSkipFile, true)
    if rc != 0:
      echo "The WriteValidUtf8File procedure with skipInvalid = true failed."
      result = false

    # Compare the file generated with the expected file.
    passed = compareUtf8TestFiles(expectedSkip, gotSkipFile)
    if not passed:
      result = false
    discard tryRemoveFile(gotSkipFile)

  if option == "both" or option == "replace":
    # Call the write procedure with skipInvalid false.
    let gotFffdFile = "tempFffd.txt"
    rc = testProc(binTestCases, gotFffdFile, false)
    if rc != 0:
      echo "The WriteValidUtf8File procedure with skipInvalid = false failed."
      result = false

    # Compare the file generated with the expected file.
    passed = compareUtf8TestFiles(expectedFffd, gotFffdFile)
    if not passed:
      result = false
    discard tryRemoveFile(gotFffdFile)


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
    proc callback(str: string): int =
      result = validateUtf8String(str)
    check testValidateUtf8String(callback)

  test "sanitizeUtf8":
    check sanitizeUtf8("happy path", true) == "happy path"
    check sanitizeUtf8("happy path", false) == "happy path"

    check testSanitizeutf8Empty("\x80")
    check testSanitizeutf8Empty("\xbf")
    check testSanitizeutf8Empty("\x80\xbf")
    check testSanitizeutf8Empty("\xf8\x88\x80\x80\x80")

  test "sanitizeUtf8 all 64 possible continuation bytes":
    # 0x80-0xbf
    check testSanitizeutf8Empty("\x80\x81\x82\x83\x84\x85\x86\x87")
    check testSanitizeutf8Empty("\x88\x89\x8a\x8b\x8c\x8d\x8e\x8f")
    check testSanitizeutf8Empty("\x90\x91\x92\x93\x94\x95\x96\x97")
    check testSanitizeutf8Empty("\x98\x99\x9a\x9b\x9c\x9d\x9e\x9f")
    check testSanitizeutf8Empty("\xa0\xa1\xa2\xa3\xa4\xa5\xa6\xa7")
    check testSanitizeutf8Empty("\xa8\xa9\xaa\xab\xac\xad\xae\xaf")
    check testSanitizeutf8Empty("\xb0\xb1\xb2\xb3\xb4\xb5\xb6\xb7")
    check testSanitizeutf8Empty("\xb8\xb9\xba\xbb\xbc\xbd\xbe\xbf")

  test "32 first bytes of 2-byte sequences (0xc0-0xdf)":
    check testSanitizeutf8("\xc0\x20\xc1\x20\xc2\x20\xc3\x20", "    ")
    check testSanitizeutf8("\xc4\x20\xc5\x20\xc6\x20\xc7\x20", "    ")
    check testSanitizeutf8("\xc8\x20\xc9\x20\xca\x20\xcb\x20", "    ")
    check testSanitizeutf8("\xcc\x20\xcd\x20\xce\x20\xcf\x20", "    ")
    check testSanitizeutf8("\xd0\x20\xd1\x20\xd2\x20\xd3\x20", "    ")
    check testSanitizeutf8("\xd4\x20\xd5\x20\xd6\x20\xd7\x20", "    ")
    check testSanitizeutf8("\xd8\x20\xd9\x20\xda\x20\xdb\x20", "    ")
    check testSanitizeutf8("\xdc\x20\xdd\x20\xde\x20\xdf\x20", "    ")

  test "Byte fe and ff cannot appear in UTF-8":

    check testSanitizeutf8Empty("\x80")
    check testSanitizeutf8Empty("\x81")
    check testSanitizeutf8Empty("\xfe")
    check testSanitizeutf8Empty("\xff")

    check sanitizeutf8("\x37\xff", true) ==  "7"
    check sanitizeutf8("\x37\xff", false) ==  "7\ufffd"
    check sanitizeutf8("\xff56", true) ==  "56"
    check sanitizeutf8("\xff56", false) ==  "\ufffd56"

    check testSanitizeutf8("\x37\x38\xfe", "78")
    check testSanitizeutf8("\x37\x38\x39\xfe", "789")

  test "overlong solidus":
    check testSanitizeutf8Empty("\xc0\xaf")
    check testSanitizeutf8Empty("\xe0\x80\xaf")

  test "restart after invalid":
    # This test shows how restarting works after an invalid multi-byte
    # sequence when replacing.
    check testSanitizeutf8("\xf4\x31", "\xef\xbf\xbd\x31", false)
    check testSanitizeutf8("\xf4\x80\x31", "\xef\xbf\xbd\xef\xbf\xbd\x31", false)
    check testSanitizeutf8("\xf0\x90\x80\x31", "\xef\xbf\xbd\xef\xbf\xbd\xef\xbf\xbd\x31", false)

  test "WriteValidUtf8FileTea":
    check testWriteValidUtf8File(writeValidUtf8FileTea)

  test "sanitizeUtf8Nim":
    check sanitizeUtf8Nim("abc", true) == "abc"
    check sanitizeUtf8Nim("abc", false) == "abc"
    check sanitizeUtf8Nim("ab\xffc", true) == "abc"
    check sanitizeUtf8Nim("\xffabc", true) == "abc"
    check sanitizeUtf8Nim("abc\xff", true) == "abc"
    check sanitizeUtf8Nim("\xff", true) == ""
    check sanitizeUtf8Nim("\xff\xff\xff", true) == ""
    check sanitizeUtf8Nim("a\xff\xffb", true) == "ab"
    check sanitizeUtf8Nim("", true) == ""

  test "hexString":
    check hexString("") == ""
    check hexString("1") == "31"
    check hexString("12") == "31 32"
    check hexString("\x00\x12\x34\xff") == "00 12 34 ff"

  test "formatGotLine":
    let str = "invalid at 0: 6.0, too big U-001FFFFF, <F7 BF BF BF>: "
    let expected = "6.0, too big U-001FFFFF, <F7 BF BF BF>: "
    check formatGotLine(str) == expected

  when testNim:
    test "writeValidUtf8FileNim":
      check testWriteValidUtf8File(writeValidUtf8FileNim)

  when testIconv:
    test "writeValidUtf8FileIconv":
      check testWriteValidUtf8File(writeValidUtf8FileIconv)

  when testPython3:
    test "writeValidUtf8FilePython3":
      check testWriteValidUtf8File(writeValidUtf8FilePython3, "skip")
      # todo: research how python3 replaces invalid when there are muliple bytes.
      # 33.2, <f0 90 80 c0>: ef bf bd ef bf bd

  test "generateExpectedFiles":
    # Generate the bin file when the txt file is newer or the bin file
    # is missing.
    if not fileExists(binTestCases) or fileNewer(testCases, binTestCases):
        echo "generating file: " & binTestCases
        check generateExpectedFiles()
        echo "run the tests again"
        fail()
