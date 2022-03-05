# matches.nim

Regular expression matching methods.

* [matches.nim](../src/matches.nim) &mdash; Nim source code.
# Index

* type: [PrepostTable](#preposttable) &mdash; The prefix postfix pairs stored in an ordered dictionary.
* [makeDefaultPrepostTable](#makedefaultpreposttable) &mdash; Return the default ordered table that maps prefixes to postfixes.
* [makeUserPrepostTable](#makeuserpreposttable) &mdash; Return the user's ordered table that maps prefixes to postfixes.
* [matchPrefix](#matchprefix) &mdash; Match lines that start with one of the prefixes in the given table plus optional following whitespace.
* [matchCommand](#matchcommand) &mdash; Match statictea commands.
* [matchLastPart](#matchlastpart) &mdash; Match the last part of a command line.
* [getLastPart](#getlastpart) &mdash; Return the optional plus and line endings from the line.
* [matchAllSpaceTab](#matchallspacetab) &mdash; Match a line of all spaces or tabs.
* [matchTabSpace](#matchtabspace) &mdash; Match one or more spaces or tabs.
* [notEmptyOrSpaces](#notemptyorspaces) &mdash; Return true when a statement is not empty or not all whitespace.
* [matchEqualSign](#matchequalsign) &mdash; Match an equal sign or "&=" and the optional trailing whitespace.
* [matchLeftParentheses](#matchleftparentheses) &mdash; Match a left parenthese and the optional trailing whitespace.
* [matchCommaParentheses](#matchcommaparentheses) &mdash; Match a comma or right parentheses and the optional trailing whitespace.
* [matchRightParentheses](#matchrightparentheses) &mdash; Match a right parentheses and the optional trailing whitespace.
* [matchNumber](#matchnumber) &mdash; Match a number and the optional trailing whitespace.
* [matchNumberNotCached](#matchnumbernotcached) &mdash; Match a number and the optional trailing whitespace.
* [matchLeftBracket](#matchleftbracket) &mdash; Match everything up to a left backet.
* [matchFileLine](#matchfileline) &mdash; Match a file and line number like: filename(234).
* [matchVersion](#matchversion) &mdash; Match a StaticTea version number.
* [matchVersionNotCached](#matchversionnotcached) &mdash; Match a StaticTea version number.
* [matchDotNames](#matchdotnames) &mdash; Matches variable dot names and surrounding whitespace.

# PrepostTable

The prefix postfix pairs stored in an ordered dictionary.

```nim
PrepostTable = OrderedTable[string, string]
```

# makeDefaultPrepostTable

Return the default ordered table that maps prefixes to postfixes.

```nim
proc makeDefaultPrepostTable(): PrepostTable
```

# makeUserPrepostTable

Return the user's ordered table that maps prefixes to postfixes. This is used when the user specifies prefixes on the command line and it does not contain any defaults.

```nim
proc makeUserPrepostTable(prepostList: seq[Prepost]): PrepostTable
```

# matchPrefix

Match lines that start with one of the prefixes in the given table plus optional following whitespace.

```nim
proc matchPrefix(line: string; prepostTable: PrepostTable; start: Natural = 0): Option[
    Matches]
```

# matchCommand

Match statictea commands.

```nim
proc matchCommand(line: string; start: Natural = 0): Option[Matches]
```

# matchLastPart

Match the last part of a command line.  It matches the optional continuation plus character, the optional postfix and the optional line endings.

```nim
proc matchLastPart(line: string; postfix: string; start: Natural = 0): Option[
    Matches]
```

# getLastPart

Return the optional plus and line endings from the line.

```nim
proc getLastPart(line: string; postfix: string): Option[Matches]
```

# matchAllSpaceTab

Match a line of all spaces or tabs.

```nim
proc matchAllSpaceTab(line: string; start: Natural = 0): Option[Matches]
```

# matchTabSpace

Match one or more spaces or tabs.

```nim
proc matchTabSpace(line: string; start: Natural = 0): Option[Matches]
```

# notEmptyOrSpaces

Return true when a statement is not empty or not all whitespace.

```nim
proc notEmptyOrSpaces(text: string): bool
```

# matchEqualSign

Match an equal sign or "&=" and the optional trailing whitespace. Return the operator in the group, "=" or "&=".

```nim
proc matchEqualSign(line: string; start: Natural = 0): Option[Matches]
```

# matchLeftParentheses

Match a left parenthese and the optional trailing whitespace.

```nim
proc matchLeftParentheses(line: string; start: Natural = 0): Option[Matches]
```

# matchCommaParentheses

Match a comma or right parentheses and the optional trailing whitespace.

```nim
proc matchCommaParentheses(line: string; start: Natural = 0): Option[Matches]
```

# matchRightParentheses

Match a right parentheses and the optional trailing whitespace.

```nim
proc matchRightParentheses(line: string; start: Natural = 0): Option[Matches]
```

# matchNumber

Match a number and the optional trailing whitespace. Return the optional decimal point that tells whether the number is a float or integer.

```nim
proc matchNumber(line: string; start: Natural = 0): Option[Matches]
```

# matchNumberNotCached

Match a number and the optional trailing whitespace. Return the optional decimal point that tells whether the number is a float or integer.

```nim
func matchNumberNotCached(line: string; start: Natural = 0): Option[Matches]
```

# matchLeftBracket

Match everything up to a left backet. The match length includes
the bracket.

A replacement variable is inside brackets.

~~~
text on the line {variable} more text {variable2} asdf
                  ^
~~~~

```nim
proc matchLeftBracket(line: string; start: Natural = 0): Option[Matches]
```

# matchFileLine

Match a file and line number like: filename(234).

```nim
proc matchFileLine(line: string; start: Natural = 0): Option[Matches]
```

# matchVersion

Match a StaticTea version number.

```nim
proc matchVersion(line: string; start: Natural = 0): Option[Matches]
```

# matchVersionNotCached

Match a StaticTea version number.

```nim
func matchVersionNotCached(line: string; start: Natural = 0): Option[Matches]
```

# matchDotNames

Matches variable dot names and surrounding whitespace. Return the
leading whitespace and dot names as one string like "a.b.c.d".
This is used to match functions too. They look like a variable
followed by an open parentheses.

A dot name is a list of variable names separated by dots.
You can have 1 to 5 variable names in a dot name.

A variable name starts with a letter followed by letters, digits
and underscores limited to a total of 64 characters.

The match stops on the first non matching character. You need to
check the next character to see whether it makes sense in the
statement, for example, "t." matches and returns "t" but it is a
syntax error.

Return two groups, the leading whitespace and the dotNames. The
length returned includes the optional trailing whitespace.

~~~
let dotNamesO = matchDotNames(line, start)
if dotNamesO.isSome:
  let (leadingSpaces, dotNameStr) = dotNamesO.get()
~~~~

```nim
proc matchDotNames(line: string; start: Natural = 0): Option[Matches]
```


---
⦿ Markdown page generated by [StaticTea](https://github.com/flenniken/statictea/) from nim doc comments. ⦿
