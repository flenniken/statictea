# vartypes.nim

StaticTea variable types.

* [vartypes.nim](../src/vartypes.nim) &mdash; Nim source code.
# Index

* type: [VarsDict](#varsdict) &mdash; Variables dictionary type.
* type: [ValueKind](#valuekind) &mdash; The type of Variables.
* type: [Value](#value) &mdash; Variable value reference.
* [newVarsDict](#newvarsdict) &mdash; Create a new empty variables dictionary.
* [newValue](#newvalue) &mdash; Create a string value.
* [newValue](#newvalue-1) &mdash; Create an integer value.
* [newValue](#newvalue-2) &mdash; Create an integer value from a bool.
* [newValue](#newvalue-3) &mdash; Create a float value.
* [newValue](#newvalue-4) &mdash; Create a list value.
* [newValue](#newvalue-5) &mdash; Create a dictionary value from a VarsDict.
* [newValue](#newvalue-6) &mdash; New value from an existing value.
* [newValue](#newvalue-7) &mdash; New list value from an array of items of the same kind.
* [newValue](#newvalue-8) &mdash; New dict value from an array of pairs where the pairs are the
same type (may be Value type).
* [newEmptyListValue](#newemptylistvalue) &mdash; Return an empty list value.
* [newEmptyDictValue](#newemptydictvalue) &mdash; Create a dictionary value from a VarsDict.
* [`==`](#) &mdash; Return true when two values are equal.
* [`$`](#-1) &mdash; Return a string representation of a value's type.
* [dictToString](#dicttostring) &mdash; Return a string representation of a dict Value in JSON format.
* [listToString](#listtostring) &mdash; Return a string representation of a list Value in JSON format.
* [valueToString](#valuetostring) &mdash; Return a string representation of a Value in JSON format.
* [valueToStringRB](#valuetostringrb) &mdash; Return the string representation of the Value for use in the replacement blocks.
* [`$`](#-2) &mdash; Return a string representation of a Value.
* [`$`](#-3) &mdash; Return a string representation of a VarsDict.
* [newValueOr](#newvalueor) &mdash; Create a OpResultWarn[Value] warning.
* [newValueOr](#newvalueor-1) &mdash; Create a OpResultWarn[Value] warning.
* [newValueOr](#newvalueor-2) &mdash; Create a OpResultWarn[Value] value.

# VarsDict

Variables dictionary type. This is a ref type. Create a new
VarsDict with newVarsDict procedure.

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

Create an integer value from a bool.

```nim
proc newValue(a: bool): Value
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

New value from an existing value. Since values are ref types, the
new value is an alias to the same value.

```nim
proc newValue(value: Value): Value
```

# newValue

New list value from an array of items of the same kind.

~~~
let listValue = newValue([1, 2, 3])
let listValue = newValue(["a", "b", "c"])
let listValue = newValue([newValue(1), newValue("b")])
~~~~

```nim
proc newValue[T](list: openArray[T]): Value
```

# newValue

New dict value from an array of pairs where the pairs are the
same type (may be Value type).

 let dictValue = newValue([("a", 1), ("b", 2), ("c", 3)])
 let dictValue = newValue([("a", 1.1), ("b", 2.2), ("c", 3.3)])
 let dictValue = newValue([("a", newValue(1.1)), ("b", newValue("a"))])

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

# `==`

Return true when two values are equal.

```nim
proc `==`(value1: Value; value2: Value): bool
```

# `$`

Return a string representation of a value's type.

```nim
func `$`(kind: ValueKind): string
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

# valueToStringRB

Return the string representation of the Value for use in the replacement blocks.

```nim
func valueToStringRB(value: Value): string
```

# `$`

Return a string representation of a Value.

```nim
func `$`(value: Value): string
```

# `$`

Return a string representation of a VarsDict.

```nim
proc `$`(varsDict: VarsDict): string
```

# newValueOr

Create a OpResultWarn[Value] warning.

```nim
func newValueOr(warning: Warning; p1 = ""; pos = 0): OpResultWarn[Value]
```

# newValueOr

Create a OpResultWarn[Value] warning.

```nim
func newValueOr(warningData: WarningData): OpResultWarn[Value]
```

# newValueOr

Create a OpResultWarn[Value] value.

```nim
func newValueOr(value: Value): OpResultWarn[Value]
```


---
⦿ Markdown page generated by [StaticTea](https://github.com/flenniken/statictea/) from nim doc comments. ⦿
