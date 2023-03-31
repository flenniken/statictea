stf file, version 0.1.0

# Test Boolean Expressions

Test boolean expressions.

### File cmd.sh command nonZeroReturn

~~~
$statictea \
  -s server.json \
  -o shared.tea \
  -t tmpl.txt \
  -r result \
  >stdout 2>stderr
~~~

### File tmpl.txt

~~~
$$ block
$$ : a = if((true), "always", "failed")
$$ : b = if((a == "always"), "expected", "failed")
$$ : c = if((true and true and true and true), "expected", "failed")
$$ : d = if(("a" != "b"), "expected", "failed")
hello {o.name}
a = {a}
b = {b}
c = {c}
d = {d}
shortCiruit = {o.shortCiruit}
$$ endblock
~~~

### File server.json

~~~
{
  "selected": true,
  "color": "green"
}
~~~

### File shared.tea

~~~ nim
o.name = if((s.color == "green"), "ok", "failed")
o.shortCiruit = if((false and exists(aaa, x)), "failed", "expected")

a0 = if(3 < 5, 1, 2)

# Comparing different types.
a1 = if((5 > 2.3), 1, 2)
a2 = if((5 > "one"), 1, 2)
a3 = if((5.2 > "one"), 1, 2)
a4 = if((true and 5), 1, 2)
a5 = if((5 and true), 1, 2)
a6 = if((true and true or false), 1, 2)
a7 = if((false or false or false and true), 1, 2)
a8 = if((5 nor 2.3), 1, 2)
a9 = if((5 < 3 or 2 = 2), 1, 2)


~~~

### File result.expected

~~~
hello ok
a = always
b = expected
c = expected
d = expected
shortCiruit = expected
~~~

### File stdout.expected

~~~
~~~

### File stderr.expected

~~~
shared.tea(4): w193: The argument must be a bool value, got int.
statement: a0 = if(3 < 5, 1, 2)
                   ^
shared.tea(7): w201: The comparison operator’s right value must be the same type as the left value.
statement: a1 = if((5 > 2.3), 1, 2)
                        ^
shared.tea(8): w201: The comparison operator’s right value must be the same type as the left value.
statement: a2 = if((5 > "one"), 1, 2)
                        ^
shared.tea(9): w201: The comparison operator’s right value must be the same type as the left value.
statement: a3 = if((5.2 > "one"), 1, 2)
                          ^
shared.tea(10): w198: Expected a compare operator, ==, !=, <, >, <=, >=.
statement: a4 = if((true and 5), 1, 2)
                              ^
shared.tea(11): w199: A boolean operator’s left value must be a bool.
statement: a5 = if((5 and true), 1, 2)
                      ^
shared.tea(12): w202: When mixing 'and's and 'or's you need to specify the precedence with parentheses.
statement: a6 = if((true and true or false), 1, 2)
                                  ^
shared.tea(13): w202: When mixing 'and's and 'or's you need to specify the precedence with parentheses.
statement: a7 = if((false or false or false and true), 1, 2)
                                            ^
shared.tea(14): w196: Expected a boolean operator, and, or, ==, !=, <, >, <=, >=.
statement: a8 = if((5 nor 2.3), 1, 2)
                      ^
shared.tea(15): w198: Expected a compare operator, ==, !=, <, >, <=, >=.
statement: a9 = if((5 < 3 or 2 = 2), 1, 2)
                               ^
~~~


### Expected result == result.expected
### Expected stdout == stdout.expected
### Expected stderr == stderr.expected
