[Home](https://github.com/flenniken/statictea/)

# runFunction.nim

This module contains the StaticTea functions and supporting types. The StaticTea language functions start with "fun", for example, the "funCmp" function implements the StaticTea "cmp" function.

# Index

* type: [FunctionPtr](#user-content-a0) &mdash; Signature of a statictea function.
* type: [FunResultKind](#user-content-a1) &mdash; The kind of a FunResult object, either a value or warning.
* type: [FunResult](#user-content-a2) &mdash; Contains the result of calling a function, either a value or a warning.
* [newFunResultWarn](#user-content-a3) &mdash; Return a new FunResult object.
* [newFunResult](#user-content-a4) &mdash; Return a new FunResult object containing a value.
* [`==`](#user-content-a5) &mdash; Compare two FunResult objects and return true when equal.
* [`$`](#user-content-a6) &mdash; Return a string representation of a FunResult object.
* [cmpString](#user-content-a7) &mdash; Compares two UTF-8 strings.
* [funCmp](#user-content-a8) &mdash; Compare two values.
* [funConcat](#user-content-a9) &mdash; Concatentate two or more strings.
* [funLen](#user-content-a10) &mdash; Return the len of a value.
* [funGet](#user-content-a11) &mdash; Return a value contained in a list or dictionary.
* [funIf](#user-content-a12) &mdash; You use the if function to return a value based on a condition.
* [funAdd](#user-content-a13) &mdash; Return the sum of two or more values.
* [funExists](#user-content-a14) &mdash; Return 1 when a variable exists in a dictionary, else return @@0.
* [funCase](#user-content-a15) &mdash; The case function returns a value from multiple choices.
* [parseVersion](#user-content-a16) &mdash; Parse a StaticTea version number and return its three components.
* [funCmpVersion](#user-content-a17) &mdash; Compare two StaticTea type version numbers.
* [funFloat](#user-content-a18) &mdash; Convert an int or an int number string to a float.
* [funInt](#user-content-a19) &mdash; Convert a float or a number string to an int.
* [funFind](#user-content-a20) &mdash; Find a substring in a string and return its position when found.
* [funSubstr](#user-content-a21) &mdash; Extract a substring from a string.
* [funDup](#user-content-a22) &mdash; Duplicate a string.
* [funDict](#user-content-a23) &mdash; Create a dictionary from a list of key, value pairs.
* [funList](#user-content-a24) &mdash; Create a list of values.
* [funReplace](#user-content-a25) &mdash; Replace a part of a string (substring) with another string.
* [funReplaceRe](#user-content-a26) &mdash; Replace multiple parts of a string defined by regular expressions with replacement strings.
* [funPath](#user-content-a27) &mdash; <p>Split a file path into pieces.
* [getFunction](#user-content-a28) &mdash; Look up a function by its name.

# <a id="a0"></a>FunctionPtr

Signature of a statictea function. It takes any number of values and returns a value or a warning message.

```nim
FunctionPtr = proc (parameters: seq[Value]): FunResult
```

[source](../src/runFunction.nim#L19)

# <a id="a1"></a>FunResultKind

The kind of a FunResult object, either a value or warning.

```nim
FunResultKind = enum
  frValue, frWarning
```

[source](../src/runFunction.nim#L23)

# <a id="a2"></a>FunResult

Contains the result of calling a function, either a value or a warning.

```nim
FunResult = object
  case kind*: FunResultKind
  of frValue:
      value*: Value          ## Return value of the function.
    
  of frWarning:
      parameter*: Natural    ## Index of problem parameter.
      warningData*: WarningData


```

[source](../src/runFunction.nim#L28)

# <a id="a3"></a>newFunResultWarn

Return a new FunResult object. It contains a warning, the index of the problem parameter, and the two optional strings that go with the warning.

```nim
func newFunResultWarn(warning: Warning; parameter: Natural = 0; p1: string = "";
                      p2: string = ""): FunResult
```

[source](../src/runFunction.nim#L41)

# <a id="a4"></a>newFunResult

Return a new FunResult object containing a value.

```nim
func newFunResult(value: Value): FunResult
```

[source](../src/runFunction.nim#L50)

# <a id="a5"></a>`==`

Compare two FunResult objects and return true when equal.

```nim
func `==`(r1: FunResult; r2: FunResult): bool
```

[source](../src/runFunction.nim#L54)

# <a id="a6"></a>`$`

Return a string representation of a FunResult object.

```nim
func `$`(funResult: FunResult): string
```

[source](../src/runFunction.nim#L65)

# <a id="a7"></a>cmpString

Compares two UTF-8 strings. Returns 0 when equal, 1 when a is greater than b and -1 when a less than b. Optionally Ignore case.

```nim
func cmpString(a, b: string; ignoreCase: bool = false): int
```

[source](../src/runFunction.nim#L75)

# <a id="a8"></a>funCmp

Compare two values.  The values are either numbers or strings (both the same type), and it returns whether the first parameter is less than, equal to or greater than the second parameter. It returns -1 for less, 0 for equal and 1 for greater than. The optional third parameter compares strings case insensitive when it is 1.

Compare numbers:

* p1: number
* p2: number

Compare strings:

* p1: string
* p2: string
* p3: optional: 1 for case insensitive

Examples:

~~~
cmp(7, 9) => -1
cmp(8, 8) => 0
cmp(9, 2) => 1

cmp("coffee", "tea") => -1
cmp("tea", "tea") => 0
cmp("Tea", "tea") => 1
cmp("Tea", "tea", 1) => 0
~~~

```nim
func funCmp(parameters: seq[Value]): FunResult
```

[source](../src/runFunction.nim#L100)

# <a id="a9"></a>funConcat

Concatentate two or more strings.

* p1: string
* p2: string
* ...
* pn: string

Examples:

~~~
concat("tea", " time") => "tea time"
concat("a", "b", "c", "d") => "abcd"
~~~

```nim
func funConcat(parameters: seq[Value]): FunResult
```

[source](../src/runFunction.nim#L158)

# <a id="a10"></a>funLen

Return the len of a value. It takes one parameter and returns the number of characters in a string (not bytes), the number of elements in a list or the number of elements in a dictionary.

* p1: string, list or dict

Examples:

~~~
len("tea") => 3
len(list(4, 1)) => 2
len(dict('a', 4)) => 1
~~~

```nim
func funLen(parameters: seq[Value]): FunResult
```

[source](../src/runFunction.nim#L183)

# <a id="a11"></a>funGet

Return a value contained in a list or dictionary. You pass two or three parameters, the first is the dictionary or list to use, the second is the dictionary's key name or the list index, and the third optional parameter is the default value when the element doesn't exist. If you don't specify the default, a warning is generated when the element doesn't exist and the statement is skipped.

Get Dictionary Item:

* p1: dictionary to search
* p2: variable (key name) to find
* p3: optional default value returned when key is missing

Get List Item:

* p1: list to use
* p2: index of item in the list
* p3: optional default value returned when index is too big

Examples:

~~~
d = dict("tea", "Earl Grey")
get(d, 'tea') => "Earl Grey"
get(d, 'coffee', 'Tea') => "Tea"

l = list(4, 'a', 10)
get(l, 2) => 10
get(l, 3, 99) => 99
~~~

```nim
func funGet(parameters: seq[Value]): FunResult
```

[source](../src/runFunction.nim#L215)

# <a id="a12"></a>funIf

You use the if function to return a value based on a condition. It has three parameters, the condition, the true case and the false case.

* p1: integer condition
* p2: true case: the value returned when condition is 1
* p3: else case: the value returned when condition is not 1.

Examples:

~~~
if(1, 'tea', 'beer') => "tea"
if(0, 'tea', 'beer') => "beer"
if(4, 'tea', 'beer') => "beer"
~~~

```nim
func funIf(parameters: seq[Value]): FunResult
```

[source](../src/runFunction.nim#L279)

# <a id="a13"></a>funAdd

Return the sum of two or more values.  The parameters must be all integers or all floats.  A warning is generated on overflow.

Integer case:

* p1: int
* p2: int
* ...
* pn: int

Float case:

* p1: float
* p2: float
* ...
* pn: float

Examples:

~~~
add(1, 2) => 3
add(1, 2, 3) => 6

add(1.5, 2.3) => 3.8
add(1.1, 2.2, 3.3) => 6.6
~~~

```nim
func funAdd(parameters: seq[Value]): FunResult
```

[source](../src/runFunction.nim#L312)

# <a id="a14"></a>funExists

Return 1 when a variable exists in a dictionary, else return 0. The first parameter is the dictionary to check and the second parameter is the name of the variable.

* p1: dictionary
* p2: string: variable name (key name)

Examples:

~~~
d = dict("tea", "Earl")
exists(d, "tea") => 1
exists(d, "coffee") => 0
~~~

```nim
func funExists(parameters: seq[Value]): FunResult
```

[source](../src/runFunction.nim#L367)

# <a id="a15"></a>funCase

The case function returns a value from multiple choices. It takes a main condition, any number of case pairs then an optional else value.
 The first parameter of a case pair is the condition and the second is the return value when that condition matches the main condition. The function compares the conditions left to right and returns the first match.
 When none of the cases match the main condition, the "else" value is returned. If none match and the else is missing, a warning is generated and the statement is skipped. The conditions must be integers or strings. The return values can be any type.

* p1: the main condition value
* p2: the first case condition
* p3: the first case value
* ...
* pn-2: the last case condition
* pn-1: the last case value
* pn: the optional "else" value returned when nothing matches

Examples:

~~~
case(8, 8, "tea", "water") => "tea"
case(8, 3, "tea", "water") => "water"
case(8,
  1, "tea", \
  2, "water", \
  3, "wine", \
  "beer") => "beer"
~~~

```nim
func funCase(parameters: seq[Value]): FunResult
```

[source](../src/runFunction.nim#L402)

# <a id="a16"></a>parseVersion

Parse a StaticTea version number and return its three components.

```nim
func parseVersion(version: string): Option[(int, int, int)]
```

[source](../src/runFunction.nim#L482)

# <a id="a17"></a>funCmpVersion

Compare two StaticTea type version numbers. Return whether the first parameter is less than, equal to or greater than the second parameter. It returns -1 for less, 0 for equal and 1 for greater than.
 StaticTea uses [Semantic Versioning](https://semver.org/) with the added restriction that each version component has one to three digits (no letters).

* p1: version number string
* p2: version number string

Examples:

~~~
cmpVersion("1.2.5", "1.1.8") => -1
cmpVersion("1.2.5", "1.3.0") => 1
cmpVersion("1.2.5", "1.2.5") => 1
~~~

```nim
func funCmpVersion(parameters: seq[Value]): FunResult
```

[source](../src/runFunction.nim#L493)

# <a id="a18"></a>funFloat

Convert an int or an int number string to a float.
 Note: Use the format function to convert a number to a string.

* p1: int or int string

Examples:

~~~
float(2) => 2.0
float("33") => 33.0
~~~

```nim
func funFloat(parameters: seq[Value]): FunResult
```

[source](../src/runFunction.nim#L540)

# <a id="a19"></a>funInt

Convert a float or a number string to an int.

* p1: float or float number string
* p2: optional round option. "round" is the default.

Round options:

* "round" - nearest integer
* "floor" - integer below (to the left on number line)
* "ceiling" - integer above (to the right on number line)
* "truncate" - remove decimals

Examples:

~~~
int("2") => 2
int("2.34") => 2
int(2.34, "round") => 2
int(-2.34, "round") => -2
int(6.5, "round") => 7
int(-6.5, "round") => -7
int(4.57, "floor") => 4
int(-4.57, "floor") => -5
int(6.3, "ceiling") => 7
int(-6.3, "ceiling") => -6
int(6.3456, "truncate") => 6
int(-6.3456, "truncate") => -6
~~~

```nim
func funInt(parameters: seq[Value]): FunResult
```

[source](../src/runFunction.nim#L583)

# <a id="a20"></a>funFind

Find a substring in a string and return its position when found. The first parameter is the string and the second is the substring. The third optional parameter is returned when the substring is not found.  A warning is generated when the substring is missing and no third parameter. Positions start at 0.

~~~
#      0123456789 1234567
msg = "Tea time at 3:30."
find(msg, "Tea") = 0
find(msg, "time") = 4
find(msg, "me") = 6
find(msg, "party", -1) = -1
find(msg, "party", len(msg)) = 17
find(msg, "party", 0) = 0
~~~

```nim
func funFind(parameters: seq[Value]): FunResult
```

[source](../src/runFunction.nim#L670)

# <a id="a21"></a>funSubstr

Extract a substring from a string.  The first parameter is the string, the second is the substring's starting position and the third is one past the end. The first position is 0. The third parameter is optional and defaults to one past the end of the string.
 This kind of positioning is called a half-open range that includes the first position but not the second. For example, [3, 7) includes 3, 4, 5, 6. The end minus the start is equal to the length of the substring.

* p1: string
* p2: start index
* p3: optional: end index (one past end)

Examples:

~~~
substr("Earl Grey", 0, 4) => "Earl"
substr("Earl Grey", 5) => => "Grey"
~~~

```nim
func funSubstr(parameters: seq[Value]): FunResult
```

[source](../src/runFunction.nim#L707)

# <a id="a22"></a>funDup

Duplicate a string. The first parameter is the string to dup and the second parameter is the number of times to duplicate it.

* p1: string to duplicate
* p2: number of times to repeat

Examples:

~~~
dup("=", 3) => "==="
substr("abc", 2) => => "abcabc"
~~~

```nim
func funDup(parameters: seq[Value]): FunResult
```

[source](../src/runFunction.nim#L765)

# <a id="a23"></a>funDict

Create a dictionary from a list of key, value pairs. You can specify as many pairs as you want. The keys must be strings and the values can be any type.

* p1: string key
* p2: value
* ...
* pn-1: string key
* pn: value

Examples:

~~~
dict("a", 5) => {"a": 5}
dict("a", 5, "b", 33, "c", 0) =>
  {"a": 5, "b": 33, "c": 0}
~~~

```nim
func funDict(parameters: seq[Value]): FunResult
```

[source](../src/runFunction.nim#L804)

# <a id="a24"></a>funList

Create a list of values. You can specify as many variables as you want.

* p1: value
* p2: value
* p3: value
* ...
* pn: value

Examples:

~~~
list() => []
list(1) => [1]
list(1, 2, 3) => [1, 2, 3]
list("a", 5, "b") => ["a", 5, "b"]
~~~

```nim
func funList(parameters: seq[Value]): FunResult
```

[source](../src/runFunction.nim#L840)

# <a id="a25"></a>funReplace

Replace a part of a string (substring) with another string. You can use it to insert and append to a string as well.
 The first parameter is the string, the second is the substring's starting position, starting a 0, the third is the length of the substring and the fourth is the replacement string.

* p1: string to replace
* p2: substring start index
* p3: substring length
* p4: replacement string

Examples:

~~~
replace("Earl Grey", 5, 4, "of Sandwich")
  => "Earl of Sandwich"
replace("123", 0, 0, "abcd") => abcd123
replace("123", 0, 1, "abcd") => abcd23
replace("123", 0, 2, "abcd") => abcd3
replace("123", 0, 3, "abcd") => abcd
replace("123", 3, 0, "abcd") => 123abcd
replace("123", 2, 1, "abcd") => 12abcd
replace("123", 1, 2, "abcd") => 1abcd
replace("123", 0, 3, "abcd") => abcd
replace("123", 1, 0, "abcd") => 1abcd23
replace("123", 1, 1, "abcd") => 1abcd3
replace("123", 1, 2, "abcd") => 1abcd
replace("", 0, 0, "abcd") => abcd
replace("", 0, 0, "abc") => abc
replace("", 0, 0, "ab") => ab
replace("", 0, 0, "a") => a
replace("", 0, 0, "") =>
replace("123", 0, 0, "") => 123
replace("123", 0, 1, "") => 23
replace("123", 0, 2, "") => 3
replace("123", 0, 3, "") =>
~~~

```nim
func funReplace(parameters: seq[Value]): FunResult
```

[source](../src/runFunction.nim#L861)

# <a id="a26"></a>funReplaceRe

Replace multiple parts of a string defined by regular expressions with replacement strings.
 The basic case uses one replacement pattern. It takes three parameters, the first parameter is the string to work on, the second is the regular expression pattern, and the third is the replacement string.
 In general you can have multiple sets of patterns and associated replacements. You add each pair of parameters at the end.
 If the second parameter is a list, the patterns and replacements come from it.

Case one:

* p1: string to replace
* p2: pattern 1
* p3: replacement string 1
* p4: optional: pattern 2
* p5: optional: replacement string 2
* ...
* pn-1: optional: pattern n
* pn: optional: replacement string n

Case two:

* p1: string to replace
* p2: list of pattern and replacement pairs

Examples:

~~~
replaceRe("abcdefabc", "abc", "456")
  => "456def456"
replaceRe("abcdefabc", "abc", "456", "def", "")
  => "456456"
l = list("abc", "456", "def", "")
replaceRe("abcdefabc", l))
  => "456456"
~~~

```nim
func funReplaceRe(parameters: seq[Value]): FunResult
```

[source](../src/runFunction.nim#L998)

# <a id="a27"></a>funPath

<p>Split a file path into pieces. Return a dictionary with the filename, basename, extension and directory.</p>
<p>You pass a path string and the optional path separator. When no separator, the current system separator is used.

* p1: path string
* p2: optional separator string, "/" or "".

Examples:

~~~
path("src/runFunction.nim") => {
  "filename": "runFunction.nim",
  "basename": "runFunction",
  "ext": ".nim",
  "dir": "src/",
}
~~~</p>


```nim
func funPath(parameters: seq[Value]): FunResult
```

[source](../src/runFunction.nim#L1069)

# <a id="a28"></a>getFunction

Look up a function by its name.

```nim
proc getFunction(functionName: string): Option[FunctionPtr]
```

[source](../src/runFunction.nim#L1164)


---
⦿ StaticTea markdown template for nim doc comments. ⦿
