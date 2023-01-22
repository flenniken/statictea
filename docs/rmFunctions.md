# Statictea Functions

# Index

* add - Add two floats.
* and - Boolean AND with short circuit.
* bool - Create an bool from a value.
* case - Compare integer cases and return the matching value.
* cmp - Compare two floats.
* cmpVersion - Compare two StaticTea version numbers.
* concat - Concatentate two strings.
* dict - Create a dictionary from a list of key, value pairs.
* dup - Duplicate a string x times.
* eq - Return true when two floats are equal.
* exists - Determine whether a key exists in a dictionary.
* find - Find the position of a substring in a string.
* float - Create a float from an int.
* format - Format a string using replacement variables similar to a replacement block.
* func - Define a function.
* functionDetails - Return the function details.
* get - Get a dictionary value by its key.
* githubAnchor - Create Github anchor names from heading names.
* gt - Return true when one float is greater than another float.
* gte - Return true when a float is greater than or equal to another float.
* if0 - If the condition is 0, return the second argument, else return the third argument.
* if - If the condition is true, return the second argument, else return the third argument.
* int - Create an int from a float.
* join - Join a list of strings with a separator.
* joinPath - Join the path components with a path separator.
* keys - Create a list from the keys in a dictionary.
* len - Number of elements in a dictionary.
* list - Create a list of variables.
* listLoop - Create a new list from a list and a callback function.
* log - Log a message to the log file.
* lower - Lowercase a string.
* lt - Return true when a float is less then another float.
* lte - Return true when a float is less than or equal to another float.
* ne - Return true when two floats are not equal.
* not - Boolean not.
* or - Boolean OR with short circuit.
* path - Split a file path into its component pieces.
* readJson - Convert a JSON string to a variable.
* replace - Replace a substring specified by its position and length with another string.
* replaceRe - Replace multiple parts of a string using regular expressions.
* return - Return is a special function that returns the value passed in and has side effects.
* slice - Extract a substring from a string by its position and length.
* sort - Sort a list of values of the same type.
* startsWith - Check whether a strings starts with the given prefix.
* string - Convert a variable to a string.
* sub - Sub two floats.
* type - Return the parameter type, one of: int, float, string, list, dict, bool or func.
* values - Create a list out of the values in the specified dictionary.
* warn - Return a warning message and skip the current statement.

# add

Add two floats. A warning is generated on overflow.

~~~
add(a: float, b: float) float
~~~

Examples:

~~~
add(1.5, 2.3) => 3.8
add(3.2, -2.2) => 1.0
~~~


# and

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


# bool

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


# case

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


# cmp

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


# cmpVersion

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


# concat

