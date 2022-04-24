# variables.nim

Procedures for working with statictea variables.

There is one dictionary to hold the logically separate dictionaries,
g, h, s, t etc which makes passing them around easier.
The language allows local variables to be specified without the l
prefix and it allows functions to be specified without the f prefix.
Dot names ie: l.d.a can be used on the left hand side of the equal sign.

* [variables.nim](../src/variables.nim) &mdash; Nim source code.
# Index

* const: [outputValues](#outputvalues) &mdash; Where the replacement block's output goes.
* type: [Variables](#variables) &mdash; Dictionary holding all statictea variables in multiple distinct logical dictionaries.
* type: [VariableData](#variabledata) &mdash; A variable name, operator and value which is the result of
running a statement.
* [newVariableData](#newvariabledata) &mdash; Create a new VariableData object.
* [newVariableDataOr](#newvariabledataor) &mdash; Create a VariableData object containing a warning.
* [newVariableDataOr](#newvariabledataor-1) &mdash; Create a VariableData object containing a warning.
* [newVariableDataOr](#newvariabledataor-2) &mdash; Create a VariableData object containing a value.
* [`$`](#) &mdash; Return a string representation of VariableData.
* [newVarsDictOr](#newvarsdictor) &mdash; Return a new varsDictOr object containing a warning.
* [newVarsDictOr](#newvarsdictor-1) &mdash; Return a new VarsDict object containing a dictionary.
* [emptyVariables](#emptyvariables) &mdash; Create an empty variables object in its initial state.
* [getTeaVarIntDefault](#getteavarintdefault) &mdash; Return the int value of one of the tea dictionary integer items.
* [getTeaVarStringDefault](#getteavarstringdefault) &mdash; Return the string value of one of the tea dictionary string items.
* [resetVariables](#resetvariables) &mdash; Clear the local variables and reset the tea variables for running a command.
* [assignVariable](#assignvariable) &mdash; Assign the variable the given value if possible, else return a warning.
* [getVariable](#getvariable) &mdash; Look up the variable and return its value when found, else return a warning.
* [argsPrepostList](#argsprepostlist) &mdash; Create a prepost list of lists for t args.
* [getTeaArgs](#getteaargs) &mdash; Create the t args dictionary from the statictea arguments.

# outputValues

Where the replacement block's output goes.
* result -- output goes to the result file
* stdout -- output goes to the standard output stream
* stdout -- output goes to the standard error stream
* log -- output goes to the log file
* skip -- output goes to the bit bucket

```nim
outputValues = ["result", "stdout", "stderr", "log", "skip"]
```

# Variables

Dictionary holding all statictea variables in multiple distinct logical dictionaries.

```nim
Variables = VarsDict
```

# VariableData

A variable name, operator and value which is the result of
running a statement.

* dotNameStr -- the dot name tells which dictionary contains
the variable, i.e.: l.d.a
* operator -- the statement's operator, either = or &=
* value -- the variable's value

```nim
VariableData = object
  dotNameStr*: string
  operator*: string
  value*: Value

```

# newVariableData

Create a new VariableData object.

```nim
func newVariableData(dotNameStr: string; operator: string; value: Value): VariableData
```

# newVariableDataOr

Create a VariableData object containing a warning.

```nim
func newVariableDataOr(warning: Warning; p1 = ""; pos = 0): OpResultWarn[
    VariableData]
```

# newVariableDataOr

Create a VariableData object containing a warning.

```nim
func newVariableDataOr(warningData: WarningData): OpResultWarn[VariableData]
```

# newVariableDataOr

Create a VariableData object containing a value.

```nim
func newVariableDataOr(dotNameStr: string; operator = "="; value: Value): OpResultWarn[
    VariableData]
```

# `$`

Return a string representation of VariableData.

```nim
func `$`(v: VariableData): string
```

# newVarsDictOr

Return a new varsDictOr object containing a warning.

```nim
func newVarsDictOr(warning: Warning; p1: string = ""; pos = 0): OpResultWarn[
    VarsDict]
```

# newVarsDictOr

Return a new VarsDict object containing a dictionary.

```nim
func newVarsDictOr(varsDict: VarsDict): OpResultWarn[VarsDict]
```

# emptyVariables

Create an empty variables object in its initial state.

```nim
func emptyVariables(server: VarsDict = nil; shared: VarsDict = nil;
                    args: VarsDict = nil): Variables
```

# getTeaVarIntDefault

Return the int value of one of the tea dictionary integer items. If the value does not exist, return its default value.

```nim
func getTeaVarIntDefault(variables: Variables; varName: string): int64
```

# getTeaVarStringDefault

Return the string value of one of the tea dictionary string items. If the value does not exist, return its default value.

```nim
func getTeaVarStringDefault(variables: Variables; varName: string): string
```

# resetVariables

Clear the local variables and reset the tea variables for running a command.

```nim
proc resetVariables(variables: var Variables)
```

# assignVariable

Assign the variable the given value if possible, else return a warning.

```nim
proc assignVariable(variables: var Variables; dotNameStr: string; value: Value;
                    operator: string = "="): Option[WarningData]
```

# getVariable

Look up the variable and return its value when found, else return a warning.

```nim
proc getVariable(variables: Variables; dotNameStr: string): OpResultWarn[Value]
```

# argsPrepostList

Create a prepost list of lists for t args.

```nim
func argsPrepostList(prepostList: seq[Prepost]): seq[seq[string]]
```

# getTeaArgs

Create the t args dictionary from the statictea arguments.

```nim
func getTeaArgs(args: Args): Value
```


---
⦿ Markdown page generated by [StaticTea](https://github.com/flenniken/statictea/) from nim doc comments. ⦿
