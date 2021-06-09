[StaticTea Modules](/)

# matches.nim

Regular expression matching methods.

# Index

* type: [PrepostTable](#user-content-a0) &mdash; The prefix postfix pairs stored in an ordered dictionary.
* [makeDefaultPrepostTable](#user-content-a1) &mdash; Return the default ordered table that maps prefixes to postfixes.
* [makeUserPrepostTable](#user-content-a2) &mdash; Return the user's ordered table that maps prefixes to postfixes.
* [matchPrefix](#user-content-a3) &mdash; Match lines that start with one of the prefixes in the given table.
* [matchCommand](#user-content-a4) &mdash; Match statictea commands.
* [matchLastPart](#user-content-a5) &mdash; Match the last part of a command line.
* [getLastPart](#user-content-a6) &mdash; Return the optional plus and line endings from the line.
* [matchAllSpaceTab](#user-content-a7) &mdash; Match a line of all spaces or tabs.
* [matchTabSpace](#user-content-a8) &mdash; Match one or more spaces or tabs.
* [notEmptyOrSpaces](#user-content-a9) &mdash; Return true when a statement is not empty or not all whitespace.
* [matchEqualSign](#user-content-a10) &mdash; Match an equal sign and the optional trailing whitespace.
* [matchLeftParentheses](#user-content-a11) &mdash; Match a left parenthese and the optional trailing whitespace.
* [matchCommaParentheses](#user-content-a12) &mdash; Match a comma or right parentheses and the optional trailing whitespace.
* [matchRightParentheses](#user-content-a13) &mdash; Match a right parentheses and the optional trailing whitespace.
* [matchNumber](#user-content-a14) &mdash; Match a number and the optional trailing whitespace.
* [matchNumberNotCached](#user-content-a15) &mdash; Match a number and the optional trailing whitespace.
* [matchString](#user-content-a16) &mdash; Match a string inside either single or double quotes.
* [matchLeftBracket](#user-content-a17) &mdash; Match everything up to a left backet.
* [matchFileLine](#user-content-a18) &mdash; Match a file and line number like: filename(234).
* [matchVersion](#user-content-a19) &mdash; Match a StaticTea version number.
* [matchVersionNotCached](#user-content-a20) &mdash; Match a StaticTea version number.
* [matchDotNames](#user-content-a21) &mdash; Matches variable dot names and surrounding whitespace.

# <a id="a0"></a>PrepostTable

The prefix postfix pairs stored in an ordered dictionary.

```nim
PrepostTable = OrderedTable[string, string]
```


# <a id="a1"></a>makeDefaultPrepostTable

Return the default ordered table that maps prefixes to postfixes.

```nim
proc makeDefaultPrepostTable(): PrepostTable
```


# <a id="a2"></a>makeUserPrepostTable

Return the user's ordered table that maps prefixes to postfixes. This is used when the user specifies prefixes on the command line and it does not contain any defaults.

```nim
proc makeUserPrepostTable(prepostList: seq[Prepost]): PrepostTable
```


# <a id="a3"></a>matchPrefix

Match lines that start with one of the prefixes in the given table.

```nim
proc matchPrefix(line: string; prepostTable: PrepostTable; start: Natural = 0): Option[
    Matches]
```


# <a id="a4"></a>matchCommand

Match statictea commands.

```nim
proc matchCommand(line: string; start: Natural = 0): Option[Matches]
```


# <a id="a5"></a>matchLastPart

Match the last part of a command line.  It matches the optional continuation plus character, the optional postfix and the optional line endings.

```nim
proc matchLastPart(line: string; postfix: string; start: Natural = 0): Option[
    Matches]
```


# <a id="a6"></a>getLastPart

Return the optional plus and line endings from the line.

```nim
proc getLastPart(line: string; postfix: string): Option[Matches]
```


# <a id="a7"></a>matchAllSpaceTab

Match a line of all spaces or tabs.

```nim
proc matchAllSpaceTab(line: string; start: Natural = 0): Option[Matches]
```


# <a id="a8"></a>matchTabSpace

Match one or more spaces or tabs.

```nim
proc matchTabSpace(line: string; start: Natural = 0): Option[Matches]
```


# <a id="a9"></a>notEmptyOrSpaces

Return true when a statement is not empty or not all whitespace.

```nim
proc notEmptyOrSpaces(text: string): bool
```


# <a id="a10"></a>matchEqualSign

Match an equal sign and the optional trailing whitespace.

```nim
proc matchEqualSign(line: string; start: Natural = 0): Option[Matches]
```


# <a id="a11"></a>matchLeftParentheses

Match a left parenthese and the optional trailing whitespace.

```nim
proc matchLeftParentheses(line: string; start: Natural = 0): Option[Matches]
```


# <a id="a12"></a>matchCommaParentheses

Match a comma or right parentheses and the optional trailing whitespace.

```nim
proc matchCommaParentheses(line: string; start: Natural = 0): Option[Matches]
```


# <a id="a13"></a>matchRightParentheses

Match a right parentheses and the optional trailing whitespace.

```nim
proc matchRightParentheses(line: string; start: Natural = 0): Option[Matches]
```


# <a id="a14"></a>matchNumber

Match a number and the optional trailing whitespace. Return the optional decimal point that tells whether the number is a float or integer.

```nim
proc matchNumber(line: string; start: Natural = 0): Option[Matches]
```


# <a id="a15"></a>matchNumberNotCached

Match a number and the optional trailing whitespace. Return the optional decimal point that tells whether the number is a float or integer.

```nim
func matchNumberNotCached(line: string; start: Natural = 0): Option[Matches]
```


# <a id="a16"></a>matchString

Match a string inside either single or double quotes.  The optional white space after the string is matched too. There are two returned groups and only one will contain anything. The first is for single quotes and the second is for double quotes.

```nim
proc matchString(line: string; start: Natural = 0): Option[Matches]
```


# <a id="a17"></a>matchLeftBracket

Match everything up to a left backet. The match length includes the bracket.

```nim
proc matchLeftBracket(line: string; start: Natural = 0): Option[Matches]
```


# <a id="a18"></a>matchFileLine

Match a file and line number like: filename(234).

```nim
proc matchFileLine(line: string; start: Natural = 0): Option[Matches]
```


# <a id="a19"></a>matchVersion

Match a StaticTea version number.

```nim
proc matchVersion(line: string; start: Natural = 0): Option[Matches]
```


# <a id="a20"></a>matchVersionNotCached

Match a StaticTea version number.

```nim
func matchVersionNotCached(line: string; start: Natural = 0): Option[Matches]
```


# <a id="a21"></a>matchDotNames

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
⦿ StaticTea markdown template for nim doc comments. ⦿