Concatentate two strings. See [[#join][join]] for more that two arguments.

~~~
concat(a: string, b: string) string
~~~

Examples:

~~~
concat("tea", " time") => "tea time"
concat("a", "b") => "ab"
~~~


# dict

Create a dictionary from a list of key, value pairs.  The keys must be strings and the values can be any type.

~~~
dict(pairs: optional list) dict
~~~

Examples:

~~~
dict() => {}
dict(list("a", 5)) => {"a": 5}
dict(list("a", 5, "b", 33, "c", 0)) =>
  {"a": 5, "b": 33, "c": 0}
~~~


# dup

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


# eq

Return true when two floats are equal.

~~~
eq(a: float, b: float) bool
~~~

Examples:

~~~
eq(1.2, 1.2) => true
eq(1.2, 3.2) => false
~~~


# exists

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


# find

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


# float

Create a float from an int.

~~~
float(num: int) float
~~~

Examples:

~~~
float(2) => 2.0
float(-33) => -33.0
~~~


# format

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


# func

Define a function.

~~~
func(signature: string) func
~~~

Example:

~~~
mycmp = func("numStrCmp(numStr1: string, numStr2: string) int")
  ## Compare two number strings
  ## and return 1, 0, or -1.
  num1 = int(numStr1)
  num2 = int(numStr2)
  return(cmp(num1, num2))
~~~


# functionDetails

Return the function details.

~~~
functionDetails(funcVar: func) dict
~~~

The following example defines a simple function then gets its
function details.

~~~
mycmp = func("strNumCmp(numStr1: string, numStr2: string) int")
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
fd.docComment = "  ## Compare two number strings and return 1, 0, or -1.n"
fd.filename = "testcode.tea"
fd.lineNum = 3
fd.numLines = 2
fd.statements = ["  return(cmp(int(numStr1), int(numStr2)))"]
~~~


# get

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


# githubAnchor

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


# gt

Return true when one float is greater than another float.

~~~
gt(a: float, b: float) bool
~~~

Examples:

~~~
gt(2.8, 4.3) => false
gt(3.1, 2.5) => true
~~~


# gte

Return true when a float is greater than or equal to another float.

~~~
gte(a: float, b: float) bool
~~~

Examples:

~~~
gte(2.8, 4.3) => false
gte(3.1, 3.1) => true
~~~


# if0

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
~~~

You don't have to assign the result of an if0 function which is
useful when using a warn or return function for its side effects.
The if takes two arguments when there is no assignment.

~~~
c = 0
if0(c, warn("got zero value"))
~~~


# if

If the condition is true, return the second argument, else return the third argument.

The if functions are special in a couple of ways, see
[[#if-functions][If Functions]].  You usually use boolean infix
expressions for the condition, see:
[[#boolean-expressions][Boolean Expressions]]

~~~
if(condition: bool, then: any, else: optional any) any
~~~

Examples:

~~~
a = if(true, "tea", "beer") => tea
b = if(false, "tea", "beer") => beer
c = if((d < 5), "tea", "beer") => beer
~~~

You don't have to assign the result of an if function which is
useful when using a warn or return function for its side effects.
The if takes two arguments when there is no assignment.

~~~
if(c, warn("c is true"))
if(c, return("skip"))
~~~


# int

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


# join

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


# joinPath

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


# keys

Create a list from the keys in a dictionary.

~~~
keys(dictionary: dict) list
~~~

Examples:

~~~
d = dict("a", 1, "b", 2, "c", 3)
keys(d) => ["a", "b", "c"]
values(d) => ["apple", 2, 3]
~~~


# len

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


# list

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


# listLoop

Create a new list from a list and a callback function. The callback function is called for each item in the list and it decides what goes in the list.

You pass a list, a callback function, and an optional state
variable.

~~~
listLoop(a: list, callback: func, state: optional any) list
~~~

The callback gets pasted the index to the item, its value, the
new list and the state variable.  The callback looks at the
information and adds to the new list when appropriate. The
callback returns true to stop iterating.

~~~
callback(ix: int, item: any, newList: list, state: optional any) bool
~~~

The following example makes a new list [6, 8] from the list
[2,4,6,8].  The callback is called b5.

~~~
list = [2,4,6,8]
newlist = listLoop(list, b5)
=> [6, 8]
~~~

Below is the definition of the b5 callback function.

~~~
b5 = func(“b5(ix: int, value: int, newList: list) bool”)
  ## Collect values greater than 5.
  if( (value <= 5), return(false))
  newList &= value
  return(false)
~~~


# log

Log a message to the log file.  You can call the log function without an assignment.

~~~
log(message: string) string
~~~

You can log conditionally in a bare if statement:

~~~
if0(c, log("log this message when c is 0"))
~~~

You can log conditionally in a normal if statement. In the
following example, if log is called the b variable will not
get created.

~~~
b = if0(c, log("c is not 0"), "")
~~~

You can log unconditionally using a bare log statement:

~~~
log("always log")
~~~


# lower

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


# lt

Return true when a float is less then another float.

~~~
lt(a: float, b: float) bool
~~~

Examples:

~~~
lt(2.8, 4.3) => true
lt(3.1, 2.5) => false
~~~


# lte

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


# ne

Return true when two floats are not equal.

~~~
ne(a: float, b: float) bool
~~~

Examples:

~~~
ne(1.2, 1.2) => false
ne(1.2, 3.2) => true
~~~


# not

Boolean not.

~~~
not(value: bool) bool
~~~

Examples:

~~~
not(true) => false
not(false) => true
~~~


# or

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


# path

Split a file path into its component pieces. Return a dictionary with the filename, basename, extension and directory.

You pass a path string and the optional path separator, forward
slash or or backwards slash. When no separator, the current
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


# readJson

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


# replace

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


# replaceRe

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


# return

Return is a special function that returns the value passed in and has side effects.

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


# slice

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


# sort

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


# startsWith

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


# string

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
are printed one per line as "key = value".

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


# sub

Sub two floats. A warning is generated on overflow.

~~~
sub(a: float, b: float) float
~~~

Examples:

~~~
sub(4.5, 2.3) => 2.2
sub(1.0, 2.2) => -1.2
~~~


# type

Return the parameter type, one of: int, float, string, list, dict, bool or func.

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
type(f.cmp) => "func"
~~~


# values

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


# warn

Return a warning message and skip the current statement. You can call the warn function without an assignment.

~~~
warn(message: string) string
~~~

You can warn conditionally in a bare if statement:

~~~
if0(c, warn("message is 0"))
~~~

You can warn conditionally in a normal if statement. In the
following example, if warn is called the b variable will not
get created.

~~~
b = if0(c, warn("c is not 0"), "")
~~~

You can warn unconditionally using a bare warn statement:

~~~
warn("always warn")
~~~



---

⦿ Markdown page generated by StaticTea from the function dictionary.
