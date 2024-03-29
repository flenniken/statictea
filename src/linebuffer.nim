## Read lines from a stream without exceeding the maximum line
#$ length. The returned lines contain the line ending, either crlf or
#$ lf.
#$
#$ Example:
#$
#$ ~~~ nim
#$ let lbO = newLineBuffer(stream)
#$ check lbO.isSome == true
#$ var lb = lbO.get()
#$ while line = lb.readLine():
#$   processLine(line)
#$ ~~~

import std/streams
import std/options

const
  minMaxLineLen* = 8
    ## The minimum line length supported.
  maxMaxLineLen* = 8*1024
    ## The maximum line length supported.
  defaultMaxLineLen* = 1024
    ## The maximum line length.
  defaultBufferSize* = 16*1024
    ## The buffer size for reading lines.

type
  LineBuffer* = object
    ## The LineBuffer holds information about reading lines from a buffer.
    ## * stream — a stream containing lines to read processed sequentially
    ## * maxLineLen — the maximum line length
    ## * bufferSize — the buffer size for reading lines
    ## * lineNum — he current line number in the file starting at 1
    ## * pos — current byte position in the buffer
    ## * charsRead — number of bytes in the buffer
    ## * buffer — memory allocated for the buffer
    ## * filename — the optional stream's filename
    stream: Stream
    maxLineLen: int
    bufferSize: int
    lineNum: int
    pos: int
    charsRead: int
    buffer: string
    filename: string

func getLineNum*(lineBuffer: LineBuffer): int =
  ## Return the current line number.
  result = lineBuffer.lineNum

func getMaxLineLen*(lineBuffer: LineBuffer): int =
  ## Return the maximum line length.
  result = lineBuffer.maxLineLen

func getFilename*(lineBuffer: LineBuffer): string =
  ## Return the filename of the stream, if there is one.
  result = lineBuffer.filename

func getStream*(lineBuffer: LineBuffer): Stream =
  ## Return the associated stream.
  result = lineBuffer.stream

func newLineBuffer*(stream: Stream,
    maxLineLen: int = defaultMaxLineLen,
    bufferSize: int = defaultBufferSize,
    filename: string = ""): Option[LineBuffer] =
  ## Return a new LineBuffer for the given stream.

  if stream == nil:
    return
  if maxLineLen < minMaxLineLen or maxLineLen > maxMaxLineLen:
    return
  if bufferSize < maxLineLen:
    return

  # Allocate the buffer.
  var buffer: string
  buffer.setLen(bufferSize)

  var lb = LineBuffer(stream: stream, maxLineLen: maxLineLen,
    bufferSize:bufferSize, buffer:buffer, filename:filename)

  result = some(lb)

proc reset*(lb: var LineBuffer) =
  ## Clear the buffer and set the read position at the start of the
  ## stream.
  lb.stream.setPosition(0)
  lb.charsRead = 0
  lb.pos = 0

proc readline*(lb: var LineBuffer): string =
  ## Return the next line from the LineBuffer. Reading starts from the
  ## current position in the stream and advances the amount read.
  ##
  ## A line end is defined by either a crlf or lf and they get
  ## returned with the line bytes. A line is returned when the line
  ## ending is found, when the stream runs out of bytes or when the
  ## maximum line length is reached.
  ##
  ## You cannot tell whether the line was truncated or not without
  ## reading the next line. When no more data exists in the stream, an
  ## empty string is returned.

  if lb.stream == nil:
    return

  var line = newStringOfCap(lb.maxLineLen)

  while true:
    if lb.pos >= lb.charsRead:
      # Read a buffer.
      lb.charsRead = lb.stream.readDataStr(lb.buffer, 0..<lb.bufferSize)
      lb.pos = 0
      if lb.charsRead == 0:
        inc(lb.lineNum)
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

iterator yieldContentLine*(content: string): string =
  ## Yield one line at a time from the content string and keep the
  ## line endings.
  var start = 0
  for pos in 0 ..< content.len:
    let ch = content[pos]
    if ch == '\n':
      yield(content[start .. pos])
      start = pos+1
  if start < content.len:
    yield(content[start ..< content.len])
