## Shared test code.

when defined(test):
  func bytesToString*(buffer: openArray[uint8|char]): string =
    ## Create a string from bytes in a buffer. A nim string is UTF-8
    ## incoded but it isn't validated so it is just a string of bytes.
    if buffer.len == 0:
      return ""
    result = newStringOfCap(buffer.len)
    for ix in 0 .. buffer.len-1:
      result.add((char)buffer[ix])

