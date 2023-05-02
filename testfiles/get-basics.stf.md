stf file, version 0.1.0

# Get Function

Test the get function.

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
  "float": 3.14159
}
~~~

### File shared.tea

~~~
o.tea = s.tea
o.num = s.num
o.float = s.float

if( (get(s, "tea") != "Earl Grey"), "error")
if( (get(s, "num") != 1), "error")
if( (get(s, "float") != 3.14159), "error")

o["a"] = "apple"
if( (o.a != "apple"), "error")

key = "b"
o[key] = "banana"
if( (o.b != "banana"), "error")

key1 = "key1"
o[key1] = "one"
if( (get(o, key1) != "one"), "error")

if( (get(s, "missing", 123) != 123), "error")

d = dict(["tea", "Earl Grey"])
if( (get(d, "tea") != "Earl Grey"), "error")
if( (get(d, "coffee", "water") != "water"), "error")

if( (d.tea != "Earl Grey"), "error")

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
