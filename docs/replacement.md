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

# ReplaceLineKind

Line type returned by yieldReplacementLine.

* rlNoLine -- Value when not initialized.
* rlReplaceLine -- A replacement block line.
* rlEndblockLine -- The endblock command line.
* rlNormalLine -- The last line when maxLines was exceeded.

~~~nim
ReplaceLineKind = enum
  rlNoLine, rlReplaceLine, rlEndblockLine, rlNormalLine
~~~

# ReplaceLine

Line information returned by yieldReplacementLine.

~~~nim
ReplaceLine = object
  kind*: ReplaceLineKind
  line*: string
~~~

# newReplaceLine

Return a new ReplaceLine object.

~~~nim
func newReplaceLine(kind: ReplaceLineKind; line: string): ReplaceLine
~~~

# `$`

Return a string representation of a ReplaceLine object.

~~~nim
func `$`(replaceLine: ReplaceLine): string
~~~

# stringSegment

Return a string segment made from the fragment. AtEnd is true when the fragment ends the line.

~~~nim
proc stringSegment(fragment: string; atEnd: bool): string {.
    raises: [ValueError], tags: [].}
~~~

# varSegment

Return a variable segment made from the dot name. AtEnd is true when the bracketed variable ends the line.

~~~nim
proc varSegment(dotName: string; atEnd: bool): string {.raises: [ValueError],
    tags: [].}
~~~

# lineToSegments

Convert a line to a list of segments. No warnings.

~~~nim
proc lineToSegments(line: string): seq[string] {.raises: [ValueError], tags: [].}
~~~

# varSegmentDotName

Given a variable segment, return its dot name.

~~~nim
func varSegmentDotName(segment: string): string
~~~

# writeTempSegments

Write the replacement block's stored segments to the result stream with the variables filled in.  The lineNum is the beginning line of the replacement block.

~~~nim
proc writeTempSegments(env: var Env; tempSegments: var TempSegments;
                       lineNum: Natural; variables: Variables) {.
    raises: [IOError, OSError, KeyError, Exception, ValueError],
    tags: [ReadIOEffect, RootEffect, WriteIOEffect, TimeEffect].}
~~~

# allocTempSegments

Create a TempSegments object. This reserves memory for a line buffer and creates a backing temp file. Call the closeDeleteTempSegments procedure when done to free the memory and to close and delete the file.

~~~nim
proc allocTempSegments(env: var Env; lineNum: Natural): Option[TempSegments] {.
    raises: [ValueError, IOError, OSError, Exception],
    tags: [ReadEnvEffect, ReadIOEffect, WriteIOEffect, WriteDirEffect].}
~~~

# closeDeleteTempSegments

Close the TempSegments and delete its backing temporary file.

~~~nim
proc closeDeleteTempSegments(tempSegments: TempSegments) {.
    raises: [Exception, IOError, OSError], tags: [WriteIOEffect, WriteDirEffect].}
~~~

# storeLineSegments

Divide the line into segments and write them to the TempSegments' temp file.

~~~nim
proc storeLineSegments(env: var Env; tempSegments: TempSegments; line: string) {.
    raises: [ValueError, IOError, OSError], tags: [WriteIOEffect].}
~~~

# yieldReplacementLine

Yield all the replacement block lines and one line after.

~~~nim
iterator yieldReplacementLine(env: var Env; firstReplaceLine: string;
                              lb: var LineBuffer; prepostTable: PrepostTable;
                              command: string; maxLines: Natural): ReplaceLine {.
    raises: [ValueError, KeyError, IOError, OSError],
    tags: [WriteIOEffect, ReadIOEffect].}
~~~


---
⦿ Markdown page generated by [StaticTea](https://github.com/flenniken/statictea/) from nim doc comments. ⦿
