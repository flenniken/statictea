
import std/unittest
import std/options
import vartypes
import parseNumber
import sharedtestcode
import runCommand

proc testParseInteger(text: string, start: Natural, expectedNumber: int64,
    ePos: Natural): bool =
  # Return true when the string parses as expected.
  var valueAndPosO = parseInteger(text, start)
  if not isSome(valueAndPosO):
    echo "Did not find an integer for:"
    echo text
    return false
  let valueAndPos = valueAndPosO.get()
  let eValueAndPos = newValueAndPos(newValue(expectedNumber), ePos)
  result = gotExpected($valueAndPos, $eValueAndPos)
  if not result:
    echo text
    echo startColumn(text, start)
    echo startColumn(text, valueAndPos.pos, "^ got")
    echo startColumn(text, ePos, "^ expected")

proc testParseIntegerError(text: string, start: Natural = 0): bool =
  # Return true when the given string does not parse as an integer,
  # else return false.
  var valueAndPosO = parseInteger(text, start)
  if not valueAndPosO.isSome:
    result = true

proc testParseFloat(text: string, start: Natural, expectedNumber: BiggestFloat,
    ePos: Natural): bool =
  # Return true when the string parses as expected.
  var valueAndPosO = parseFloat(text, start)
  if not isSome(valueAndPosO):
    echo "Did not find a float for:"
    echo text
    return false
  let valueAndPos = valueAndPosO.get()
  let eValueAndPos = newValueAndPos(newValue(expectedNumber), ePos)
  result = gotExpected($valueAndPos, $eValueAndPos)
  if not result:
    echo text
    echo startColumn(text, start)
    echo startColumn(text, valueAndPos.pos, "^ got")
    echo startColumn(text, ePos, "^ expected")

proc testParseFloatError(text: string, start: Natural = 0): bool =
  # Return true when the given string does not parse as an float,
  # else return false.
  var valueAndPosO = parseFloat(text, start)
  if not valueAndPosO.isSome:
    result = true


suite "parseNumber.nim":

  test "parseInteger1":
    check testParseInteger("0", 0, 0, 1)
    check testParseInteger("7", 0, 7, 1)
    check testParseInteger("9", 0, 9, 1)

  test "parseInteger2":
    check testParseInteger("12", 0, 12, 2)
    check testParseInteger("99", 0, 99, 2)
    check testParseInteger("-1", 0, -1, 2)
    check testParseInteger("+2", 0, 2, 2)
    check testParseInteger("2_", 0, 2, 2)

  test "parseInteger3":
    check testParseInteger("123", 0, 123, 3)
    check testParseInteger("-23", 0, -23, 3)
    check testParseInteger("-88", 0, -88, 3)
    check testParseInteger("-8_", 0, -8, 3)
    check testParseInteger("+8_", 0, 8, 3)
    check testParseInteger("12_", 0, 12, 3)
    check testParseInteger("1__", 0, 1, 3)
    check testParseInteger("1_2", 0, 12, 3)

  test "parseIntegerBigger":
    check testParseInteger("123456789", 0, 123456789, 9)
    check testParseInteger("123_456_789", 0, 123456789, 11)
    check testParseInteger("-123456789", 0, -123456789, 10)
    check testParseInteger("+123_456_789", 0, 123456789, 12)

  test "parseIntegerMax":
    check testParseInteger("-9_223_372_036_854_775_808", 0, low(int64), 26)
    check testParseInteger("+9_223_372_036_854_775_807", 0, high(int64), 26)
    check testParseInteger("-9223372036854775808", 0, low(int64), 20)
    check testParseInteger("+9223372036854775807", 0, high(int64), 20)
    check testParseInteger("9223372036854775807", 0, high(int64), 19)

  test "parseIntegerStopEarly":
    check testParseInteger("1a", 0, 1, 1)
    check testParseInteger("1*", 0, 1, 1)
    check testParseInteger("1_a", 0, 1, 2)
    check testParseInteger("1___a", 0, 1, 4)

  test "parseIntegerStartLate":
    check testParseInteger("abc9", 3, 9, 4)

  test "parseIntegerStartLateStopEarly":
    check testParseInteger("abc9def", 3, 9, 4)

  test "parseIntegerNotInt":
    check testParseIntegerError("")
    check testParseIntegerError("a")
    check testParseIntegerError("+")
    check testParseIntegerError("-")
    check testParseIntegerError("_")
    check testParseIntegerError("ab 123")

  test "parseIntegerOverflow":
    check testParseIntegerError("9_223_372_036_854_775_808")
    check testParseIntegerError("-9_223_372_036_854_775_809")

  test "parseFloat":
    check testParseFloat("def0abc", 3, 0.0, 4)
    check testParseFloat("0", 0, 0.0, 1)
    check testParseFloat("9", 0, 9.0, 1)
    check testParseFloat("9e2", 0, 900.0, 3)
    check testParseFloat("9E2", 0, 900.0, 3)
    check testParseFloat("-9", 0, -9.0, 2)
    check testParseFloat("+9", 0, 9.0, 2)
    check testParseFloat("1.0", 0, 1.0, 3)
    check testParseFloat("123", 0, 123, 3)
    check testParseFloat("12.33", 0, 12.33, 5)
    check testParseFloat(".33", 0, 0.33, 3)
    check testParseFloat("2_777.33", 0, 2777.33, 8)

  test "parseFloat error":
    check testParseFloatError("defabc", 0)

#[ A float64 can represent all integers in the range 2**54 to -2**52
including boundaries.  If we limited our int to this range, we could
use float64 for all numbers.  ]#
