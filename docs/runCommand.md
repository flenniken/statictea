# runCommand.nim

Run a command and fill in the variables dictionaries.

* [runCommand.nim](../src/runCommand.nim) &mdash; Nim source code.
# Index

* type: [Statement](#statement) &mdash; A Statement object stores the statement text and where it
starts in the template file.
* type: [ValueAndLength](#valueandlength) &mdash; A value and the length of the matching text in the statement.
* [newValueAndLength](#newvalueandlength) &mdash; Create a newValueAndLength object.
* [newValueAndLengthOr](#newvalueandlengthor) &mdash; Create a ValueAndLengthOr warning.
* [newValueAndLengthOr](#newvalueandlengthor-1) &mdash; Create a ValueAndLengthOr warning.
* [newValueAndLengthOr](#newvalueandlengthor-2) &mdash; Create a ValueAndLengthOr value.
* [newValueAndLengthOr](#newvalueandlengthor-3) &mdash; Create a ValueAndLengthOr.
* [newLengthOr](#newlengthor) &mdash; Create a LengthOr warning.
* [newLengthOr](#newlengthor-1) &mdash; Create a LengthOr value.
* [newStatement](#newstatement) &mdash; Create a new statement.
* [startColumn](#startcolumn) &mdash; Return enough spaces to point at the warning column.
* [getFragmentAndPos](#getfragmentandpos) &mdash; Return a statement fragment, and new position to show the given position.
* [getWarnStatement](#getwarnstatement) &mdash; Return a multiline error message.
* [warnStatement](#warnstatement) &mdash; Show an invalid statement with a pointer pointing at the start of the problem.
* [`==`](#) &mdash; Return true when the two statements are equal.
* [`$`](#-1) &mdash; Return a string representation of a Statement.
* [yieldStatements](#yieldstatements) &mdash; Iterate through the command's statements.
* [getMultilineStr](#getmultilinestr) &mdash; Return the triple quoted string literal.
* [getString](#getstring) &mdash; Return a literal string value and match length from a statement.
* [getNumber](#getnumber) &mdash; Return the literal number value and match length from the statement.
* [ifFunctions](#iffunctions) &mdash; Return the if/if0 function's value and the length.
* [andOrFunctions](#andorfunctions) &mdash; Return the and/or function's value and the length.
* [getFunctionValueAndLength](#getfunctionvalueandlength) &mdash; Return the function's value and the length.
* [runBoolOp](#runboolop) &mdash; Evaluate the bool expression and return a bool value or a warning message.
* [runCompareOp](#runcompareop) &mdash; Evaluate the comparison and return a bool value or a warning message.
* [skipCondition](#skipcondition) &mdash; Skip the condition expression.
* [getCondition](#getcondition) &mdash; Return the bool value of the condition expression and its length.
* [getValueAndLength](#getvalueandlength) &mdash; Return the value and length of the item that the start parameter points at which is a string, number, variable, function or list.
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

# ValueAndLength

A value and the length of the matching text in the statement. For the example statement: "var = 567 ". The value 567 starts at index 6 and the matching length is 4 because it includes the trailing space. For example "id = row(3 )" the value is 3 and the length is 2. Exit is set true by the return function to exit a command.

```nim
ValueAndLength = object
  value*: Value
  length*: Natural
  exit*: bool

```

# newValueAndLength

Create a newValueAndLength object.

```nim
proc newValueAndLength(value: Value; length: Natural; exit = false): ValueAndLength
```

# newValueAndLengthOr

Create a ValueAndLengthOr warning.

```nim
func newValueAndLengthOr(warning: MessageId; p1 = ""; pos = 0): ValueAndLengthOr
```

# newValueAndLengthOr

Create a ValueAndLengthOr warning.

```nim
func newValueAndLengthOr(warningData: WarningData): ValueAndLengthOr
```

# newValueAndLengthOr

Create a ValueAndLengthOr value.

```nim
func newValueAndLengthOr(value: Value; length: Natural; exit = false): ValueAndLengthOr
```

# newValueAndLengthOr

Create a ValueAndLengthOr.

```nim
func newValueAndLengthOr(val: ValueAndLength): ValueAndLengthOr
```

# newLengthOr

Create a LengthOr warning.

```nim
func newLengthOr(warning: MessageId; p1 = ""; pos = 0): LengthOr
```

# newLengthOr

Create a LengthOr value.

```nim
func newLengthOr(length: Natural): LengthOr
```

# newStatement

Create a new statement.

```nim
func newStatement(text: string; lineNum: Natural = 1; start: Natural = 0): Statement
```

# startColumn

Return enough spaces to point at the warning column.  Used under the statement line.

```nim
proc startColumn(start: Natural; symbol: string = "^"): string
```

# getFragmentAndPos

Return a statement fragment, and new position to show the given position.

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
func getMultilineStr(text: string; start: Natural): StrAndPosOr
```

# getString

Return a literal string value and match length from a statement. The start parameter is the index of the first quote in the statement and the return length includes optional trailing white space after the last quote.

```nim
func getString(statement: Statement; start: Natural): ValueAndLengthOr
```

# getNumber

Return the literal number value and match length from the statement. The start index points at a digit or minus sign. The length includes the trailing whitespace.

```nim
proc getNumber(statement: Statement; start: Natural): ValueAndLengthOr
```

# ifFunctions

Return the if/if0 function's value and the length. It conditionally runs one of its parameters. Start points at the first parameter of the function. The length includes the trailing whitespace after the ending ).

```nim
proc ifFunctions(functionName: string; statement: Statement; start: Natural;
                 variables: Variables; list = false): ValueAndLengthOr
```

# andOrFunctions

Return the and/or function's value and the length. The and function stops on the first false. The or function stops on the first true. The rest of the arguments are skipped. Start points at the first parameter of the function. The length includes the trailing whitespace after the ending ).

```nim
proc andOrFunctions(functionName: string; statement: Statement; start: Natural;
                    variables: Variables; list = false): ValueAndLengthOr
```

# getFunctionValueAndLength

Return the function's value and the length. Start points at the first parameter of the function. The length includes the trailing whitespace after the ending ).

```nim
proc getFunctionValueAndLength(functionName: string; statement: Statement;
                               start: Natural; variables: Variables;
                               list = false; skip: bool): ValueAndLengthOr
```

# runBoolOp

Evaluate the bool expression and return a bool value or a warning message.

```nim
proc runBoolOp(left: Value; op: string; right: Value): ValueOr
```

# runCompareOp

Evaluate the comparison and return a bool value or a warning message.

```nim
proc runCompareOp(left: Value; op: string; right: Value): ValueOr
```

# skipCondition

Skip the condition expression. Start points at the ( and the function finds the matching ) and trailing whitespace and returns the length. When not found return a message.

```nim
func skipCondition(statement: string; start: Natural): LengthOr
```

# getCondition

Return the bool value of the condition expression and its length. The start index points at the ( left parentheses. The length includes the trailing whitespace after the ending ).

```nim
proc getCondition(statement: Statement; start: Natural; variables: Variables;
                  skip: bool = false): ValueAndLengthOr
```

# getValueAndLength

Return the value and length of the item that the start parameter points at which is a string, number, variable, function or list. The length returned includes the trailing whitespace after the item. So the ending position is pointing at the end of the statement, or at the first whitspace character after the item. When skip is true, the return value is 0 and functions are not executed.

```nim
proc getValueAndLength(statement: Statement; start: Natural;
                       variables: Variables; skip: bool): ValueAndLengthOr
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
