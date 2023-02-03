stf file, version 0.1.0

# Test Cmp Function

Test the cmp functions.

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
$$ block
$$ : a1 = cmp(1, 2)
$$ : b1 = cmp(2, 2)
$$ : c1 = cmp(3, 2)
$$ : a2 = cmp(1.2, 2.3)
$$ : b2 = cmp(2.2, 2.2)
$$ : c2 = cmp(3.2, 2.2)
$$ : a3 = cmp("a", "b")
$$ : b3 = cmp("abc", "abc")
$$ : c3 = cmp("b", "a")
a1 = {a1} = -1
a2 = {a2} = -1
a3 = {a3} = -1

b1 = {b1} = 0
b2 = {b2} = 0
b3 = {b3} = 0

c1 = {c1} = 1
c2 = {c2} = 1
c3 = {c3} = 1
$$ endblock
~~~

### File shared.tea

~~~
o.a = cmp(l, f)
o.b = cmp(1, 4.5)
o.c = cmp(1.9, 5)
~~~

### File result.expected

~~~
a1 = -1 = -1
a2 = -1 = -1
a3 = -1 = -1

b1 = 0 = 0
b2 = 0 = 0
b3 = 0 = 0

c1 = 1 = 1
c2 = 1 = 1
c3 = 1 = 1
~~~

### File stdout.expected

~~~
~~~

### File stderr.expected

~~~
shared.tea(1): w207: None of the 3 functions matched the first argument.
statement: o.a = cmp(l, f)
                     ^
shared.tea(2): w120: Wrong argument type, expected int.
statement: o.b = cmp(1, 4.5)
                        ^
shared.tea(3): w120: Wrong argument type, expected float.
statement: o.c = cmp(1.9, 5)
                          ^
~~~

### Expected result == result.expected
### Expected stdout == stdout.expected
### Expected stderr == stderr.expected
