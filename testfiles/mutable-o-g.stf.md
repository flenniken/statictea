stf file, version 0.1.0

# Mutable O and G

Test that you cannot change o variables in templates and that you
cannot change g variables in code files.

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
$$ : o.abc = 5
$$ : g.var = 6
o.abc = {o.abc} = {{o.abc}
g.var = {g.var} = 6
o.shared = {o.shared} = shared
g.hello = {g.hello} = {{g.hello}
$$ endblock
~~~

### File shared.tea

~~~
o.shared = "shared"
g.hello = "hello"
~~~

### File result.expected

~~~
o.abc = {o.abc} = {o.abc}
g.var = 6 = 6
o.shared = shared = shared
g.hello = {g.hello} = {g.hello}
~~~

### File stdout.expected

~~~
~~~

### File stderr.expected

~~~
shared.tea(2): w186: You can only change global variables (g dictionary) in template files.
statement: g.hello = "hello"
           ^
tmpl.txt(2): w182: You can only change code variables (o dictionary) in code files.
statement: o.abc = 5
           ^
tmpl.txt(4): w58: The replacement variable doesn't exist: o.abc.
tmpl.txt(7): w58: The replacement variable doesn't exist: g.hello.
~~~

### Expected result == result.expected
### Expected stdout == stdout.expected
### Expected stderr == stderr.expected
