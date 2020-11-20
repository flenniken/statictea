## The version.nim file defines the version numbers of statictea and its
## required components.

import options

type
  IntPos* = object
    integer*: BiggestInt
    length*: int

proc parseInteger*(s: string, start: Natural = 0): Option[IntPos] =
  ## Parse the string and return the integer and number of characters
  ## processed. Nothing is returned when the integer is out of range
  ## or the str is not a number.  An integer starts with an optional +
  ## or -, followed by a digit, followed by digits or underscores. The
  ## underscores are skipped. Processing stops at the first non-digit
  ## or underscore.

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
