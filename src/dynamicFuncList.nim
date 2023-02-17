# This file is auto generated from src/functions.nim doc comments using
# the statictea template templates/dynamicFuncList.nim and the nimble
# task dyfuncs.

const
  dc_fun_add_fff = """
Add two floats. A warning is generated on overflow.

~~~
add(a: float, b: float) float
~~~

Examples:

~~~
add(1.5, 2.3) => 3.8
add(3.2, -2.2) => 1.0
~~~
"""

  dc_fun_add_iii = """
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
"""

  dc_fun_and_bbb = """
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
"""

  dc_fun_bool_ab = """
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
"""

  dc_fun_case_iloaa = """
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
"""

  dc_fun_case_sloaa = """
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
"""

  dc_fun_cmp_ffi = """
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
"""

  dc_fun_cmp_iii = """
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
"""

  dc_fun_cmp_ssobi = """
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
"""

  dc_fun_cmpVersion_ssi = """
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
"""

  dc_fun_concat_sss = """
Concatenate two strings. See the join function for more that two arguments.

~~~
concat(a: string, b: string) string
~~~

Examples:

~~~
concat("tea", " time") => "tea time"
concat("a", "b") => "ab"
~~~
"""

  dc_fun_dict_old = """
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
"""

  dc_fun_dup_sis = """
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
"""

  dc_fun_eq_ffb = """
Return true when two floats are equal.

~~~
eq(a: float, b: float) bool
~~~

Examples:

~~~
eq(1.2, 1.2) => true
eq(1.2, 3.2) => false
~~~
"""

  dc_fun_eq_iib = """
Return true when the two ints are equal.

~~~
eq(a: int, b: int) bool
~~~

Examples:

~~~
eq(1, 1) => true
eq(2, 3) => false
~~~
"""

  dc_fun_eq_ssb = """
Return true when two strings are equal.  See cmp function for case insensitive compare.

~~~
eq(a: string, b: string) bool
~~~

Examples:

~~~
eq("tea", "tea") => true
eq("1.2", "3.2") => false
~~~
"""

  dc_fun_exists_dsb = """
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
"""

  dc_fun_find_ssoaa = """
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
"""

  dc_fun_float_if = """
Create a float from an int.

~~~
float(num: int) float
~~~

Examples:

~~~
float(2) => 2.0
float(-33) => -33.0
~~~
"""

  dc_fun_float_saa = """
Create a float from a number string. If the string is not a number, return the default.

~~~
float(numString: string, default: optional any) any
~~~

Examples:

~~~
float("2") => 2.0
float("notnum", "nan") => nan
~~~
"""

  dc_fun_float_sf = """
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
"""

  dc_fun_format_ss = """
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
"""

  dc_fun_func_sp = """
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
"""

  dc_fun_functionDetails_pd = """
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
"""

  dc_fun_get_dsoaa = """
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
"""

  dc_fun_get_lioaa = """
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
"""

  dc_fun_githubAnchor_ll = """
Create Github anchor names from heading names. Use it for Github markdown internal links. It handles duplicate heading names.

~~~
githubAnchor(names: list) list
~~~

Examples:

~~~
list = list("Tea", "Water", "Tea")
githubAnchor(list) =>
  ["tea", "water", "tea-1"]
~~~
"""

  dc_fun_gt_ffb = """
Return true when one float is greater than another float.

~~~
gt(a: float, b: float) bool
~~~

Examples:

~~~
gt(2.8, 4.3) => false
gt(3.1, 2.5) => true
~~~
"""

  dc_fun_gt_iib = """
Return true when an int is greater then another int.

~~~
gt(a: int, b: int) bool
~~~

Examples:

~~~
gt(2, 4) => false
gt(3, 2) => true
~~~
"""

  dc_fun_gte_ffb = """
Return true when a float is greater than or equal to another float.

~~~
gte(a: float, b: float) bool
~~~

Examples:

~~~
gte(2.8, 4.3) => false
gte(3.1, 3.1) => true
~~~
"""

  dc_fun_gte_iib = """
Return true when an int is greater then or equal to another int.

~~~
gte(a: int, b: int) bool
~~~

Examples:

~~~
gte(2, 4) => false
gte(3, 3) => true
~~~
"""

  dc_fun_if0_iaoaa = """
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
"""

  dc_fun_if_baoaa = """
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
"""

  dc_fun_int_fosi = """
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
"""

  dc_fun_int_sosi = """
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
"""

  dc_fun_int_ssaa = """
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
"""

  dc_fun_join_lsois = """
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
"""

  dc_fun_joinPath_loss = """
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
"""

  dc_fun_keys_dl = """
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
"""

  dc_fun_len_di = """
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
"""

  dc_fun_len_li = """
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
"""

  dc_fun_len_si = """
Number of unicode characters in a string.

~~~
len(str: string) int
~~~

Examples:

~~~
len("tea") => 3
len("añyóng") => 6
~~~
"""

  dc_fun_list_al = """
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
"""

  dc_fun_listLoop_lapoab = """
Loop over items in a list and fill in a container. A callback function is called for each item in the list and it decides what goes in the container.

You pass a list to loop over, a container to fill in, a callback
function, and an optional state variable. The function returns
whether the callback stopped early or not.

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
stopped = listLoop(list, o.container, b5)
# o.container => [6, 8]
~~~

Below is the definition of the b5 callback function.

~~~
b5 = func(ix: int, value: int, container: list) bool
  ## Collect values greater than 5.
  container &= if( (value > 5), value)
  return(false)
~~~
"""

  dc_fun_log_ss = """
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
"""

  dc_fun_lower_ss = """
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
"""

  dc_fun_lt_ffb = """
Return true when a float is less then another float.

~~~
lt(a: float, b: float) bool
~~~

Examples:

~~~
lt(2.8, 4.3) => true
lt(3.1, 2.5) => false
~~~
"""

  dc_fun_lt_iib = """
Return true when an int is less than another int.

~~~
lt(a: int, b: int) bool
~~~

Examples:

~~~
gt(2, 4) => true
gt(3, 2) => false
~~~
"""

  dc_fun_lte_ffb = """
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
"""

  dc_fun_lte_iib = """
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
"""

  dc_fun_ne_ffb = """
Return true when two floats are not equal.

~~~
ne(a: float, b: float) bool
~~~

Examples:

~~~
ne(1.2, 1.2) => false
ne(1.2, 3.2) => true
~~~
"""

  dc_fun_ne_iib = """
Return true when two ints are not equal.

~~~
ne(a: int, b: int) bool
~~~

Examples:

~~~
ne(1, 1) => false
ne(2, 3) => true
~~~
"""

  dc_fun_ne_ssb = """
Return true when two strings are not equal.

~~~
ne(a: string, b: string) bool
~~~

Examples:

~~~
ne("tea", "tea") => false
ne("earl", "grey") => true
~~~
"""

  dc_fun_not_bb = """
Boolean not.

~~~
not(value: bool) bool
~~~

Examples:

~~~
not(true) => false
not(false) => true
~~~
"""

  dc_fun_or_bbb = """
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
"""

  dc_fun_path_sosd = """
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
"""

  dc_fun_readJson_sa = """
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
"""

  dc_fun_replace_siiss = """
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
"""

  dc_fun_replaceRe_sls = """
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
"""

  dc_fun_return_aa = """
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
"""

  dc_fun_slice_siois = """
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
"""

  dc_fun_sort_lsosl = """
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
"""

  dc_fun_sort_lssil = """
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
"""

  dc_fun_sort_lsssl = """
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
"""

  dc_fun_startsWith_ssb = """
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
"""

  dc_fun_string_aoss = """
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
fn = cmp[[0]
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
"""

  dc_fun_string_sds = """
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
"""

  dc_fun_sub_fff = """
Subtract two floats. A warning is generated on overflow.

~~~
sub(a: float, b: float) float
~~~

Examples:

~~~
sub(4.5, 2.3) => 2.2
sub(1.0, 2.2) => -1.2
~~~
"""

  dc_fun_sub_iii = """
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
"""

  dc_fun_type_as = """
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
"""

  dc_fun_values_dl = """
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
"""

  dc_fun_warn_ss = """
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
"""

  info = newBuiltInInfo
  functionsList* = [
    info("fun_add_fff", dc_fun_add_fff, 23),
    info("fun_add_iii", dc_fun_add_iii, 24),
    info("fun_and_bbb", dc_fun_and_bbb, 23),
    info("fun_bool_ab", dc_fun_bool_ab, 37),
    info("fun_case_iloaa", dc_fun_case_iloaa, 33),
    info("fun_case_sloaa", dc_fun_case_sloaa, 32),
    info("fun_cmp_ffi", dc_fun_cmp_ffi, 21),
    info("fun_cmp_iii", dc_fun_cmp_iii, 21),
    info("fun_cmp_ssobi", dc_fun_cmp_ssobi, 33),
    info("fun_cmpVersion_ssi", dc_fun_cmpVersion_ssi, 44),
    info("fun_concat_sss", dc_fun_concat_sss, 19),
    info("fun_dict_old", dc_fun_dict_old, 37),
    info("fun_dup_sis", dc_fun_dup_sis, 39),
    info("fun_eq_ffb", dc_fun_eq_ffb, 19),
    info("fun_eq_iib", dc_fun_eq_iib, 19),
    info("fun_eq_ssb", dc_fun_eq_ssb, 20),
    info("fun_exists_dsb", dc_fun_exists_dsb, 52),
    info("fun_find_ssoaa", dc_fun_find_ssoaa, 38),
    info("fun_float_if", dc_fun_float_if, 17),
    info("fun_float_saa", dc_fun_float_saa, 55),
    info("fun_float_sf", dc_fun_float_sf, 26),
    info("fun_format_ss", dc_fun_format_ss, 34),
    info("fun_func_sp", dc_fun_func_sp, 21),
    info("fun_functionDetails_pd", dc_fun_functionDetails_pd, 35),
    info("fun_get_dsoaa", dc_fun_get_dsoaa, 38),
    info("fun_get_lioaa", dc_fun_get_lioaa, 48),
    info("fun_githubAnchor_ll", dc_fun_githubAnchor_ll, 41),
    info("fun_gt_ffb", dc_fun_gt_ffb, 19),
    info("fun_gt_iib", dc_fun_gt_iib, 19),
    info("fun_gte_ffb", dc_fun_gte_ffb, 19),
    info("fun_gte_iib", dc_fun_gte_iib, 19),
    info("fun_if0_iaoaa", dc_fun_if0_iaoaa, 58),
    info("fun_if_baoaa", dc_fun_if_baoaa, 39),
    info("fun_int_fosi", dc_fun_int_fosi, 35),
    info("fun_int_sosi", dc_fun_int_sosi, 42),
    info("fun_int_ssaa", dc_fun_int_ssaa, 35),
    info("fun_join_lsois", dc_fun_join_lsois, 45),
    info("fun_joinPath_loss", dc_fun_joinPath_loss, 41),
    info("fun_keys_dl", dc_fun_keys_dl, 24),
    info("fun_len_di", dc_fun_len_di, 19),
    info("fun_len_li", dc_fun_len_li, 19),
    info("fun_len_si", dc_fun_len_si, 18),
    info("fun_list_al", dc_fun_list_al, 21),
    info("fun_listLoop_lapoab", dc_fun_listLoop_lapoab, 47),
    info("fun_log_ss", dc_fun_log_ss, 24),
    info("fun_lower_ss", dc_fun_lower_ss, 19),
    info("fun_lt_ffb", dc_fun_lt_ffb, 19),
    info("fun_lt_iib", dc_fun_lt_iib, 19),
    info("fun_lte_ffb", dc_fun_lte_ffb, 20),
    info("fun_lte_iib", dc_fun_lte_iib, 20),
    info("fun_ne_ffb", dc_fun_ne_ffb, 19),
    info("fun_ne_iib", dc_fun_ne_iib, 19),
    info("fun_ne_ssb", dc_fun_ne_ssb, 19),
    info("fun_not_bb", dc_fun_not_bb, 18),
    info("fun_or_bbb", dc_fun_or_bbb, 23),
    info("fun_path_sosd", dc_fun_path_sosd, 55),
    info("fun_readJson_sa", dc_fun_readJson_sa, 23),
    info("fun_replace_siiss", dc_fun_replace_siiss, 110),
    info("fun_replaceRe_sls", dc_fun_replaceRe_sls, 33),
    info("fun_return_aa", dc_fun_return_aa, 57),
    info("fun_slice_siois", dc_fun_slice_siois, 35),
    info("fun_sort_lsosl", dc_fun_sort_lsosl, 33),
    info("fun_sort_lssil", dc_fun_sort_lssil, 29),
    info("fun_sort_lsssl", dc_fun_sort_lsssl, 29),
    info("fun_startsWith_ssb", dc_fun_startsWith_ssb, 23),
    info("fun_string_aoss", dc_fun_string_aoss, 86),
    info("fun_string_sds", dc_fun_string_sds, 24),
    info("fun_sub_fff", dc_fun_sub_fff, 25),
    info("fun_sub_iii", dc_fun_sub_iii, 24),
    info("fun_type_as", dc_fun_type_as, 53),
    info("fun_values_dl", dc_fun_values_dl, 123),
    info("fun_warn_ss", dc_fun_warn_ss, 25),
  ]
    ## Dynamically generated sorted list of built-in functions. Each
    ## line contains the nim function name, its doc comment, and the
    ## starting line number.  See templates/dynamicFuncList.nim
    
  # Note: the function starting lines is separate from the list above
  # so when there are changes the diffs are easier to read.

  functionStarts* = [
    594,
    570,
    2335,
    1073,
    718,
    751,
    258,
    237,
    279,
    795,
    312,
    1222,
    1183,
    2400,
    2381,
    2419,
    666,
    1110,
    839,
    882,
    856,
    2204,
    2238,
    2259,
    435,
    387,
    1808,
    2515,
    2496,
    2553,
    2534,
    473,
    531,
    937,
    972,
    1014,
    1943,
    1902,
    1570,
    368,
    349,
    331,
    1259,
    1280,
    2013,
    1551,
    2591,
    2572,
    2630,
    2610,
    2458,
    2439,
    2477,
    2317,
    2358,
    1496,
    2650,
    1327,
    1437,
    2037,
    1148,
    1717,
    1750,
    1779,
    2294,
    2094,
    2180,
    641,
    617,
    1849,
    1594,
    1988,
  ]
    ## Dynamically generated array of starting line numbers for each
    ## built-in function in the functions.nim file.
