# replacement.nim

Handle the replacement block lines.

* [replacement.nim](../src/replacement.nim) &mdash; Nim source code.
# Index

* type: [ReplaceLineKind](#replacelinekind) &mdash; Line type returned by yieldReplacementLine.
* type: [ReplaceLine](#replaceline) &mdash; Line information returned by yieldReplacementLine.
* type: [StringOr](#stringor) &mdash; A string or a warning.
* [newStringOr](#newstringor) &mdash; Return a new StringOr object containing a warning.
* [newStringOr](#newstringor-1) &mdash; Return a new StringOr object containing a warning.
* [newStringOr](#newstringor-2) &mdash; Return a new StringOr object containing a string.
* [newReplaceLine](#newreplaceline) &mdash; Return a new ReplaceLine object.
* [`$`](#) &mdash; Return a string representation of a ReplaceLine object.
* [stringSegment](#stringsegment) &mdash; Return a string segment made from the fragment.
* [varSegment](#varsegment) &mdash; Return a variable segment made from the dot name.
* [lineToSegments](#linetosegments) &mdash; Convert a line to a list of segments.
* [varSegmentDotName](#varsegmentdotname) &mdash; Given a variable segment, return its dot name.
* [writeTempSegments](#writetempsegments) &mdash; Write the replacement block's stored segments to the result stream with the variables filled in.
* [allocTempSegments](#alloctempsegments) &mdash; Create a TempSegments object.
* [closeDeleteTempSegments](#closedeletetempsegments) &mdash; Close the TempSegments and delete its backing temporary file.
* [storeLineSegments](#storelinesegments) &mdash; Divide the line into segments and write them to the TempSegments' temp file.
* [yieldReplacementLine](#yieldreplacementline) &mdash; Yield all the replacement block lines and one line after.
* [formatString](#formatstring) &mdash; Format a string by filling in the variable placeholders with
their values.

# ReplaceLineKind

Line type returned by yieldReplacementLine.<ul class="simple"><li>rlNoLine -- Value when not initialized.</li>
<li>rlReplaceLine -- A replacement block line.</li>
<li>rlEndblockLine -- The endblock command line.</li>
<li>rlNormalLine -- The last line when maxLines was exceeded.</li>
</ul>


```nim
ReplaceLineKind = enum
  rlNoLine, rlReplaceLine, rlEndblockLine, rlNormalLine
```

# ReplaceLine

Line information returned by yieldReplacementLine.

```nim
ReplaceLine = object
  kind*: ReplaceLineKind
  line*: string

```

# StringOr

A string or a warning.

```nim
StringOr = OpResultWarn[string]
```

# newStringOr

Return a new StringOr object containing a warning.

```nim
func newStringOr(warning: MessageId; p1: string = ""; pos = 0): StringOr
```

# newStringOr

Return a new StringOr object containing a warning.

```nim
func newStringOr(warningData: WarningData): StringOr
```

# newStringOr

Return a new StringOr object containing a string.

```nim
func newStringOr(str: string): StringOr
```

# newReplaceLine

Return a new ReplaceLine object.

```nim
func newReplaceLine(kind: ReplaceLineKind; line: string): ReplaceLine
```

# `$`

Return a string representation of a ReplaceLine object.

```nim
func `$`(replaceLine: ReplaceLine): string
```

# stringSegment

Return a string segment made from the fragment. AtEnd is true when the fragment ends the line.

```nim
proc stringSegment(fragment: string; atEnd: bool): string
```

# varSegment

Return a variable segment made from the dot name. AtEnd is true when the bracketed variable ends the line.

```nim
proc varSegment(dotName: string; atEnd: bool): string
```

# lineToSegments

Convert a line to a list of segments. No warnings.

```nim
proc lineToSegments(line: string): seq[string]
```

# varSegmentDotName

Given a variable segment, return its dot name.

```nim
func varSegmentDotName(segment: string): string
```

# writeTempSegments

Write the replacement block's stored segments to the result stream with the variables filled in.  The lineNum is the beginning line of the replacement block.

```nim
proc writeTempSegments(env: var Env; tempSegments: var TempSegments;
                       lineNum: Natural; variables: Variables)
```

# allocTempSegments

Create a TempSegments object. This reserves memory for a line buffer and creates a backing temp file. Call the closeDeleteTempSegments procedure when done to free the memory and to close and delete the file.

```nim
proc allocTempSegments(env: var Env; lineNum: Natural): Option[TempSegments]
```

# closeDeleteTempSegments

Close the TempSegments and delete its backing temporary file.

```nim
proc closeDeleteTempSegments(tempSegments: TempSegments)
```

# storeLineSegments

Divide the line into segments and write them to the TempSegments' temp file.

```nim
proc storeLineSegments(env: var Env; tempSegments: TempSegments; line: string)
```

# yieldReplacementLine

Yield all the replacement block lines and one line after.

```nim
iterator yieldReplacementLine(env: var Env; firstReplaceLine: string;
                              lb: var LineBuffer; prepostTable: PrepostTable;
                              command: string; maxLines: Natural): ReplaceLine
```

# formatString

Format a string by filling in the variable placeholders with
their values. Generate a warning when the variable doesn't
exist. No space around the bracketed variables.

~~~
let first = "Earl"
let last = "Grey"
"name: {first} {last}" => "name: Earl Grey"
~~~~

To enter a left bracket use two in a row.

~~~
"{{" => "{"
~~~~

```nim
proc formatString(variables: Variables; text: string): StringOr
```


---
⦿ Markdown page generated by [StaticTea](https://github.com/flenniken/statictea/) from nim doc comments. ⦿
