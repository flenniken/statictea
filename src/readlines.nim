## Read lines from a stream without exceeding the maximum line
## length. The returned lines contain the line ending, either crlf or
## lf.

import streams
import options

const
  minMaxLineLen* = 8           ## The minimum line length supported.
  maxMaxLineLen* = 8*1024      ## The maximum line length supported.
  defaultMaxLineLen* = 1024    ## The maximum line length.
  defaultBufferSize* = 16*1024 ## The buffer size for reading lines.

type
  LineBuffer* = object
    ## Object to hold information about the state of the line buffer.
    stream*: Stream   ## Stream containing lines to read processed sequentially.
    maxLineLen*: int  ## The maximum line length.
    bufferSize*: int  ## The buffer size for reading lines.
    lineNum*: int     ## The current line number in the file starting at 1.
    pos*: int         ## Current byte position in the buffer.
    charsRead*: int   ## Number of bytes of chars in the buffer.
    buffer*: string   ## Memory pre-allocated for the buffer.
    filename*: string ## The optional stream's filename.

proc getLineNum*(lineBuffer: LineBuffer): int =
  ## Return the current line number.
  result = lineBuffer.lineNum

proc getMaxLineLen*(lineBuffer: LineBuffer): int =
  ## Return the maximum line length.
  result = lineBuffer.maxLineLen

proc getFilename*(lineBuffer: LineBuffer): string =
  ## Return the filename of the stream, if there is one.
  result = lineBuffer.filename

proc newLineBuffer*(stream: Stream, maxLineLen: int = defaultMaxLineLen,
    bufferSize: int = defaultBufferSize, filename: string = ""): Option[LineBuffer] =
  ## Return a new LineBuffer for the given stream.

  if stream == nil:
    return
  if maxLineLen < minMaxLineLen or maxLineLen > maxMaxLineLen:
    return
  if bufferSize < maxLineLen:
    return

  var lb: LineBuffer
  lb.stream = stream
  lb.maxLineLen = maxLineLen
  lb.bufferSize = bufferSize
  lb.charsRead = 0
  lb.pos = 0
  lb.buffer.setLen(bufferSize)
  lb.filename = filename

  result = some(lb)

proc reset*(lb: var LineBuffer) =
  ## Clear the buffer.
  lb.stream.setPosition(0)
  lb.charsRead = 0
  lb.pos = 0

proc readline*(lb: var LineBuffer): string =
  ## Return a line from the LineBuffer. Reading starts from
  ## the current position in the stream and advances the amount read.
  ## blank
  ## A line end is defined by either a crlf or lf and they get
  ## returned with the line bytes. A line is returned when the line
  ## ending is found, when the streams runs out of bytes or when the
  ## maximum line length is reached. You cannot tell whether the
  ## line was truncated or not without reading the next line. When no
  ## more data exists in the stream, an empty string is returned.

  if lb.stream == nil:
    return

  var line = newStringOfCap(lb.maxLineLen)

  while true:
    if lb.pos >= lb.charsRead:
      # Read a buffer.
      lb.charsRead = lb.stream.readDataStr(lb.buffer, 0..<lb.bufferSize)
      lb.pos = 0
      if lb.charsRead == 0:
        break # Done reading the stream.
    let charByte = lb.buffer[lb.pos]
    line.add(charByte)
    lb.pos += 1
    if charByte == char('\n'):
      inc(lb.lineNum)
      break
    if line.len == lb.maxLineLen:
      break

  result = line

when defined(test):
  proc readXLines*(lb: var LineBuffer, maxLines: Natural = high(Natural)): seq[string] =
    ## Read lines from a LineBuffer returning line endings but don't
    ## read more than the maximum number of lines. Reading starts at
    ## the current lb's current position and the position at the end
    ## is ready for reading the next line.
    var count = 0
    while true:
      if count >= maxLines:
        break
      var line = lb.readline()
      if line == "":
        break
      result.add(line)
      inc(count)

  proc readXLines*(stream: Stream,
    maxLineLen: int = defaultMaxLineLen,
    bufferSize: int = defaultBufferSize,
    filename: string = "",
    maxLines: Natural = high(Natural)
  ): seq[string] =
    ## Read all lines from a stream returning line endings but don't
    ## read more than the maximum number of lines.
    stream.setPosition(0)
    var lineBufferO = newLineBuffer(stream)
    if not lineBufferO.isSome:
      return
    var lb = lineBufferO.get()
    result = readXLines(lb, maxLines)

  proc readXLines*(filename: string,
    maxLineLen: int = defaultMaxLineLen,
    bufferSize: int = defaultBufferSize,
    maxLines: Natural = high(Natural)
  ): seq[string] =
    ## Read all lines from a file returning line endings but don't
    ## read more than the maximum number of lines.
    var stream = newFileStream(filename)
    if stream == nil:
      return
    result = readXLines(stream, maxLineLen, bufferSize, filename, maxLines)
    stream.close
