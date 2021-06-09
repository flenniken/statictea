[StaticTea Modules](/)

# replacement.nim

Handle the replacement block lines.

# Index

* type: [ReplaceLineKind](#user-content-a0) &mdash; Line type returned by yieldReplacementLine.
* type: [ReplaceLine](#user-content-a1) &mdash; Line information returned by yieldReplacementLine.
* [newReplaceLine](#user-content-a2) &mdash; Return a ReplaceLine object.
* [`$`](#user-content-a3) &mdash; Return a string representation of a ReplaceLine.
* [writeTempSegments](#user-content-a4) &mdash; Write the updated replacement block to the result stream.
* [closeDelete](#user-content-a5) &mdash; Close the TempSegments and delete its backing temporary file.
* [storeLineSegments](#user-content-a6) &mdash; Divide the line into segments and write them to the TempSegments' temp file.
* [yieldReplacementLine](#user-content-a7) &mdash; Yield all the replacement block lines and the endblock line too, if it exists.
* [newTempSegments](#user-content-a8) &mdash; Read replacement block lines and return a TempSegments object containing the compiled block.

# <a id="a0"></a>ReplaceLineKind

Line type returned by yieldReplacementLine.

```nim
ReplaceLineKind = enum
  rlReplaceLine,            ## A replacement block line.
  rlEndblockLine             ## The endblock line.
```


# <a id="a1"></a>ReplaceLine

Line information returned by yieldReplacementLine.

```nim
ReplaceLine = object
  kind*: ReplaceLineKind
  line*: string

```


# <a id="a2"></a>newReplaceLine

Return a ReplaceLine object.

```nim
func newReplaceLine(kind: ReplaceLineKind; line: string): ReplaceLine
```


# <a id="a3"></a>`$`

Return a string representation of a ReplaceLine.

```nim
func `$`(replaceLine: ReplaceLine): string
```


# <a id="a4"></a>writeTempSegments

Write the updated replacement block to the result stream.  It does it by writing all the stored segments and updating variable segments as it goes. The lineNum is the beginning line of the replacement block.

```nim
proc writeTempSegments(env: var Env; tempSegments: var TempSegments;
                       lineNum: Natural; variables: Variables)
```


# <a id="a5"></a>closeDelete

Close the TempSegments and delete its backing temporary file.

```nim
proc closeDelete(tempSegments: TempSegments)
```


# <a id="a6"></a>storeLineSegments

Divide the line into segments and write them to the TempSegments' temp file.

```nim
proc storeLineSegments(env: var Env; tempSegments: TempSegments;
                       prepostTable: PrepostTable; line: string)
```


# <a id="a7"></a>yieldReplacementLine

Yield all the replacement block lines and the endblock line too, if it exists.

```nim
iterator yieldReplacementLine(env: var Env; firstReplaceLine: string;
                              lb: var LineBuffer; prepostTable: PrepostTable;
                              command: string; maxLines: Natural): ReplaceLine
```


# <a id="a8"></a>newTempSegments

Read replacement block lines and return a TempSegments object containing the compiled block. Call writeTempSegments to write out the segments. Call closeDelete to close and delete the associated temp file.

```nim
proc newTempSegments(env: var Env; lb: var LineBuffer;
                     prepostTable: PrepostTable; command: string;
                     repeat: Natural; variables: Variables): Option[TempSegments]
```



---
⦿ StaticTea markdown template for nim doc comments. ⦿
