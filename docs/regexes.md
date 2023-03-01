# regexes.nim

Perl regular expression matching.

Examples:

Match a string with "abc" in it:

~~~
let line = "123abc456"
let pattern = ".*abc"
let matchesO = matchPattern(line, pattern, start=0, numGroups=0)

check matchesO.isSome == true
check matchesO.get().length == 6
~~~

Match a file and line number like: filename(234):

~~~
let line = "template.html(87)"
let pattern = r"^(.*)(([0-9]+))$"
let matchesO = matchPatternCached(line, pattern, 0, 2)

check matchesO.isSome == true
let (filename, lineNum) = matchesO.get2Groups()
check filename == "template.html"
check lineNum == "87"
~~~

Replace the patterns in the string with their replacements:

~~~
var replacements: seq[Replacement]
replacements.add(newReplacement("abc", "456"))
replacements.add(newReplacement("def", ""))

let resultStringO = replaceMany("abcdefabc", replacements)

check resultStringO.isSome
check resultStringO.get() == "456456"
~~~

* [regexes.nim](../src/regexes.nim) &mdash; Nim source code.
# Index

* type: [Matches](#matches) &mdash; Holds the result of a match.
* type: [Replacement](#replacement) &mdash; Holds the regular expression pattern and its replacement for the replaceMany function.
* [newMatches](#newmatches) &mdash; Create a new Matches object with no groups.
* [newMatches](#newmatches-1) &mdash; Create a new Matches object with one group.
* [newMatches](#newmatches-2) &mdash; Create a new Matches object with two groups.
* [newMatches](#newmatches-3) &mdash; Create a new Matches object with three groups.
* [newMatches](#newmatches-4) &mdash; Create a Matches object with the given number of groups.
* [newMatches](#newmatches-5) &mdash; Create a Matches object with the given number of groups.
* [newReplacement](#newreplacement) &mdash; Create a new Replacement object.
* [getGroup](#getgroup) &mdash; Get the group in matches.
* [getGroupLen](#getgrouplen) &mdash; Get the group in matches.
* [getGroup](#getgroup-1) &mdash; Get the group in matches.
* [getGroupLen](#getgrouplen-1) &mdash; Get the group in matches and the match length.
* [get2Groups](#get2groups) &mdash; Get two groups in matches.
* [get2GroupsLen](#get2groupslen) &mdash; Get two groups and length in matches.
* [get2Groups](#get2groups-1) &mdash; Get two groups in matches.
* [get2GroupsLen](#get2groupslen-1) &mdash; Get two groups and length in matchesO.
* [get3Groups](#get3groups) &mdash; Get three groups in matches.
* [get3Groups](#get3groups-1) &mdash; Get three groups in matches.
* [get3GroupsLen](#get3groupslen) &mdash; Return the three groups and the length of the match.
* [getGroups](#getgroups) &mdash; Return the number of groups specified.
* [getGroups](#getgroups-1) &mdash; Return the number of groups specified.
* [matchPattern](#matchpattern) &mdash; Match a regular expression pattern in a string.
* [matchPatternCached](#matchpatterncached) &mdash; Match a pattern in a string and cache the compiled regular
expression pattern for next time.
* [replaceMany](#replacemany) &mdash; Replace the patterns in the string with their replacements.

# Matches

Holds the result of a match.
* groups -- list of matching groups
* length -- length of the match
* start -- where the match started
* numGroups -- number of groups

```nim
Matches = object
  groups*: seq[string]
  length*: Natural
  start*: Natural
  numGroups*: Natural

```

# Replacement

Holds the regular expression pattern and its replacement for the replaceMany function.

```nim
Replacement = object
  pattern*: string
  sub*: string

```

# newMatches

Create a new Matches object with no groups.

```nim
func newMatches(length: Natural; start: Natural): Matches 
```

# newMatches

Create a new Matches object with one group.

```nim
func newMatches(length: Natural; start: Natural; group: string): Matches 
```

# newMatches

Create a new Matches object with two groups.

```nim
func newMatches(length: Natural; start: Natural; group1: string; group2: string): Matches 
```

# newMatches

Create a new Matches object with three groups.

```nim
func newMatches(length: Natural; start: Natural; group1: string; group2: string;
                group3: string): Matches 
```

# newMatches

Create a Matches object with the given number of groups.

```nim
proc newMatches(length: Natural; start: Natural; groups: seq[string]): Matches 
```

# newMatches

Create a Matches object with the given number of groups.

```nim
proc newMatches(length: Natural; start: Natural; numGroups: Natural): Matches 
```

# newReplacement

Create a new Replacement object.

```nim
func newReplacement(pattern: string; sub: string): Replacement 
```

# getGroup

Get the group in matches.

```nim
func getGroup(matches: Matches): string 
```

# getGroupLen

Get the group in matches.

```nim
func getGroupLen(matches: Matches): (string, Natural) 
```

# getGroup

Get the group in matches.

```nim
func getGroup(matchesO: Option[Matches]): string 
```

# getGroupLen

Get the group in matches and the match length.

```nim
func getGroupLen(matchesO: Option[Matches]): (string, Natural) 
```

# get2Groups

Get two groups in matches.

```nim
func get2Groups(matches: Matches): (string, string) 
```

# get2GroupsLen

Get two groups and length in matches.

```nim
func get2GroupsLen(matches: Matches): (string, string, Natural) 
```

# get2Groups

Get two groups in matches.

```nim
func get2Groups(matchesO: Option[Matches]): (string, string) 
```

# get2GroupsLen

Get two groups and length in matchesO.

```nim
func get2GroupsLen(matchesO: Option[Matches]): (string, string, Natural) 
```

# get3Groups

Get three groups in matches.

```nim
func get3Groups(matches: Matches): (string, string, string) 
```

# get3Groups

Get three groups in matches.

```nim
func get3Groups(matchesO: Option[Matches]): (string, string, string) 
```

# get3GroupsLen

Return the three groups and the length of the match.

```nim
func get3GroupsLen(matchesO: Option[Matches]): (string, string, string, Natural) 
```

# getGroups

Return the number of groups specified. If one of the groups doesn't exist, "" is returned for it.

```nim
func getGroups(matches: Matches; numGroups: Natural): seq[string] 
```

# getGroups

Return the number of groups specified. If one of the groups doesn't exist, "" is returned for it.

```nim
func getGroups(matchesO: Option[Matches]; numGroups: Natural): seq[string] 
```

# matchPattern

Match a regular expression pattern in a string. Start is the
index in the string to start the search. NumGroups is the number
of groups in the pattern.

Note: the pattern uses the anchored option.

```nim
func matchPattern(str: string; pattern: string; start: Natural;
                  numGroups: Natural): Option[Matches] 
```

# matchPatternCached

Match a pattern in a string and cache the compiled regular
expression pattern for next time. Start is the index in the
string to start the search. NumGroups is the number of groups in
the pattern.

```nim
proc matchPatternCached(str: string; pattern: string; start: Natural;
                        numGroups: Natural): Option[Matches] {.
    raises: [KeyError], tags: [].}
```

# replaceMany

Replace the patterns in the string with their replacements.

```nim
proc replaceMany(str: string; replacements: seq[Replacement]): Option[string] {.
    raises: [ValueError], tags: [].}
```


---
⦿ Markdown page generated by [StaticTea](https://github.com/flenniken/statictea/) from nim doc comments. ⦿
