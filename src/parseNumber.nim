## Parse an int or float number string.  Return the number and number
## of characters processed.

import options
import parseUtils

# todo: use int64 instead of BiggestInt everywhere.
assert sizeof[BiggestInt] == sizeof[int64]

type
  IntPos* = object
    ## Integer and its text length.
    integer*: BiggestInt
    length*: int

  FloatPos* = object
    ## Float and its text length.
    number*: float64
    length*: int

proc parseFloat64*(str: string, start: Natural = 0): Option[FloatPos] =
  ## Parse the string and return the 64 bit float number and the
  ## number of characters processed. Nothing is returned when the
  ## float is out of range or the str is not a float number.
  ## Processing stops at the first non-number character.

  ## A float number starts with an optional minus sign, followed by a
  ## digit, followed by digits, underscores or a decimal point. Only
  ## one decimal point is allowed and underscores are skipped.

  assert sizeof[BiggestFloat] == sizeof[float64]
  var number: BiggestFloat
  let length = parseBiggestFloat(str, number, start)
  if length > 0:
    result = some(FloatPos(number: number, length: length))

proc parseInteger*(s: string, start: Natural = 0): Option[IntPos] =
  ## Parse the string and return the integer and number of characters
  ## processed. Nothing is returned when the integer is out of range
  ## or the str is not a number.

  ## An integer starts with an optional minus sign, followed by a
  ## digit, followed by digits or underscores. The underscores are
  ## skipped. Processing stops at the first non-number character.

  var
    sign: BiggestInt = -1
    b: BiggestInt = 0
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
        if b >= (low(BiggestInt) + c) div 10:
          b = b * 10 - c
        else:
          return
      inc(i)
    if sign == -1 and b == low(BiggestInt):
      return

    b = b * sign
    let value = IntPos(integer: b, length: i - start)
    result = some(value)
