[StaticTea Modules](./)

# parseNumber.nim

Parse an int or float number string.  Return the number and number of characters processed.

# Index

* type: [IntPos](#user-content-a0) &mdash; Integer and characters processed.
* type: [FloatPos](#user-content-a1) &mdash; Float and characters processed.
* [parseFloat64](#user-content-a2) &mdash; Parse the string and return the 64 bit float number and the
number of characters processed.
* [parseInteger](#user-content-a3) &mdash; Parse the string and return the integer and number of characters
processed.

# <a id="a0"></a>IntPos

Integer and characters processed.

```nim
IntPos = object
  integer*: BiggestInt
  length*: int

```


# <a id="a1"></a>FloatPos

Float and characters processed.

```nim
FloatPos = object
  number*: float64
  length*: int

```


# <a id="a2"></a>parseFloat64

Parse the string and return the 64 bit float number and the
number of characters processed. Nothing is returned when the
float is out of range or the str is not a float number.
Processing stops at the first non-number character.

A float number starts with an optional minus sign, followed by a
digit, followed by digits, underscores or a decimal point. Only
one decimal point is allowed and underscores are skipped.

```nim
proc parseFloat64(str: string; start: Natural = 0): Option[FloatPos]
```


# <a id="a3"></a>parseInteger

Parse the string and return the integer and number of characters
processed. Nothing is returned when the integer is out of range
or the str is not a number.

An integer starts with an optional minus sign, followed by a
digit, followed by digits or underscores. The underscores are
skipped. Processing stops at the first non-number character.

```nim
proc parseInteger(s: string; start: Natural = 0): Option[IntPos]
```



---
⦿ StaticTea markdown template for nim doc comments. ⦿
