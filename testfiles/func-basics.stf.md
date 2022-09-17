stf file, version 0.1.0

# Test Func Type

Test the func type.

### File cmd.sh command

~~~
$statictea \
  -o shared.tea \
  -t tmpl.txt \
  -r result >stdout 2>stderr
~~~

### File tmpl.txt

~~~
$$ block
$$ : a = cmp
$$ : fa = a("tea", "tea2")
$$ : foa = o.a(3, 4)
$$ : fob = o.b(true, true)
$$ : foc = o.c(5.5, 5.1)
o.a = {o.a} = array of signatures
o.b = {o.b} = cmp
o.c = {o.c} = cmp
{fa} = -1
{foa} = -1
{fob} = 0
{foc} = 1
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
o.a = ["cmp(bb)i","cmp(ff)i","cmp(ii)i","cmp(ssob)i"] = array of signatures
o.b = cmp = cmp
o.c = cmp = cmp
-1 = -1
-1 = -1
0 = 0
1 = 1
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
