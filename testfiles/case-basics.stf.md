stf file, version 0.1.0

# Case Function

Test the case function.

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
$$ block a1 = case(1, [0, 0, 1, 1, 2, 2, 3, 3])
a1 = {a1} = 1
$$ endblock
~~~

### File shared.tea

~~~
a1 = case(1, [0, 0, 1, 1, 2, 2, 3, 3])
if((a1 != 1), warn("error"))

a2 = case("a2", ["a1", 1, "a2", 2])
if((a2 != 2), warn("a2 error"))

a3 = case(len("tea"), [3, "three"])
if((a3 != "three"), warn("error"))

a4 = case(4, [0, 0, 1, 1, 2, 2, 3, 3], 4)
if((a4 != 4), warn("error"))

# warning case
a5 = case(4, [0, 0, 1, 1, 2, 2, 3, 3])

x = case(1, [ +
    0, warn("not hit"), +
    1, "match", +
    2, warn("not hit") +
  ])
if((x != "match"), warn("error"))
~~~

### File result.expected

~~~
a1 = 1 = 1
~~~

### File stdout.expected

~~~
~~~

### File stderr.expected

~~~
shared.tea(14): w94: None of the case conditions match the main condition and there is no else case.
statement: a5 = case(4, [0, 0, 1, 1, 2, 2, 3, 3])
                                                 ^
~~~

### Expected result == result.expected
### Expected stdout == stdout.expected
### Expected stderr == stderr.expected
