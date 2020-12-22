## Read lines from a stream without exceeding the maximum line
## length. The returned lines contain the line ending, either crlf or
## lf.

import streams
import options

const
  minMaxLineLen* = 8
  maxMaxLineLen* = 8*1024
  defaultMaxLineLen* = 1024
  defaultBufferSize* = 16*1024

type
  LineBuffer* = object
    stream*: Stream
    maxLineLen*: int
    bufferSize*: int
    lineNum*: int
    pos*: int         ## Current byte position in the buffer.
    charsRead*: int   ## Number of bytes of chars in the buffer.
    buffer*: string   ## Memory pre-allocated for the buffer.
    filename*: string ## Optional. The stream's filename.

proc getLineNum*(lineBuffer: LineBuffer): int =
  result = lineBuffer.lineNum

proc getMaxLineLen*(lineBuffer: LineBuffer): int =
  result = lineBuffer.maxLineLen

proc getFilename*(lineBuffer: LineBuffer): string =
  result = lineBuffer.filename

proc newLineBuffer*(stream: Stream, maxLineLen: int =
    defaultMaxLineLen, bufferSize: int =
    defaultBufferSize, filename: string = ""): Option[LineBuffer] =
  ## Return a new LineBuffer.

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

proc readline*(lb: var LineBuffer): string =
  ## Return a line from the LineBuffer. Reading starts from
  ## the current position in the stream and advances the amount read.
  ##
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

  proc readlines*(lb: var LineBuffer): seq[string] =
    while true:
      var line = lb.readline()
      if line == "":
        break
      result.add(line)

  proc readlines*(stream: Stream): seq[string] =
    var lineBufferO = newLineBuffer(stream)
    if not lineBufferO.isSome:
      return
    var lb = lineBufferO.get()
    result = readLines(lb)

  proc theLines*(stream: Stream): seq[string] =
    ## Read all the lines in the stream.
    stream.setPosition(0)
    for line in stream.lines():
      result.add line

  proc theLines*(filename: string): seq[string] =
    ## Read all the lines in the file.
    for line in lines(filename):
      result.add line
