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
$$ : sc = a("tea", "tea2")
$$ : fc = o.floatCmp(5.5, 5.1)
$$ : ic = o.intCmp(3, 3)
{a} = array of cmp signatures
string compare = {sc} = -1
int compare = {ic} = 0
float compare = {fc} = 1
$$ endblock
~~~

### File shared.tea

~~~
o.floatCmp = get(cmp, 0)
o.intCmp = get(cmp, 1)
~~~

### File result.expected

~~~
["cmp(ff)i","cmp(ii)i","cmp(ssob)i"] = array of cmp signatures
string compare = -1 = -1
int compare = 0 = 0
float compare = 1 = 1
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