[StaticTea Modules](./)

# readlines.nim

Read lines from a stream without exceeding the maximum line length. The returned lines contain the line ending, either crlf or lf.

# Index

* const: [minMaxLineLen](#user-content-a0) &mdash; The minimum line length supported.
* const: [maxMaxLineLen](#user-content-a1) &mdash; The maximum line length supported.
* const: [defaultMaxLineLen](#user-content-a2) &mdash; The maximum line length.
* const: [defaultBufferSize](#user-content-a3) &mdash; The buffer size for reading lines.
* type: [LineBuffer](#user-content-a4) &mdash; Object to hold information about the state of the line buffer.
* [getLineNum](#user-content-a5) &mdash; Return the current line number.
* [getMaxLineLen](#user-content-a6) &mdash; Return the maximum line length.
* [getFilename](#user-content-a7) &mdash; Return the filename of the stream, if there is one.
* [newLineBuffer](#user-content-a8) &mdash; Return a new LineBuffer for the given stream.
* [reset](#user-content-a9) &mdash; Clear the buffer.
* [readline](#user-content-a10) &mdash; Return a line from the LineBuffer.

# <a id="a0"></a>minMaxLineLen

The minimum line length supported.

```nim
minMaxLineLen = 8
```


# <a id="a1"></a>maxMaxLineLen

The maximum line length supported.

```nim
maxMaxLineLen = 8192
```


# <a id="a2"></a>defaultMaxLineLen

The maximum line length.

```nim
defaultMaxLineLen = 1024
```


# <a id="a3"></a>defaultBufferSize

The buffer size for reading lines.

```nim
defaultBufferSize = 16384
```


# <a id="a4"></a>LineBuffer

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


# <a id="a5"></a>getLineNum

Return the current line number.

```nim
proc getLineNum(lineBuffer: LineBuffer): int
```


# <a id="a6"></a>getMaxLineLen

Return the maximum line length.

```nim
proc getMaxLineLen(lineBuffer: LineBuffer): int
```


# <a id="a7"></a>getFilename

Return the filename of the stream, if there is one.

```nim
proc getFilename(lineBuffer: LineBuffer): string
```


# <a id="a8"></a>newLineBuffer

Return a new LineBuffer for the given stream.

```nim
proc newLineBuffer(stream: Stream; maxLineLen: int = defaultMaxLineLen;
                   bufferSize: int = defaultBufferSize; filename: string = ""): Option[
    LineBuffer]
```


# <a id="a9"></a>reset

Clear the buffer.

```nim
proc reset(lb: var LineBuffer)
```


# <a id="a10"></a>readline

Return a line from the LineBuffer. Reading starts from the current position in the stream and advances the amount read.

A line end is defined by either a crlf or lf and they get returned with the line bytes. A line is returned when the line ending is found, when the streams runs out of bytes or when the maximum line length is reached.

You cannot tell whether the line was truncated or not without reading the next line. When no more data exists in the stream, an empty string is returned.

```nim
proc readline(lb: var LineBuffer): string
```



---
⦿ StaticTea markdown template for nim doc comments. ⦿
