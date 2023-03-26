# matches.nim

Methods for matching sub-strings.

* [matches.nim](../src/matches.nim) &mdash; Nim source code.
# Index

* const: [commands](#commands) &mdash; The StaticTea commands.
* [parsePrepost](#parseprepost) &mdash; Parse the prepost item on the terminal command line.
* [matchPrefix](#matchprefix) &mdash; Match lines that start with one of the prefixes in the given table plus optional following whitespace.
* [matchCommand](#matchcommand) &mdash; Match statictea commands.
* [matchLastPart](#matchlastpart) &mdash; Match the last part of a command line.
* [getLastPart](#getlastpart) &mdash; Return the optional plus sign and line endings from the line.
* [matchTabSpace](#matchtabspace) &mdash; Match one or more spaces or tabs starting at the given position.
* [emptyOrSpaces](#emptyorspaces) &mdash; Return true when the text is empty or all whitespace from start to the end.
* [matchEqualSign](#matchequalsign) &mdash; Match an equal sign or "&=" and the optional trailing whitespace.
* [matchCommaParentheses](#matchcommaparentheses) &mdash; Match a comma or right parentheses and the optional trailing whitespace.
* [matchNumber](#matchnumber) &mdash; Match a number and the optional trailing whitespace.
* [matchNumberNotCached](#matchnumbernotcached) &mdash; Match a number and the optional trailing whitespace.
* [matchUpToLeftBracket](#matchuptoleftbracket) &mdash; Match everything up to a left backet.
* [matchFileLine](#matchfileline) &mdash; Match a file and line number like: filename(234).
* [matchVersion](#matchversion) &mdash; Match a StaticTea version number.
* [matchVersionNotCached](#matchversionnotcached) &mdash; Match a StaticTea version number.
* [matchDotNames](#matchdotnames) &mdash; Matches variable dot names and surrounding whitespace.
* type: [GroupSymbol](#groupsymbol) &mdash; Grouping symbols we search for in the statements.
* [matchCommaOrSymbol](#matchcommaorsymbol) &mdash; Match a comma or the symbol and the optional trailing whitespace.
* [matchSymbol](#matchsymbol) &mdash; Match the symbol and the optional trailing whitespace.
* [matchNotOrParen](#matchnotorparen) &mdash; Match "not " or "(" and the trailing whitespace.
* [matchBoolExprOperator](#matchboolexproperator) &mdash; Match boolean expression operators (bool operators plus compareh operators) and the trailing whitespace.
* [matchCompareOperator](#matchcompareoperator) &mdash; Match the compare operators and the trailing whitespace.
* [matchReplCmd](#matchreplcmd) &mdash; Match the REPL commands and the trailing optional whitespace.
* [matchParameterType](#matchparametertype) &mdash; Match a parameter type and the trailing whitespace.
* [matchDocComment](#matchdoccomment) &mdash; Match a doc comment.
* [matchReturnStatement](#matchreturnstatement) &mdash; Match a return statement.

# commands

The StaticTea commands.
* nextline -- make substitutions in the next line
* block —- make substitutions in the next block of lines
* replace -— replace the block with a variable
* "#" -- code comment
* ":" -- continue a command
* endblock -- end the block and replace commands

~~~nim
commands: array[6, string] = ["nextline", "block", "replace", "#", ":",
                              "endblock"]
~~~

# parsePrepost

Parse the prepost item on the terminal command line.  A prefix is followed by an optional postfix, prefix[,postfix].  Each part contains 1 to 20 ascii characters including spaces but without control characters or commas.

~~~nim
proc parsePrepost(str: string): Option[tuple[prefix: string, postfix: string]]
~~~

# matchPrefix

Match lines that start with one of the prefixes in the given table plus optional following whitespace.

~~~nim
proc matchPrefix(line: string; prefixes: seq[string]; start: Natural = 0): Option[
    Matches] {.raises: [ValueError, KeyError], tags: [].}
~~~

# matchCommand

Match statictea commands.

~~~nim
proc matchCommand(line: string; start: Natural = 0): Option[Matches] {.
    raises: [ValueError, KeyError], tags: [].}
~~~

# matchLastPart

Match the last part of a command line.  It matches the optional continuation plus character, the optional postfix and the optional line endings. A match has two groups, the plus sign and the line ending. When nothing at the end, return groups: "", "".

~~~nim
proc matchLastPart(line: string; postfix: string; start: Natural = 0): Option[
    Matches] {.raises: [ValueError, KeyError], tags: [].}
~~~

# getLastPart

Return the optional plus sign and line endings from the line.

~~~nim
proc getLastPart(line: string; postfix: string): Option[Matches] {.
    raises: [ValueError, KeyError], tags: [].}
~~~

# matchTabSpace

Match one or more spaces or tabs starting at the given position.

~~~nim
proc matchTabSpace(line: string; start: Natural = 0): Option[Matches] {.
    raises: [KeyError], tags: [].}
~~~

# emptyOrSpaces

Return true when the text is empty or all whitespace from start to the end.

~~~nim
proc emptyOrSpaces(text: string; start: Natural = 0): bool {.raises: [KeyError],
    tags: [].}
~~~

# matchEqualSign

Match an equal sign or "&=" and the optional trailing whitespace. Return the operator in the group, "=" or "&=".

~~~nim
proc matchEqualSign(line: string; start: Natural = 0): Option[Matches] {.
    raises: [KeyError], tags: [].}
~~~

# matchCommaParentheses

Match a comma or right parentheses and the optional trailing whitespace.

~~~nim
proc matchCommaParentheses(line: string; start: Natural = 0): Option[Matches] {.
    raises: [KeyError], tags: [].}
~~~

# matchNumber

Match a number and the optional trailing whitespace. Return the optional decimal point that tells whether the number is a float or integer.

~~~nim
proc matchNumber(line: string; start: Natural = 0): Option[Matches] {.
    raises: [KeyError], tags: [].}
~~~

# matchNumberNotCached

Match a number and the optional trailing whitespace. Return the optional decimal point that tells whether the number is a float or integer. "Not cached" allows it to be called by a function because it has no side effects.

~~~nim
func matchNumberNotCached(line: string; start: Natural = 0): Option[Matches]
~~~

# matchUpToLeftBracket

Match everything up to a left backet. The match length includes
the bracket.

A replacement variable is inside brackets.

~~~
text on the line {variable} more text {variable2} asdf
                  ^
~~~

~~~nim
proc matchUpToLeftBracket(line: string; start: Natural = 0): Option[Matches] {.
    raises: [KeyError], tags: [].}
~~~

# matchFileLine

Match a file and line number like: filename(234).

~~~nim
proc matchFileLine(line: string; start: Natural = 0): Option[Matches] {.
    raises: [KeyError], tags: [].}
~~~

# matchVersion

Match a StaticTea version number.

~~~nim
proc matchVersion(line: string; start: Natural = 0): Option[Matches] {.
    raises: [KeyError], tags: [].}
~~~

# matchVersionNotCached

Match a StaticTea version number. "Not cached" allows it to be called by a function because it has no side effects.

~~~nim
func matchVersionNotCached(line: string; start: Natural = 0;
                           numGroups: Natural = 0): Option[Matches]
~~~

# matchDotNames

Matches variable dot names and surrounding whitespace. Return the dot names as one string like "a.b.c.d".

A dot name is a list of variable names separated y dots.
You can have 1 to 5 variable names in a dot name.

A variable name starts with a letter followed by letters, digits
minuses and underscores limited to a total of 64 characters.
No space is allowed between the function name and the left
parentheses or bracket.
Return three groups, the leading whitespace, the dotNames and the
optional left parentheses or bracket following the dot name. The
length returned includes the optional trailing whitespace.

Example call:

~~~
let (_, dotNameStr, leftParenBrack, dotNameLen) = matchesO.get3GroupsLen()
~~~

~~~nim
proc matchDotNames(line: string; start: Natural = 0): Option[Matches] {.
    raises: [ValueError, KeyError], tags: [].}
~~~

# GroupSymbol

Grouping symbols we search for in the statements.

~~~nim
GroupSymbol = enum
  gLeftParentheses, gRightParentheses, gLeftBracket, gRightBracket, gComma,
  gColon
~~~

# matchCommaOrSymbol

Match a comma or the symbol and the optional trailing whitespace.

~~~nim
proc matchCommaOrSymbol(line: string; symbol: GroupSymbol; start: Natural = 0): Option[
    Matches] {.raises: [KeyError], tags: [].}
~~~

# matchSymbol

Match the symbol and the optional trailing whitespace.

~~~nim
proc matchSymbol(line: string; symbol: GroupSymbol; start: Natural = 0): Option[
    Matches] {.raises: [KeyError], tags: [].}
~~~

# matchNotOrParen

Match "not " or "(" and the trailing whitespace.

~~~nim
proc matchNotOrParen(line: string; start: Natural = 0): Option[Matches] {.
    raises: [KeyError], tags: [].}
~~~

# matchBoolExprOperator

Match boolean expression operators (bool operators plus compareh operators) and the trailing whitespace.  The bool operators require a trailing space but it isn't part of the operator name returned but still in the length.

~~~nim
proc matchBoolExprOperator(line: string; start: Natural): Option[Matches] {.
    raises: [KeyError], tags: [].}
~~~

# matchCompareOperator

Match the compare operators and the trailing whitespace.

~~~nim
proc matchCompareOperator(line: string; start: Natural): Option[Matches] {.
    raises: [KeyError], tags: [].}
~~~

# matchReplCmd

Match the REPL commands and the trailing optional whitespace. One space or end of line is required.

~~~nim
proc matchReplCmd(line: string; start: Natural): Option[Matches] {.
    raises: [KeyError], tags: [].}
~~~

# matchParameterType

Match a parameter type and the trailing whitespace.

~~~nim
proc matchParameterType(line: string; start: Natural): Option[Matches] {.
    raises: [KeyError], tags: [].}
~~~

# matchDocComment

Match a doc comment.

~~~nim
proc matchDocComment(line: string; start: Natural): Option[Matches] {.
    raises: [KeyError], tags: [].}
~~~

# matchReturnStatement

Match a return statement. a = return(...

~~~nim
proc matchReturnStatement(line: string; start: Natural): Option[Matches] {.
    raises: [KeyError], tags: [].}
~~~


---
⦿ Markdown page generated by [StaticTea](https://github.com/flenniken/statictea/) from nim doc comments. ⦿
