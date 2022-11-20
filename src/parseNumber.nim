## Parse an int or float number string.  Return the number and number
## of characters processed.

import std/options
import std/parseutils

proc parseFloat*(str: string, start: Natural = 0): Option[tuple[number: float64, pos: Natural]] =
  ## Parse the string and return the 64 bit float number and the
  ## position after the number. The number starts at the start
  ## index. Nothing is returned when the float is out of range or the
  ## str is not a float number.  Processing stops at the first
  ## non-number character.
  assert sizeof[BiggestFloat] == sizeof[float64]
  var number: BiggestFloat
  let length = parseBiggestFloat(str, number, start)
  if length > 0:
    result = some((number, Natural(start+length)))

proc parseInteger*(s: string, start: Natural = 0): Option[tuple[number: int64, pos: Natural]] =
  ## Parse the string and return the 64 bit signed integer and the
  ## position after the number. The number starts at the start
  ## parameter index. Parsing stops at the first non-number character.
  ## Nothing is returned when the integer is out of range or the str
  ## is not a number.
  ## @:
  ## @:An integer starts with an optional minus sign, followed by a
  ## @:digit, followed by digits or underscores. The underscores are
  ## @:skipped.
  # This version is used instead of the nim version because of leading
  # underscores, plus signs and start position.
  var
    sign: int64 = -1
    b: int64 = 0
    i = start

  if i < s.len:
    if s[i] == '+':
      inc(i)
    elif s[i] == '-':
      inc(i)
      sign = 1

  if i < s.len and s[i] in {'0'..'9'}:
    while i < s.len and s[i] in {'0'..'9', '_'}:
      if s[i] != '_':
        let c = ord(s[i]) - ord('0')
        if b >= (low(int64) + c) div 10:
          b = b * 10 - c
        else:
          return
      inc(i)
    if sign == -1 and b == low(int64):
      return

    b = b * sign
    result = some((b, i))
