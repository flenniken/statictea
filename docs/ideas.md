# Statictea Ideas

This note describes potential enhancements for Statictea.

## infix expressions

Add infix arithmetic expressions.  These are wrapped with parentheses
like boolean expressions.

There are three type of expressions, boolean, integer and float.

The expression type is determined from the type of the first argument
and the first operator.

* bool expression
* int arithmetic expression
* float arithmetic expression

Example arithmetic expressions:

~~~
num = (a + 1)
num = (a + 1.0)
num =( (a + 1 * 3) / b)
~~~

There is also a function for each operator:

~~~
+ add
- subtract
* multiple
/ divide
~~~

Other math operations are done with functions.

~~~
mod
trig
power
…
~~~

## find regex pattern

Add a new function that finds a regular expression pattern in a string
starting at an index. Return the first pattern found as a dictionary.
The dictionary contains the start and length of the found pattern.
When not found the start is -1.

~~~
d = find(str, pattern, start)
d.start
d.length

find(str: string, pattern: string, start: optional int) dict
~~~

## find regex groups

Find the regex patterns in a string. Return the list of groups found.

~~~
find(str: string, pattern: string, start: int, numGroups: int) list
~~~

## sort with callback

Define a sort function with a callback method.

~~~
sort(items: list, callback: func) list
~~~

~~~
callback(a: any, b: any) int
## Compare a and b.  Return -1 when a is less
## than b, 0 when equal and 1 when greater than.
~~~

Example callback:

~~~
aName, aSig = splitName(a)
bName, bSig = splitName(b)
ret = cmp(aName, bName)
if((ret != 0), return(ret))
ret2 = cmp(aSig, bSig)
return(ret2)
~~~

I tried this, have a branch for it. There is a nim compiler error
because env is a var variable.

## date time now function

Add a now function that returns the current time as a dictionary.

The dictionary contains: year, month, day, hour, minute, second,
fractions of second

~~~
dt = now()

=>

{
“y”: 2023,
“M”: 1 - 12,
“d”: 1 - 31,
“h”: 1 - 24,
“m”: 0 - 59,
“s”: 0 - 59,
“f”: float, 0 - < 1
}
~~~

Make the function by turning off side effects?

## float formatting

Add a function for formatting floats.

## loop full mutation

Switch to full mutation for the container while the loop is running if
the container is:

* dictionary
* initially empty
* in append mode

then you can count things

~~~
u. count-fives(ix: int, num: int, d: dict) bool
  ## Count the number of fives.
  d.fives = if((num == 5), add(d.fives, 1))
  return(false)

d = dict()
teas = [1,6,8,5,5,3,5,8]
loop(teas, d, count-fives)
d.fives => 3
~~~

switch back to append after listLoop finishes, promoting to full is
temporary

## relax immutability?

Allow dicts and lists returned by built-in functions to be appended
to?

## logging

Make a nim debugLog function so we can log inside the pure functions
with no side effects.

## Support both fences

both ~~~ and ```

Support both markdown fence types in markdownLite. Runner already does
this.

## dictionary literals?

~~~
{“a”: 1, “b”: 2}
~~~

Use brackets as a signal to call readJson.

~~~
d = {“a”: 1, “b”: 2}
~~~

Same as readJson(json) where json is the bracketed string.

## u dictionary lists

Allow adding a list of functions to the u dictionary.

~~~
shared.tea(10): w269: You can only assign a user function variable to the u dictionary.
statement: u.myfunc = [hello, double]
           ^
~~~

## print user functions

Print the function given a functionDetails object.  User functions
have source.

~~~
pf funcVar
~~~

## negative index

Support negative index with brackets like you can with get.

~~~
a = images[-1]
a = get(images, -1)
~~~

## slice

Support slice with lists and dictionaries.

## signature list

Support signatures for lists of the same type, all ints for example.

~~~
li, lf, ls, ll, ld, la
or
IFSLDA
~~~

## Json Non-Dict

Support including non-dictionary at the top level; json file styles.

Currently statictea imports json dictionaries. But the definition of
json includes any element as the top level item.

The json file can be a dictionary, list or single value.  Any of these
lines can be a json file:

~~~
123
4.56
“asdf”
[1,2,3] plus nested lists or dicts
{“a”: 1} plus nested lists or dicts
~~~

For a dictionary style file you don’t need to specify a name on the
command line.

~~~
-s=server.json
—server=server.json
~~~

For non-dictionary style files, you name the variable on the command
line.

~~~
-s.v=server.json
—server.v=server.json
~~~

You access the values with the name.

~~~
s.v => 123
s.v => 4.56
~~~

The values are merged into the server dictionary in the order
specified on the command line. If anitem already exists, a warning is
generated and the item is skipped.

## code point

Work with unicode code points.

~~~
string(codePoint: int, optional default: string) string
## Convert a code point to a one character string. The default is used
## when the codePoint is invalid, else a warning is generated.
~~~

Make a function that takes a list?

~~~
codePoint(oneChar: string) int
## Convert a one character string to an integer code point.
~~~

Return a list of code points instead.
