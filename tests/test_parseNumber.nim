
import unittest
import parseNumber
import strutils
import options

proc testParseInteger(str: string, expectedInteger: BiggestInt, expectedLength: int,
                      start: Natural = 0): bool =
  # Return true when the string parses as expected.
  var integer: BiggestInt
  var intPosO = parseInteger(str, start)
  if not isSome(intPosO):
    echo "Did not find an integer for:"
    echo string
    return false
  let intPos = intPosO.get()
  if intPos.length != expectedLength:
    echo "         length: $1" % $intPos.length
    echo "expected length: $1" % $expectedLength
    return false
  if intPos.integer != expectedInteger:
    echo "         integer: $1" % $intPos.integer
    echo "expected integer: $1" % $expectedInteger
    return false
  return true

proc testParseIntegerError(str: string, start: Natural = 0): bool =
  # Return true when the given string does not parse as an integer,
  # else return false.
  var intPosO = parseInteger(str, start)
  if not intPosO.isSome:
    result = true

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
    check testParseInteger("-9_223_372_036_854_775_808", low(BiggestInt), 26)
    check testParseInteger("+9_223_372_036_854_775_807", high(BiggestInt), 26)
    check testParseInteger("-9223372036854775808", low(BiggestInt), 20)
    check testParseInteger("+9223372036854775807", high(BiggestInt), 20)
    check testParseInteger("9223372036854775807", high(BiggestInt), 19)

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
