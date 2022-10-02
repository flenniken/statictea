# runCommand.nim

Run a command and fill in the variables dictionaries.

* [runCommand.nim](../src/runCommand.nim) &mdash; Nim source code.
# Index

* type: [Statement](#statement) &mdash; A Statement object stores the statement text and where it
starts in the template file.
* [newPosOr](#newposor) &mdash; Create a PosOr warning.
* [newPosOr](#newposor-1) &mdash; Create a PosOr value.
* [`==`](#) &mdash; Return true when a equals b.
* [startColumn](#startcolumn) &mdash; Return enough spaces to point at the start byte position of the given text.
* [newStatement](#newstatement) &mdash; Create a new statement.
* [getFragmentAndPos](#getfragmentandpos) &mdash; Split up a long statement around the given position.
* [getWarnStatement](#getwarnstatement) &mdash; Return a multiline error message.
* [warnStatement](#warnstatement) &mdash; Show an invalid statement with a pointer pointing at the start of the problem.
* [`==`](#-1) &mdash; Return true when the two statements are equal.
* [`$`](#-2) &mdash; Return a string representation of a Statement.
* [yieldStatements](#yieldstatements) &mdash; Iterate through the command's statements.
* [getMultilineStr](#getmultilinestr) &mdash; Return the triple quoted string literal.
* [getString](#getstring) &mdash; Return a literal string value and position after it.
* [getNumber](#getnumber) &mdash; Return the literal number value and position after it.
* [skipArgument](#skipargument) &mdash; Skip past the argument.
* [ifFunctions](#iffunctions) &mdash; Return the if/if0 function's value and position after.
* [andOrFunctions](#andorfunctions) &mdash; Return the and/or function's value and the position after.
* [getFunctionValueAndPos](#getfunctionvalueandpos) &mdash; Return the function's value and the position after it.
* [runBoolOp](#runboolop) &mdash; Evaluate the bool expression and return a bool value.
* [runCompareOp](#runcompareop) &mdash; Evaluate the comparison and return a bool value.
* [getCondition](#getcondition) &mdash; Return the bool value of the condition expression and the position after it.
* [getValueAndPos](#getvalueandpos) &mdash; Return the value and position of the item that the start parameter points at which is a string, number, variable, list, or condition.
* [runStatement](#runstatement) &mdash; Run one statement and return the variable dot name string, operator and value.
* [runCommand](#runcommand) &mdash; Run a command and fill in the variables dictionaries.

# Statement

A Statement object stores the statement text and where it
starts in the template file.

* lineNum -- line number, starting at 1, where the statement
             starts.
* start -- index where the statement starts
* text -- the statement text.

```nim
Statement = object
  lineNum*: Natural
  start*: Natural
  text*: string

```

# newPosOr

Create a PosOr warning.

```nim
func newPosOr(warning: MessageId; p1 = ""; pos = 0): PosOr
```

# newPosOr

Create a PosOr value.

```nim
func newPosOr(pos: Natural): PosOr
```

# `==`

Return true when a equals b.

```nim
proc `==`(a: PosOr; b: PosOr): bool
```

# startColumn

Return enough spaces to point at the start byte position of the given text.  This accounts for multibyte UTF-8 sequences that might be in the text.

```nim
proc startColumn(text: string; start: Natural; message: string = "^"): string
```

# newStatement

Create a new statement.

```nim
func newStatement(text: string; lineNum: Natural = 1; start: Natural = 0): Statement
```

# getFragmentAndPos

Split up a long statement around the given position.  Return the statement fragment, and the position where the fragment starts in the statement.

```nim
func getFragmentAndPos(statement: Statement; start: Natural): (string, Natural)
```

# getWarnStatement

Return a multiline error message.

```nim
proc getWarnStatement(filename: string; statement: Statement;
                      warningData: WarningData): string
```

# warnStatement

Show an invalid statement with a pointer pointing at the start of the problem. Long statements are trimmed around the problem area.

```nim
proc warnStatement(env: var Env; statement: Statement; warningData: WarningData;
                   sourceFilename = "")
```

# `==`

Return true when the two statements are equal.

```nim
func `==`(s1: Statement; s2: Statement): bool
```

# `$`

Return a string representation of a Statement.

```nim
func `$`(s: Statement): string
```

# yieldStatements

Iterate through the command's statements. Skip blank statements.

```nim
iterator yieldStatements(cmdLines: CmdLines): Statement
```

# getMultilineStr

Return the triple quoted string literal. The startPos points one
past the leading triple quote.  Return the parsed
string value and the ending position one past the trailing
whitespace.

```nim
func getMultilineStr(text: string; start: Natural): ValueAndPosOr
```

# getString

Return a literal string value and position after it. The start parameter is the index of the first quote in the statement and the return position is after the optional trailing white space following the last quote.

```nim
func getString(statement: Statement; start: Natural): ValueAndPosOr
```

# getNumber

Return the literal number value and position after it.  The start index points at a digit or minus sign. The position includes the trailing whitespace.

```nim
proc getNumber(statement: Statement; start: Natural): ValueAndPosOr
```

# skipArgument

Skip past the argument.  startPos points at the first character of a function argument.  Return the first non-whitespace character after the argument or a message when there is a problem.
~~~
a = fn( 1 )
        ^ ^
          ^^
a = fn( 1 , 2 )
        ^ ^
~~~~

```nim
func skipArgument(statement: Statement; startPos: Natural): PosOr
```

# ifFunctions

Return the if/if0 function's value and position after. It conditionally runs one of its arguments and skips the other. Start points at the first argument of the function. The position includes the trailing whitespace after the ending ).

```nim
proc ifFunctions(functionName: string; statement: Statement; start: Natural;
                 variables: Variables; list = false; bare = false): ValueAndPosOr
```

# andOrFunctions

Return the and/or function's value and the position after. The and function stops on the first false. The or function stops on the first true. The rest of the arguments are skipped. Start points at the first parameter of the function. The position includes the trailing whitespace after the ending ).

```nim
proc andOrFunctions(functionName: string; statement: Statement; start: Natural;
                    variables: Variables; list = false): ValueAndPosOr
```

# getFunctionValueAndPos

Return the function's value and the position after it. Start points at the first argument of the function. The position includes the trailing whitespace after the ending ).

```nim
proc getFunctionValueAndPos(dotNameStr: string; statement: Statement;
                            start: Natural; variables: Variables; list = false): ValueAndPosOr
```

# runBoolOp

Evaluate the bool expression and return a bool value.

```nim
proc runBoolOp(left: Value; op: string; right: Value): Value
```

# runCompareOp

Evaluate the comparison and return a bool value.

```nim
proc runCompareOp(left: Value; op: string; right: Value): Value
```

# getCondition

Return the bool value of the condition expression and the position after it.  The start index points at the ( left parentheses. The position includes the trailing whitespace after the ending ).

```nim
proc getCondition(statement: Statement; start: Natural; variables: Variables): ValueAndPosOr
```

# getValueAndPos

Return the value and position of the item that the start parameter points at which is a string, number, variable, list, or condition. The position returned includes the trailing whitespace after the item. So the ending position is pointing at the end of the statement, or at the first non-whitespace character after the item.

~~~
a = "tea" # string
    ^     ^
a = 123.5 # number
    ^     ^
a = t.row # variable
    ^     ^
a = [1, 2, 3] # list
    ^         ^
a = (c < 10) # condition
    ^        ^
a = cmp(b, c) # calling variable
    ^         ^
a = if( (b < c), d, e) # if
    ^                  ^
a = if( bool(len(b)), d, e) # if
    ^                       ^
        ^             ^
             ^     ^
                 ^^
                      ^  ^
                         ^  ^
~~~~

```nim
proc getValueAndPos(statement: Statement; start: Natural; variables: Variables): ValueAndPosOr
```

# runStatement

Run one statement and return the variable dot name string, operator and value.

```nim
proc runStatement(statement: Statement; variables: Variables): VariableDataOr
```

# runCommand

Run a command and fill in the variables dictionaries. Return "",
"skip" or "stop".

* "" -- output the replacement block. This is the default.
* "skip" -- skip this replacement block but continue with the
next.
* "stop" -- stop processing the block.

```nim
proc runCommand(env: var Env; cmdLines: CmdLines; variables: var Variables): string
```


---
⦿ Markdown page generated by [StaticTea](https://github.com/flenniken/statictea/) from nim doc comments. ⦿
