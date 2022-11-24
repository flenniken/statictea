stf file, version 0.1.0

# Special Forms

Test the special forms.

The normal way functions behave when you call them is known as the
normal form. A few functions deviate in one or more ways from the
normal form and these are known as special forms.

The normal form you call with parentheses, pass a fixed number of
arguments which get evaluated before hand.  It returns a value and
there are no side effects.

A normal statement has a left side, an operator, and a right hand
side, for example:

~~~
a = len(“tea”)
~~~

The special forms and how they deviate from the normal form:

* list - any number of arguments
* if - conditional evaluation of arguments, bare no return value option
* and — conditional evaluation of arguments
* or — conditional evaluation of arguments
* warn — no return value, exits the statement like a normal warning
* return - no return value, exits command block or function

Special Form Examples:

~~~
v = list(1,2,3,4,5,6,7)
v = if(b, 5, 6)
if(c, warn(“abc”))
if(c, return(“abc”))
v = and(c, d)
v = or(c, d)
warn(“abc”)
return(1)
~~~


### File cmd.sh command nonZeroReturn

~~~
$statictea \
  -s server.json \
  -o shared.tea \
  -t tmpl.txt \
  -r result >stdout 2>stderr
~~~


### File tmpl.txt

~~~
$$ block
$$ :
o.r1 = {o.r1}
o.r2 = {o.r2}
o.r3 = {o.r3}
$$ endblock
~~~

### File server.json

~~~
{
  "name": "server",
  "type": "json"
}
~~~

### File shared.tea

~~~
# Try to call "a" which is not defined.
o.r1 = a(true, 1, 2)

# Try to call "a" which is a number.
a = 5
o.r2 = a(true, 3, 4)

o.iffunc = f.if
o.r3 = o.iffunc(true, 5, 6)


~~~

### File result.expected

~~~
o.r1 = {o.r1}
o.r2 = {o.r2}
o.r3 = 6
~~~

### File stdout.expected

~~~
~~~

### File stderr.expected

~~~
shared.tea(2): w224: The variable 'a' isn't in the f dictionary.
statement: o.r1 = a(true, 1, 2)
                  ^
shared.tea(6): w224: The variable 'a' isn't in the f dictionary.
statement: o.r2 = a(true, 3, 4)
                  ^
tmpl.txt(3): w58: The replacement variable doesn't exist: o.r1.
tmpl.txt(4): w58: The replacement variable doesn't exist: o.r2.
~~~

### Expected result == result.expected
### Expected stdout == stdout.expected
### Expected stderr == stderr.expected
