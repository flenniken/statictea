[StaticTea Modules](/)

# regexes.nim

Perl regular expression matching.

# Index

* type: [Matches](#user-content-a0) &mdash; Holds the result of a match.
* [getGroup](#user-content-a1) &mdash; Get the first group in matches if it exists, else return &quot;&quot;.
* [get2Groups](#user-content-a2) &mdash; Get the first two groups in matches.
* [get3Groups](#user-content-a3) &mdash; Get the first three groups in matches.
* [matchRegex](#user-content-a4) &mdash; Match a regular expression pattern in a string.
* [matchPatternCached](#user-content-a5) &mdash; Match a pattern in a string.
* [matchPattern](#user-content-a6) &mdash; Match a regular expression pattern in a string.

# <a id="a0"></a>Matches

Holds the result of a match.

```nim
Matches = object
  groups*: seq[string]
  length*: Natural
  start*: Natural

```


# <a id="a1"></a>getGroup

Get the first group in matches if it exists, else return "".

```nim
func getGroup(matches: Matches): string
```


# <a id="a2"></a>get2Groups

Get the first two groups in matches. If one of the groups doesn't exist, "" is returned for it.

```nim
func get2Groups(matches: Matches): (string, string)
```


# <a id="a3"></a>get3Groups

Get the first three groups in matches. If one of the groups doesn't exist, "" is returned for it.

```nim
func get3Groups(matches: Matches): (string, string, string)
```


# <a id="a4"></a>matchRegex

Match a regular expression pattern in a string.

```nim
func matchRegex(str: string; regex: Regex; start: Natural = 0): Option[Matches]
```


# <a id="a5"></a>matchPatternCached

Match a pattern in a string. Cache the compiled regular expression pattern.

```nim
proc matchPatternCached(str: string; pattern: string; start: Natural = 0): Option[
    Matches]
```


# <a id="a6"></a>matchPattern

Match a regular expression pattern in a string.

```nim
func matchPattern(str: string; pattern: string; start: Natural = 0): Option[
    Matches]
```



---
⦿ StaticTea markdown template for nim doc comments. ⦿
