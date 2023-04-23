# regexes.nim

Perl regular expression matching.

Examples:

Match a string with "abc" in it:

~~~nim
let line = "123abc456"
let pattern = ".*abc"
let matchesO = matchPattern(line, pattern, start=0, numGroups=0)

check matchesO.isSome == true
check matchesO.get().length == 6
~~~

Match a file and line number like: filename(234):

~~~ nim
let line = "template.html(87)"
let pattern = r"^(.*)\(([0-9]+)\):$"
let matchesO = matchPattern(line, pattern, start = 0, groups = 2)

check matchesO.isSome == true
let (filename, lineNum, length) = matchesO.get2GroupsLen()
check filename == "template.html"
check lineNum == "87"
check length == 14
~~~

Replace the patterns in the string with their replacements:

~~~ nim
var replacements: seq[Replacement]
replacements.add(newReplacement("abc", "456"))
replacements.add(newReplacement("def", ""))

let resultStringO = replaceMany("abcdefabc", replacements)

check resultStringO.isSome
check resultStringO.get() == "456456"
~~~


* [regexes.nim](../../src/regexes.nim) &mdash; Nim source code.
# Index

* type: [CompiledPattern](#compiledpattern) &mdash; A compiled regular expression.
* type: [Matches](#matches) &mdash; Holds the result of a match.
* type: [Replacement](#replacement) &mdash; Holds the regular expression pattern and its replacement for the replaceMany function.
* [newMatches](#newmatches) &mdash; Create a new Matches object with no groups.
* [newMatches](#newmatches-1) &mdash; Create a new Matches object with one group.
* [newMatches](#newmatches-2) &mdash; Create a new Matches object with two groups.
* [newMatches](#newmatches-3) &mdash; Create a Matches object with the given number of groups.
* [getGroupLen](#getgrouplen) &mdash; Get the one group in matchesO and the match length.
* [get2GroupsLen](#get2groupslen) &mdash; Get two groups and length in matchesO.
* [getGroups](#getgroups) &mdash; Return the number of groups specified.
* [matchRegex](#matchregex) &mdash; Match a regular expression pattern in a string.
* [compilePattern](#compilepattern) &mdash; Compile the pattern and return a regex object.
* [matchPattern](#matchpattern) &mdash; Match a regular expression pattern in a string.
* [newReplacement](#newreplacement) &mdash; Create a new Replacement object.
* [replaceMany](#replacemany) &mdash; Replace the patterns in the string with their replacements.

# CompiledPattern

A compiled regular expression.


~~~nim
CompiledPattern = Regex
~~~

# Matches

Holds the result of a match.
* groups — list of matching groups
* length — length of the match
* start — where the match started
* numGroups — number of groups


~~~nim
Matches = object
  groups*: seq[string]
  length*: Natural
  start*: Natural
  numGroups*: Natural
~~~

# Replacement

Holds the regular expression pattern and its replacement for
the replaceMany function.


~~~nim
Replacement = object
  pattern*: string
  sub*: string
~~~

# newMatches

Create a new Matches object with no groups.


~~~nim
func newMatches(length: Natural; start: Natural): Matches
~~~

# newMatches

Create a new Matches object with one group.


~~~nim
func newMatches(length: Natural; start: Natural; group: string): Matches
~~~

# newMatches

Create a new Matches object with two groups.


~~~nim
func newMatches(length: Natural; start: Natural; group1: string; group2: string): Matches
~~~

# newMatches

Create a Matches object with the given number of groups.


~~~nim
proc newMatches(length: Natural; start: Natural; groups: seq[string]): Matches
~~~

# getGroupLen

Get the one group in matchesO and the match length.


~~~nim
func getGroupLen(matchesO: Option[Matches]): (string, Natural)
~~~

# get2GroupsLen

Get two groups and length in matchesO.


~~~nim
func get2GroupsLen(matchesO: Option[Matches]): (string, string, Natural)
~~~

# getGroups

Return the number of groups specified. If one of the groups doesn't
exist, "" is returned for it.


~~~nim
func getGroups(matchesO: Option[Matches]; numGroups: Natural): seq[string]
~~~

# matchRegex

Match a regular expression pattern in a string. Start is the
index in the string to start the search. NumGroups is the number
of groups in the pattern.


~~~nim
func matchRegex(str: string; regex: CompiledPattern; start: Natural;
                numGroups: Natural): Option[Matches]
~~~

# compilePattern

Compile the pattern and return a regex object.
Note: the pattern uses the anchored option.


~~~nim
func compilePattern(pattern: string): Option[CompiledPattern]
~~~

# matchPattern

Match a regular expression pattern in a string. Start is the
index in the string to start the search. NumGroups is the number
of groups in the pattern.

Note: the pattern uses the anchored option.


~~~nim
func matchPattern(str: string; pattern: string; start: Natural;
                  numGroups: Natural): Option[Matches]
~~~

# newReplacement

Create a new Replacement object.


~~~nim
func newReplacement(pattern: string; sub: string): Replacement
~~~

# replaceMany

Replace the patterns in the string with their replacements.


~~~nim
proc replaceMany(str: string; replacements: seq[Replacement]): Option[string] {.
    raises: [ValueError], tags: [].}
~~~


---
⦿ Markdown page generated by [StaticTea](https://github.com/flenniken/statictea/) from nim doc comments. ⦿
