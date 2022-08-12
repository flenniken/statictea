stf file, version 0.1.0

# Template warn-basics

Test the warn function.

### File cmd.sh command nonZeroReturn

~~~
$statictea \
  -t tmpl.txt \
  -r result >stdout 2>stderr
~~~

### File tmpl.txt

~~~
$$ nextline a = warn("My message that's always output.")
next line case

$$ block a = if0(0, warn("warning 1 is 1"), 2)
a = {a}
$$ endblock

$$ block a = if0(1, warn("warning 1 is 1"), 2)
a = {a}
$$ endblock

$$ block
$$ : a = if0(0, warn("warning a"), "a")
$$ : b = if0(1, warn("warning b"), "b")
$$ : c = if0(0, warn("warning c"), "c")
a = {a}
b = {b}
c = {c}
$$ endblock
~~~


### File result.expected

~~~
next line case

a = {a}

a = 2

a = {a}
b = b
c = {c}
~~~

### File stdout.expected

~~~
~~~

### File stderr.expected

~~~
tmpl.txt(1): My message that's always output.
tmpl.txt(4): warning 1 is 1
tmpl.txt(5): w58: The replacement variable doesn't exist: a.
tmpl.txt(13): warning a
tmpl.txt(15): warning c
tmpl.txt(16): w58: The replacement variable doesn't exist: a.
tmpl.txt(18): w58: The replacement variable doesn't exist: c.
~~~

### Expected result == result.expected
### Expected stdout == stdout.expected
### Expected stderr == stderr.expected
