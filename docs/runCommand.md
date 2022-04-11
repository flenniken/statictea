# runCommand.nim

Run a command and fill in the variables dictionaries.

* [runCommand.nim](../src/runCommand.nim) &mdash; Nim source code.
# Index

* type: [Statement](#statement) &mdash; A Statement object stores the statement text and where it
starts in the template file.
* type: [ValueAndLength](#valueandlength) &mdash; A value and the length of the matching text in the statement.
* [newValueAndLengthOr](#newvalueandlengthor) &mdash; Create a OpResultWarn[ValueAndLength] warning.
* [newValueAndLengthOr](#newvalueandlengthor-1) &mdash; Create a OpResultWarn[ValueAndLength] warning.
* [newValueAndLengthOr](#newvalueandlengthor-2) &mdash; Create a OpResultWarn[ValueAndLength] value.
* [newValueAndLengthOr](#newvalueandlengthor-3) &mdash; Create a OpResultWarn[ValueAndLength].
* [newVariableDataOr](#newvariabledataor) &mdash; Create a OpResultWarn[VariableData] warning.
* [newVariableDataOr](#newvariabledataor-1) &mdash; Create a OpResultWarn[VariableData] warning.
* [newVariableDataOr](#newvariabledataor-2) &mdash; Create a OpResultWarn[VariableData] value.
* [newLengthOr](#newlengthor) &mdash; Create a OpResultWarn[Natural] warning.
* [newLengthOr](#newlengthor-1) &mdash; Create a OpResultWarn[Natural] value.
* [newStatement](#newstatement) &mdash; Create a new statement.
* [startColumn](#startcolumn) &mdash; Return enough spaces to point at the warning column.
* [getWarnStatement](#getwarnstatement) &mdash; Return a multiline error message.
* [warnStatement](#warnstatement) &mdash; Show an invalid statement with a pointer pointing at the start of the problem.
* [`==`](#) &mdash; Return true when the two statements are equal.
* [`$`](#-1) &mdash; Return a string representation of a Statement.
* [newValueAndLength](#newvalueandlength) &mdash; Create a newValueAndLength object.
* [yieldStatements](#yieldstatements) &mdash; Iterate through the command's statements.
* [getString](#getstring) &mdash; Return a literal string value and match length from a statement.
* [getNumber](#getnumber) &mdash; Return the literal number value and match length from the statement.
* [ifFunction](#iffunction) &mdash; Handle the if0 and if1 functions which conditionally run one of their parameters.
* [getFunctionValueAndLength](#getfunctionvalueandlength) &mdash; Collect the function parameters then call it and return the function's value and the position after trailing whitespace.
* [runStatement](#runstatement) &mdash; Run one statement and return the variable dot name string, operator and value.
* [runCommand](#runcommand) &mdash; Run a command and fill in the variables dictionaries.

# Statement

A Statement object stores the statement text and where it
starts in the template file.

* lineNum -- Line number starting at 1 where the statement
             starts.
* start -- Column position starting at 1 where the statement
           starts on the line.
* text -- The statement text.

```nim
Statement = object
  lineNum*: Natural
  start*: Natural
  text*: string

```

# ValueAndLength

A value and the length of the matching text in the statement. For the example statement: "var = 567 ". The value 567 starts at index 6 and the matching length is 4 because it includes the trailing space. For example "id = row(3 )" the value is 3 and the length is 2.

```nim
ValueAndLength = object
  value*: Value
  length*: Natural

```

# newValueAndLengthOr

Create a OpResultWarn[ValueAndLength] warning.

```nim
func newValueAndLengthOr(warning: Warning; p1 = ""; pos = 0): OpResultWarn[
    ValueAndLength]
```

# newValueAndLengthOr

Create a OpResultWarn[ValueAndLength] warning.

```nim
func newValueAndLengthOr(warningData: WarningData): OpResultWarn[ValueAndLength]
```

# newValueAndLengthOr

Create a OpResultWarn[ValueAndLength] value.

```nim
func newValueAndLengthOr(value: Value; length: Natural): OpResultWarn[
    ValueAndLength]
```

# newValueAndLengthOr

Create a OpResultWarn[ValueAndLength].

```nim
func newValueAndLengthOr(val: ValueAndLength): OpResultWarn[ValueAndLength]
```

# newVariableDataOr

Create a OpResultWarn[VariableData] warning.

```nim
func newVariableDataOr(warning: Warning; p1 = ""; pos = 0): OpResultWarn[
    VariableData]
```

# newVariableDataOr

Create a OpResultWarn[VariableData] warning.

```nim
func newVariableDataOr(warningData: WarningData): OpResultWarn[VariableData]
```

# newVariableDataOr

Create a OpResultWarn[VariableData] value.

```nim
func newVariableDataOr(dotNameStr: string; operator = "="; value: Value): OpResultWarn[
    VariableData]
```

# newLengthOr

Create a OpResultWarn[Natural] warning.

```nim
func newLengthOr(warning: Warning; p1 = ""; pos = 0): OpResultWarn[Natural]
```

# newLengthOr

Create a OpResultWarn[Natural] value.

```nim
func newLengthOr(pos: Natural): OpResultWarn[Natural]
```

# newStatement

Create a new statement.

```nim
func newStatement(text: string; lineNum: Natural = 1; start: Natural = 1): Statement
```

# startColumn

Return enough spaces to point at the warning column.  Used under the statement line.

```nim
proc startColumn(start: Natural): string
```

# getWarnStatement

Return a multiline error message.

```nim
proc getWarnStatement(statement: Statement; warningData: WarningData;
                      templateFilename: string): string
```

# warnStatement

Show an invalid statement with a pointer pointing at the start of the problem. Long statements are trimmed around the problem area.

```nim
proc warnStatement(env: var Env; statement: Statement; warningData: WarningData)
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

# newValueAndLength

Create a newValueAndLength object.

```nim
proc newValueAndLength(value: Value; length: Natural): ValueAndLength
```

# yieldStatements

Iterate through the command's statements. Skip blank statements.

```nim
iterator yieldStatements(cmdLines: CmdLines): Statement
```

# getString

Return a literal string value and match length from a statement. The start parameter is the index of the first quote in the statement and the return length includes optional trailing white space after the last quote.

```nim
func getString(statement: Statement; start: Natural): OpResultWarn[
    ValueAndLength]
```

# getNumber

Return the literal number value and match length from the statement. The start index points at a digit or minus sign.

```nim
proc getNumber(statement: Statement; start: Natural): OpResultWarn[
    ValueAndLength]
```

# ifFunction

Handle the if0 and if1 functions which conditionally run one of their parameters.  Return the function's value and the position after trailing whitespace.  Start points at the first parameter.

```nim
proc ifFunction(functionName: string; statement: Statement; start: Natural;
                variables: Variables; list = false): OpResultWarn[ValueAndLength]
```

# getFunctionValueAndLength

Collect the function parameters then call it and return the function's value and the position after trailing whitespace. Start points at the first parameter.

```nim
proc getFunctionValueAndLength(functionName: string; statement: Statement;
                               start: Natural; variables: Variables;
                               list = false): OpResultWarn[ValueAndLength]
```

# runStatement

Run one statement and return the variable dot name string, operator and value.

```nim
proc runStatement(statement: Statement; variables: Variables): OpResultWarn[
    VariableData]
```

# runCommand

Run a command and fill in the variables dictionaries.

```nim
proc runCommand(env: var Env; cmdLines: CmdLines; variables: var Variables)
```


---
⦿ Markdown page generated by [StaticTea](https://github.com/flenniken/statictea/) from nim doc comments. ⦿
