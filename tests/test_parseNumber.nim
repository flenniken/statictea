
import std/unittest
import std/options
import std/strutils
import parseNumber

proc testParseInteger(str: string, expectedNumber: int64,
    expectedLength: int, start: Natural = 0): bool =
  # Return true when the string parses as expected.
  var intAndLengthO = parseInteger(str, start)
  if not isSome(intAndLengthO):
    echo "Did not find an integer for:"
    echo string
    return false
  let intAndLength = intAndLengthO.get()
  if intAndLength.length != expectedLength:
    echo "         length: $1" % $intAndLength.length
    echo "expected length: $1" % $expectedLength
    return false
  if intAndLength.number != expectedNumber:
    echo "         number: $1" % $intAndLength.number
    echo "expected number: $1" % $expectedNumber
    return false
  return true

proc testParseIntegerError(str: string, start: Natural = 0): bool =
  # Return true when the given string does not parse as an integer,
  # else return false.
  var intAndLengthO = parseInteger(str, start)
  if not intAndLengthO.isSome:
    result = true

proc testParseFloat(str: string, expectedFloat: BiggestFloat, expectedLength: int,
                      start: Natural = 0): bool =
  # Return true when the string parses as expected.
  var floatAndLengthO = parseFloat(str, start)
  if not isSome(floatAndLengthO):
    echo "Did not find a float for:"
    echo string
    return false
  let floatAndLength = floatAndLengthO.get()
  if floatAndLength.length != expectedLength:
    echo "         length: $1" % $floatAndLength.length
    echo "expected length: $1" % $expectedLength
    return false
  if floatAndLength.number != expectedFloat:
    echo "         number: $1" % $floatAndLength.number
    echo "expected number: $1" % $expectedFloat
    return false
  return true

suite "parseNumber.nim":

  test "parseInteger1":
    check testParseInteger("0", 0, 1)
    check testParseInteger("7", 7, 1)
    check testParseInteger("9", 9, 1)

  test "parseInteger2":
    check testParseInteger("12", 12, 2)
    check testParseInteger("99", 99, 2)
    check testParseInteger("-1", -1, 2)
    check testParseInteger("+2", 2, 2)
    check testParseInteger("2_", 2, 2)

  test "parseInteger3":
    check testParseInteger("123", 123, 3)
    check testParseInteger("-23", -23, 3)
    check testParseInteger("-88", -88, 3)
    check testParseInteger("-8_", -8, 3)
    check testParseInteger("+8_", 8, 3)
    check testParseInteger("12_", 12, 3)
    check testParseInteger("1__", 1, 3)
    check testParseInteger("1_2", 12, 3)

  test "parseIntegerBigger":
    check testParseInteger("123456789", 123456789, 9)
    check testParseInteger("123_456_789", 123456789, 11)
    check testParseInteger("-123456789", -123456789, 10)
    check testParseInteger("+123_456_789", 123456789, 12)

  test "parseIntegerMax":
    check testParseInteger("-9_223_372_036_854_775_808", low(int64), 26)
    check testParseInteger("+9_223_372_036_854_775_807", high(int64), 26)
    check testParseInteger("-9223372036854775808", low(int64), 20)
    check testParseInteger("+9223372036854775807", high(int64), 20)
    check testParseInteger("9223372036854775807", high(int64), 19)

  test "parseIntegerStopEarly":
    check testParseInteger("1a", 1, 1)
    check testParseInteger("1*", 1, 1)
    check testParseInteger("1_a", 1, 2)
    check testParseInteger("1___a", 1, 4)

  test "parseIntegerStartLate":
    check testParseInteger("abc9", 9, 1, 3)

  test "parseIntegerStartLateStopEarly":
    check testParseInteger("abc9def", 9, 1, 3)

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
    check testParseFloat("0", 0.0, 1)
    check testParseFloat("9", 9.0, 1)
    check testParseFloat("9e2", 900.0, 3)
    check testParseFloat("9E2", 900.0, 3)

    check testParseFloat("-9", -9.0, 2)
    check testParseFloat("+9", 9.0, 2)

    check testParseFloat("1.0", 1.0, 3)
    check testParseFloat("123", 123, 3)

    check testParseFloat("12.33", 12.33, 5)

    check testParseFloat(".33", 0.33, 3)

    check testParseFloat("2_777.33", 2777.33, 8)

#[ A float64 can represent all integers in the range 2**54 to -2**52
including boundaries.  If we limited our int to this range, we could
use float64 for all numbers.  ]#
