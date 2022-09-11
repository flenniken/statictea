stf file, version 0.1.0

# Test Func Type

Test the func type.

### File cmd.sh command nonZeroReturn

~~~
$statictea \
  -o shared.tea \
  -t tmpl.txt \
  -r result >stdout 2>stderr
~~~

### File tmpl.txt

~~~
$$ block
cmp (o.a) = {o.a}
cmp[0] (o.b) = {o.b}
cmp[1] (o.c) = {o.c}
$$ endblock
~~~

### File shared.tea

~~~
o.a = cmp
o.b = get(cmp, 0)
o.c = get(cmp, 1)
~~~

### File result.expected

~~~
~~~

### File stdout.expected

~~~
~~~

### File stderr.expected

~~~
~~~

### Expected result == result.expected
### Expected stdout == stdout.expected
### Expected stderr == stderr.expected
