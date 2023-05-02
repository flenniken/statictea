stf file, version 0.1.0

# Get Dict

Test the get function with dictionaries.

### File cmd.sh command

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
s.tea = o.tea = {s.tea} = {o.tea}
s.num = o.num = {s.num} = {o.num}
s.float = o.float = {s.float} = {o.float}
$$ endblock
~~~

### File server.json

~~~
{
  "tea": "Earl Grey",
  "num": 1,
  "float": 3.14159,
  "1": 1,
}
~~~

### File shared.tea

~~~
e = "test failed"
o.tea = s.tea
o.num = s.num
o.float = s.float

if( (get(s, "tea") != "Earl Grey"), warn(e))
if( (get(s, "num") != 1), warn(e))
if( (get(s, "float") != 3.14159), warn(e))

o["a"] = "apple"
if( (o.a != "apple"), warn(e))

key = "b"
o[key] = "banana"
if( (o.b != "banana"), warn(e))

key1 = "key1"
o[key1] = "one"
if( (get(o, key1) != "one"), warn(e))

if( (get(s, "1") != 1), warn(e))

if( (get(s, "missing", 123) != 123), warn(e))

d = dict(["tea", "Earl Grey"])
if( (get(d, "tea") != "Earl Grey"), warn(e))
if( (get(d, "coffee", "water") != "water"), warn(e))

if( (d.tea != "Earl Grey"), warn(e))

~~~

### File result.expected

~~~
s.tea = o.tea = Earl Grey = Earl Grey
s.num = o.num = 1 = 1
s.float = o.float = 3.14159 = 3.14159
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
