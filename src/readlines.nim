## Read lines from a file preserving line endings and with control
## over the maximum line length.  You can readlines from text or
## binary files or mixtures of both.
##
## You can copy a file using the following code without changing the
## bytes.
##
## for line, ascii in readline(inStream):
##   outStream.write(line)

import streams

const
  newline = char('\n')
  maxLineLen* = 1024
  bufferSize* = 16*1024

iterator readline*(stream: Stream, maxLineLen: int = maxLineLen,
    bufferSize: int = bufferSize): tuple[line: string, ascii: bool] =
  ## Return all lines of the stream. A line end is defined by either a
  ## crlf or lf and they get returned with the line bytes. A line is
  ## returned when the line ending is found, when the streams runs out
  ## of bytes or when the maximum line length is reached. Note: you
  ## cannot tell whether the line was truncated or not without reading
  ## the next line. The ascii return value is true when all the bytes
  ## in the line are ascii (no high bit set).  The maxLineLen must be
  ## greater than 8 and lessthan or equal to bufferSize.

  assert maxLineLen > 8
  assert maxLineLen <= bufferSize

  var buffer: string
  buffer.setLen(bufferSize)
  var line = newStringOfCap(maxLineLen)
  var pos = 0 # current position in the buffer
  var ascii = true

  while true:
    let charsRead = stream.readDataStr(buffer, 0..<bufferSize)
    if charsRead == 0:
      break # Done reading the stream.
    pos = 0
    while true:
      if pos >= charsRead:
        break # go read another buffer
      let ch = buffer[pos]
      pos += 1
      line.add(ch)
      if ord(ch) > 0x7f:
        ascii = false
      if ch == newline or line.len >= maxLineLen:
        yield((line, ascii))
        line.setLen(0)
        ascii = true

  # Output the last line, if any.
  if line.len > 0:
    yield((line, ascii))



when defined(test):
  type
    TGenericSeq = object
      len, reserved: int
    PGenericSeq = ptr TGenericSeq

  proc getCap*[T](s: seq[T]): int =
    ## Return the capacity of the sequence.
    result = cast[PGenericSeq](s).reserved
