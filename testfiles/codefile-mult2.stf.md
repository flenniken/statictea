stf file, version 0.1.0

# Multiline Strings

Test multiline strings.

### File cmd.sh command nonZeroReturn

~~~
$statictea \
  -o shared.tea \
  -o shared2.tea \
  -t tmpl.txt \
  -r result \
  >stdout 2>stderr
~~~


### File tmpl.txt

~~~
$$ block
{o.a} = 5
{o.b} = {{o.b}
{o.c} = 6
{o.d} = {{o.d}
{o.e} = {{o.e}
$$ endblock
~~~

### File shared.tea

Errors reading statement lines stop further processing of the code
file. These are issues with triple quotes, continuation plus signs
or invalid UTF-8 characters.

Errors in a statement skip the statement and continue with the next
one.

~~~
o.a = 5
o.b = "missing ending quote
o.c = 6
o.d = """invalid"""
o.e = 7
~~~


### File shared2.tea

~~~
missing-end = """


~~~


### File result.expected

~~~
5 = 5
{o.b} = {o.b}
6 = 6
{o.d} = {o.d}
{o.e} = {o.e}
~~~

### File stdout.expected

~~~
~~~

### File stderr.expected

~~~
shared.tea(2): w139: No ending double quote.
statement: o.b = "missing ending quote
                                      ^
shared.tea(4): w185: A multiline string's leading and ending triple quotes must end the line.
statement: o.d = """invalid"""␊
                    ^
shared2.tea(4): w184: Out of lines looking for the multiline string.
tmpl.txt(3): w58: The replacement variable doesn't exist: o.b.
tmpl.txt(5): w58: The replacement variable doesn't exist: o.d.
tmpl.txt(6): w58: The replacement variable doesn't exist: o.e.
~~~

### Expected result == result.expected
### Expected stdout == stdout.expected
### Expected stderr == stderr.expected
