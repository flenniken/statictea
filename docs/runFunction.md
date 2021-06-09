[StaticTea Modules](./)

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
* [cmpString](#user-content-a7) &mdash; Compares two utf8 strings a and b.
* [cmpBaseValues](#user-content-a8) &mdash; Compares two values a and b.
* [funCmp](#user-content-a9) &mdash; Compare two values.
* [funConcat](#user-content-a10) &mdash; Concatentate two or more strings.
* [funLen](#user-content-a11) &mdash; Length of a string, list or dictionary.
* [funGet](#user-content-a12) &mdash; Get a value from a list or dictionary.
* [funIf](#user-content-a13) &mdash; Return a value based on a condition.
* [funAdd](#user-content-a14) &mdash; Add two or more numbers.
* [funExists](#user-content-a15) &mdash; Determine whether a key exists in a dictionary.
* [funCase](#user-content-a16) &mdash; Return a value from multiple choices.
* [parseVersion](#user-content-a17) &mdash; Parse a StaticTea version number and return its three components.
* [funCmpVersion](#user-content-a18) &mdash; Compare two StaticTea version numbers.
* [funFloat](#user-content-a19) &mdash; Create a float from an int or an int number string.
* [funInt](#user-content-a20) &mdash; Create an int from a float or a float number string.
* [funFind](#user-content-a21) &mdash; Find the position of a substring in a string.
* [funSubstr](#user-content-a22) &mdash; Extract a substring from a string by its position.
* [funDup](#user-content-a23) &mdash; Duplicate a string.
* [funDict](#user-content-a24) &mdash; Create a dictionary from a list of key, value pairs.
* [funList](#user-content-a25) &mdash; Create a list of values.
* [funReplace](#user-content-a26) &mdash; Replace a substring by its position.
* [funReplaceRe](#user-content-a27) &mdash; Replace multiple parts of a string using regular expressions.
* [funPath](#user-content-a28) &mdash; Split a file path into pieces.
* [funLower](#user-content-a29) &mdash; Lowercase a string.
* [funKeys](#user-content-a30) &mdash; Create a list from the keys in a dictionary.
* [funValues](#user-content-a31) &mdash; Create a list of the values in a dictionary.
* [funSort](#user-content-a32) &mdash; Sort a list of values of the same type.
* [getFunction](#user-content-a33) &mdash; Look up a function by its name.

# <a id="a0"></a>FunctionPtr

Signature of a statictea function. It takes any number of values and returns a value or a warning message.

```nim
FunctionPtr = proc (parameters: seq[Value]): FunResult
```


# <a id="a1"></a>FunResultKind

The kind of a FunResult object, either a value or warning.

```nim
FunResultKind = enum
  frValue, frWarning
```


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


# <a id="a3"></a>newFunResultWarn

Return a new FunResult object. It contains a warning, the index of the problem parameter, and the two optional strings that go with the warning.

```nim
func newFunResultWarn(warning: Warning; parameter: Natural = 0; p1: string = "";
                      p2: string = ""): FunResult
```


# <a id="a4"></a>newFunResult

Return a new FunResult object containing a value.

```nim
func newFunResult(value: Value): FunResult
```


# <a id="a5"></a>`==`

Compare two FunResult objects and return true when equal.

```nim
func `==`(r1: FunResult; r2: FunResult): bool
```


# <a id="a6"></a>`$`

Return a string representation of a FunResult object.

```nim
func `$`(funResult: FunResult): string
```


# <a id="a7"></a>cmpString

Compares two utf8 strings a and b.  When a equals b return 0, when a is greater than b return 1 and when a is less than b return -1. Optionally Ignore case.

```nim
func cmpString(a, b: string; insensitive: bool = false): int
```


# <a id="a8"></a>cmpBaseValues

Compares two values a and b.  When a equals b return 0, when a is greater than b return 1 and when a is less than b return -1. The values must be the same kind and either int, float or string.

```nim
func cmpBaseValues(a, b: Value; insensitive: bool = false): int
```


# <a id="a9"></a>funCmp

Compare two values. Returns -1 for less, 0 for equal and 1 for
greater than.  The values are either int, float or string (both the
same type) The default compares strings case sensitive.

Compare numbers:

* p1: number
* p2: number
* return: -1, 0, 1

Compare strings:

* p1: string
* p2: string
* p3: optional: 1 for case insensitive
* return: -1, 0, 1

Examples:

~~~
cmp(7, 9) => -1
cmp(8, 8) => 0
cmp(9, 2) => 1

cmp("coffee", "tea") => -1
cmp("tea", "tea") => 0
cmp("Tea", "tea") => 1
cmp("Tea", "tea", 1) => 0
~~~~

```nim
func funCmp(parameters: seq[Value]): FunResult
```


# <a id="a10"></a>funConcat

Concatentate two or more strings.

* p1: string
* p2: string
* ...
* pn: string
* return: string

Examples:

~~~
concat("tea", " time") => "tea time"
concat("a", "b", "c", "d") => "abcd"
~~~~

```nim
func funConcat(parameters: seq[Value]): FunResult
```


# <a id="a11"></a>funLen

Length of a string, list or dictionary. For strings it returns
the number of characters, not bytes. For lists and dictionaries
it return the number of elements.

* p1: string, list or dict
* return: int

Examples:

~~~
len("tea") => 3
len(list(4, 1)) => 2
len(dict('a', 4)) => 1
~~~~

```nim
func funLen(parameters: seq[Value]): FunResult
```


# <a id="a12"></a>funGet

Get a value from a list or dictionary.  You can specify a default
value to return when the value doesn't exist, if you don't, a
warning is generated when the element doesn't exist.

Note: for dictionary lookup you can use dot notation for many
cases.

Dictionary case:

* p1: dictionary
* p2: key string
* p3: optional default value returned when key is missing
* return: value

List case:

* p1: list
* p2: index of item
* p3: optional default value returned when index is too big
* return: value

Examples:

~~~
d = dict("tea", "Earl Grey")
get(d, 'tea') => "Earl Grey"
get(d, 'coffee', 'Tea') => "Tea"

l = list(4, 'a', 10)
get(l, 2) => 10
get(l, 3, 99) => 99

d = dict("tea", "Earl Grey")
d.tea => "Earl Grey"
~~~~

```nim
func funGet(parameters: seq[Value]): FunResult
```


# <a id="a13"></a>funIf

Return a value based on a condition.

* p1: int condition
* p2: true case: the value returned when condition is 1
* p3: else case: the value returned when condition is not 1.
* return: p2 or p3

Examples:

~~~
if(1, 'tea', 'beer') => "tea"
if(0, 'tea', 'beer') => "beer"
if(4, 'tea', 'beer') => "beer"
~~~~

```nim
func funIf(parameters: seq[Value]): FunResult
```


# <a id="a14"></a>funAdd

Add two or more numbers.  The parameters must be all integers or
all floats.  A warning is generated on overflow.

Integer case:

* p1: int
* p2: int
* ...
* pn: int
* return: int

Float case:

* p1: float
* p2: float
* ...
* pn: float
* return: float

Examples:

~~~
add(1, 2) => 3
add(1, 2, 3) => 6

add(1.5, 2.3) => 3.8
add(1.1, 2.2, 3.3) => 6.6
~~~~

```nim
func funAdd(parameters: seq[Value]): FunResult
```


# <a id="a15"></a>funExists

Determine whether a key exists in a dictionary.

* p1: dictionary
* p2: key string
* return: 0 or 1

Examples:

~~~
d = dict("tea", "Earl")
exists(d, "tea") => 1
exists(d, "coffee") => 0
~~~~

```nim
func funExists(parameters: seq[Value]): FunResult
```


# <a id="a16"></a>funCase

Return a value from multiple choices. It takes a main condition,
any number of case pairs then an optional else value.

The first parameter of a case pair is the condition and the
second is the return value when that condition matches the main
condition. The function compares the conditions left to right and
returns the first match.

When none of the cases match the main condition, the "else"
value is returned. If none match and the else is missing, a
warning is generated and the statement is skipped. The conditions
must be integers or strings. The return values can be any type.

* p1: the main condition value
* p2: the first case condition
* p3: the first case value
* ...
* pn-2: the last case condition
* pn-1: the last case value
* pn: the optional "else" value returned when nothing matches
* return: any value

Examples:

~~~
case(8, 8, "tea", "water") => "tea"
case(8, 3, "tea", "water") => "water"
case(8,
  1, "tea", +
  2, "water", +
  3, "wine", +
  "beer") => "beer"
~~~~

```nim
func funCase(parameters: seq[Value]): FunResult
```


# <a id="a17"></a>parseVersion

Parse a StaticTea version number and return its three components.

```nim
func parseVersion(version: string): Option[(int, int, int)]
```


# <a id="a18"></a>funCmpVersion

Compare two StaticTea version numbers. Returns -1 for less, 0 for
equal and 1 for greater than.

StaticTea uses [Semantic Versioning](https://semver.org/)
with the added restriction that each version component has one
to three digits (no letters).

* p1: version number string
* p2: version number string
* return: -1, 0, 1

Examples:

~~~
cmpVersion("1.2.5", "1.1.8") => -1
cmpVersion("1.2.5", "1.3.0") => 1
cmpVersion("1.2.5", "1.2.5") => 1
~~~~

```nim
func funCmpVersion(parameters: seq[Value]): FunResult
```


# <a id="a19"></a>funFloat

Create a float from an int or an int number string.

* p1: int or int string
* return: float

Examples:

~~~
float(2) => 2.0
float("33") => 33.0
~~~~

```nim
func funFloat(parameters: seq[Value]): FunResult
```


# <a id="a20"></a>funInt

Create an int from a float or a float number string.

* p1: float or float number string
* p2: optional round option. "round" is the default.
* return: int

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
~~~~

```nim
func funInt(parameters: seq[Value]): FunResult
```


# <a id="a21"></a>funFind

Find the position of a substring in a string.  When the substring
is not found you can return a default value.  A warning is
generated when the substring is missing and you don't specify a
default value.


* p1: string
* p2: substring
* p3: optional default value
* return: the index of substring or p3

~~~
       0123456789 1234567
msg = "Tea time at 3:30."
find(msg, "Tea") = 0
find(msg, "time") = 4
find(msg, "me") = 6
find(msg, "party", -1) = -1
find(msg, "party", len(msg)) = 17
find(msg, "party", 0) = 0
~~~~

```nim
func funFind(parameters: seq[Value]): FunResult
```


# <a id="a22"></a>funSubstr

Extract a substring from a string by its position. You pass the
string, the substring's start index then its end index+1.
The end index is optional and defaults to the end of the
string.

The range is half-open which includes the start position but not
the end position. For example, [3, 7) includes 3, 4, 5, 6. The
end minus the start is equal to the length of the substring.

* p1: string
* p2: start index
* p3: optional: end index (one past end)
* return: string

Examples:

~~~
substr("Earl Grey", 0, 4) => "Earl"
substr("Earl Grey", 5) => => "Grey"
~~~~

```nim
func funSubstr(parameters: seq[Value]): FunResult
```


# <a id="a23"></a>funDup

Duplicate a string. The first parameter is the string to dup and
the second parameter is the number of times to duplicate it.

* p1: string to duplicate
* p2: number of times to repeat
* return: string

Examples:

~~~
dup("=", 3) => "==="
substr("abc", 2) => "abcabc"
~~~~

```nim
func funDup(parameters: seq[Value]): FunResult
```


# <a id="a24"></a>funDict

Create a dictionary from a list of key, value pairs.  The keys
must be strings and the values can be any type.

* p1: key string
* p2: value
* ...
* pn-1: key string
* pn: value
* return: dict

Examples:

~~~
dict("a", 5) => {"a": 5}
dict("a", 5, "b", 33, "c", 0) =>
  {"a": 5, "b": 33, "c": 0}
~~~~

```nim
func funDict(parameters: seq[Value]): FunResult
```


# <a id="a25"></a>funList

Create a list of values.

* p1: value
* p2: value
* p3: value
* ...
* pn: value
* return: list

Examples:

~~~
list() => []
list(1) => [1]
list(1, 2, 3) => [1, 2, 3]
list("a", 5, "b") => ["a", 5, "b"]
~~~~

```nim
func funList(parameters: seq[Value]): FunResult
```


# <a id="a26"></a>funReplace

Replace a substring by its position.  You specify the substring
position and the string to take its place.  You can use it to
insert and append to a string as well.

* p1: string
* p2: start index of substring
* p3: length of substring
* p4: replacement substring
* return: string

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
~~~~

```nim
func funReplace(parameters: seq[Value]): FunResult
```


# <a id="a27"></a>funReplaceRe

Replace multiple parts of a string using regular expressions.

You specify one or more pairs of a regex patterns and its string
replacement. The pairs can be specified as parameters to the
function or they can be part of a list.

Muliple parameters case:

* p1: string to replace
* p2: pattern 1
* p3: replacement string 1
* p4: optional: pattern 2
* p5: optional: replacement string 2
* ...
* pn-1: optional: pattern n
* pn: optional: replacement string n
* return: string

List case:

* p1: string to replace
* p2: list of pattern and replacement pairs
* return: string

Examples:

~~~
replaceRe("abcdefabc", "abc", "456")
  => "456def456"
replaceRe("abcdefabc", "abc", "456", "def", "")
  => "456456"
l = list("abc", "456", "def", "")
replaceRe("abcdefabc", l))
  => "456456"
~~~~

```nim
func funReplaceRe(parameters: seq[Value]): FunResult
```


# <a id="a28"></a>funPath

Split a file path into pieces. Return a dictionary with the
filename, basename, extension and directory.

You pass a path string and the optional path separator. When no
separator, the current system separator is used.

* p1: path string
* p2: optional separator string, "/" or "\".
* return: dict

Examples:

~~~
path("src/runFunction.nim") => {
  "filename": "runFunction.nim",
  "basename": "runFunction",
  "ext": ".nim",
  "dir": "src/",
}

path("src\runFunction.nim", "\") => {
  "filename": "runFunction.nim",
  "basename": "runFunction",
  "ext": ".nim",
  "dir": "src\",
}
~~~~

```nim
func funPath(parameters: seq[Value]): FunResult
```


# <a id="a29"></a>funLower

Lowercase a string.

* p1: string
* return: lowercase string

Examples:

~~~
lower("Tea") => "tea"
~~~~

```nim
func funLower(parameters: seq[Value]): FunResult
```


# <a id="a30"></a>funKeys

Create a list from the keys in a dictionary.

* p1: dictionary
* return: list

Examples:

~~~
d = dict("a", 1, "b", 2, "c", 3)
keys(d) => ["a", "b", "c"]
values(d) => ["apple", 2, 3]
~~~~

```nim
func funKeys(parameters: seq[Value]): FunResult
```


# <a id="a31"></a>funValues

Create a list of the values in a dictionary.

* p1: dictionary
* return: list

Examples:

~~~
d = dict("a", "apple", "b", 2, "c", 3)
keys(d) => ["a", "b", "c"]
values(d) => ["apple", 2, 3]
~~~~

```nim
func funValues(parameters: seq[Value]): FunResult
```


# <a id="a32"></a>funSort

Sort a list of values of the same type.

When sorting strings you have the option to compare case
sensitive or insensitive.

When sorting lists the lists are compared by their first
element. The first elements must exist, be the same type and be
an int, float or string. You have the option of comparing strings
case insensitive.

Dictionaries are compared by the value of one of their keys.  The
key values must exist, be the same type and be an int, float or
string. You have the option of comparing strings case
insensitive.

int, float case:

* p1: list of ints or list of floats
* p2: optional: "ascending", "descending"
* return: sorted list

string or list case:

* p1: list of strings or list of lists
* p2: optional: "ascending", "descending"
* p3: optional: default "sensitive", "insensitive"
* return: sorted list

dictionary case:

* p1: list of dictionaries
* p2: "ascending", "descending"
* p3: "sensitive", "insensitive"
* p4: key string
* return: sorted list

Examples:

~~~
l = list(4, 3, 5, 5, 2, 4)
sort(l) => [2, 3, 4, 4, 5, 5]
sort(l, "descending") => [5, 5, 4, 4, 3, 2]

strs = list('T', 'e', 'a')
sort(strs) => ['T', 'a', 'e']
sort(strs, "ascending", "sensitive") => ['T', 'a', 'e']
sort(strs, "ascending", "insensitive") => ['a', 'e', 'T']

l1 = list(4, 3, 1)
l2 = list(2, 3, 0)
listOfList = list(l1, l2)
sort(listOfList) => [l2, l1]

d1 = dict('name', 'Earl Gray', 'weight', 1.2)
d2 = dict('name', 'Tea Pot', 'weight', 3.5)
dicts = list(d1, d2)
sort(dicts, "ascending", "sensitive", 'weight') => [d1, d2]
sort(dicts, "descending", "sensitive", 'name') => [d2, d1]
~~~~

```nim
func funSort(parameters: seq[Value]): FunResult
```


# <a id="a33"></a>getFunction

Look up a function by its name.

```nim
proc getFunction(functionName: string): Option[FunctionPtr]
```



---
⦿ StaticTea markdown template for nim doc comments. ⦿
