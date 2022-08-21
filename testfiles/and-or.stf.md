stf file, version 0.1.0

# Test And Or

Test the and and or functions.

### File cmd.sh command nonZeroReturn

~~~
$statictea \
  -t tmpl.txt \
  -r result >stdout 2>stderr
~~~

### File tmpl.txt

~~~
$$ block
$$ : c1 = and(1, 2)
$$ : c2 = and(true, 2)
$$ : c3 = or(1, 2)
$$ : c4 = or(false, 2)
$$ : c5 = or(false, false, true)
$$ : c6 = and(false, false, true)
$$ : c7 = or(false)
$$ : c8 = and(false)
$$ endblock

$$ block
$$ : c1 = and(true, true)
$$ : c2 = and(false, true)
$$ : c3 = and(true, false)
$$ : c4 = and(false, false)
$$ : c5 = and(false, warn("not hit"))
c1 = {c1} = true
c2 = {c2} = false
c3 = {c3} = false
c4 = {c4} = false
c5 = {c5} = false
$$ endblock

$$ block
$$ : c1 = or(true, true)
$$ : c2 = or(false, true)
$$ : c3 = or(true, false)
$$ : c4 = or(false, false)
$$ : c5 = or(true, warn("or 2 not hit"))
c1 = {c1} = true
c2 = {c2} = true
c3 = {c3} = true
c4 = {c4} = false
c5 = {c5} = true
$$ endblock
~~~


### File result.expected

~~~

c1 = true = true
c2 = false = false
c3 = false = false
c4 = false = false
c5 = false = false

c1 = true = true
c2 = true = true
c3 = true = true
c4 = false = false
c5 = true = true
~~~

### File stdout.expected

~~~
~~~

### File stderr.expected

~~~
tmpl.txt(2): w193: The argument must be a bool value, got a int.
statement: c1 = and(1, 2)
                    ^
tmpl.txt(3): w193: The argument must be a bool value, got a int.
statement: c2 = and(true, 2)
                          ^
tmpl.txt(4): w193: The argument must be a bool value, got a int.
statement: c3 = or(1, 2)
                   ^
tmpl.txt(5): w193: The argument must be a bool value, got a int.
statement: c4 = or(false, 2)
                          ^
tmpl.txt(6): w195: Expected two arguments.
statement: c5 = or(false, false, true)
                               ^
tmpl.txt(7): w195: Expected two arguments.
statement: c6 = and(false, false, true)
                                ^
tmpl.txt(8): w195: Expected two arguments.
statement: c7 = or(false)
                        ^
tmpl.txt(9): w195: Expected two arguments.
statement: c8 = and(false)
                         ^
~~~

### Expected result == result.expected
### Expected stdout == stdout.expected
### Expected stderr == stderr.expected
