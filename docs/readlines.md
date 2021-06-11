# readlines.nim

Read lines from a stream without exceeding the maximum line length. The returned lines contain the line ending, either crlf or lf.

* [readlines.nim](../src/readlines.nim) &mdash; Nim source code.
# Index

* const: [minMaxLineLen](#minmaxlinelen) &mdash; The minimum line length supported.
* const: [maxMaxLineLen](#maxmaxlinelen) &mdash; The maximum line length supported.
* const: [defaultMaxLineLen](#defaultmaxlinelen) &mdash; The maximum line length.
* const: [defaultBufferSize](#defaultbuffersize) &mdash; The buffer size for reading lines.
* type: [LineBuffer](#linebuffer) &mdash; Object to hold information about the state of the line buffer.
* [getLineNum](#getlinenum) &mdash; Return the current line number.
* [getMaxLineLen](#getmaxlinelen) &mdash; Return the maximum line length.
* [getFilename](#getfilename) &mdash; Return the filename of the stream, if there is one.
* [newLineBuffer](#newlinebuffer) &mdash; Return a new LineBuffer for the given stream.
* [reset](#reset) &mdash; Clear the buffer.
* [readline](#readline) &mdash; Return a line from the LineBuffer.

# minMaxLineLen

The minimum line length supported.

```nim
minMaxLineLen = 8
```


# maxMaxLineLen

The maximum line length supported.

```nim
maxMaxLineLen = 8192
```


# defaultMaxLineLen

The maximum line length.

```nim
defaultMaxLineLen = 1024
```


# defaultBufferSize

The buffer size for reading lines.

```nim
defaultBufferSize = 16384
```


# LineBuffer

Object to hold information about the state of the line buffer.

```nim
LineBuffer = object
  stream*: Stream            ## Stream containing lines to read processed sequentially.
  maxLineLen*: int           ## The maximum line length.
  bufferSize*: int           ## The buffer size for reading lines.
  lineNum*: int              ## The current line number in the file starting at 1.
  pos*: int                  ## Current byte position in the buffer.
  charsRead*: int            ## Number of bytes of chars in the buffer.
  buffer*: string            ## Memory pre-allocated for the buffer.
  filename*: string          ## The optional stream's filename.

```


# getLineNum

Return the current line number.

```nim
proc getLineNum(lineBuffer: LineBuffer): int
```


# getMaxLineLen

Return the maximum line length.

```nim
proc getMaxLineLen(lineBuffer: LineBuffer): int
```


# getFilename

Return the filename of the stream, if there is one.

```nim
proc getFilename(lineBuffer: LineBuffer): string
```


# newLineBuffer

Return a new LineBuffer for the given stream.

```nim
proc newLineBuffer(stream: Stream; maxLineLen: int = defaultMaxLineLen;
                   bufferSize: int = defaultBufferSize; filename: string = ""): Option[
    LineBuffer]
```


# reset

Clear the buffer.

```nim
proc reset(lb: var LineBuffer)
```


# readline

Return a line from the LineBuffer. Reading starts from the current position in the stream and advances the amount read.

A line end is defined by either a crlf or lf and they get returned with the line bytes. A line is returned when the line ending is found, when the streams runs out of bytes or when the maximum line length is reached.

You cannot tell whether the line was truncated or not without reading the next line. When no more data exists in the stream, an empty string is returned.

```nim
proc readline(lb: var LineBuffer): string
```



---
⦿ Markdown page generated by [StaticTea](https://github.com/flenniken/statictea/) from nim doc comments. ⦿