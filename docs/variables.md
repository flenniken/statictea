# variables.nim

Language variable methods.

 Here are the tea variables:

 - t.content -- content of the replace block.
 - t.maxLines -- maximum number of replacement block lines (lines before endblock).
 - t.maxRepeat -- maximum number of times to repeat the block.
 - t.output -- where the block output goes.
 - t.repeat -- controls how many times the block repeats.
 - t.row -- the current row number of a repeating block.
 - t.version -- the StaticTea version number.

 Here are the tea variables grouped by type:

 Constant:

 - t.version

 Dictionaries:

 - t -- tea system variables
 - l -- local variables
 - s -- read only server json variables
 - h -- read only shared json variables
 - f -- reserved
 - g -- global variables

 Integers:

 - t.maxLines -- default when not set: 50
 - t.maxRepeat -- default when not set: 100
 - t.repeat -- default when not set: 1
 - t.row -- 0 read only, automatically increments

 String:

 - t.content -- default when not set: ""

 String enum t.output:

 - "result" -- the block output goes to the result file (default)
 - "stderr" -- the block output goes to standard error
 - "log" -- the block output goes to the log file
 - "skip" -- the block is skipped

* [variables.nim](../src/variables.nim) &mdash; Nim source code.
# Index

* const: [outputValues](#outputvalues) &mdash; Tea output variable values.
* type: [Variables](#variables) &mdash; Dictionary holding all statictea variables.
* type: [VariableData](#variabledata) &mdash; A variable name and value.
* type: [ParentDictKind](#parentdictkind) &mdash; The kind of a ParentDict object, either a dict or warning.
* type: [ParentDict](#parentdict) &mdash; Contains the result of calling getParentDict, either a dictionary or a warning.
* [`$`](#) &mdash; Return a string representation of ParentDict.
* [`==`](#-1) &mdash; Return true when the two ParentDict are equal.
* [newParentDictWarn](#newparentdictwarn) &mdash; Return a new ParentDict object of the warning kind.
* [newParentDict](#newparentdict) &mdash; Return a new ParentDict object containing a dict.
* [emptyVariables](#emptyvariables) &mdash; Create an empty variables object in its initial state.
* [newVariableData](#newvariabledata) &mdash; Create a new VariableData object.
* [getTeaVarIntDefault](#getteavarintdefault) &mdash; Return the int value of one of the tea dictionary integer items.
* [getTeaVarStringDefault](#getteavarstringdefault) &mdash; Return the string value of one of the tea dictionary string items.
* [resetVariables](#resetvariables) &mdash; Clear the local variables and reset the tea variables for running a command.
* [getParentDict](#getparentdict) &mdash; Return the last component dictionary specified by the given names or, on error, return a warning.
* [assignVariable](#assignvariable) &mdash; Assign the variable the given value if possible, else return a warning.
* [getVariable](#getvariable) &mdash; Look up the variable and return its value when found, else return a warning.

# outputValues

Tea output variable values.

```nim
outputValues = ["result", "stderr", "log", "skip"]
```

# Variables

Dictionary holding all statictea variables.

```nim
Variables = VarsDict
```

# VariableData

A variable name and value. The names tells where the variable is stored, i.e.: s.varName

```nim
VariableData = object
  names*: seq[string]
  value*: Value

```

# ParentDictKind

The kind of a ParentDict object, either a dict or warning.

```nim
ParentDictKind = enum
  fdDict, fdWarning
```

# ParentDict

Contains the result of calling getParentDict, either a dictionary or a warning.

```nim
ParentDict = object
  case kind*: ParentDictKind
  of fdDict:
      dict*: VarsDict

  of fdWarning:
      warningData*: WarningData


```

# `$`

Return a string representation of ParentDict.

```nim
func `$`(parentDict: ParentDict): string
```

# `==`

Return true when the two ParentDict are equal.

```nim
func `==`(s1: ParentDict; s2: ParentDict): bool
```

# newParentDictWarn

Return a new ParentDict object of the warning kind. It contains a warning and the two optional strings that go with the warning.

```nim
func newParentDictWarn(warning: Warning; p1: string = ""; p2: string = ""): ParentDict
```

# newParentDict

Return a new ParentDict object containing a dict.

```nim
func newParentDict(dict: VarsDict): ParentDict
```

# emptyVariables

Create an empty variables object in its initial state.

```nim
func emptyVariables(server: VarsDict = nil; shared: VarsDict = nil): Variables
```

# newVariableData

Create a new VariableData object.

```nim
func newVariableData(dotNameStr: string; value: Value): VariableData
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

# getParentDict

Return the last component dictionary specified by the given names or, on error, return a warning.  The sequence [a, b, c, d] corresponds to the dot name string "a.b.c.d" and the c dictionary is the result.

```nim
proc getParentDict(variables: Variables; names: seq[string]): ParentDict
```

# assignVariable

Assign the variable the given value if possible, else return a warning.

```nim
proc assignVariable(variables: var Variables; dotNameStr: string; value: Value): Option[
    WarningData]
```

# getVariable

Look up the variable and return its value when found, else return a warning.

```nim
proc getVariable(variables: Variables; dotNameStr: string): ValueOrWarning
```


---
⦿ Markdown page generated by [StaticTea](https://github.com/flenniken/statictea/) from nim doc comments. ⦿
