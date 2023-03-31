stf file, version 0.1.0

# Test Function Warnings

Test the function warnings.

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
$$ endblock
~~~

### File shared.tea

~~~ nim
a = 1
o.name = a("shared")
b &= 2
o.t = b(1)
b &= 3
o.t2 = b(1)
b2 = ccc()
b3 = cmp(1 2)
b4 = cmp(1,)
b5 = cmp([1)
~~~

### File result.expected

~~~
~~~

### File stdout.expected

~~~
~~~

### File stderr.expected

~~~
shared.tea(2): w224: The variable 'a' isn't in the f dictionary.
statement: o.name = a("shared")
                    ^
shared.tea(4): w224: The variable 'b' isn't in the f dictionary.
statement: o.t = b(1)
                 ^
shared.tea(6): w224: The variable 'b' isn't in the f dictionary.
statement: o.t2 = b(1)
                  ^
shared.tea(7): w224: The variable 'ccc' isn't in the f dictionary.
statement: b2 = ccc()
                ^
shared.tea(8): w46: Expected comma or right parentheses.
statement: b3 = cmp(1 2)
                      ^
shared.tea(9): w33: Expected a string, number, variable, list or condition.
statement: b4 = cmp(1,)
                      ^
shared.tea(10): w170: Missing comma or right bracket.
statement: b5 = cmp([1)
                      ^
~~~

### Expected result == result.expected
### Expected stdout == stdout.expected
### Expected stderr == stderr.expected
