# runCommand.nim

Run a command.

* [runCommand.nim](../src/runCommand.nim) &mdash; Nim source code.
# Index

* type: [Statement](#statement) &mdash; A Statement object stores the statement text and where it
starts in the template file.
* type: [ValueAndLength](#valueandlength) &mdash; A value and the length of the matching text in the statement.
* [newStatement](#newstatement) &mdash; Create a new statement.
* [startColumn](#startcolumn) &mdash; Return enough spaces to point at the warning column.
* [warnStatement](#warnstatement) &mdash; Show an invalid statement with a pointer pointing at the start of the problem.
* [`==`](#) &mdash; Return true when the two statements are equal.
* [`$`](#) &mdash; Return a string representation of a Statement.
* [newValueAndLength](#newvalueandlength) &mdash; Create a newValueAndLength object.
* [getString](#getstring) &mdash; Return a literal string value and match length from a statement.
* [getNumber](#getnumber) &mdash; Return the literal number value and match length from the statement.
* [getFunctionValue](#getfunctionvalue) &mdash; Collect the function parameter values then call it.
* [getVarOrFunctionValue](#getvarorfunctionvalue) &mdash; Return the statement's right hand side value and the length matched.
* [runStatement](#runstatement) &mdash; Run one statement and assign a variable.
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


# warnStatement

Show an invalid statement with a pointer pointing at the start of the problem. Long statemetns are trimmed around the problem area.

```nim
proc warnStatement(env: var Env; statement: Statement; warning: Warning;
                   start: Natural; p1: string = ""; p2: string = "")
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


# getString

Return a literal string value and match length from a statement. The start parameter is the index of the first quote in the statement and the return length includes optional trailing white space after the last quote.

```nim
proc getString(env: var Env; prepostTable: PrepostTable; statement: Statement;
               start: Natural): Option[ValueAndLength]
```


# getNumber

Return the literal number value and match length from the statement. The start index points at a digit or minus sign.

```nim
proc getNumber(env: var Env; prepostTable: PrepostTable; statement: Statement;
               start: Natural): Option[ValueAndLength]
```


# getFunctionValue

Collect the function parameter values then call it. Start should be pointing at the first parameter.

```nim
proc getFunctionValue(env: var Env; prepostTable: PrepostTable;
                      function: FunctionPtr; statement: Statement;
                      start: Natural; variables: Variables): Option[
    ValueAndLength]
```


# getVarOrFunctionValue

Return the statement's right hand side value and the length matched. The right hand side must be a variable or a function. The right hand side starts at the index specified by start.

```nim
proc getVarOrFunctionValue(env: var Env; prepostTable: PrepostTable;
                           statement: Statement; start: Natural;
                           variables: Variables): Option[ValueAndLength]
```


# runStatement

Run one statement and assign a variable. Return the variable dot name string and value.

```nim
proc runStatement(env: var Env; statement: Statement;
                  prepostTable: PrepostTable; variables: var Variables): Option[
    VariableData]
```


# runCommand

Run a command and fill in the variables dictionaries.

```nim
proc runCommand(env: var Env; cmdLines: seq[string];
                cmdLineParts: seq[LineParts]; prepostTable: PrepostTable;
                variables: var Variables)
```



---
⦿ Markdown page generated by [StaticTea](https://github.com/flenniken/statictea/) from nim doc comments. ⦿
