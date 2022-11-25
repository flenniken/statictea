# runFunction.nim

This module contains the StaticTea functions and supporting types. The StaticTea language functions start with "fun", for example, the "funCmp" function implements the StaticTea "cmp" function.

* [runFunction.nim](../src/runFunction.nim) &mdash; Nim source code.
# Index

* [cmpBaseValues](#cmpbasevalues) &mdash; Compares two values a and b.
* [parseNumber](#parsenumber) &mdash; Return the literal number value and position after it.
* type: [StringOr](#stringor) &mdash; A string or a warning.
* [newStringOr](#newstringor) &mdash; Return a new StringOr object containing a warning.
* [newStringOr](#newstringor-1) &mdash; Return a new StringOr object containing a warning.
* [newStringOr](#newstringor-2) &mdash; Return a new StringOr object containing a string.
* [formatString](#formatstring) &mdash; Format a string by filling in the variable placeholders with
their values.
* [funCmp_iii](#funcmp_iii) &mdash; Compare two ints.
* [funCmp_ffi](#funcmp_ffi) &mdash; Compare two floats.
* [funCmp_ssobi](#funcmp_ssobi) &mdash; Compare two strings.
* [funConcat_sss](#funconcat_sss) &mdash; Concatentate two strings.
* [funLen_si](#funlen_si) &mdash; Number of unicode characters in a string.
* [funLen_li](#funlen_li) &mdash; Number of elements in a list.
* [funLen_di](#funlen_di) &mdash; Number of elements in a dictionary.
* [funGet_lioaa](#funget_lioaa) &mdash; Get a list value by its index.
* [funGet_dsoaa](#funget_dsoaa) &mdash; Get a dictionary value by its key.
* [funIf0_iaoaa](#funif0_iaoaa) &mdash; If the condition is 0, return the second argument, else return the third argument.
* [funIf_baoaa](#funif_baoaa) &mdash; If the condition is true, return the second argument, else return the third argument.
* [funAdd_iii](#funadd_iii) &mdash; Add two integers.
* [funAdd_fff](#funadd_fff) &mdash; Add two floats.
* [funExists_dsb](#funexists_dsb) &mdash; Determine whether a key exists in a dictionary.
* [funCase_iloaa](#funcase_iloaa) &mdash; Compare integer cases and return the matching value.
* [funCase_sloaa](#funcase_sloaa) &mdash; Compare string cases and return the matching value.
* [parseVersion](#parseversion) &mdash; Parse a StaticTea version number and return its three components.
* [funCmpVersion_ssi](#funcmpversion_ssi) &mdash; Compare two StaticTea version numbers.
* [funFloat_if](#funfloat_if) &mdash; Create a float from an int.
* [funFloat_sf](#funfloat_sf) &mdash; Create a float from a number string.
* [funFloat_saa](#funfloat_saa) &mdash; Create a float from a number string.
* [funInt_fosi](#funint_fosi) &mdash; Create an int from a float.
* [funInt_sosi](#funint_sosi) &mdash; Create an int from a number string.
* [funInt_ssaa](#funint_ssaa) &mdash; Create an int from a number string.
* [if0Condition](#if0condition) &mdash; Convert the value to a boolean.
* [funBool_ab](#funbool_ab) &mdash; Create an bool from a value.
* [funFind_ssoaa](#funfind_ssoaa) &mdash; Find the position of a substring in a string.
* [funSlice_siois](#funslice_siois) &mdash; Extract a substring from a string by its position and length.
* [funDup_sis](#fundup_sis) &mdash; Duplicate a string x times.
* [funDict_old](#fundict_old) &mdash; Create a dictionary from a list of key, value pairs.
* [funList](#funlist) &mdash; Create a list of variables.
* [funReplace_siiss](#funreplace_siiss) &mdash; Replace a substring specified by its position and length with another string.
* [funReplaceRe_sls](#funreplacere_sls) &mdash; Replace multiple parts of a string using regular expressions.
* type: [PathComponents](#pathcomponents) &mdash; PathComponents holds the components of the file path components.
* [newPathComponents](#newpathcomponents) &mdash; 
* [parsePath](#parsepath) &mdash; Parse the given file path into its component pieces.
* [funPath_sosd](#funpath_sosd) &mdash; Split a file path into its component pieces.
* [funLower_ss](#funlower_ss) &mdash; Lowercase a string.
* [funKeys_dl](#funkeys_dl) &mdash; Create a list from the keys in a dictionary.
* [funValues_dl](#funvalues_dl) &mdash; Create a list out of the values in the specified dictionary.
* [funSort_lsosl](#funsort_lsosl) &mdash; Sort a list of values of the same type.
* [funSort_lssil](#funsort_lssil) &mdash; Sort a list of lists.
* [funSort_lsssl](#funsort_lsssl) &mdash; Sort a list of dictionaries.
* [funGithubAnchor_ss](#fungithubanchor_ss) &mdash; Create a Github anchor name from a heading name.
* [funGithubAnchor_ll](#fungithubanchor_ll) &mdash; Create Github anchor names from heading names.
* [funType_as](#funtype_as) &mdash; Return the parameter type, one of: int, float, string, list, dict, bool or func.
* [funJoinPath_loss](#funjoinpath_loss) &mdash; Join the path components with a path separator.
* [funJoin_lsois](#funjoin_lsois) &mdash; Join a list of strings with a separator.
* [funWarn_ss](#funwarn_ss) &mdash; Return a warning message and skip the current statement.
* [funReturn_ss](#funreturn_ss) &mdash; Return the given value and control command looping.
* [funString_aoss](#funstring_aoss) &mdash; Convert a variable to a string.
* [funString_sds](#funstring_sds) &mdash; Convert the dictionary variable to dot names.
* [funFormat_ss](#funformat_ss) &mdash; Format a string using replacement variables similar to a replacement block.
* [funStartsWith_ssb](#funstartswith_ssb) &mdash; Check whether a strings starts with the given prefix.
* [funNot_bb](#funnot_bb) &mdash; Boolean not.
* [funAnd_bbb](#funand_bbb) &mdash; Boolean AND with short circuit.
* [funOr_bbb](#funor_bbb) &mdash; Boolean OR with short circuit.
* [funEq_iib](#funeq_iib) &mdash; Return true when the two ints are equal.
* [funEq_ffb](#funeq_ffb) &mdash; Return true when two floats are equal.
* [funEq_ssb](#funeq_ssb) &mdash; Return true when two strings are equal.
* [funNe_iib](#funne_iib) &mdash; Return true when two ints are not equal.
* [funNe_ffb](#funne_ffb) &mdash; Return true when two floats are not equal.
* [funNe_ssb](#funne_ssb) &mdash; Return true when two strings are not equal.
* [funGt_iib](#fungt_iib) &mdash; Return true when an int is greater then another int.
* [funGt_ffb](#fungt_ffb) &mdash; Return true when one float is greater than another float.
* [funGte_iib](#fungte_iib) &mdash; Return true when an int is greater then or equal to another int.
* [funGte_ffb](#fungte_ffb) &mdash; Return true when a float is greater than or equal to another float.
* [funLt_iib](#funlt_iib) &mdash; Return true when an int is less than another int.
* [funLt_ffb](#funlt_ffb) &mdash; Return true when a float is less then another float.
* [funLte_iib](#funlte_iib) &mdash; Return true when an int is less than or equal to another int.
* [funLte_ffb](#funlte_ffb) &mdash; Return true when a float is less than or equal to another float.
* [funReadJson_sa](#funreadjson_sa) &mdash; Convert a JSON string to a variable.
* const: [functionsList](#functionslist) &mdash; Sorted list of built in functions, their function name, nim name and their signature.
* [getBestFunction](#getbestfunction) &mdash; Given a function variable or a list of function variables and a list of arguments, return the one that best matches the arguments.
* [createFuncDictionary](#createfuncdictionary) &mdash; Create the f dictionary from the built in functions.

# cmpBaseValues

Compares two values a and b.  When a equals b return 0, when a is greater than b return 1 and when a is less than b return -1. The values must be the same kind and either int, float or string.

```nim
func cmpBaseValues(a, b: Value; insensitive: bool = false): int
```

# parseNumber

Return the literal number value and position after it.  The start index points at a digit or minus sign. The position includes the trailing whitespace.

```nim
func parseNumber(line: string; start: Natural): ValueAndPosOr
```

# StringOr

A string or a warning.

```nim
StringOr = OpResultWarn[string]
```

# newStringOr

Return a new StringOr object containing a warning.

```nim
func newStringOr(warning: MessageId; p1: string = ""; pos = 0): StringOr
```

# newStringOr

Return a new StringOr object containing a warning.

```nim
func newStringOr(warningData: WarningData): StringOr
```

# newStringOr

Return a new StringOr object containing a string.

```nim
func newStringOr(str: string): StringOr
```

# formatString

Format a string by filling in the variable placeholders with
their values. Generate a warning when the variable doesn't
exist. No space around the bracketed variables.

~~~
let first = "Earl"
let last = "Grey"
"name: {first} {last}" => "name: Earl Grey"
~~~~

To enter a left bracket use two in a row.

~~~
"{{" => "{"
~~~~

```nim
proc formatString(variables: Variables; text: string): StringOr
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
func funCmp_iii(variables: Variables; parameters: seq[Value]): FunResult
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
func funCmp_ffi(variables: Variables; parameters: seq[Value]): FunResult
```

# funCmp_ssobi

Compare two strings. Returns -1 for less, 0 for equal and 1 for
greater than.

You have the option to compare case insensitive. Case sensitive
is the default.

~~~
cmp(a: string, b: string, optional insensitive: bool) int
~~~~

Examples:

~~~
cmp("coffee", "tea") => -1
cmp("tea", "tea") => 0
cmp("Tea", "tea") => 1
cmp("Tea", "tea", true) => 1
cmp("Tea", "tea", false) => 0
~~~~

```nim
func funCmp_ssobi(variables: Variables; parameters: seq[Value]): FunResult
```

# funConcat_sss

Concatentate two strings. See [[#join][join]] for more that two arguments.

~~~
concat(a: string, b: string) string
~~~~

Examples:

~~~
concat("tea", " time") => "tea time"
concat("a", "b") => "ab"
~~~~

```nim
func funConcat_sss(variables: Variables; parameters: seq[Value]): FunResult
```

# funLen_si

Number of unicode characters in a string.

~~~
len(str: string) int
~~~~

Examples:

~~~
len("tea") => 3
len("añyóng") => 6
~~~~

```nim
func funLen_si(variables: Variables; parameters: seq[Value]): FunResult
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
func funLen_li(variables: Variables; parameters: seq[Value]): FunResult
```

# funLen_di

Number of elements in a dictionary.

~~~
len(dictionary: dict) int
~~~~

Examples:

~~~
len(dict()) => 0
len(dict("a", 4)) => 1
len(dict("a", 4, "b", 3)) => 2
~~~~

```nim
func funLen_di(variables: Variables; parameters: seq[Value]): FunResult
```

# funGet_lioaa

Get a list value by its index.  If the index is invalid, the
default value is returned when specified, else a warning is
generated. You can use negative index values. Index -1 gets the
last element. It is short hand for len - 1. Index -2 is len - 2,
etc.

~~~
get(list: list, index: int, optional default: any) any
~~~~

Examples:

~~~
list = list(4, "a", 10)
get(list, 0) => 4
get(list, 1) => "a"
get(list, 2) => 10
get(list, 3, 99) => 99
get(list, -1) => 10
get(list, -2) => "a"
get(list, -3) => 4
get(list, -4, 11) => 11
~~~~

```nim
func funGet_lioaa(variables: Variables; parameters: seq[Value]): FunResult
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
get(d, "tea") => "Earl Grey"
get(d, "coffee", "Tea") => "Tea"
~~~~

Using dot notation:
~~~
d = dict("tea", "Earl Grey")
d.tea => "Earl Grey"
~~~~

```nim
func funGet_dsoaa(variables: Variables; parameters: seq[Value]): FunResult
```

# funIf0_iaoaa

If the condition is 0, return the second argument, else return the third argument.  You can use any type for the condition.  The condition is 0 for strings, lists and dictionaries when their length is 0.

The condition types and what is considered 0:

* bool -- false
* int -- 0
* float -- 0.0
* string -- when the length of the string is 0
* list -- when the length of the list is 0
* dict -- when the length of the dictionary is 0
* func -- always 0

The if functions are special in a couple of ways, see
[[#if-functions][If Functions]]

~~~
if0(condition: any, then: any, else: any) any
if0(condition: any, then: any)
~~~~

Examples:

~~~
a = if0(0, "tea", "beer") => tea
a = if0(1, "tea", "beer") => beer
a = if0(4, "tea", "beer") => beer
a = if0("", "tea", "beer") => tea
a = if0("abc", "tea", "beer") => beer
a = if0([], "tea", "beer") => tea
a = if0([1,2], "tea", "beer") => beer
a = if0(dict(), "tea", "beer") => tea
a = if0(dict("a",1), "tea", "beer") => beer
a = if0(false, "tea", "beer") => tea
a = if0(true, "tea", "beer") => beer
~~~~

You don't have to assign the result of an if0 function which is
useful when using a warn or return function for its side effects.
The if takes two arguments when there is no assignment.

~~~
c = 0
if0(c, warn("got zero value"))
~~~~

```nim
func funIf0_iaoaa(variables: Variables; parameters: seq[Value]): FunResult
```

# funIf_baoaa

If the condition is true, return the second argument, else return the third argument.

- The if functions are special in a couple of ways, see
[[#if-functions][If Functions]]
- You usually use boolean expressions for the condition, see:
[[#boolean-expressions][Boolean Expressions]]

~~~
if(condition: bool, then: any, optional else: any) any
~~~~

Examples:

~~~
a = if(true, "tea", "beer") => tea
b = if(false, "tea", "beer") => beer
c = if((d < 5), "tea", "beer") => beer
~~~~

You don't have to assign the result of an if function which is
useful when using a warn or return function for its side effects.
The if takes two arguments when there is no assignment.

~~~
if(c, warn("c is true"))
if(c, return("skip"))
~~~~

```nim
func funIf_baoaa(variables: Variables; parameters: seq[Value]): FunResult
```

# funAdd_iii

Add two integers. A warning is generated on overflow.

~~~
add(a: int, b: int)) int
~~~~

Examples:

~~~
add(1, 2) => 3
add(3, -2) => 1
add(-2, -5) => -7
~~~~

```nim
func funAdd_iii(variables: Variables; parameters: seq[Value]): FunResult
```

# funAdd_fff

Add two floats. A warning is generated on overflow.

~~~
add(a: float, b: float) float
~~~~

Examples:

~~~
add(1.5, 2.3) => 3.8
add(3.2, -2.2) => 1.0
~~~~

```nim
func funAdd_fff(variables: Variables; parameters: seq[Value]): FunResult
```

# funExists_dsb

Determine whether a key exists in a dictionary. Return true when it exists, else false.

~~~
exists(dictionary: dict, key: string) bool
~~~~

Examples:

~~~
d = dict("tea", "Earl")
exists(d, "tea") => true
exists(d, "coffee") => false
~~~~

```nim
func funExists_dsb(variables: Variables; parameters: seq[Value]): FunResult
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
func funCase_iloaa(variables: Variables; parameters: seq[Value]): FunResult
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
func funCase_sloaa(variables: Variables; parameters: seq[Value]): FunResult
```

# parseVersion

Parse a StaticTea version number and return its three components.

```nim
func parseVersion(version: string): Option[(int, int, int)]
```

# funCmpVersion_ssi

Compare two StaticTea version numbers. Returns -1 for less, 0 for
equal and 1 for greater than.

~~~
cmpVersion(versionA: string, versionB: string) int
~~~~

StaticTea uses [[https://semver.org/][Semantic Versioning]]
with the added restriction that each version component has one
to three digits (no letters).

Examples:

~~~
cmpVersion("1.2.5", "1.1.8") => 1
cmpVersion("1.2.5", "1.3.0") => -1
cmpVersion("1.2.5", "1.2.5") => 0
~~~~

```nim
func funCmpVersion_ssi(variables: Variables; parameters: seq[Value]): FunResult
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
func funFloat_if(variables: Variables; parameters: seq[Value]): FunResult
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
func funFloat_sf(variables: Variables; parameters: seq[Value]): FunResult
```

# funFloat_saa

Create a float from a number string. If the string is not a number, return the default.

~~~
float(numString: string, default: optional any) any
~~~~

Examples:

~~~
float("2") => 2.0
float("notnum", "nan") => nan
~~~~

```nim
func funFloat_saa(variables: Variables; parameters: seq[Value]): FunResult
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
func funInt_fosi(variables: Variables; parameters: seq[Value]): FunResult
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
func funInt_sosi(variables: Variables; parameters: seq[Value]): FunResult
```

# funInt_ssaa

Create an int from a number string. If the string is not a number, return the default value.

~~~
int(numString: string, roundOption: string, default: optional any) any
~~~~

Round options:

* "round" - nearest integer, the default
* "floor" - integer below (to the left on number line)
* "ceiling" - integer above (to the right on number line)
* "truncate" - remove decimals

Examples:

~~~
int("2", "round", "nan") => 2
int("notnum", "round", "nan") => nan
~~~~

```nim
func funInt_ssaa(variables: Variables; parameters: seq[Value]): FunResult
```

# if0Condition

Convert the value to a boolean.

```nim
func if0Condition(cond: Value): bool
```

# funBool_ab

Create an bool from a value.

~~~
bool(value: Value) bool
~~~~

False values by variable types:

* bool -- false
* int -- 0
* float -- 0.0
* string -- when the length of the string is 0
* list -- when the length of the list is 0
* dict -- when the length of the dictionary is 0
* func -- always false

Examples:

~~~
bool(0) => false
bool(0.0) => false
bool([]) => false
bool("") => false
bool(dict()) => false

bool(5) => true
bool(3.3) => true
bool([8]) => true
bool("tea") => true
bool(dict("tea", 2)) => true
~~~~

```nim
func funBool_ab(variables: Variables; parameters: seq[Value]): FunResult
```

# funFind_ssoaa

Find the position of a substring in a string.  When the substring
is not found, return an optional default value.  A warning is
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
func funFind_ssoaa(variables: Variables; parameters: seq[Value]): FunResult
```

# funSlice_siois

Extract a substring from a string by its position and length. You
pass the string, the substring's start index and its length.  The
length is optional. When not specified, the slice returns the
characters from the start to the end of the string.

The start index and length are by unicode characters not bytes.

~~~
slice(str: string, start: int, optional length: int) string
~~~~

Examples:

~~~
slice("Earl Grey", 1, 3) => "arl"
slice("Earl Grey", 6) => "rey"
slice("añyóng", 0, 3) => "añy"
~~~~

```nim
func funSlice_siois(variables: Variables; parameters: seq[Value]): FunResult
```

# funDup_sis

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
func funDup_sis(variables: Variables; parameters: seq[Value]): FunResult
```

# funDict_old

Create a dictionary from a list of key, value pairs.  The keys
must be strings and the values can be any type.

~~~
dict(pairs: optional list) dict
~~~~

Examples:

~~~
dict() => {}
dict(list("a", 5)) => {"a": 5}
dict(list("a", 5, "b", 33, "c", 0)) =>
  {"a": 5, "b": 33, "c": 0}
~~~~

```nim
func funDict_old(variables: Variables; parameters: seq[Value]): FunResult
```

# funList

Create a list of variables. You can also create a list with brackets.

~~~
list(...) list
~~~~

Examples:

~~~
a = list()
a = list(1)
a = list(1, 2, 3)
a = list("a", 5, "b")
a = []
a = [1]
a = [1, 2, 3]
a = ["a", 5, "b"]
~~~~

```nim
func funList(variables: Variables; parameters: seq[Value]): FunResult
```

# funReplace_siiss

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

Replace:
~~~
replace("Earl Grey", 5, 4, "of Sandwich")
  => "Earl of Sandwich"
replace("123", 0, 1, "abcd") => abcd23
replace("123", 0, 2, "abcd") => abcd3

replace("123", 1, 1, "abcd") => 1abcd3
replace("123", 1, 2, "abcd") => 1abcd

replace("123", 2, 1, "abcd") => 12abcd
~~~~
Insert:
~~~
replace("123", 0, 0, "abcd") => abcd123
replace("123", 1, 0, "abcd") => 1abcd23
replace("123", 2, 0, "abcd") => 12abcd3
replace("123", 3, 0, "abcd") => 123abcd
~~~~
Append:
~~~
replace("123", 3, 0, "abcd") => 123abcd
~~~~
Delete:
~~~
replace("123", 0, 1, "") => 23
replace("123", 0, 2, "") => 3
replace("123", 0, 3, "") => ""

replace("123", 1, 1, "") => 13
replace("123", 1, 2, "") => 1

replace("123", 2, 1, "") => 12
~~~~
Edge Cases:
~~~
replace("", 0, 0, "") =>
replace("", 0, 0, "a") => a
replace("", 0, 0, "ab") => ab
replace("", 0, 0, "abc") => abc
replace("", 0, 0, "abcd") => abcd
~~~~

```nim
func funReplace_siiss(variables: Variables; parameters: seq[Value]): FunResult
```

# funReplaceRe_sls

Replace multiple parts of a string using regular expressions.

You specify one or more pairs of regex patterns and their string
replacements.

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
func funReplaceRe_sls(variables: Variables; parameters: seq[Value]): FunResult
```

# PathComponents

PathComponents holds the components of the file path components.

```nim
PathComponents = object
  dir: string
  filename: string
  basename: string
  ext: string

```

# newPathComponents



```nim
func newPathComponents(dir, filename, basename, ext: string): PathComponents
```

# parsePath

Parse the given file path into its component pieces.

```nim
func parsePath(path: string; separator = '/'): PathComponents
```

# funPath_sosd

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
func funPath_sosd(variables: Variables; parameters: seq[Value]): FunResult
```

# funLower_ss

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
func funLower_ss(variables: Variables; parameters: seq[Value]): FunResult
```

# funKeys_dl

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
func funKeys_dl(variables: Variables; parameters: seq[Value]): FunResult
```

# funValues_dl

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
func funValues_dl(variables: Variables; parameters: seq[Value]): FunResult
```

# funSort_lsosl

Sort a list of values of the same type.  The values are ints,
floats, or strings.

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

strs = list("T", "e", "a")
sort(strs, "ascending") => ["T", "a", "e"]
sort(strs, "ascending", "sensitive") => ["T", "a", "e"]
sort(strs, "ascending", "insensitive") => ["a", "e", "T"]
~~~~

```nim
func funSort_lsosl(variables: Variables; parameters: seq[Value]): FunResult
```

# funSort_lssil

Sort a list of lists.

You specify the sort order, "ascending" or "descending".

You specify how to sort strings either case "sensitive" or
"insensitive".

You specify which index to compare by.  The compare index value
must exist in each list, be the same type and be an int, float,
or string.

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
func funSort_lssil(variables: Variables; parameters: seq[Value]): FunResult
```

# funSort_lsssl

Sort a list of dictionaries.

You specify the sort order, "ascending" or "descending".

You specify how to sort strings either case "sensitive" or
"insensitive".

You specify the compare key.  The key value must exist in
each dictionary, be the same type and be an int, float or
string.

~~~
sort(dicts: list, order: string, case: string, key: string) list
~~~~

Examples:

~~~
d1 = dict("name", "Earl Gray", "weight", 1.2)
d2 = dict("name", "Tea Pot", "weight", 3.5)
dicts = list(d1, d2)
sort(dicts, "ascending", "sensitive", "weight") => [d1, d2]
sort(dicts, "descending", "sensitive", "name") => [d2, d1]
~~~~

```nim
func funSort_lsssl(variables: Variables; parameters: seq[Value]): FunResult
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
* {type]{{entry.name}](#{anchor}) &mdash; {short}
...
# {entry.name}
~~~~

```nim
func funGithubAnchor_ss(variables: Variables; parameters: seq[Value]): FunResult
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
func funGithubAnchor_ll(variables: Variables; parameters: seq[Value]): FunResult
```

# funType_as

Return the parameter type, one of: int, float, string, list, dict, bool or func.

~~~
type(variable: any) string
~~~~

Examples:

~~~
type(2) => "int"
type(3.14159) => "float"
type("Tea") => "string"
type(list(1,2)) => "list"
type(dict("a", 1)) => "dict"
type(true) => "bool"
type(f.cmp) => "func"
~~~~

```nim
func funType_as(variables: Variables; parameters: seq[Value]): FunResult
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
joinPath(["images", "tea"]) =>
  "images/tea"

joinPath(["images", "tea"], "/") =>
  "images/tea"

joinPath(["images", "tea"], "\") =>
  "images\tea"

joinPath(["images/", "tea"]) =>
  "images/tea"

joinPath(["", "tea"]) =>
  "/tea"

joinPath(["/", "tea"]) =>
  "/tea"
~~~~

```nim
func funJoinPath_loss(variables: Variables; parameters: seq[Value]): FunResult
```

# funJoin_lsois

Join a list of strings with a separator.  An optional parameter determines whether you skip empty strings or not. You can use an empty separator to concatenate the arguments.

~~~
join(strs: list, sep: string, optional skipEmpty: bool) string
~~~~

Examples:

~~~
join(["a", "b"], ", ") => "a, b"
join(["a", "b"], "") => "ab"
join(["a", "b", "c"], "") => "abc"
join(["a"], ", ") => "a"
join([""], ", ") => ""
join(["a", "b"], "") => "ab"
join(["a", "", "c"], "|") => "a||c"
join(["a", "", "c"], "|", true) => "a|c"
~~~~

```nim
func funJoin_lsois(variables: Variables; parameters: seq[Value]): FunResult
```

# funWarn_ss

Return a warning message and skip the current statement. You can call the warn function without an assignment.

~~~
warn(message: string) string
~~~~

You can warn conditionally in a bare if statement:

~~~
if0(c, warn("message is 0"))
~~~~

You can warn conditionally in a normal if statement. In the
following example, if warn is called the b variable will not
get created.

~~~
b = if0(c, warn("c is not 0"), "")
~~~~

You can warn unconditionally using a bare warn statement:

~~~
warn("always warn")
~~~~

```nim
func funWarn_ss(variables: Variables; parameters: seq[Value]): FunResult
```

# funReturn_ss

Return the given value and control command looping. A return in a
statement causes the command to stop processing the current
statement and following statements in the command. You can
control whether the replacement block is output or not.

* "stop" -- stop processing the command
* "skip" -- skip this replacement block and continue with the next
* "" -- output the replacement block and continue

~~~
return(value: string) string
~~~~

Examples:

~~~
if(c, return("stop"))
if(c, return("skip"))
if(c, return(""))
~~~~

```nim
func funReturn_ss(variables: Variables; parameters: seq[Value]): FunResult
```

# funString_aoss

Convert a variable to a string. You specify the variable and optionally the type of output you want.

~~~
string(var: any, optional stype: string) string
~~~~

The default stype is "rb" which is used for replacement blocks.

stype:

* json -- returns JSON
* rb -- returns JSON except strings are not quoted and @ characters are not excaped. Rb stands for replacement block.
* dn -- returns JSON except dictionary elements are @ printed one per line as "key = value". Dn stands for dot name.

Examples variables:

~~~
str = "Earl Grey"
pi = 3.14159
one = 1
a = [1, 2, 3]
d = dict(["x", 1, "y", 2])
fn = cmp[[0]
found = true
~~~~

json:

~~~
str => "Earl Grey"
pi => 3.14159
one => 1
a => [1,2,3]
d => {"x":1,"y":2}
fn => "cmp"
found => true
~~~~

rb:

Same as JSON except the following.

~~~
str => Earl Grey
fn => cmp
~~~~

dn:

Same as JSON except the following.

~~~
d =>
x = 1
y = 2
~~~~

```nim
func funString_aoss(variables: Variables; parameters: seq[Value]): FunResult
```

# funString_sds

Convert the dictionary variable to dot names. You specify the name of the dictionary and the dict variable.

~~~
string(dictName: string: d: dict) string
~~~~

Example:

~~~
d = {"x",1, "y":"tea", "z":{"a":8}}
string("teas", d) =>

teas.x = 1
teas.y = "tea"
teas.z.a = 8
~~~~

```nim
func funString_sds(variables: Variables; parameters: seq[Value]): FunResult
```

# funFormat_ss

Format a string using replacement variables similar to a replacement block. To enter a left bracket use two in a row.

~~~
format(str: string) string
~~~~

Example:

~~~
let first = "Earl"
let last = "Grey"
str = format("name: {first} {last}")

str => "name: Earl Grey"
~~~~

To enter a left bracket use two in a row.

~~~
str = format("use two {{ to get one")

str => "use two { to get one"
~~~~

```nim
func funFormat_ss(variables: Variables; parameters: seq[Value]): FunResult
```

# funStartsWith_ssb

Check whether a strings starts with the given prefix. Return true when it does, else false.

~~~
startsWith(str: string, str: prefix) bool
~~~~

Examples:

~~~
a = startsWith("abcdef", "abc")
b = startsWith("abcdef", "abf")

a => true
b => false
~~~~

```nim
func funStartsWith_ssb(variables: Variables; parameters: seq[Value]): FunResult
```

# funNot_bb

Boolean not.

~~~
not(value: bool) bool
~~~~

Examples:

~~~
not(true) => false
not(false) => true
~~~~

```nim
func funNot_bb(variables: Variables; parameters: seq[Value]): FunResult
```

# funAnd_bbb

Boolean AND with short circuit. If the first argument is false, the second argument is not evaluated.

~~~
and(a: bool, b: bool) bool
~~~~

Examples:

~~~
and(true, true) => true
and(false, true) => false
and(true, false) => false
and(false, false) => false
and(false, warn("not hit")) => false
~~~~

```nim
func funAnd_bbb(variables: Variables; parameters: seq[Value]): FunResult
```

# funOr_bbb

Boolean OR with short circuit. If the first argument is true, the second argument is not evaluated.

~~~
or(a: bool, b: bool) bool
~~~~

Examples:

~~~
or(true, true) => true
or(false, true) => true
or(true, false) => true
or(false, false) => false
or(true, warn("not hit")) => true
~~~~

```nim
func funOr_bbb(variables: Variables; parameters: seq[Value]): FunResult
```

# funEq_iib

Return true when the two ints are equal.

~~~
eq(a: int, b: int) bool
~~~~

Examples:

~~~
eq(1, 1) => true
eq(2, 3) => false
~~~~

```nim
func funEq_iib(variables: Variables; parameters: seq[Value]): FunResult
```

# funEq_ffb

Return true when two floats are equal.

~~~
eq(a: float, b: float) bool
~~~~

Examples:

~~~
eq(1.2, 1.2) => true
eq(1.2, 3.2) => false
~~~~

```nim
func funEq_ffb(variables: Variables; parameters: seq[Value]): FunResult
```

# funEq_ssb

Return true when two strings are equal.  See [[#cmd][cmd]] for case insensitive compare.

~~~
eq(a: string, b: string) bool
~~~~

Examples:

~~~
eq("tea", "tea") => true
eq("1.2", "3.2") => false
~~~~

```nim
func funEq_ssb(variables: Variables; parameters: seq[Value]): FunResult
```

# funNe_iib

Return true when two ints are not equal.

~~~
ne(a: int, b: int) bool
~~~~

Examples:

~~~
ne(1, 1) => false
ne(2, 3) => true
~~~~

```nim
func funNe_iib(variables: Variables; parameters: seq[Value]): FunResult
```

# funNe_ffb

Return true when two floats are not equal.

~~~
ne(a: float, b: float) bool
~~~~

Examples:

~~~
ne(1.2, 1.2) => false
ne(1.2, 3.2) => true
~~~~

```nim
func funNe_ffb(variables: Variables; parameters: seq[Value]): FunResult
```

# funNe_ssb

Return true when two strings are not equal.

~~~
ne(a: string, b: string) bool
~~~~

Examples:

~~~
ne("tea", "tea") => false
ne("earl", "grey") => true
~~~~

```nim
func funNe_ssb(variables: Variables; parameters: seq[Value]): FunResult
```

# funGt_iib

Return true when an int is greater then another int.

~~~
gt(a: int, b: int) bool
~~~~

Examples:

~~~
gt(2, 4) => false
gt(3, 2) => true
~~~~

```nim
func funGt_iib(variables: Variables; parameters: seq[Value]): FunResult
```

# funGt_ffb

Return true when one float is greater than another float.

~~~
gt(a: float, b: float) bool
~~~~

Examples:

~~~
gt(2.8, 4.3) => false
gt(3.1, 2.5) => true
~~~~

```nim
func funGt_ffb(variables: Variables; parameters: seq[Value]): FunResult
```

# funGte_iib

Return true when an int is greater then or equal to another int.

~~~
gte(a: int, b: int) bool
~~~~

Examples:

~~~
gte(2, 4) => false
gte(3, 3) => true
~~~~

```nim
func funGte_iib(variables: Variables; parameters: seq[Value]): FunResult
```

# funGte_ffb

Return true when a float is greater than or equal to another float.

~~~
gte(a: float, b: float) bool
~~~~

Examples:

~~~
gte(2.8, 4.3) => false
gte(3.1, 3.1) => true
~~~~

```nim
func funGte_ffb(variables: Variables; parameters: seq[Value]): FunResult
```

# funLt_iib

Return true when an int is less than another int.

~~~
lt(a: int, b: int) bool
~~~~

Examples:

~~~
gt(2, 4) => true
gt(3, 2) => false
~~~~

```nim
func funLt_iib(variables: Variables; parameters: seq[Value]): FunResult
```

# funLt_ffb

Return true when a float is less then another float.

~~~
lt(a: float, b: float) bool
~~~~

Examples:

~~~
lt(2.8, 4.3) => true
lt(3.1, 2.5) => false
~~~~

```nim
func funLt_ffb(variables: Variables; parameters: seq[Value]): FunResult
```

# funLte_iib

Return true when an int is less than or equal to another int.

~~~
lte(a: int, b: int) bool
~~~~

Examples:

~~~
lte(2, 4) => true
lte(3, 3) => true
lte(4, 3) => false
~~~~

```nim
func funLte_iib(variables: Variables; parameters: seq[Value]): FunResult
```

# funLte_ffb

Return true when a float is less than or equal to another float.

~~~
lte(a: float, b: float) bool
~~~~

Examples:

~~~
lte(2.3, 4.4) => true
lte(3.0, 3.0) => true
lte(4.0, 3.0) => false
~~~~

```nim
func funLte_ffb(variables: Variables; parameters: seq[Value]): FunResult
```

# funReadJson_sa

Convert a JSON string to a variable.

~~~
readJson(json: string) any
~~~~

Examples:

~~~
a = readJson(""tea"") => "tea"
b = readJson("4.5") => 4.5
c = readJson("[1,2,3]") => [1, 2, 3]
d = readJson("{"a":1, "b": 2}")
  => {"a": 1, "b", 2}
~~~~

```nim
func funReadJson_sa(variables: Variables; parameters: seq[Value]): FunResult
```

# functionsList

Sorted list of built in functions, their function name, nim name and their signature.

```nim
functionsList = [("add", funAdd_fff, "fff"), ("add", funAdd_iii, "iii"),
                 ("and", funAnd_bbb, "bbb"), ("bool", funBool_ab, "ab"),
                 ("case", funCase_iloaa, "iloaa"),
                 ("case", funCase_sloaa, "sloaa"), ("cmp", funCmp_ffi, "ffi"),
                 ("cmp", funCmp_iii, "iii"), ("cmp", funCmp_ssobi, "ssobi"),
                 ("cmpVersion", funCmpVersion_ssi, "ssi"),
                 ("concat", funConcat_sss, "sss"),
                 ("dict", funDict_old, "old"), ("dup", funDup_sis, "sis"),
                 ("eq", funEq_ffb, "ffb"), ("eq", funEq_iib, "iib"),
                 ("eq", funEq_ssb, "ssb"), ("exists", funExists_dsb, "dsb"),
                 ("find", funFind_ssoaa, "ssoaa"),
                 ("float", funFloat_if, "if"), ("float", funFloat_saa, "saa"),
                 ("float", funFloat_sf, "sf"), ("format", funFormat_ss, "ss"),
                 ("get", funGet_dsoaa, "dsoaa"),
                 ("get", funGet_lioaa, "lioaa"),
                 ("githubAnchor", funGithubAnchor_ll, "ll"),
                 ("githubAnchor", funGithubAnchor_ss, "ss"),
                 ("gt", funGt_ffb, "ffb"), ("gt", funGt_iib, "iib"),
                 ("gte", funGte_ffb, "ffb"), ("gte", funGte_iib, "iib"),
                 ("if", funIf_baoaa, "baoaa"), ("if0", funIf0_iaoaa, "iaoaa"),
                 ("int", funInt_fosi, "fosi"), ("int", funInt_sosi, "sosi"),
                 ("int", funInt_ssaa, "ssaa"),
                 ("join", funJoin_lsois, "lsois"),
                 ("joinPath", funJoinPath_loss, "loss"),
                 ("keys", funKeys_dl, "dl"), ("len", funLen_di, "di"),
                 ("len", funLen_li, "li"), ("len", funLen_si, "si"),
                 ("list", funList, "..."), ("lower", funLower_ss, "ss"),
                 ("lt", funLt_ffb, "ffb"), ("lt", funLt_iib, "iib"),
                 ("lte", funLte_ffb, "ffb"), ("lte", funLte_iib, "iib"),
                 ("ne", funNe_ffb, "ffb"), ("ne", funNe_iib, "iib"),
                 ("ne", funNe_ssb, "ssb"), ("not", funNot_bb, "bb"),
                 ("or", funOr_bbb, "bbb"), ("path", funPath_sosd, "sosd"),
                 ("readJson", funReadJson_sa, "sa"),
                 ("replace", funReplace_siiss, "siiss"),
                 ("replaceRe", funReplaceRe_sls, "sls"),
                 ("return", funReturn_ss, "ss"),
                 ("slice", funSlice_siois, "siois"),
                 ("sort", funSort_lsosl, "lsosl"),
                 ("sort", funSort_lssil, "lssil"),
                 ("sort", funSort_lsssl, "lsssl"),
                 ("startsWith", funStartsWith_ssb, "ssb"),
                 ("string", funString_aoss, "aoss"),
                 ("string", funString_sds, "sds"), ("type", funType_as, "as"),
                 ("values", funValues_dl, "dl"), ("warn", funWarn_ss, "ss")]
```

# getBestFunction

Given a function variable or a list of function variables and a list of arguments, return the one that best matches the arguments.

```nim
proc getBestFunction(funcValue: Value; arguments: seq[Value]): ValueOr
```

# createFuncDictionary

Create the f dictionary from the built in functions.

```nim
proc createFuncDictionary(): Value
```


---
⦿ Markdown page generated by [StaticTea](https://github.com/flenniken/statictea/) from nim doc comments. ⦿
