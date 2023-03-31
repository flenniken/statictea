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
* return - exits command block or function


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
o.v = {o.v} = [1,2,3,4,5,6,7]
o.r1 = {o.r1} = {{o.r1}
o.r2 = {o.r2} = {{o.r2}
o.r3 = {o.r3} = 5
o.v1 = {o.v1} = false
o.v2 = {o.v2} = false
o.v3 = {o.v3} = true
o.v4 = {o.v4} = {{o.v4}
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

~~~ nim
# Create a list of 7 ints.
o.v = list(1,2,3,4,5,6,7)

# Try to call "a" which is not defined.
o.r1 = a(true, 1, 2)

# Try to call "a" which is a number.
a = 5
o.r2 = a(true, 3, 4)

# Call if from a variable.
o.iffunc = f.if
o.r3 = o.iffunc(true, 5, 6)

o.v1 = and(false, warn("not expected AND message"))
addfunc = f.and
o.v2 = l.addfunc(false, warn("not expected addfunc"))

orfunc = f.or
o.v3 = l.orfunc(true, warn("not expected orfunc"))

warnfunc = f.warn
o.v4 = l.warnfunc("calling warn"))

if(true, return("skip"))
# todo: return assigned to a variable
#returnfunc = f.return
#if(true,l.returnfunc("skip"))

a = len(return(4))
b = if(true, return(5))

if(false, "not expected IF message")
if(true, "if true message")
if(true, 3, "bare requires two parameters")
if(false, 3, "bare requires two parameters")
~~~

### File result.expected

~~~
o.v = [1,2,3,4,5,6,7] = [1,2,3,4,5,6,7]
o.r1 = {o.r1} = {o.r1}
o.r2 = {o.r2} = {o.r2}
o.r3 = 5 = 5
o.v1 = false = false
o.v2 = false = false
o.v3 = true = true
o.v4 = {o.v4} = {o.v4}
~~~

### File stdout.expected

~~~
~~~

### File stderr.expected

~~~
shared.tea(5): w224: The variable 'a' isn't in the f dictionary.
statement: o.r1 = a(true, 1, 2)
                  ^
shared.tea(9): w224: The variable 'a' isn't in the f dictionary.
statement: o.r2 = a(true, 3, 4)
                  ^
shared.tea(23): calling warn
shared.tea(25): w187: Use '...return("stop")...' in a code file.
statement: if(true, return("skip"))
           ^
shared.tea(30): w255: Invalid return; use a bare return in a user function or use it in a bare if statement.
statement: a = len(return(4))
                   ^
shared.tea(31): w255: Invalid return; use a bare return in a user function or use it in a bare if statement.
statement: b = if(true, return(5))
                        ^
shared.tea(35): w213: A bare IF without an assignment takes two arguments.
statement: if(true, 3, "bare requires two parameters")
                     ^
shared.tea(36): w213: A bare IF without an assignment takes two arguments.
statement: if(false, 3, "bare requires two parameters")
                      ^
tmpl.txt(4): w58: The replacement variable doesn't exist: o.r1.
tmpl.txt(5): w58: The replacement variable doesn't exist: o.r2.
tmpl.txt(10): w58: The replacement variable doesn't exist: o.v4.
~~~

### Expected result == result.expected
### Expected stdout == stdout.expected
### Expected stderr == stderr.expected
