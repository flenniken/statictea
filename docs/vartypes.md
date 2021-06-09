[StaticTea Modules](./)

# vartypes.nim

StaticTea variable types.

# Index

* type: [VarsDict](#user-content-a0) &mdash; Variables dictionary type.
* type: [ValueKind](#user-content-a1) &mdash; The type of Variables.
* type: [Value](#user-content-a2) &mdash; Variable value reference.
* type: [ValueOrWarningKind](#user-content-a3) &mdash; The kind of a ValueOrWarning object, either a value or warning.
* type: [ValueOrWarning](#user-content-a4) &mdash; Holds a value or a warning.
* [newVarsDict](#user-content-a5) &mdash; Create a new empty variables dictionary.
* [newValue](#user-content-a6) &mdash; Create a string value.
* [newValue](#user-content-a7) &mdash; Create an integer value.
* [newValue](#user-content-a8) &mdash; Create a float value.
* [newValue](#user-content-a9) &mdash; Create a list value.
* [newValue](#user-content-a10) &mdash; Create a dictionary value from a VarsDict.
* [newValue](#user-content-a11) &mdash; New value from an existing value.
* [newValue](#user-content-a12) &mdash; New list value from an array of items of the same kind.
* [newValue](#user-content-a13) &mdash; <p>New dict value from an array of pairs where the pairs are the same type (may be Value type).
* [newEmptyListValue](#user-content-a14) &mdash; Return an empty list value.
* [newEmptyDictValue](#user-content-a15) &mdash; Create a dictionary value from a VarsDict.
* [dictToString](#user-content-a16) &mdash; Return a string representation of a dict Value in JSON format.
* [listToString](#user-content-a17) &mdash; Return a string representation of a list Value in JSON format.
* [valueToString](#user-content-a18) &mdash; Return a string representation of a Value in JSON format.
* [`$`](#user-content-a19) &mdash; Return a string representation of a Value.
* [shortValueToString](#user-content-a20) &mdash; Return a string representation of Value.
* [`$`](#user-content-a21) &mdash; Return a string representation of a value's type.
* [`$`](#user-content-a22) &mdash; Return a string representation of a VarsDict.
* [`==`](#user-content-a23) &mdash; Return true when two values are equal.
* [newValueOrWarning](#user-content-a24) &mdash; Return a new ValueOrWarning object containing a value.
* [newValueOrWarning](#user-content-a25) &mdash; Return a new ValueOrWarning object containing a warning.
* [newValueOrWarning](#user-content-a26) &mdash; Return a new ValueOrWarning object containing a warning.
* [`==`](#user-content-a27) &mdash; Compare two ValueOrWarning objects and return true when equal.
* [`$`](#user-content-a28) &mdash; Return a string representation of a ValueOrWarning object.
* type: [Statement](#user-content-a29) &mdash; A Statement object stores the statement text and where it starts in the template file.
* type: [ValueAndLength](#user-content-a30) &mdash; A value and the length of the matching text in the statement.
* [newStatement](#user-content-a31) &mdash; Create a new statement.
* [startColumn](#user-content-a32) &mdash; Return enough spaces to point at the warning column.
* [warnStatement](#user-content-a33) &mdash; Warn about an invalid statement.
* [`==`](#user-content-a34) &mdash; Return true when the two statements are equal.
* [`$`](#user-content-a35) &mdash; Retrun a string representation of a Statement.
* [newValueAndLength](#user-content-a36) &mdash; Create a newValueAndLength object.

# <a id="a0"></a>VarsDict

Variables dictionary type. This is a ref type. Create a new VarsDict with newVarsDict procedure.

```nim
VarsDict = OrderedTableRef[string, Value]
```


# <a id="a1"></a>ValueKind

The type of Variables.

```nim
ValueKind = enum
  vkString, vkInt, vkFloat, vkDict, vkList
```


# <a id="a2"></a>Value

Variable value reference.

```nim
Value = ref ValueObj
```


# <a id="a3"></a>ValueOrWarningKind

The kind of a ValueOrWarning object, either a value or warning.

```nim
ValueOrWarningKind = enum
  vwValue, vwWarning
```


# <a id="a4"></a>ValueOrWarning

Holds a value or a warning.

```nim
ValueOrWarning = object
  case kind*: ValueOrWarningKind
  of vwValue:
      value*: Value

  of vwWarning:
      warningData*: WarningData


```


# <a id="a5"></a>newVarsDict

Create a new empty variables dictionary. VarsDict is a ref type.

```nim
proc newVarsDict(): VarsDict
```


# <a id="a6"></a>newValue

Create a string value.

```nim
proc newValue(str: string): Value
```


# <a id="a7"></a>newValue

Create an integer value.

```nim
proc newValue(num: int | int64): Value
```


# <a id="a8"></a>newValue

Create a float value.

```nim
proc newValue(num: float): Value
```


# <a id="a9"></a>newValue

Create a list value.

```nim
proc newValue(valueList: seq[Value]): Value
```


# <a id="a10"></a>newValue

Create a dictionary value from a VarsDict.

```nim
proc newValue(varsDict: VarsDict): Value
```


# <a id="a11"></a>newValue

New value from an existing value. Since values are ref types, the new value is an alias to the same value.

```nim
proc newValue(value: Value): Value
```


# <a id="a12"></a>newValue

New list value from an array of items of the same kind. @ let listValue = newValue([1, 2, 3]) let listValue = newValue(["a", "b", "c"]) let listValue = newValue([newValue(1), newValue("b")])

```nim
proc newValue[T](list: openArray[T]): Value
```


# <a id="a13"></a>newValue

<p>New dict value from an array of pairs where the pairs are the same type (may be Value type).</p>
<p>let dictValue = newValue([("a", 1), ("b", 2), ("c", 3)]) let dictValue = newValue([("a", 1.1), ("b", 2.2), ("c", 3.3)]) let dictValue = newValue([("a", newValue(1.1)), ("b", newValue("a"))])</p>


```nim
proc newValue[T](dictPairs: openArray[(string, T)]): Value
```


# <a id="a14"></a>newEmptyListValue

Return an empty list value.

```nim
proc newEmptyListValue(): Value
```


# <a id="a15"></a>newEmptyDictValue

Create a dictionary value from a VarsDict.

```nim
proc newEmptyDictValue(): Value
```


# <a id="a16"></a>dictToString

Return a string representation of a dict Value in JSON format.

```nim
func dictToString(value: Value): string
```


# <a id="a17"></a>listToString

Return a string representation of a list Value in JSON format.

```nim
func listToString(value: Value): string
```


# <a id="a18"></a>valueToString

Return a string representation of a Value in JSON format.

```nim
func valueToString(value: Value): string
```


# <a id="a19"></a>`$`

Return a string representation of a Value.

```nim
func `$`(value: Value): string
```


# <a id="a20"></a>shortValueToString

Return a string representation of Value. This is used to convert values to strings in replacement blocks.

```nim
func shortValueToString(value: Value): string
```


# <a id="a21"></a>`$`

Return a string representation of a value's type.

```nim
func `$`(kind: ValueKind): string
```


# <a id="a22"></a>`$`

Return a string representation of a VarsDict.

```nim
proc `$`(varsDict: VarsDict): string
```


# <a id="a23"></a>`==`

Return true when two values are equal.

```nim
proc `==`(value1: Value; value2: Value): bool
```


# <a id="a24"></a>newValueOrWarning

Return a new ValueOrWarning object containing a value.

```nim
func newValueOrWarning(value: Value): ValueOrWarning
```


# <a id="a25"></a>newValueOrWarning

Return a new ValueOrWarning object containing a warning.

```nim
func newValueOrWarning(warning: Warning; p1: string = ""; p2: string = ""): ValueOrWarning
```


# <a id="a26"></a>newValueOrWarning

Return a new ValueOrWarning object containing a warning.

```nim
func newValueOrWarning(warningData: WarningData): ValueOrWarning
```


# <a id="a27"></a>`==`

Compare two ValueOrWarning objects and return true when equal.

```nim
func `==`(vw1: ValueOrWarning; vw2: ValueOrWarning): bool
```


# <a id="a28"></a>`$`

Return a string representation of a ValueOrWarning object.

```nim
func `$`(vw: ValueOrWarning): string
```


# <a id="a29"></a>Statement

A Statement object stores the statement text and where it starts in the template file. @ @ * lineNum -- Line number starting at 1 where the statement @              starts. @ * start -- Column position starting at 1 where the statement @            starts on the line. @ * text -- The statement text.

```nim
Statement = object
  lineNum*: Natural
  start*: Natural
  text*: string

```


# <a id="a30"></a>ValueAndLength

A value and the length of the matching text in the statement. For the example statement: "var = 567 ". The value 567 starts at index 6 and the matching length is 4 because it includes the trailing space. For example "id = row(3 )" the value is 3 and the length is 2.

```nim
ValueAndLength = object
  value*: Value
  length*: Natural

```


# <a id="a31"></a>newStatement

Create a new statement.

```nim
func newStatement(text: string; lineNum: Natural = 1; start: Natural = 1): Statement
```


# <a id="a32"></a>startColumn

Return enough spaces to point at the warning column.  Used under the statement line.

```nim
proc startColumn(start: Natural): string
```


# <a id="a33"></a>warnStatement

Warn about an invalid statement. Show and tell the statement with the problem.  Start is the position in the statement where the problem starts. If the statement is long, trim it around the problem area.

```nim
proc warnStatement(env: var Env; statement: Statement; warning: Warning;
                   start: Natural; p1: string = ""; p2: string = "")
```


# <a id="a34"></a>`==`

Return true when the two statements are equal.

```nim
func `==`(s1: Statement; s2: Statement): bool
```


# <a id="a35"></a>`$`

Retrun a string representation of a Statement.

```nim
func `$`(s: Statement): string
```


# <a id="a36"></a>newValueAndLength

Create a newValueAndLength object.

```nim
proc newValueAndLength(value: Value; length: Natural): ValueAndLength
```



---
⦿ StaticTea markdown template for nim doc comments. ⦿
