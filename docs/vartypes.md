# vartypes.nim

StaticTea variable types.

* [vartypes.nim](../src/vartypes.nim) &mdash; Nim source code.
# Index

* type: [VarsDict](#varsdict) &mdash; Variables dictionary type.
* type: [ValueKind](#valuekind) &mdash; The type of Variables.
* type: [Value](#value) &mdash; Variable value reference.
* type: [ValueOrWarningKind](#valueorwarningkind) &mdash; The kind of a ValueOrWarning object, either a value or warning.
* type: [ValueOrWarning](#valueorwarning) &mdash; Holds a value or a warning.
* [newVarsDict](#newvarsdict) &mdash; Create a new empty variables dictionary.
* [newValue](#newvalue) &mdash; Create a string value.
* [newValue](#newvalue) &mdash; Create an integer value.
* [newValue](#newvalue) &mdash; Create a float value.
* [newValue](#newvalue) &mdash; Create a list value.
* [newValue](#newvalue) &mdash; Create a dictionary value from a VarsDict.
* [newValue](#newvalue) &mdash; New value from an existing value.
* [newValue](#newvalue) &mdash; New list value from an array of items of the same kind.
* [newValue](#newvalue) &mdash; <p>New dict value from an array of pairs where the pairs are the same type (may be Value type).
* [newEmptyListValue](#newemptylistvalue) &mdash; Return an empty list value.
* [newEmptyDictValue](#newemptydictvalue) &mdash; Create a dictionary value from a VarsDict.
* [dictToString](#dicttostring) &mdash; Return a string representation of a dict Value in JSON format.
* [listToString](#listtostring) &mdash; Return a string representation of a list Value in JSON format.
* [valueToString](#valuetostring) &mdash; Return a string representation of a Value in JSON format.
* [`$`](#) &mdash; Return a string representation of a Value.
* [shortValueToString](#shortvaluetostring) &mdash; Return a string representation of Value.
* [`$`](#) &mdash; Return a string representation of a value's type.
* [`$`](#) &mdash; Return a string representation of a VarsDict.
* [`==`](#) &mdash; Return true when two values are equal.
* [newValueOrWarning](#newvalueorwarning) &mdash; Return a new ValueOrWarning object containing a value.
* [newValueOrWarning](#newvalueorwarning) &mdash; Return a new ValueOrWarning object containing a warning.
* [newValueOrWarning](#newvalueorwarning) &mdash; Return a new ValueOrWarning object containing a warning.
* [`==`](#) &mdash; Compare two ValueOrWarning objects and return true when equal.
* [`$`](#) &mdash; Return a string representation of a ValueOrWarning object.
* type: [Statement](#statement) &mdash; A Statement object stores the statement text and where it starts in the template file.
* type: [ValueAndLength](#valueandlength) &mdash; A value and the length of the matching text in the statement.
* [newStatement](#newstatement) &mdash; Create a new statement.
* [startColumn](#startcolumn) &mdash; Return enough spaces to point at the warning column.
* [warnStatement](#warnstatement) &mdash; Warn about an invalid statement.
* [`==`](#) &mdash; Return true when the two statements are equal.
* [`$`](#) &mdash; Retrun a string representation of a Statement.
* [newValueAndLength](#newvalueandlength) &mdash; Create a newValueAndLength object.

# VarsDict

Variables dictionary type. This is a ref type. Create a new VarsDict with newVarsDict procedure.

```nim
VarsDict = OrderedTableRef[string, Value]
```


# ValueKind

The type of Variables.

```nim
ValueKind = enum
  vkString, vkInt, vkFloat, vkDict, vkList
```


# Value

Variable value reference.

```nim
Value = ref ValueObj
```


# ValueOrWarningKind

The kind of a ValueOrWarning object, either a value or warning.

```nim
ValueOrWarningKind = enum
  vwValue, vwWarning
```


# ValueOrWarning

Holds a value or a warning.

```nim
ValueOrWarning = object
  case kind*: ValueOrWarningKind
  of vwValue:
      value*: Value

  of vwWarning:
      warningData*: WarningData


```


# newVarsDict

Create a new empty variables dictionary. VarsDict is a ref type.

```nim
proc newVarsDict(): VarsDict
```


# newValue

Create a string value.

```nim
proc newValue(str: string): Value
```


# newValue

Create an integer value.

```nim
proc newValue(num: int | int64): Value
```


# newValue

Create a float value.

```nim
proc newValue(num: float): Value
```


# newValue

Create a list value.

```nim
proc newValue(valueList: seq[Value]): Value
```


# newValue

Create a dictionary value from a VarsDict.

```nim
proc newValue(varsDict: VarsDict): Value
```


# newValue

New value from an existing value. Since values are ref types, the new value is an alias to the same value.

```nim
proc newValue(value: Value): Value
```


# newValue

New list value from an array of items of the same kind. @ let listValue = newValue([1, 2, 3]) let listValue = newValue(["a", "b", "c"]) let listValue = newValue([newValue(1), newValue("b")])

```nim
proc newValue[T](list: openArray[T]): Value
```


# newValue

<p>New dict value from an array of pairs where the pairs are the same type (may be Value type).</p>
<p>let dictValue = newValue([("a", 1), ("b", 2), ("c", 3)]) let dictValue = newValue([("a", 1.1), ("b", 2.2), ("c", 3.3)]) let dictValue = newValue([("a", newValue(1.1)), ("b", newValue("a"))])</p>


```nim
proc newValue[T](dictPairs: openArray[(string, T)]): Value
```


# newEmptyListValue

Return an empty list value.

```nim
proc newEmptyListValue(): Value
```


# newEmptyDictValue

Create a dictionary value from a VarsDict.

```nim
proc newEmptyDictValue(): Value
```


# dictToString

Return a string representation of a dict Value in JSON format.

```nim
func dictToString(value: Value): string
```


# listToString

Return a string representation of a list Value in JSON format.

```nim
func listToString(value: Value): string
```


# valueToString

Return a string representation of a Value in JSON format.

```nim
func valueToString(value: Value): string
```


# `$`

Return a string representation of a Value.

```nim
func `$`(value: Value): string
```


# shortValueToString

Return a string representation of Value. This is used to convert values to strings in replacement blocks.

```nim
func shortValueToString(value: Value): string
```


# `$`

Return a string representation of a value's type.

```nim
func `$`(kind: ValueKind): string
```


# `$`

Return a string representation of a VarsDict.

```nim
proc `$`(varsDict: VarsDict): string
```


# `==`

Return true when two values are equal.

```nim
proc `==`(value1: Value; value2: Value): bool
```


# newValueOrWarning

Return a new ValueOrWarning object containing a value.

```nim
func newValueOrWarning(value: Value): ValueOrWarning
```


# newValueOrWarning

Return a new ValueOrWarning object containing a warning.

```nim
func newValueOrWarning(warning: Warning; p1: string = ""; p2: string = ""): ValueOrWarning
```


# newValueOrWarning

Return a new ValueOrWarning object containing a warning.

```nim
func newValueOrWarning(warningData: WarningData): ValueOrWarning
```


# `==`

Compare two ValueOrWarning objects and return true when equal.

```nim
func `==`(vw1: ValueOrWarning; vw2: ValueOrWarning): bool
```


# `$`

Return a string representation of a ValueOrWarning object.

```nim
func `$`(vw: ValueOrWarning): string
```


# Statement

A Statement object stores the statement text and where it starts in the template file. @ @ * lineNum -- Line number starting at 1 where the statement @              starts. @ * start -- Column position starting at 1 where the statement @            starts on the line. @ * text -- The statement text.

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

Warn about an invalid statement. Show and tell the statement with the problem.  Start is the position in the statement where the problem starts. If the statement is long, trim it around the problem area.

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

Retrun a string representation of a Statement.

```nim
func `$`(s: Statement): string
```


# newValueAndLength

Create a newValueAndLength object.

```nim
proc newValueAndLength(value: Value; length: Natural): ValueAndLength
```



---
⦿ Markdown page generated by [StaticTea](https://github.com/flenniken/statictea/) from nim doc comments. ⦿
