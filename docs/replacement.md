# replacement.nim

Handle the replacement block lines.

To support replacement blocks that consists of many lines and blocks
that repeat many times, we read the replacement block and compile
and store it in a temp file in a format that is easy to write out
multiple times.

The temporary file consists of parts of lines called segments. There
are segments for the variables in the line and segments for the rest
of the text.

Segments are a text format containing a number (type), a comma and a
string.

All segments end with a newline. If a template line uses cr/lf, the
segment will end with cr/lf.  The segment type tells you whether to
write out the ending newline or not to the result file.

Segment text are bytes. The bracketed variables are ascii.

A bracketed variable does not contain space around the variable.
{var} not { var }.

To use a left bracket in a replacement block you use two left brackets, {{,
{{ results in {.

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
