# functions.nim

This module contains the StaticTea functions and supporting types. The StaticTea language functions start with "fun", for example, the "fun_cmp_ffi" function implements on of the StaticTea "cmp" functions.

* [functions.nim](../src/functions.nim) &mdash; Nim source code.
# Index

* type: [StringOr](#stringor) &mdash; StringOr holds a string or a warning.
* type: [PathComponents](#pathcomponents) &mdash; PathComponents holds the components of the file path components.
* [newStringOr](#newstringor) &mdash; Create a new StringOr object containing a warning.
* [newStringOr](#newstringor-1) &mdash; Create a new StringOr object containing a warning.
* [newStringOr](#newstringor-2) &mdash; Create a new StringOr object containing a string.
* [newPathComponents](#newpathcomponents) &mdash; Create a new PathComponents object from its pieces.
* [signatureDetails](#signaturedetails) &mdash; Convert the signature object to a dictionary value.
* [functionDetails](#functiondetails) &mdash; Convert the function spec to a dictionary value.
* [cmpBaseValues](#cmpbasevalues) &mdash; Compares two values a and b.
* [parseNumber](#parsenumber) &mdash; Return the literal number value and position after it.
* [formatString](#formatstring) &mdash; Format a string by filling in the variable placeholders with their values.
* [fun_cmp_iii](#fun_cmp_iii) &mdash; Compare two ints.
* [fun_cmp_ffi](#fun_cmp_ffi) &mdash; Compare two floats.
* [fun_cmp_ssobi](#fun_cmp_ssobi) &mdash; Compare two strings.
* [fun_concat_sss](#fun_concat_sss) &mdash; Concatenate two strings.
* [fun_len_si](#fun_len_si) &mdash; Number of unicode characters in a string.
* [fun_len_li](#fun_len_li) &mdash; Number of elements in a list.
* [fun_len_di](#fun_len_di) &mdash; Number of elements in a dictionary.
* [fun_get_lioaa](#fun_get_lioaa) &mdash; Get a list value by its index.
* [fun_get_dsoaa](#fun_get_dsoaa) &mdash; Get a dictionary value by its key.
* [fun_if0_iaoaa](#fun_if0_iaoaa) &mdash; If the condition is 0, return the second argument, else return the third argument.
* [fun_if_baoaa](#fun_if_baoaa) &mdash; If the condition is true, return the second argument, else return the third argument.
* [fun_add_iii](#fun_add_iii) &mdash; Add two integers.
* [fun_add_fff](#fun_add_fff) &mdash; Add two floats.
* [fun_sub_iii](#fun_sub_iii) &mdash; Subtract two integers.
* [fun_sub_fff](#fun_sub_fff) &mdash; Subtract two floats.
* [fun_exists_dsb](#fun_exists_dsb) &mdash; Determine whether a key exists in a dictionary.
* [fun_case_iloaa](#fun_case_iloaa) &mdash; Compare integer cases and return the matching value.
* [fun_case_sloaa](#fun_case_sloaa) &mdash; Compare string cases and return the matching value.
* [parseVersion](#parseversion) &mdash; Parse a StaticTea version number and return its three components.
* [fun_cmpVersion_ssi](#fun_cmpversion_ssi) &mdash; Compare two StaticTea version numbers.
* [fun_float_if](#fun_float_if) &mdash; Create a float from an int.
* [fun_float_sf](#fun_float_sf) &mdash; Create a float from a number string.
* [fun_float_saa](#fun_float_saa) &mdash; Create a float from a number string.
* [fun_int_fosi](#fun_int_fosi) &mdash; Create an int from a float.
* [fun_int_sosi](#fun_int_sosi) &mdash; Create an int from a number string.
* [fun_int_ssaa](#fun_int_ssaa) &mdash; Create an int from a number string.
* [if0Condition](#if0condition) &mdash; Convert the value to a boolean.
* [fun_bool_ab](#fun_bool_ab) &mdash; Create an bool from a value.
* [fun_find_ssoaa](#fun_find_ssoaa) &mdash; Find the position of a substring in a string.
* [fun_slice_siois](#fun_slice_siois) &mdash; Extract a substring from a string by its position and length.
* [fun_dup_sis](#fun_dup_sis) &mdash; Duplicate a string x times.
* [fun_dict_old](#fun_dict_old) &mdash; Create a dictionary from a list of key, value pairs.
* [fun_list_al](#fun_list_al) &mdash; Create a list of variables.
* [fun_listLoop_lapoab](#fun_listloop_lapoab) &mdash; Loop over items in a list and fill in a container.
* [fun_replace_siiss](#fun_replace_siiss) &mdash; Replace a substring specified by its position and length with another string.
* [fun_replaceRe_sls](#fun_replacere_sls) &mdash; Replace multiple parts of a string using regular expressions.
* [parsePath](#parsepath) &mdash; Parse the given file path into its component pieces.
* [fun_path_sosd](#fun_path_sosd) &mdash; Split a file path into its component pieces.
* [fun_lower_ss](#fun_lower_ss) &mdash; Lowercase a string.
* [fun_keys_dl](#fun_keys_dl) &mdash; Create a list from the keys in a dictionary.
* [fun_values_dl](#fun_values_dl) &mdash; Create a list out of the values in the specified dictionary.
* [fun_sort_lsosl](#fun_sort_lsosl) &mdash; Sort a list of values of the same type.
* [fun_sort_lssil](#fun_sort_lssil) &mdash; Sort a list of lists.
* [fun_sort_lsssl](#fun_sort_lsssl) &mdash; Sort a list of dictionaries.
* [fun_anchors_lsl](#fun_anchors_lsl) &mdash; Create anchor names from heading names.
* [fun_type_as](#fun_type_as) &mdash; Return the argument type, one of: int, float, string, list, dict, bool or func.
* [fun_joinPath_loss](#fun_joinpath_loss) &mdash; Join the path components with a path separator.
* [fun_join_lsois](#fun_join_lsois) &mdash; Join a list of strings with a separator.
* [fun_warn_ss](#fun_warn_ss) &mdash; Return a warning message and skip the current statement.
* [fun_log_ss](#fun_log_ss) &mdash; Log a message to the log file.
* [fun_return_aa](#fun_return_aa) &mdash; Return is a special function that returns the value passed in and has has side effects.
* [fun_string_aoss](#fun_string_aoss) &mdash; Convert a variable to a string.
* [fun_string_sds](#fun_string_sds) &mdash; Convert the dictionary variable to dot names.
* [fun_format_ss](#fun_format_ss) &mdash; Format a string using replacement variables similar to a replacement block.
* [fun_func_sp](#fun_func_sp) &mdash; Define a function.
* [fun_functionDetails_pd](#fun_functiondetails_pd) &mdash; Return the function details in a dictionary.
* [fun_startsWith_ssb](#fun_startswith_ssb) &mdash; Check whether a strings starts with the given prefix.
* [fun_not_bb](#fun_not_bb) &mdash; Boolean not.
* [fun_and_bbb](#fun_and_bbb) &mdash; Boolean AND with short circuit.
* [fun_or_bbb](#fun_or_bbb) &mdash; Boolean OR with short circuit.
* [fun_eq_iib](#fun_eq_iib) &mdash; Return true when the two ints are equal.
* [fun_eq_ffb](#fun_eq_ffb) &mdash; Return true when two floats are equal.
* [fun_eq_ssb](#fun_eq_ssb) &mdash; Return true when two strings are equal.
* [fun_ne_iib](#fun_ne_iib) &mdash; Return true when two ints are not equal.
* [fun_ne_ffb](#fun_ne_ffb) &mdash; Return true when two floats are not equal.
* [fun_ne_ssb](#fun_ne_ssb) &mdash; Return true when two strings are not equal.
* [fun_gt_iib](#fun_gt_iib) &mdash; Return true when an int is greater then another int.
* [fun_gt_ffb](#fun_gt_ffb) &mdash; Return true when one float is greater than another float.
* [fun_gte_iib](#fun_gte_iib) &mdash; Return true when an int is greater then or equal to another int.
* [fun_gte_ffb](#fun_gte_ffb) &mdash; Return true when a float is greater than or equal to another float.
* [fun_lt_iib](#fun_lt_iib) &mdash; Return true when an int is less than another int.
* [fun_lt_ffb](#fun_lt_ffb) &mdash; Return true when a float is less then another float.
* [fun_lte_iib](#fun_lte_iib) &mdash; Return true when an int is less than or equal to another int.
* [fun_lte_ffb](#fun_lte_ffb) &mdash; Return true when a float is less than or equal to another float.
* [fun_readJson_sa](#fun_readjson_sa) &mdash; Convert a JSON string to a variable.
* [fun_markdownLite_sl](#fun_markdownlite_sl) &mdash; Parse a simple subset of markdown which contains paragraphs, bullets and code blocks.
* [functionsDict](#functionsdict) &mdash; Maps a built-in function name to a function pointer you can call.
* type: [BuiltInInfo](#builtininfo) &mdash; The built-in function information.
* [newBuiltInInfo](#newbuiltininfo) &mdash; Return a BuiltInInfo object.
* [getBestFunction](#getbestfunction) &mdash; Given a function variable or a list of function variables and a list of arguments, return the one that best matches the arguments.
* [splitFuncName](#splitfuncname) &mdash; Split a funcName like "fun_cmp_ffi" to its name and signature like: "cmp" and "ffi".
* [makeFuncDictionary](#makefuncdictionary) &mdash; Create the f dictionary from the built in functions.
* [funcsVarDict](#funcsvardict) &mdash; The f dictionary of built-in functions.

# StringOr

StringOr holds a string or a warning.

```nim
StringOr = OpResultWarn[string]
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

# newStringOr

Create a new StringOr object containing a warning.

```nim
func newStringOr(warning: MessageId; p1: string = ""; pos = 0): StringOr 
```

# newStringOr

Create a new StringOr object containing a warning.

```nim
func newStringOr(warningData: WarningData): StringOr 
```

# newStringOr

Create a new StringOr object containing a string.

```nim
func newStringOr(str: string): StringOr 
```

# newPathComponents

Create a new PathComponents object from its pieces.

```nim
func newPathComponents(dir, filename, basename, ext: string): PathComponents 
```

# signatureDetails

Convert the signature object to a dictionary value.

```nim
func signatureDetails(signature: Signature): Value 
```

# functionDetails

Convert the function spec to a dictionary value.

```nim
func functionDetails(fs: FunctionSpec): Value 
```

# cmpBaseValues

Compares two values a and b.  When a equals b return 0, when a is greater than b return 1 and when a is less than b return -1. The values must be the same kind and either int, float or string.

```nim
func cmpBaseValues(a, b: Value; insensitive: bool = false): int 
```

# parseNumber

Return the literal number value and position after it.  The start index points at a digit or minus sign. The position includes the trailing whitespace.

```nim
func parseNumber(line: string; start: Natural): ValuePosSiOr 
```

# formatString

Format a string by filling in the variable placeholders with their values. Generate a warning when the variable doesn't exist. No space around the bracketed variables.

~~~
let first = "Earl"
let last = "Grey"
"name: {first} {last}" => "name: Earl Grey"
~~~

To enter a left bracket use two in a row.

~~~
"{{" => "{"
~~~

```nim
proc formatString(variables: Variables; text: string): StringOr {.
    raises: [KeyError, Exception], tags: [RootEffect].}
```

# fun_cmp_iii

Compare two ints. Returns -1 for less, 0 for equal and 1 for greater than.

~~~
cmp(a: int, b: int) int
~~~

Examples:

~~~
cmp(7, 9) => -1
cmp(8, 8) => 0
cmp(9, 2) => 1
~~~

```nim
func fun_cmp_iii(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_cmp_ffi

Compare two floats. Returns -1 for less, 0 for equal and 1 for greater than.

~~~
cmp(a: float, b: float) int
~~~

Examples:

~~~
cmp(7.8, 9.1) => -1
cmp(8.4, 8.4) => 0
cmp(9.3, 2.2) => 1
~~~

```nim
func fun_cmp_ffi(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_cmp_ssobi

Compare two strings. Returns -1 for less, 0 for equal and 1 for greater than.

You have the option to compare case insensitive. Case sensitive
is the default.

~~~
cmp(a: string, b: string, insensitive: optional bool) int
~~~

Examples:

~~~
cmp("coffee", "tea") => -1
cmp("tea", "tea") => 0
cmp("Tea", "tea") => 1
cmp("Tea", "tea", true) => 1
cmp("Tea", "tea", false) => 0
~~~

```nim
func fun_cmp_ssobi(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_concat_sss

Concatenate two strings. See the join function for more that two arguments.

~~~
concat(a: string, b: string) string
~~~

Examples:

~~~
concat("tea", " time") => "tea time"
concat("a", "b") => "ab"
~~~

```nim
func fun_concat_sss(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_len_si

Number of unicode characters in a string.

~~~
len(str: string) int
~~~

Examples:

~~~
len("tea") => 3
len("añyóng") => 6
~~~

```nim
func fun_len_si(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_len_li

Number of elements in a list.

~~~
len(list: list) int
~~~

Examples:

~~~
len(list()) => 0
len(list(1)) => 1
len(list(4, 5)) => 2
~~~

```nim
func fun_len_li(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_len_di

Number of elements in a dictionary.

~~~
len(dictionary: dict) int
~~~

Examples:

~~~
len(dict()) => 0
len(dict("a", 4)) => 1
len(dict("a", 4, "b", 3)) => 2
~~~

```nim
func fun_len_di(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_get_lioaa

Get a list value by its index.  If the index is invalid, the default value is returned when specified, else a warning is generated. You can use negative index values. Index -1 gets the last element. It is short hand for len - 1. Index -2 is len - 2, etc.

~~~
get(list: list, index: int, default: optional any) any
~~~

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
~~~

You can also use bracket notation to access list items.

~~~
a = teas[0]
~~~

```nim
func fun_get_lioaa(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_get_dsoaa

Get a dictionary value by its key.  If the key doesn't exist, the default value is returned if specified, else a warning is generated.

~~~
get(dictionary: dict, key: string, default: optional any) any
~~~

Note: For dictionary lookup you can use dot notation. It's the
same as get without the default.

Examples:

~~~
d = dict("tea", "Earl Grey")
get(d, "tea") => "Earl Grey"
get(d, "coffee", "Tea") => "Tea"
~~~

Using dot notation:
~~~
d = dict("tea", "Earl Grey")
d.tea => "Earl Grey"
~~~

```nim
func fun_get_dsoaa(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_if0_iaoaa

If the condition is 0, return the second argument, else return the third argument.  You can use any type for the condition.  The condition is 0 for strings, lists and dictionaries when their length is 0.

The condition types and what is considered 0:

* bool -- false
* int -- 0
* float -- 0.0
* string -- when the length of the string is 0
* list -- when the length of the list is 0
* dict -- when the length of the dictionary is 0
* func -- always 0

The IF functions are special in a couple of ways, see
the If Functions section.

~~~
if0(condition: any, then: any, else: optional any) any
~~~

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

a = if0(true, "tea")
a = if0(false, "tea")
~~~

You don't have to assign the result of an if0 function which is
useful when using a warn or return function for its side effects.
The if takes two arguments when there is no assignment.

~~~
if0(c, warn("got zero value"))
~~~

```nim
func fun_if0_iaoaa(variables: Variables; arguments: seq[Value]): FunResult 
```

# fun_if_baoaa

If the condition is true, return the second argument, else return the third argument.

The IF functions are special in a couple of ways, see
the If Functions section.  You usually use boolean infix
expressions for the condition, see:
the Boolean Expressions section.

~~~
if(condition: bool, then: any, else: optional any) any
~~~

Examples:

~~~
a = if(true, "tea", "beer") # => tea
b = if(false, "tea", "beer") # => beer
c = if((v < 5), "tea", "beer")
d = if((v < 5), "tea")
~~~

You don't have to assign the result of an if function which is
useful when using a warn or return function for its side effects.
The if takes two arguments when there is no assignment.

~~~
if(c, warn("c is true"))
if(c, return("skip"))
~~~

```nim
func fun_if_baoaa(variables: Variables; arguments: seq[Value]): FunResult 
```

# fun_add_iii

Add two integers. A warning is generated on overflow.

~~~
add(a: int, b: int) int
~~~

Examples:

~~~
add(1, 2) => 3
add(3, -2) => 1
add(-2, -5) => -7
~~~

```nim
func fun_add_iii(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_add_fff

Add two floats. A warning is generated on overflow.

~~~
add(a: float, b: float) float
~~~

Examples:

~~~
add(1.5, 2.3) => 3.8
add(3.2, -2.2) => 1.0
~~~

```nim
func fun_add_fff(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_sub_iii

Subtract two integers. A warning is generated on overflow.

~~~
sub(a: int, b: int) int
~~~

Examples:

~~~
sub(3, 1) => 2
add(3, -2) => 5
add(1, 5) => -4
~~~

```nim
func fun_sub_iii(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_sub_fff

Subtract two floats. A warning is generated on overflow.

~~~
sub(a: float, b: float) float
~~~

Examples:

~~~
sub(4.5, 2.3) => 2.2
sub(1.0, 2.2) => -1.2
~~~

```nim
func fun_sub_fff(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_exists_dsb

Determine whether a key exists in a dictionary. Return true when it exists, else false.

~~~
exists(dictionary: dict, key: string) bool
~~~

Examples:

~~~
d = dict("tea", "Earl")
exists(d, "tea") => true
exists(d, "coffee") => false
~~~

```nim
func fun_exists_dsb(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_case_iloaa

Compare integer cases and return the matching value.  It takes a main integer condition, a list of case pairs and an optional value when none of the cases match.

The first element of a case pair is the condition and the
second is the return value when that condition matches the main
condition. The function compares the conditions left to right and
returns the first match.

When none of the cases match the main condition, the default
value is returned if it is specified, otherwise a warning is
generated.  The conditions must be integers. The return values
can be any type.

~~~
case(condition: int, pairs: list, default: optional any) any
~~~

Examples:

~~~
cases = list(0, "tea", 1, "water", 2, "beer")
case(0, cases) => "tea"
case(1, cases) => "water"
case(2, cases) => "beer"
case(2, cases, "wine") => "beer"
case(3, cases, "wine") => "wine"
~~~

```nim
func fun_case_iloaa(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_case_sloaa

Compare string cases and return the matching value.  It takes a main string condition, a list of case pairs and an optional value when none of the cases match.

The first element of a case pair is the condition and the
second is the return value when that condition matches the main
condition. The function compares the conditions left to right and
returns the first match.

When none of the cases match the main condition, the default
value is returned if it is specified, otherwise a warning is
generated.  The conditions must be strings. The return values
can be any type.

~~~
case(condition: string, pairs: list, default: optional any) any
~~~

Examples:

~~~
cases = list("tea", 15, "water", 2.3, "beer", "cold")
case("tea", cases) => 15
case("water", cases) => 2.3
case("beer", cases) => "cold"
case("bunch", cases, "other") => "other"
~~~

```nim
func fun_case_sloaa(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# parseVersion

Parse a StaticTea version number and return its three components.

```nim
func parseVersion(version: string): Option[(int, int, int)] 
```

# fun_cmpVersion_ssi

Compare two StaticTea version numbers. Returns -1 for less, 0 for equal and 1 for greater than.

~~~
cmpVersion(versionA: string, versionB: string) int
~~~

StaticTea uses [[https://semver.org/][Semantic Versioning]]
with the added restriction that each version component has one
to three digits (no letters).

Examples:

~~~
cmpVersion("1.2.5", "1.1.8") => 1
cmpVersion("1.2.5", "1.3.0") => -1
cmpVersion("1.2.5", "1.2.5") => 0
~~~

```nim
func fun_cmpVersion_ssi(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_float_if

Create a float from an int.

~~~
float(num: int) float
~~~

Examples:

~~~
float(2) => 2.0
float(-33) => -33.0
~~~

```nim
func fun_float_if(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_float_sf

Create a float from a number string.

~~~
float(numString: string) float
~~~

Examples:

~~~
float("2") => 2.0
float("2.4") => 2.4
float("33") => 33.0
~~~

```nim
func fun_float_sf(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_float_saa

Create a float from a number string. If the string is not a number, return the default.

~~~
float(numString: string, default: optional any) any
~~~

Examples:

~~~
float("2") => 2.0
float("notnum", "nan") => nan
~~~

```nim
func fun_float_saa(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_int_fosi

Create an int from a float.

~~~
int(num: float, roundOption: optional string) int
~~~

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
~~~

```nim
func fun_int_fosi(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_int_sosi

Create an int from a number string.

~~~
int(numString: string, roundOption: optional string) int
~~~

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
~~~

```nim
func fun_int_sosi(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_int_ssaa

Create an int from a number string. If the string is not a number, return the default value.

~~~
int(numString: string, roundOption: string, default: optional any) any
~~~

Round options:

* "round" - nearest integer, the default
* "floor" - integer below (to the left on number line)
* "ceiling" - integer above (to the right on number line)
* "truncate" - remove decimals

Examples:

~~~
int("2", "round", "nan") => 2
int("notnum", "round", "nan") => nan
~~~

```nim
func fun_int_ssaa(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# if0Condition

Convert the value to a boolean.

```nim
func if0Condition(cond: Value): bool 
```

# fun_bool_ab

Create an bool from a value.

~~~
bool(value: Value) bool
~~~

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
~~~

```nim
func fun_bool_ab(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_find_ssoaa

Find the position of a substring in a string.  When the substring is not found, return an optional default value.  A warning is generated when the substring is missing and you don't specify a default value.

~~~
find(str: string, substring: string, default: optional any) any
~~~

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
~~~

```nim
func fun_find_ssoaa(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_slice_siois

Extract a substring from a string by its position and length. You pass the string, the substring's start index and its length.  The length is optional. When not specified, the slice returns the characters from the start to the end of the string.

The start index and length are by unicode characters not bytes.

~~~
slice(str: string, start: int, length: optional int) string
~~~

Examples:

~~~
slice("Earl Grey", 1, 3) => "arl"
slice("Earl Grey", 6) => "rey"
slice("añyóng", 0, 3) => "añy"
~~~

```nim
func fun_slice_siois(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_dup_sis

Duplicate a string x times.  The result is a new string built by concatenating the string to itself the specified number of times.

~~~
dup(pattern: string, count: int) string
~~~

Examples:

~~~
dup("=", 3) => "==="
dup("abc", 0) => ""
dup("abc", 1) => "abc"
dup("abc", 2) => "abcabc"
dup("", 3) => ""
~~~

```nim
func fun_dup_sis(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_dict_old

Create a dictionary from a list of key, value pairs.  The keys must be strings and the values can be any type.

~~~
dict(pairs: optional list) dict
~~~

Examples:

~~~
dict() => {}
dict(["a", 5]) => {"a": 5}
dict(["a", 5, "b", 33, "c", 0]) =>
  {"a": 5, "b": 33, "c": 0}
~~~

```nim
func fun_dict_old(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_list_al

Create a list of variables. You can also create a list with brackets.

~~~
list(...) list
~~~

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
~~~

```nim
func fun_list_al(variables: Variables; arguments: seq[Value]): FunResult 
```

# fun_listLoop_lapoab

Loop over items in a list and fill in a container. A callback function is called for each item in the list and it decides what goes in the container.

You pass a list to loop over, a container to fill in, a
callback function, and an optional state variable. The function
returns whether the callback stopped early or not and you can
ignore it using a bare form..

~~~
listLoop(a: list, container: any, listCallback: func, state: optional any) bool
~~~

The callback gets passed the index to the item, its value, the
container and the state variable.  The callback looks at the
information and adds to the container when appropriate. The
callback returns true to stop iterating.

~~~
listCallback(ix: int, item: any, container: any, state: optional any) bool
~~~

The following example makes a new list [6, 8] from the list
[2,4,6,8].  The callback is called b5.

~~~
o.container = []
list = [2,4,6,8]
listLoop(list, o.container, b5)
# o.container => [6, 8]
~~~

Below is the definition of the b5 callback function.

~~~
b5 = func(ix: int, value: int, container: list) bool
  ## Collect values greater than 5.
  container &= if( (value > 5), value)
  return(false)
~~~

```nim
func fun_listLoop_lapoab(variables: Variables; arguments: seq[Value]): FunResult 
```

# fun_replace_siiss

Replace a substring specified by its position and length with another string.  You can use the function to insert and append to a string as well.

~~~
replace(str: string, start: int, length: int, replacement: string) string
~~~

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
~~~
Insert:
~~~
replace("123", 0, 0, "abcd") => abcd123
replace("123", 1, 0, "abcd") => 1abcd23
replace("123", 2, 0, "abcd") => 12abcd3
replace("123", 3, 0, "abcd") => 123abcd
~~~
Append:
~~~
replace("123", 3, 0, "abcd") => 123abcd
~~~
Delete:
~~~
replace("123", 0, 1, "") => 23
replace("123", 0, 2, "") => 3
replace("123", 0, 3, "") => ""

replace("123", 1, 1, "") => 13
replace("123", 1, 2, "") => 1

replace("123", 2, 1, "") => 12
~~~
Edge Cases:
~~~
replace("", 0, 0, "") =>
replace("", 0, 0, "a") => a
replace("", 0, 0, "ab") => ab
replace("", 0, 0, "abc") => abc
replace("", 0, 0, "abcd") => abcd
~~~

```nim
func fun_replace_siiss(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_replaceRe_sls

Replace multiple parts of a string using regular expressions.

You specify one or more pairs of regex patterns and their string
replacements.

~~~
replaceRe(str: string, pairs: list) string
~~~

Examples:

~~~
list = list("abc", "456", "def", "")
replaceRe("abcdefabc", list))
  => "456456"
~~~

For developing and debugging regular expressions see the
website: https://regex101.com/

```nim
func fun_replaceRe_sls(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# parsePath

Parse the given file path into its component pieces.

```nim
func parsePath(path: string; separator = '/'): PathComponents 
```

# fun_path_sosd

Split a file path into its component pieces. Return a dictionary with the filename, basename, extension and directory.

You pass a path string and the optional path separator, forward
slash or or backslash. When no separator, the current
system separator is used.

~~~
path(filename: string, separator: optional string) dict
~~~

Examples:

~~~
path("src/functions.nim") => {
  "filename": "functions.nim",
  "basename": "functions",
  "ext": ".nim",
  "dir": "src/",
}

path("src\functions.nim", "\") => {
  "filename": "functions.nim",
  "basename": "functions",
  "ext": ".nim",
  "dir": "src\",
}
~~~

```nim
func fun_path_sosd(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_lower_ss

Lowercase a string.

~~~
lower(str: string) string
~~~

Examples:

~~~
lower("Tea") => "tea"
lower("TEA") => "tea"
lower("TEĀ") => "teā"
~~~

```nim
func fun_lower_ss(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_keys_dl

Create a list from the keys in a dictionary.

~~~
keys(dictionary: dict) list
~~~

Examples:

~~~
d = dict("a", 1, "b", 2, "c", 3)
keys(d) => ["a", "b", "c"]
values(d) => [1, 2, 3]
~~~

```nim
func fun_keys_dl(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_values_dl

Create a list out of the values in the specified dictionary.

~~~
values(dictionary: dict) list
~~~

Examples:

~~~
d = dict("a", "apple", "b", 2, "c", 3)
keys(d) => ["a", "b", "c"]
values(d) => ["apple", 2, 3]
~~~

```nim
func fun_values_dl(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_sort_lsosl

Sort a list of values of the same type.  The values are ints, floats, or strings.

You specify the sort order, "ascending" or "descending".

You have the option of sorting strings case "insensitive". Case
"sensitive" is the default.

~~~
sort(values: list, order: string, insensitive: optional string) list
~~~

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
~~~

```nim
func fun_sort_lsosl(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_sort_lssil

Sort a list of lists.

You specify the sort order, "ascending" or "descending".

You specify how to sort strings either case "sensitive" or
"insensitive".

You specify which index to compare by.  The compare index value
must exist in each list, be the same type and be an int, float,
or string.

~~~
sort(lists: list, order: string, case: string, index: int) list
~~~

Examples:

~~~
l1 = list(4, 3, 1)
l2 = list(2, 3, 4)
listOfLists = list(l1, l2)
sort(listOfLists, "ascending", "sensitive", 0) => [l2, l1]
sort(listOfLists, "ascending", "sensitive", 2) => [l1, l2]
~~~

```nim
func fun_sort_lssil(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_sort_lsssl

Sort a list of dictionaries.

You specify the sort order, "ascending" or "descending".

You specify how to sort strings either case "sensitive" or
"insensitive".

You specify the compare key.  The key value must exist in
each dictionary, be the same type and be an int, float or
string.

~~~
sort(dicts: list, order: string, case: string, key: string) list
~~~

Examples:

~~~
d1 = dict("name", "Earl Gray", "weight", 1.2)
d2 = dict("name", "Tea Pot", "weight", 3.5)
dicts = list(d1, d2)
sort(dicts, "ascending", "sensitive", "weight") => [d1, d2]
sort(dicts, "descending", "sensitive", "name") => [d2, d1]
~~~

```nim
func fun_sort_lsssl(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_anchors_lsl

Create anchor names from heading names. Use it for HTML class names or Github markdown internal links. It handles duplicate heading names.

~~~
anchors(names: list, type: string) list
~~~

type:

* html -- HTML class names
* github -- GitHub markdown anchor links

Examples:

~~~
list = list("Tea", "Water", "Tea")
anchores(list, "github") =>
  ["tea", "water", "tea-1"]
~~~

```nim
func fun_anchors_lsl(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError, ValueError, Exception], tags: [RootEffect].}
```

# fun_type_as

Return the argument type, one of: int, float, string, list, dict, bool or func.

~~~
type(variable: any) string
~~~

Examples:

~~~
type(2) => "int"
type(3.14159) => "float"
type("Tea") => "string"
type(list(1,2)) => "list"
type(dict("a", 1)) => "dict"
type(true) => "bool"
type(f.cmp[0]) => "func"
~~~

```nim
func fun_type_as(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_joinPath_loss

Join the path components with a path separator.

You pass a list of components to join. For the second optional
parameter you specify the separator to use, either "/", "" or
"". If you specify "" or leave off the parameter, the current
platform separator is used.

If the separator already exists between components, a new one
is not added. If a component is "", the platform separator is
used for it.

~~~
joinPath(components: list, separator: optional string) string
~~~

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
~~~

```nim
func fun_joinPath_loss(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_join_lsois

Join a list of strings with a separator.  An optional parameter determines whether you skip empty strings or not. You can use an empty separator to concatenate the arguments.

~~~
join(strs: list, sep: string, skipEmpty: optional bool) string
~~~

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
~~~

```nim
func fun_join_lsois(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_warn_ss

Return a warning message and skip the current statement. You can call the warn function without an assignment.

~~~
warn(message: string) string
~~~

You can warn conditionally in a bare if statement:

~~~
if0(c, warn("message is 0"))
~~~

You can warn unconditionally using a bare warn statement:

~~~
warn("always warn")
~~~

```nim
func fun_warn_ss(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_log_ss

Log a message to the log file.  You can call the log function without an assignment.

~~~
log(message: string) string
~~~

You can log conditionally in a bare if statement:

~~~
if0(c, log("log this message when c is 0"))
~~~

You can log unconditionally using a bare log statement:

~~~
log("always log")
~~~

```nim
func fun_log_ss(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_return_aa

Return is a special function that returns the value passed in and has has side effects.

In a function, the return completes the function and returns
the value of it.

~~~
return(false)
~~~

You can also use it with a bare IF statement to conditionally
return a function value.

~~~
if(c, return(5))
~~~

In a template command a return controls the replacement block
looping by returning “skip” and “stop”.

~~~
if(c, return("stop"))
if(c, return("skip"))
~~~

* “stop” – stops processing the command
* “skip” – skips this replacement block and continues with the next iteration

The following block command repeats 4 times but skips when t.row is 2.

~~~
$$ block t.repeat = 4
$$ : if((t.row == 2), return(“skip”))
{t.row}
$$ endblock

output:

0
1
3
~~~

```nim
func fun_return_aa(variables: Variables; arguments: seq[Value]): FunResult 
```

# fun_string_aoss

Convert a variable to a string. You specify the variable and optionally the type of output you want.

~~~
string(var: any, stype: optional string) string
~~~

The default stype is "rb" which is used for replacement blocks.

stype:

* json -- returns JSON
* rb — replacement block (rb) returns JSON except strings are
not quoted and special characters are not escaped.
* dn -- dot name (dn) returns JSON except dictionary elements
are printed one per line as "key = value". See string(dotName, string).

Examples variables:

~~~
str = "Earl Grey"
pi = 3.14159
one = 1
a = [1, 2, 3]
d = dict(["x", 1, "y", 2])
fn = cmp[0]
found = true
~~~

json:

~~~
str => "Earl Grey"
pi => 3.14159
one => 1
a => [1,2,3]
d => {"x":1,"y":2}
fn => "cmp"
found => true
~~~

rb:

Same as JSON except the following.

~~~
str => Earl Grey
fn => cmp
~~~

dn:

Same as JSON except the following.

~~~
d =>
x = 1
y = 2
~~~

```nim
func fun_string_aoss(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError, Exception, ValueError], tags: [RootEffect].}
```

# fun_string_sds

Convert the dictionary variable to dot names. You specify the name of the dictionary and the dict variable.

~~~
string(dictName: string: d: dict) string
~~~

Example:

~~~
d = {"x",1, "y":"tea", "z":{"a":8}}
string("teas", d) =>

teas.x = 1
teas.y = "tea"
teas.z.a = 8
~~~

```nim
func fun_string_sds(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError, ValueError, Exception], tags: [RootEffect].}
```

# fun_format_ss

Format a string using replacement variables similar to a replacement block. To enter a left bracket use two in a row.

~~~
format(str: string) string
~~~

Example:

~~~
let first = "Earl"
let last = "Grey"
str = format("name: {first} {last}")

str => "name: Earl Grey"
~~~

To enter a left bracket use two in a row.

~~~
str = format("use two {{ to get one")

str => "use two { to get one"
~~~

```nim
func fun_format_ss(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError, Exception], tags: [RootEffect].}
```

# fun_func_sp

Define a function.

~~~
func(signature: string) func
~~~

Example:

~~~
mycmp = func(numStr1: string, numStr2: string) int
  ## Compare two number strings
  ## and return 1, 0, or -1.
  num1 = int(numStr1)
  num2 = int(numStr2)
  return(cmp(num1, num2))
~~~

```nim
func fun_func_sp(variables: Variables; arguments: seq[Value]): FunResult 
```

# fun_functionDetails_pd

Return the function details in a dictionary.

~~~
functionDetails(funcVar: func) dict
~~~

The following example defines a simple function then gets its
function details.

~~~
mycmp = func(numStr1: string, numStr2: string) int
  ## Compare two number strings and return 1, 0, or -1.
  return(cmp(int(numStr1), int(numStr2)))

fd = functionDetails(mycmp)

fd =>
fd.builtIn = false
fd.signature.optional = false
fd.signature.name = "strNumCmp"
fd.signature.paramNames = ["numStr1","numStr2"]
fd.signature.paramTypes = ["string","string"]
fd.signature.returnType = "int"
fd.docComment = "  ## Compare two number strings and return 1, 0, or -1.\n"
fd.filename = "testcode.tea"
fd.lineNum = 3
fd.numLines = 2
fd.statements = ["  return(cmp(int(numStr1), int(numStr2)))"]
~~~

```nim
func fun_functionDetails_pd(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_startsWith_ssb

Check whether a strings starts with the given prefix. Return true when it does, else false.

~~~
startsWith(str: string, str: prefix) bool
~~~

Examples:

~~~
a = startsWith("abcdef", "abc")
b = startsWith("abcdef", "abf")

a => true
b => false
~~~

```nim
func fun_startsWith_ssb(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_not_bb

Boolean not.

~~~
not(value: bool) bool
~~~

Examples:

~~~
not(true) => false
not(false) => true
~~~

```nim
func fun_not_bb(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_and_bbb

Boolean AND with short circuit. If the first argument is false, the second argument is not evaluated.

~~~
and(a: bool, b: bool) bool
~~~

Examples:

~~~
and(true, true) => true
and(false, true) => false
and(true, false) => false
and(false, false) => false
and(false, warn("not hit")) => false
~~~

```nim
func fun_and_bbb(variables: Variables; arguments: seq[Value]): FunResult 
```

# fun_or_bbb

Boolean OR with short circuit. If the first argument is true, the second argument is not evaluated.

~~~
or(a: bool, b: bool) bool
~~~

Examples:

~~~
or(true, true) => true
or(false, true) => true
or(true, false) => true
or(false, false) => false
or(true, warn("not hit")) => true
~~~

```nim
func fun_or_bbb(variables: Variables; arguments: seq[Value]): FunResult 
```

# fun_eq_iib

Return true when the two ints are equal.

~~~
eq(a: int, b: int) bool
~~~

Examples:

~~~
eq(1, 1) => true
eq(2, 3) => false
~~~

```nim
func fun_eq_iib(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_eq_ffb

Return true when two floats are equal.

~~~
eq(a: float, b: float) bool
~~~

Examples:

~~~
eq(1.2, 1.2) => true
eq(1.2, 3.2) => false
~~~

```nim
func fun_eq_ffb(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_eq_ssb

Return true when two strings are equal.  See cmp function for case insensitive compare.

~~~
eq(a: string, b: string) bool
~~~

Examples:

~~~
eq("tea", "tea") => true
eq("1.2", "3.2") => false
~~~

```nim
func fun_eq_ssb(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_ne_iib

Return true when two ints are not equal.

~~~
ne(a: int, b: int) bool
~~~

Examples:

~~~
ne(1, 1) => false
ne(2, 3) => true
~~~

```nim
func fun_ne_iib(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_ne_ffb

Return true when two floats are not equal.

~~~
ne(a: float, b: float) bool
~~~

Examples:

~~~
ne(1.2, 1.2) => false
ne(1.2, 3.2) => true
~~~

```nim
func fun_ne_ffb(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_ne_ssb

Return true when two strings are not equal.

~~~
ne(a: string, b: string) bool
~~~

Examples:

~~~
ne("tea", "tea") => false
ne("earl", "grey") => true
~~~

```nim
func fun_ne_ssb(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_gt_iib

Return true when an int is greater then another int.

~~~
gt(a: int, b: int) bool
~~~

Examples:

~~~
gt(2, 4) => false
gt(3, 2) => true
~~~

```nim
func fun_gt_iib(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_gt_ffb

Return true when one float is greater than another float.

~~~
gt(a: float, b: float) bool
~~~

Examples:

~~~
gt(2.8, 4.3) => false
gt(3.1, 2.5) => true
~~~

```nim
func fun_gt_ffb(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_gte_iib

Return true when an int is greater then or equal to another int.

~~~
gte(a: int, b: int) bool
~~~

Examples:

~~~
gte(2, 4) => false
gte(3, 3) => true
~~~

```nim
func fun_gte_iib(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_gte_ffb

Return true when a float is greater than or equal to another float.

~~~
gte(a: float, b: float) bool
~~~

Examples:

~~~
gte(2.8, 4.3) => false
gte(3.1, 3.1) => true
~~~

```nim
func fun_gte_ffb(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_lt_iib

Return true when an int is less than another int.

~~~
lt(a: int, b: int) bool
~~~

Examples:

~~~
gt(2, 4) => true
gt(3, 2) => false
~~~

```nim
func fun_lt_iib(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_lt_ffb

Return true when a float is less then another float.

~~~
lt(a: float, b: float) bool
~~~

Examples:

~~~
lt(2.8, 4.3) => true
lt(3.1, 2.5) => false
~~~

```nim
func fun_lt_ffb(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_lte_iib

Return true when an int is less than or equal to another int.

~~~
lte(a: int, b: int) bool
~~~

Examples:

~~~
lte(2, 4) => true
lte(3, 3) => true
lte(4, 3) => false
~~~

```nim
func fun_lte_iib(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_lte_ffb

Return true when a float is less than or equal to another float.

~~~
lte(a: float, b: float) bool
~~~

Examples:

~~~
lte(2.3, 4.4) => true
lte(3.0, 3.0) => true
lte(4.0, 3.0) => false
~~~

```nim
func fun_lte_ffb(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# fun_readJson_sa

Convert a JSON string to a variable.

~~~
readJson(json: string) any
~~~

Examples:

~~~
a = readJson(""tea"") => "tea"
b = readJson("4.5") => 4.5
c = readJson("[1,2,3]") => [1, 2, 3]
d = readJson("{"a":1, "b": 2}")
  => {"a": 1, "b", 2}
~~~

```nim
func fun_readJson_sa(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [ReadIOEffect, WriteIOEffect].}
```

# fun_markdownLite_sl

Parse a simple subset of markdown which contains paragraphs, bullets and code blocks. This subset is used to document all StaticTea functions. Return a list of lists.

list elements:

* p -- A paragraph element is one string, possibly containing
newlines.

* code -- A code element is three strings. The first string is
the code start line, for example “~~~” or “~~~nim”.  The second
string (with newlines) contains the text of the block.  The third
string is the ending line, for example “~~~”.

* bullets -- A bullets element contains a string (with newlines)
for each bullet point.  The leading “* “ is not part of the
string.

~~~
elements = markdownLite(description)
elements => [
  ["p", ["the paragraph which may contain newlines"]]
  ["code", ["~~~", "code text with newlines", "~~~"]]
  ["bullets", ["bullet (newlines) 1", "point 2", "3", ...]
]
~~~

```nim
func fun_markdownLite_sl(variables: Variables; arguments: seq[Value]): FunResult {.
    raises: [KeyError], tags: [].}
```

# functionsDict

Maps a built-in function name to a function pointer you can call.

```nim
functionsDict = newTable(32)
```

# BuiltInInfo

The built-in function information.

* funcName -- the function name in the nim file, e.g.: fun_add_ii
* docComment -- the function documentation
* numLines -- the number of function code lines

```nim
BuiltInInfo = object
  funcName*: string
  docComment*: string
  numLines*: Natural
```

# newBuiltInInfo

Return a BuiltInInfo object.

```nim
func newBuiltInInfo(funcName: string; docComment: string; numLines: Natural): BuiltInInfo 
```

# getBestFunction

Given a function variable or a list of function variables and a list of arguments, return the one that best matches the arguments.

```nim
proc getBestFunction(funcValue: Value; arguments: seq[Value]): ValueOr 
```

# splitFuncName

Split a funcName like "fun_cmp_ffi" to its name and signature like: "cmp" and "ffi".

```nim
func splitFuncName(funcName: string): (string, string) 
```

# makeFuncDictionary

Create the f dictionary from the built in functions.

```nim
proc makeFuncDictionary(): VarsDict {.raises: [ValueError, KeyError, Exception],
                                      tags: [RootEffect].}
```

# funcsVarDict

The f dictionary of built-in functions.

```nim
funcsVarDict = makeFuncDictionary()
```


---
⦿ Markdown page generated by [StaticTea](https://github.com/flenniken/statictea/) from nim doc comments. ⦿
