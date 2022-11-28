stf file, version 0.1.0

# Warn Function

Test the warn function.

### File cmd.sh command nonZeroReturn

~~~
$statictea \
  -t tmpl.txt \
  -r result >stdout 2>stderr
~~~

### File tmpl.txt

When the warn function is run, it exits the statement and no
assignment happens. It similar to what happens when a function
generates a normal warning.

~~~
$$ nextline a = warn("warn1: My message that's always output.")
next line case

$$ block
$$ : a = if0(0, warn("warn2: conditional warning"), 2)
a = {a} -- missing
$$ endblock

$$ block
$$ : a = if0(1, warn("warning not hit"), 2)
a = {a} = 2
$$ endblock

$$ block
$$ : a = if0(0, warn("warn3: conditional warning"), "a")
$$ : b = if0(1, warn("b warning not hit"), "b")
$$ : c = if0(0, warn("warn4: conditional warning"), "c")
a = {a} = missing
b = {b} = b
c = {c} = missing
$$ endblock

$$ block
$$ : warn("warn5: bare warning")
$$ : if0(0, warn("warn6: warning in bare if")
$$ : if0(2, warn("not hit"))
$$ endblock
~~~

### File result.expected

~~~
next line case

a = {a} -- missing

a = 2 = 2

a = {a} = missing
b = b = b
c = {c} = missing

~~~

### File stdout.expected

~~~
~~~

### File stderr.expected

~~~
tmpl.txt(1): warn1: My message that's always output.
tmpl.txt(5): warn2: conditional warning
tmpl.txt(6): w58: The replacement variable doesn't exist: a.
tmpl.txt(15): warn3: conditional warning
tmpl.txt(17): warn4: conditional warning
tmpl.txt(18): w58: The replacement variable doesn't exist: a.
tmpl.txt(20): w58: The replacement variable doesn't exist: c.
tmpl.txt(24): warn5: bare warning
tmpl.txt(25): warn6: warning in bare if
~~~

### Expected result == result.expected
### Expected stdout == stdout.expected
### Expected stderr == stderr.expected
