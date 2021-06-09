[StaticTea Modules](/)

# variables.nim

Language variable methods.

 Here are the tea variables:

 - t.content -- content of the replace block.
 - t.g -- dictionary containing the global variables.
 - t.l -- dictionary containing the current command's local variables.
 - t.maxLines -- maximum number of replacement block lines (lines before endblock).
 - t.maxRepeat -- maximum number of times to repeat the block.
 - t.output -- where the block output goes.
 - t.repeat -- controls how many times the block repeats.
 - t.row -- the current row number of a repeating block.
 - t.s -- dictionary containing the server json variables.
 - t.h -- dictionary containing the shared json variables.
 - t.version -- the StaticTea version number.

 Here are the tea variables grouped by type:

 Constant:

 - t.version

 Dictionaries:

 - t.g
 - t.l
 - t.s -- read only
 - t.h -- read only
 - t.f -- reserved

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

# Index

* const: [outputValues](#user-content-a0) &mdash; Tea output variable values.
* type: [Variables](#user-content-a1) &mdash; Dictionary holding all statictea variables.
* type: [VariableData](#user-content-a2) &mdash; A variable name and value.
* type: [WarningSide](#user-content-a3) &mdash; Tells which side of the assignment the warning applies to, the left var side or the right value side.
* type: [WarningDataPos](#user-content-a4) &mdash; A warning and the side it applies to.
* type: [ParentDictKind](#user-content-a5) &mdash; The kind of a ParentDict object, either a dict or warning.
* type: [ParentDict](#user-content-a6) &mdash; Contains the result of calling getParentDict, either a dictionary or a warning.
* [`$`](#user-content-a7) &mdash; Return a string representation of ParentDict.
* [`==`](#user-content-a8) &mdash; Return true when the two ParentDict are equal.
* [newParentDictWarn](#user-content-a9) &mdash; Return a new ParentDict warning object.
* [newParentDict](#user-content-a10) &mdash; Return a new ParentDict object containing a dict.
* [emptyVariables](#user-content-a11) &mdash; Create an empty variables object in its initial state.
* [newVariableData](#user-content-a12) &mdash; Create a new VariableData object.
* [newWarningDataPos](#user-content-a13) &mdash; Create a WarningDataPos object containing the given warning information.
* [`$`](#user-content-a14) &mdash; Return a string representation of WarningDataPos.
* [getTeaVarIntDefault](#user-content-a15) &mdash; Return the int value of one of the tea dictionary integer items.
* [getTeaVarStringDefault](#user-content-a16) &mdash; Return the string value of one of the tea dictionary string items.
* [resetVariables](#user-content-a17) &mdash; Clear the local variables and reset the tea variables for running a command.
* [getParentDict](#user-content-a18) &mdash; Return the last component dictionary specified by the given names or, on error, return a warning.
* [assignVariable](#user-content-a19) &mdash; Assign the variable the given value if possible, else return a warning.
* [getVariable](#user-content-a20) &mdash; Look up the variable and return its value when found, else return a warning.

# <a id="a0"></a>outputValues

Tea output variable values.

```nim
outputValues = ["result", "stderr", "log", "skip"]
```


# <a id="a1"></a>Variables

Dictionary holding all statictea variables.

```nim
Variables = VarsDict
```


# <a id="a2"></a>VariableData

A variable name and value. The names tells where the variable is stored, i.e.: s.varName

```nim
VariableData = object
  names*: seq[string]
  value*: Value

```


# <a id="a3"></a>WarningSide

Tells which side of the assignment the warning applies to, the left var side or the right value side.

```nim
WarningSide = enum
  wsVarName, wsValue
```


# <a id="a4"></a>WarningDataPos

A warning and the side it applies to.

```nim
WarningDataPos = object
  warningData*: WarningData
  warningSide*: WarningSide

```


# <a id="a5"></a>ParentDictKind

The kind of a ParentDict object, either a dict or warning.

```nim
ParentDictKind = enum
  fdDict, fdWarning
```


# <a id="a6"></a>ParentDict

Contains the result of calling getParentDict, either a dictionary or a warning.

```nim
ParentDict = object
  case kind*: ParentDictKind
  of fdDict:
      dict*: VarsDict

  of fdWarning:
      warningData*: WarningData


```


# <a id="a7"></a>`$`

Return a string representation of ParentDict.

```nim
func `$`(parentDict: ParentDict): string
```


# <a id="a8"></a>`==`

Return true when the two ParentDict are equal.

```nim
func `==`(s1: ParentDict; s2: ParentDict): bool
```


# <a id="a9"></a>newParentDictWarn

Return a new ParentDict warning object. It contains a warning and the two optional strings that go with the warning.

```nim
func newParentDictWarn(warning: Warning; p1: string = ""; p2: string = ""): ParentDict
```


# <a id="a10"></a>newParentDict

Return a new ParentDict object containing a dict.

```nim
func newParentDict(dict: VarsDict): ParentDict
```


# <a id="a11"></a>emptyVariables

Create an empty variables object in its initial state.

```nim
func emptyVariables(server: VarsDict = nil; shared: VarsDict = nil): Variables
```


# <a id="a12"></a>newVariableData

Create a new VariableData object.

```nim
func newVariableData(dotNameStr: string; value: Value): VariableData
```


# <a id="a13"></a>newWarningDataPos

Create a WarningDataPos object containing the given warning information.

```nim
func newWarningDataPos(warning: Warning; p1: string = ""; p2: string = "";
                       warningSide: WarningSide): WarningDataPos
```


# <a id="a14"></a>`$`

Return a string representation of WarningDataPos.

```nim
func `$`(warningDataPos: WarningDataPos): string
```


# <a id="a15"></a>getTeaVarIntDefault

Return the int value of one of the tea dictionary integer items. If the value does not exist, return its default value.

```nim
func getTeaVarIntDefault(variables: Variables; varName: string): int64
```


# <a id="a16"></a>getTeaVarStringDefault

Return the string value of one of the tea dictionary string items. If the value does not exist, return its default value.

```nim
func getTeaVarStringDefault(variables: Variables; varName: string): string
```


# <a id="a17"></a>resetVariables

Clear the local variables and reset the tea variables for running a command.

```nim
proc resetVariables(variables: var Variables)
```


# <a id="a18"></a>getParentDict

Return the last component dictionary specified by the given names or, on error, return a warning.  The sequence [a, b, c, d] corresponds to the dot name string "a.b.c.d" and the c dictionary is the result.

```nim
proc getParentDict(variables: Variables; names: seq[string]): ParentDict
```


# <a id="a19"></a>assignVariable

Assign the variable the given value if possible, else return a warning.

```nim
proc assignVariable(variables: var Variables; dotNameStr: string; value: Value): Option[
    WarningData]
```


# <a id="a20"></a>getVariable

Look up the variable and return its value when found, else return a warning.

```nim
proc getVariable(variables: Variables; dotNameStr: string): ValueOrWarning
```



---
⦿ StaticTea markdown template for nim doc comments. ⦿
