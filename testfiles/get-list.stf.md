stf file, version 0.1.0

# Get List

Test getting items from a list.

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
o.one = {o.one} = 1
$$ endblock
~~~

### File server.json

~~~
{
  "list": [1, 2, 3, 4]
}
~~~

### File shared.tea

~~~
e = "test failed"
o.one = s.list[0]
if( (get(s.list, 0) != 1), warn(e))
if( (get(s.list, 1) != 2), warn(e))
if( (get(s.list, 2) != 3), warn(e))
if( (get(s.list, 3) != 4), warn(e))
if( (get(s.list, -1) != 4), warn(e))
if( (get(s.list, -2) != 3), warn(e))
if( (get(s.list, -3) != 2), warn(e))
if( (get(s.list, -4) != 1), warn(e))

if( (get(s.list, 4, 99) != 99), warn(e))
if( (get(s.list, -5, 99) != 99), warn(e))

# Expected warnings:
a = get(s.list, 4)
a = get(s.list, -5)
a = get(s.list, "0")
a = get(s.list, 0.1)

~~~

### File result.expected

~~~
o.one = 1 = 1
~~~

### File stdout.expected

~~~
~~~

### File stderr.expected

~~~
shared.tea(16): w54: The list index 4 is out of range.
statement: a = get(s.list, 4)
                           ^
shared.tea(17): w54: The list index -5 is out of range.
statement: a = get(s.list, -5)
                           ^
shared.tea(18): w120: Wrong argument type, expected int.
statement: a = get(s.list, "0")
                           ^
shared.tea(19): w120: Wrong argument type, expected int.
statement: a = get(s.list, 0.1)
                           ^
~~~


### Expected result == result.expected
### Expected stdout == stdout.expected
### Expected stderr == stderr.expected
