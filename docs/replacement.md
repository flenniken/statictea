# replacement.nim

Handle the replacement block lines.

* [replacement.nim](../src/replacement.nim) &mdash; Nim source code.
# Index

* type: [ReplaceLineKind](#replacelinekind) &mdash; Line type returned by yieldReplacementLine.
* type: [ReplaceLine](#replaceline) &mdash; Line information returned by yieldReplacementLine.
* [newReplaceLine](#newreplaceline) &mdash; Return a ReplaceLine object.
* [`$`](#) &mdash; Return a string representation of a ReplaceLine.
* [getTempFileStream](#gettempfilestream) &mdash; Create a stream from a temporary file and return both.
* [stringSegment](#stringsegment) &mdash; Return the string segment.
* [varSegment](#varsegment) &mdash; Return a variable segment.
* [lineToSegments](#linetosegments) &mdash; Convert a line to a list of segments.
* [parseVarSegment](#parsevarsegment) &mdash; Parse a variable type segment and return the dotNameStr.
* [writeTempSegments](#writetempsegments) &mdash; Write the updated replacement block to the result stream.
* [allocTempSegments](#alloctempsegments) &mdash; Create a TempSegments object.
* [closeDelete](#closedelete) &mdash; Close the TempSegments and delete its backing temporary file.
* [storeLineSegments](#storelinesegments) &mdash; Divide the line into segments and write them to the TempSegments' temp file.
* [yieldReplacementLine](#yieldreplacementline) &mdash; Yield all the replacement block lines and one after.
* [newTempSegments](#newtempsegments) &mdash; Read replacement block lines and return a TempSegments object containing the compiled block.
* [fillReplacementBlock](#fillreplacementblock) &mdash; Fill in the replacement block and return the line after it.

# ReplaceLineKind

Line type returned by yieldReplacementLine.

```nim
ReplaceLineKind = enum
  rlNoLine,                 ## Value when not initialized.
  rlReplaceLine,            ## A replacement block line.
  rlEndblockLine,           ## The endblock line.
  rlNormalLine               ## The last line when maxLines was exceeded.
```

# ReplaceLine

Line information returned by yieldReplacementLine.

```nim
ReplaceLine = object
  kind*: ReplaceLineKind
  line*: string

```

# newReplaceLine

Return a ReplaceLine object.

```nim
func newReplaceLine(kind: ReplaceLineKind; line: string): ReplaceLine
```

# `$`

Return a string representation of a ReplaceLine.

```nim
func `$`(replaceLine: ReplaceLine): string
```

# getTempFileStream

Create a stream from a temporary file and return both.

```nim
proc getTempFileStream(): Option[TempFileStream]
```

# stringSegment

Return the string segment. The line contains the segment starting at the given position and ending at finish position in the line (1 after). If the start and finish are at the end, output a endline segment.

```nim
proc stringSegment(line: string; start: Natural; finish: Natural): string
```

# varSegment

Return a variable segment. The bracketedVar is a string starting with { and ending with } that has a variable inside with optional whitespace around the variable, i.e. "{ s.name }". The atEnd parameter is true when the bracketedVar ends the line without an ending newline.

```nim
proc varSegment(bracketedVar: string; dotNameStrPos: Natural;
                dotNameStrLen: Natural; atEnd: bool): string
```

# lineToSegments

Convert a line to a list of segments.

```nim
proc lineToSegments(prepostTable: PrepostTable; line: string): seq[string]
```

# parseVarSegment

Parse a variable type segment and return the dotNameStr.

```nim
func parseVarSegment(segment: string): string
```

# writeTempSegments

Write the updated replacement block to the result stream.  It does it by writing all the stored segments and updating variable segments as it goes. The lineNum is the beginning line of the replacement block.

```nim
proc writeTempSegments(env: var Env; tempSegments: var TempSegments;
                       lineNum: Natural; variables: Variables)
```

# allocTempSegments

Create a TempSegments object. This reserves memory for a line buffer and creates a backing temp file. Call the closeDelete procedure when done to free the memory and to close and delete the file.

```nim
proc allocTempSegments(env: var Env; lineNum: Natural): Option[TempSegments]
```

# closeDelete

Close the TempSegments and delete its backing temporary file.

```nim
proc closeDelete(tempSegments: TempSegments)
```

# storeLineSegments

Divide the line into segments and write them to the TempSegments' temp file.

```nim
proc storeLineSegments(env: var Env; tempSegments: TempSegments;
                       prepostTable: PrepostTable; line: string)
```

# yieldReplacementLine

Yield all the replacement block lines and one after.

```nim
iterator yieldReplacementLine(env: var Env; firstReplaceLine: string;
                              lb: var LineBuffer; prepostTable: PrepostTable;
                              command: string; maxLines: Natural): ReplaceLine
```

# newTempSegments

Read replacement block lines and return a TempSegments object containing the compiled block. Call writeTempSegments to write out the segments. Call closeDelete to close and delete the associated temp file.

```nim
proc newTempSegments(env: var Env; lb: var LineBuffer;
                     prepostTable: PrepostTable; command: string;
                     repeat: Natural; variables: Variables): Option[TempSegments]
```

# fillReplacementBlock

Fill in the replacement block and return the line after it.

```nim
proc fillReplacementBlock(env: var Env; lb: LineBuffer; command: string;
                          prepostTable: PrepostTable; variables: Variables;
                          inOutExtraLine: var ExtraLine)
```


---
⦿ Markdown page generated by [StaticTea](https://github.com/flenniken/statictea/) from nim doc comments. ⦿
