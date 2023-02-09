stf file, version 0.1.0

# Return Function

Test the return function.

### File cmd.sh command nonZeroReturn

~~~
$statictea \
  -o shared.tea \
  -t tmpl.txt \
  -r result \
  >stdout 2>stderr
~~~


### File tmpl.txt

~~~
$$ # The return is ignored because the arg is not skip or stop.
$$ block
$$ : return(5)
$$ : a = 4
a = {a} = 4
$$ endblock

$$ # Skip outputting the replacement block.
$$ block
$$ : g.a1 = 1
$$ : return("skip")
$$ : g.a2 = 2
not expected
$$ endblock
$$ block
g.a1 = {g.a1} = 1
g.a2 = {g.a2} = {{g.a2}
$$ endblock

$$ # Stop outputting the replacement block.
$$ block t.repeat = 3
$$ : g.a3 = 3
$$ : return("stop")
$$ : g.a4 = 4
$$ endblock
$$ block
g.a3 = {g.a3} = 3
g.a4 = {g.a4} = {{g.a4}
$$ endblock

$$ # return in IF function
$$ block t.repeat = 3
$$ : if((t.row == 1), return("stop"))
t.row = {t.row} = 0
$$ endblock

0, 2
$$ # return in IF function
$$ block t.repeat = 3
$$ : if((t.row == 1), return("skip"))
{t.row}
$$ endblock

$$ # return not taken, confusing but expected
$$ block
$$ : a = if(false, return("skip"), 4)
$$ : b = if(false, missing(), 5)
a = {a} = 4
b = {b} = 5
$$ endblock

$$ # return taken, not valid
$$ block
$$ : a = if(true, return("skip"), 4)
a = {a} = {{a}
$$ endblock

$$ # return taken, not valid
$$ block
$$ : a = len(return("skip"))
a = {a} = {{a}
$$ endblock


$$ block
o.a = {o.a} = 1
o.b = {o.b} = 2
o.c = {o.c} = 3
o.d = {o.d} = {{o.d}
$$ endblock
~~~

### File shared.tea

~~~
o.a = 1
return("skip")
o.b = 2
return(5)
o.c = 3
return("stop")
o.d = 4
~~~

### File result.expected

~~~
a = 4 = 4

g.a1 = 1 = 1
g.a2 = {g.a2} = {g.a2}

g.a3 = 3 = 3
g.a4 = {g.a4} = {g.a4}

t.row = 0 = 0

0, 2
0
2

a = 4 = 4
b = 5 = 5

a = {a} = {a}

a = {a} = {a}


o.a = 1 = 1
o.b = 2 = 2
o.c = 3 = 3
o.d = {o.d} = {o.d}
~~~

### File stdout.expected

~~~
~~~

### File stderr.expected

~~~
shared.tea(2): w187: Use '...return("stop")...' in a code file.
statement: return("skip")
           ^
shared.tea(4): w177: Expected 'skip' or 'stop' for the return function value.
statement: return(5)
           ^
tmpl.txt(3): w177: Expected 'skip' or 'stop' for the return function value.
statement: return(5)
           ^
tmpl.txt(17): w58: The replacement variable doesn't exist: g.a2.
tmpl.txt(28): w58: The replacement variable doesn't exist: g.a4.
tmpl.txt(54): w255: Invalid return; use a bare return in a user function or use it in a bare if statement.
statement: a = if(true, return("skip"), 4)
                        ^
tmpl.txt(55): w58: The replacement variable doesn't exist: a.
tmpl.txt(60): w255: Invalid return; use a bare return in a user function or use it in a bare if statement.
statement: a = len(return("skip"))
                   ^
tmpl.txt(61): w58: The replacement variable doesn't exist: a.
tmpl.txt(69): w58: The replacement variable doesn't exist: o.d.
~~~

### Expected result == result.expected
### Expected stdout == stdout.expected
### Expected stderr == stderr.expected
