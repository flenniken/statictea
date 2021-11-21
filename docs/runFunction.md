# runFunction.nim

This module contains the StaticTea functions and supporting types. The StaticTea language functions start with "fun", for example, the "funCmp" function implements the StaticTea "cmp" function.

* [runFunction.nim](../src/runFunction.nim) &mdash; Nim source code.
# Index

* [cmpBaseValues](#cmpbasevalues) &mdash; Compares two values a and b.
* [funCmp_iii](#funcmp_iii) &mdash; Compare two ints.
* [funCmp_ffi](#funcmp_ffi) &mdash; Compare two floats.
* [funCmp_ssoii](#funcmp_ssoii) &mdash; Compare two strings.
* [funConcat](#funconcat) &mdash; Concatentate strings.
* [funLen_si](#funlen_si) &mdash; Number of characters in a string.
* [funLen_li](#funlen_li) &mdash; Number of elements in a list.
* [funLen_di](#funlen_di) &mdash; Number of elements in a dictionary.
* [funGet_lioaa](#funget_lioaa) &mdash; Get a list value by its index.
* [funGet_dsoaa](#funget_dsoaa) &mdash; Get a dictionary value by its key.
* [funIf](#funif) &mdash; If the condition is true return a value, else return another value.
* [funAdd_Ii](#funadd_ii) &mdash; Add integers.
* [funAdd_Fi](#funadd_fi) &mdash; Add floats.
* [funExists](#funexists) &mdash; Determine whether a key exists in a dictionary.
* [funCase_iloaa](#funcase_iloaa) &mdash; Compare integer cases and return the matching value.
* [funCase_sloaa](#funcase_sloaa) &mdash; Compare string cases and return the matching value.
* [parseVersion](#parseversion) &mdash; Parse a StaticTea version number and return its three components.
* [funCmpVersion](#funcmpversion) &mdash; Compare two StaticTea version numbers.
* [funFloat_if](#funfloat_if) &mdash; Create a float from an int.
* [funFloat_sf](#funfloat_sf) &mdash; Create a float from a number string.
* [funInt_fosi](#funint_fosi) &mdash; Create an int from a float.
* [funInt_sosi](#funint_sosi) &mdash; Create an int from a number string.
* [funFind](#funfind) &mdash; Find the position of a substring in a string.
* [funSubstr](#funsubstr) &mdash; Extract a substring from a string by its position.
* [funDup](#fundup) &mdash; Duplicate a string x times.
* [funDict](#fundict) &mdash; Create a dictionary from a list of key, value pairs.
* [funList](#funlist) &mdash; Create a list of values.
* [funReplace](#funreplace) &mdash; Replace a substring specified by its position and length with another string.
* [funReplaceRe_sSSs](#funreplacere_ssss) &mdash; Replace multiple parts of a string using regular expressions.
* [funReplaceRe_sls](#funreplacere_sls) &mdash; Replace multiple parts of a string using regular expressions.
* [funPath](#funpath) &mdash; Split a file path into its component pieces.
* [funLower](#funlower) &mdash; Lowercase a string.
* [funKeys](#funkeys) &mdash; Create a list from the keys in a dictionary.
* [funValues](#funvalues) &mdash; Create a list out of the values in the specified dictionary.
* [funSort_lsosl](#funsort_lsosl) &mdash; Sort a list of values of the same type.
* [funSort_lssil](#funsort_lssil) &mdash; Sort a list of lists.
* [funSort_lsssl](#funsort_lsssl) &mdash; Sort a list of dictionaries.
* [funGithubAnchor_ss](#fungithubanchor_ss) &mdash; Create a Github anchor name from a heading name.
* [funGithubAnchor_ll](#fungithubanchor_ll) &mdash; Create Github anchor names from heading names.
* [funType_as](#funtype_as) &mdash; Return the parameter type, one of: int, float, string, list, dict.
* [funJoinPath_loss](#funjoinpath_loss) &mdash; Join the path components with a path separator.
* [funJoinPath_oSs](#funjoinpath_oss) &mdash; Join the path components with the platform path separator.
* [createFunctionTable](#createfunctiontable) &mdash; Create a table of all the built in functions.
* [getFunctionList](#getfunctionlist) &mdash; Return the functions with the given name.
* [getFunction](#getfunction) &mdash; Find the function with the given name and return a pointer to it.
* [isFunctionName](#isfunctionname) &mdash; Return true when the function exists.

# cmpBaseValues

Compares two values a and b.  When a equals b return 0, when a is greater than b return 1 and when a is less than b return -1. The values must be the same kind and either int, float or string.

```nim
func cmpBaseValues(a, b: Value; insensitive: bool = false): int
```

# funCmp_iii

Compare two ints. Returns -1 for less, 0 for equal and 1 for
 greater than.

~~~
cmp(a: int, b: int) int
~~~~

Examples:

~~~
cmp(7, 9) => -1
cmp(8, 8) => 0
cmp(9, 2) => 1
~~~~

```nim
func funCmp_iii(parameters: seq[Value]): FunResult
```

# funCmp_ffi

Compare two floats. Returns -1 for less, 0 for
equal and 1 for greater than.

~~~
cmp(a: float, b: float) int
~~~~

Examples:

~~~
cmp(7.8, 9.1) => -1
cmp(8.4, 8.4) => 0
cmp(9.3, 2.2) => 1
~~~~

```nim
func funCmp_ffi(parameters: seq[Value]): FunResult
```

# funCmp_ssoii

Compare two strings. Returns -1 for less, 0 for equal and 1 for
greater than.

You have the option to compare case insensitive. Case sensitive
is the default.

~~~
cmp(a: string, b: string, optional insensitive: int) int
~~~~

Examples:

~~~
cmp("coffee", "tea") => -1
cmp("tea", "tea") => 0
cmp("Tea", "tea") => 1
cmp("Tea", "tea", 0) => 1
cmp("Tea", "tea", 1) => 0
~~~~

```nim
func funCmp_ssoii(parameters: seq[Value]): FunResult
```

# funConcat

Concatentate strings.

~~~
concat(strs: varargs(string)) string
~~~~

Examples:

~~~
concat("tea", " time") => "tea time"
concat("a", "b", "c", "d") => "abcd"
concat("a") => "a"
~~~~

```nim
func funConcat(parameters: seq[Value]): FunResult
```

# funLen_si

Number of characters in a string.

~~~
len(str: string) int
~~~~

Examples:

~~~
len("tea") => 3
len("añyóng") => 6
~~~~

```nim
func funLen_si(parameters: seq[Value]): FunResult
```

# funLen_li

Number of elements in a list.

~~~
len(list: list) int
~~~~

Examples:

~~~
len(list()) => 0
len(list(1)) => 1
len(list(4, 5)) => 2
~~~~

```nim
func funLen_li(parameters: seq[Value]): FunResult
```

# funLen_di

Number of elements in a dictionary.

~~~
len(dictionary: dict) int
~~~~

Examples:

~~~
len(dict()) => 0
len(dict('a', 4)) => 1
len(dict('a', 4, 'b', 3)) => 2
~~~~

```nim
func funLen_di(parameters: seq[Value]): FunResult
```

# funGet_lioaa

Get a list value by its index.  If the index is invalid, the
default value is returned when specified, else a warning is
generated.

~~~
get(list: list, index: int, optional default: any) any
~~~~

Examples:

~~~
list = list(4, 'a', 10)
get(list, 2) => 10
get(list, 3, 99) => 99
~~~~

```nim
func funGet_lioaa(parameters: seq[Value]): FunResult
```

# funGet_dsoaa

Get a dictionary value by its key.  If the key doesn't exist, the
default value is returned if specified, else a warning is
generated.

~~~
get(dictionary: dict, key: string, optional default: any) any
~~~~

Note: For dictionary lookup you can use dot notation. It's the
same as get without the default.

Examples:

~~~
d = dict("tea", "Earl Grey")
get(d, 'tea') => "Earl Grey"
get(d, 'coffee', 'Tea') => "Tea"
~~~~

Using dot notation:
~~~
d = dict("tea", "Earl Grey")
d.tea => "Earl Grey"
~~~~

```nim
func funGet_dsoaa(parameters: seq[Value]): FunResult
```

# funIf

If the condition is true return a value, else return another value. False is 0 and true is not 0.

~~~
if(condition: int, true: any, false: any) any
~~~~

Examples:

~~~
if(1, 'tea', 'beer') => "tea"
if(0, 'tea', 'beer') => "beer"
if(4, 'tea', 'beer') => "beer"
~~~~

```nim
func funIf(parameters: seq[Value]): FunResult
```

# funAdd_Ii

Add integers. A warning is generated on overflow.

~~~
add(numbers: varargs(int)) int
~~~~

Examples:

~~~
add(1) => 1
add(1, 2) => 3
add(1, 2, 3) => 6
~~~~

```nim
func funAdd_Ii(parameters: seq[Value]): FunResult
```

# funAdd_Fi

Add floats. A warning is generated on overflow.

~~~
add(numbers: varargs(float)) float
~~~~

Examples:

~~~
add(1.5) => 1.5
add(1.5, 2.3) => 3.8
add(1.1, 2.2, 3.3) => 6.6
~~~~

```nim
func funAdd_Fi(parameters: seq[Value]): FunResult
```

# funExists

Determine whether a key exists in a dictionary. Return 1 when it exists, else 0.

~~~
exists(dictionary: dict, key: string) int
~~~~

Examples:

~~~
d = dict("tea", "Earl")
exists(d, "tea") => 1
exists(d, "coffee") => 0
~~~~

```nim
func funExists(parameters: seq[Value]): FunResult
```

# funCase_iloaa

Compare integer cases and return the matching value.  It takes a
main integer condition, a list of case pairs and an optional
value when none of the cases match.

The first element of a case pair is the condition and the
second is the return value when that condition matches the main
condition. The function compares the conditions left to right and
returns the first match.

When none of the cases match the main condition, the default
value is returned if it is specified, otherwise a warning is
generated.  The conditions must be integers. The return values
can be any type.

~~~
case(condition: int, pairs: list, optional default: any) any
~~~~

Examples:

~~~
cases = list(0, "tea", 1, "water", 2, "beer")
case(0, cases) => "tea"
case(1, cases) => "water"
case(2, cases) => "beer"
case(2, cases, "wine") => "beer"
case(3, cases, "wine") => "wine"
~~~~

```nim
func funCase_iloaa(parameters: seq[Value]): FunResult
```

# funCase_sloaa

Compare string cases and return the matching value.  It takes a
main string condition, a list of case pairs and an optional
value when none of the cases match.

The first element of a case pair is the condition and the
second is the return value when that condition matches the main
condition. The function compares the conditions left to right and
returns the first match.

When none of the cases match the main condition, the default
value is returned if it is specified, otherwise a warning is
generated.  The conditions must be strings. The return values
can be any type.

~~~
case(condition: string, pairs: list, optional default: any) any
~~~~

Examples:

~~~
cases = list("tea", 15, "water", 2.3, "beer", "cold")
case("tea", cases) => 15
case("water", cases) => 2.3
case("beer", cases) => "cold"
case("bunch", cases, "other") => "other"
~~~~

```nim
func funCase_sloaa(parameters: seq[Value]): FunResult
```

# parseVersion

Parse a StaticTea version number and return its three components.

```nim
func parseVersion(version: string): Option[(int, int, int)]
```

# funCmpVersion

Compare two StaticTea version numbers. Returns -1 for less, 0 for
equal and 1 for greater than.

~~~
cmpVersion(versionA: string, versionB: string) int
~~~~

StaticTea uses [|[|https://semver.org/][|Semantic Versioning]]
with the added restriction that each version component has one
to three digits (no letters).

Examples:

~~~
cmpVersion("1.2.5", "1.1.8") => 1
cmpVersion("1.2.5", "1.3.0") => -1
cmpVersion("1.2.5", "1.2.5") => 0
~~~~

```nim
func funCmpVersion(parameters: seq[Value]): FunResult
```

# funFloat_if

Create a float from an int.

~~~
float(num: int) float
~~~~

Examples:

~~~
float(2) => 2.0
float(-33) => -33.0
~~~~

```nim
func funFloat_if(parameters: seq[Value]): FunResult
```

# funFloat_sf

Create a float from a number string.

~~~
float(numString: string) float
~~~~

Examples:

~~~
float("2") => 2.0
float("2.4") => 2.4
float("33") => 33.0
~~~~

```nim
func funFloat_sf(parameters: seq[Value]): FunResult
```

# funInt_fosi

Create an int from a float.

~~~
int(num: float, optional roundOption: string) int
~~~~

Round options:

* "round" - nearest integer, the default.
* "floor" - integer below (to the left on number line)
* "ceiling" - integer above (to the right on number line)
* "truncate" - remove decimals

Examples:

~~~
int(2.34) => 2
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
func funInt_fosi(parameters: seq[Value]): FunResult
```

# funInt_sosi

Create an int from a number string.

~~~
int(numString: string, optional roundOption: string) int
~~~~

Round options:

* "round" - nearest integer, the default
* "floor" - integer below (to the left on number line)
* "ceiling" - integer above (to the right on number line)
* "truncate" - remove decimals

Examples:

~~~
int("2") => 2
int("2.34") => 2
int("-2.34", "round") => -2
int("6.5", "round") => 7
int("-6.5", "round") => -7
int("4.57", "floor") => 4
int("-4.57", "floor") => -5
int("6.3", "ceiling") => 7
int("-6.3", "ceiling") => -6
int("6.3456", "truncate") => 6
int("-6.3456", "truncate") => -6
~~~~

```nim
func funInt_sosi(parameters: seq[Value]): FunResult
```

# funFind

Find the position of a substring in a string.  When the substring
is not found you can return a default value.  A warning is
generated when the substring is missing and you don't specify a
default value.

~~~
find(str: string, substring: string, optional default: any) any
~~~~

Examples:

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

# funSubstr

Extract a substring from a string by its position. You pass the
string, the substring's start index then its end index+1.
The end index is optional and defaults to the end of the
string+1.

The range is half-open which includes the start position but not
the end position. For example, [3, 7) includes 3, 4, 5, 6. The
end minus the start is equal to the length of the substring.

~~~
substr(str: string, start: int, optional end: int) string
~~~~

Examples:

~~~
substr("Earl Grey", 1, 4) => "arl"
substr("Earl Grey", 6) => "rey"
~~~~

```nim
func funSubstr(parameters: seq[Value]): FunResult
```

# funDup

Duplicate a string x times.  The result is a new string built by
concatenating the string to itself the specified number of times.

~~~
dup(pattern: string, count: int) string
~~~~

Examples:

~~~
dup("=", 3) => "==="
dup("abc", 0) => ""
dup("abc", 1) => "abc"
dup("abc", 2) => "abcabc"
dup("", 3) => ""
~~~~

```nim
func funDup(parameters: seq[Value]): FunResult
```

# funDict

Create a dictionary from a list of key, value pairs.  The keys
must be strings and the values can be any type.

~~~
dict(pairs: optional varargs(string, any)) dict
~~~~

Examples:

~~~
dict() => {}
dict("a", 5) => {"a": 5}
dict("a", 5, "b", 33, "c", 0) =>
  {"a": 5, "b": 33, "c": 0}
~~~~

```nim
func funDict(parameters: seq[Value]): FunResult
```

# funList

Create a list of values.

~~~
list(items: optional varargs(any)) list
~~~~

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

# funReplace

Replace a substring specified by its position and length with another string.  You can use the function to insert and append to
a string as well.

~~~
replace(str: string, start: int, length: int, replacement: string) string
~~~~

* str: string
* start: substring start index
* length: substring length
* replacement: substring replacement

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

# funReplaceRe_sSSs

Replace multiple parts of a string using regular expressions.

You specify one or more pairs of a regex patterns and their string
replacements.

~~~
replaceRe(str: string, pairs: varargs(string, string) string
~~~~

Examples:

~~~
replaceRe("abcdefabc", "abc", "456")
  => "456def456"
replaceRe("abcdefabc", "abc", "456", "def", "")
  => "456456"
~~~~

For developing and debugging regular expressions see the
website: https://regex101.com/

```nim
func funReplaceRe_sSSs(parameters: seq[Value]): FunResult
```

# funReplaceRe_sls

Replace multiple parts of a string using regular expressions.

You specify one or more pairs of a regex patterns and its string
replacement.

~~~
replaceRe(str: string, pairs: list) string
~~~~

Examples:

~~~
list = list("abc", "456", "def", "")
replaceRe("abcdefabc", list))
  => "456456"
~~~~

For developing and debugging regular expressions see the
website: https://regex101.com/

```nim
func funReplaceRe_sls(parameters: seq[Value]): FunResult
```

# funPath

Split a file path into its component pieces. Return a dictionary
with the filename, basename, extension and directory.

You pass a path string and the optional path separator, forward
slash or or backwards slash. When no separator, the current
system separator is used.

~~~
path(filename: string, optional separator: string) dict
~~~~

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

# funLower

Lowercase a string.

~~~
lower(str: string) string
~~~~

Examples:

~~~
lower("Tea") => "tea"
lower("TEA") => "tea"
lower("TEĀ") => "teā"
~~~~

```nim
func funLower(parameters: seq[Value]): FunResult
```

# funKeys

Create a list from the keys in a dictionary.

~~~
keys(dictionary: dict) list
~~~~

Examples:

~~~
d = dict("a", 1, "b", 2, "c", 3)
keys(d) => ["a", "b", "c"]
values(d) => ["apple", 2, 3]
~~~~

```nim
func funKeys(parameters: seq[Value]): FunResult
```

# funValues

Create a list out of the values in the specified dictionary.

~~~
values(dictionary: dict) list
~~~~

Examples:

~~~
d = dict("a", "apple", "b", 2, "c", 3)
keys(d) => ["a", "b", "c"]
values(d) => ["apple", 2, 3]
~~~~

```nim
func funValues(parameters: seq[Value]): FunResult
```

# funSort_lsosl

Sort a list of values of the same type.  The values are ints,
floats or strings.

You specify the sort order, "ascending" or "descending".

You have the option of sorting strings case "insensitive". Case
"sensitive" is the default.

~~~
sort(values: list, order: string, optional insensitive: string) list
~~~~

Examples:

~~~
ints = list(4, 3, 5, 5, 2, 4)
sort(list, "ascending") => [2, 3, 4, 4, 5, 5]
sort(list, "descending") => [5, 5, 4, 4, 3, 2]

floats = list(4.4, 3.1, 5.9)
sort(floats, "ascending") => [3.1, 4.4, 5.9]
sort(floats, "descending") => [5.9, 4.4, 3.1]

strs = list('T', 'e', 'a')
sort(strs, "ascending") => ['T', 'a', 'e']
sort(strs, "ascending", "sensitive") => ['T', 'a', 'e']
sort(strs, "ascending", "insensitive") => ['a', 'e', 'T']
~~~~

```nim
func funSort_lsosl(parameters: seq[Value]): FunResult
```

# funSort_lssil

Sort a list of lists.

You specify the sort order, "ascending" or "descending".

You specify how to sort strings either case "sensitive" or
"insensitive".

You specify which index to compare by.  The compare index value
must exist in each list, be the same type and be an int, float or
string.

~~~
sort(lists: list, order: string, case: string, index: int) list
~~~~

Examples:

~~~
l1 = list(4, 3, 1)
l2 = list(2, 3, 4)
listOfLists = list(l1, l2)
sort(listOfLists, "ascending", "sensitive", 0) => [l2, l1]
sort(listOfLists, "ascending", "sensitive", 2) => [l1, l2]
~~~~

```nim
func funSort_lssil(parameters: seq[Value]): FunResult
```

# funSort_lsssl

Sort a list of dictionaries.

You specify the sort order, "ascending" or "descending".

You specify how to sort strings either case "sensitive" or
"insensitive".

You specify the compare key.  The key value must exist
in each dictionary, be the same type and be an int, float or
string.

~~~
sort(dicts: list, order: string, case: string, key: string) list
~~~~

Examples:

~~~
d1 = dict('name', 'Earl Gray', 'weight', 1.2)
d2 = dict('name', 'Tea Pot', 'weight', 3.5)
dicts = list(d1, d2)
sort(dicts, "ascending", "sensitive", 'weight') => [d1, d2]
sort(dicts, "descending", "sensitive", 'name') => [d2, d1]
~~~~

```nim
func funSort_lsssl(parameters: seq[Value]): FunResult
```

# funGithubAnchor_ss

Create a Github anchor name from a heading name. Use it for
Github markdown internal links. If you have duplicate heading
names, the anchor name returned only works for the
first. Punctuation characters are removed so you can get
duplicates in some cases.

~~~
githubAnchor(name: string) string
~~~~

Examples:

~~~
githubAnchor("MyHeading") => "myheading"
githubAnchor("Eary Gray") => "eary-gray"
githubAnchor("$Eary-Gray#") => "eary-gray"
~~~~

Example in a markdown template:

~~~
$$ : anchor = githubAnchor(entry.name)
* {type}[|{entry.name}](#{anchor}) &mdash; {short}
...
# {entry.name}
~~~~

```nim
func funGithubAnchor_ss(parameters: seq[Value]): FunResult
```

# funGithubAnchor_ll

Create Github anchor names from heading names. Use it for Github
markdown internal links. It handles duplicate heading names.

~~~
githubAnchor(names: list) list
~~~~

Examples:

~~~
list = list("Tea", "Water", "Tea")
githubAnchor(list) =>
  ["tea", "water", "tea-1"]
~~~~

```nim
func funGithubAnchor_ll(parameters: seq[Value]): FunResult
```

# funType_as

Return the parameter type, one of: int, float, string, list, dict.

~~~
type(variable: any) string
~~~~

Examples:

~~~
type(2) => "int"
type(3.14159) => "float"
type("Tea") => "string"
type(list(1,2)) => "list"
type(dict("a", 1, "b", 2)) => "dict"
~~~~

```nim
func funType_as(parameters: seq[Value]): FunResult
```

# funJoinPath_loss

Join the path components with a path separator.

You pass a list of components to join. For the second optional
parameter you specify the separator to use, either "/", "" or
"". If you specify "" or leave off the parameter, the current
platform separator is used.

If the separator already exists between components, a new one
is not added. If a component is "", the platform separator is
used for it.

~~~
joinPath(components: list, optional separator: string) string
~~~~

Examples:

~~~
joinPath(list("images", "tea")) =>
  "images/tea"

joinPath(list("images", "tea"), "/") =>
  "images/tea"

joinPath(list("images", "tea"), "\") =>
  "images\tea"

joinPath(list("images/", "tea") =>
  "images/tea"

joinPath(list("", "tea")) =>
  "/tea"

joinPath(list("/", "tea")) =>
  "/tea"
~~~~

```nim
func funJoinPath_loss(parameters: seq[Value]): FunResult
```

# funJoinPath_oSs

Join the path components with the platform path separator.

If the separator already exists between components, a new one
is not added. If a component is "", the platform separator is
used for it.

~~~
joinPath(components: optional vararg(string)) string
~~~~

Examples:

~~~
joinPath("images", "tea")) =>
  "images/tea"

joinPath("images/", "tea") =>
  "images/tea"
~~~~

```nim
func funJoinPath_oSs(parameters: seq[Value]): FunResult
```

# createFunctionTable

Create a table of all the built in functions.

```nim
func createFunctionTable(): Table[string, seq[FunctionSpec]]
```

# getFunctionList

Return the functions with the given name.

```nim
proc getFunctionList(name: string): seq[FunctionSpec]
```

# getFunction

Find the function with the given name and return a pointer to it. If there are multiple functions with the name, return the one that matches the parameters, if none match, return the first one.

```nim
proc getFunction(functionName: string; parameters: seq[Value]): Option[
    FunctionSpec]
```

# isFunctionName

Return true when the function exists.

```nim
proc isFunctionName(functionName: string): bool
```


---
⦿ Markdown page generated by [StaticTea](https://github.com/flenniken/statictea/) from nim doc comments. ⦿
