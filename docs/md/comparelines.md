# comparelines.nim

Compare lines of text.


* [comparelines.nim](../../src/comparelines.nim) &mdash; Nim source code.
# Index

* type: [OpResultStr](#opresultstr) &mdash; On success return T, otherwise return a message telling what went wrong.
* [opValueStr](#opvaluestr) &mdash; Return an OpResultStr with a value.
* [opMessageStr](#opmessagestr) &mdash; Return an OpResultStr with a message why the value cannot be returned.
* [splitNewLines](#splitnewlines) &mdash; Split lines and keep the line endings.
* [linesSideBySide](#linessidebyside) &mdash; Show the two sets of lines side by side.
* [testLinesSideBySide](#testlinessidebyside) &mdash; If the two strings are equal, return true, else show the differences and return false.
* [compareFiles](#comparefiles) &mdash; Compare two files and return the differences.

# OpResultStr

On success return T, otherwise return a message telling what went wrong.


~~~nim
OpResultStr[T] = OpResult[T, string]
~~~

# opValueStr

Return an OpResultStr with a value.


~~~nim
func opValueStr[T](value: T): OpResultStr[T]
~~~

# opMessageStr

Return an OpResultStr with a message why the value cannot be returned.


~~~nim
func opMessageStr[T](message: string): OpResultStr[T]
~~~

# splitNewLines

Split lines and keep the line endings. Works with \n and \r\n
type endings. keyword: splitLines


~~~nim
func splitNewLines(content: string): seq[string]
~~~

# linesSideBySide

Show the two sets of lines side by side.  For each pair of lines
one is above and one is below.


~~~nim
proc linesSideBySide(gotContent: string; expectedContent: string;
                     spacesToo = false): string {.raises: [ValueError], tags: [].}
~~~

# testLinesSideBySide

If the two strings are equal, return true, else show the
differences and return false.


~~~nim
proc testLinesSideBySide(got: string; expected: string): bool {.
    raises: [ValueError], tags: [].}
~~~

# compareFiles

Compare two files and return the differences. When they are equal
return "".


~~~nim
proc compareFiles(gotFilename: string; expectedFilename: string): OpResultStr[
    string] {.raises: [ValueError], tags: [ReadIOEffect].}
~~~


---
⦿ Markdown page generated by [StaticTea](https://github.com/flenniken/statictea/) from nim doc comments. ⦿
