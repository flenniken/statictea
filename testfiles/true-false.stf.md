stf file, version 0.1.0

# True False

Test true and false.

### File cmd.sh command nonZeroReturn

~~~
$statictea \
  -l log.txt \
  -s server.json \
  -o shared.tea \
  -t tmpl.txt \
  -r result \
  >stdout 2>stderr
~~~

### File tmpl.txt

You can assign to true or false in dictionaries except l.

~~~
$$ block
$$ : a = if(true, "expected", "false")
$$ : b = if(false, "it's false", "expected")
$$ : d = dict()
$$ : d.true = "77"
$$ : d.false = 33
$$ : # You cannot assign to true or false in the local dictionary.
$$ : true = 22
$$ : false = 33
$$ : l.true = 44
$$ : l.false = 55
$$ : #
$$ : True = true
$$ : False = false
$$ : b0 = bool(0)
$$ : b1 = bool(1)
a = {a} = expected
b = {b} = expected
s.true = {s.true} = 12
s.false = {s.false} = hello
o.true = {o.true} = my true
o.false = {o.false} = my false
d = {d.true} = 77 
d = {d.false} = 33

True = {True} = true
False = {False} = false
bool(0) = {b0} = false
bool(1) = {b1} = true
o.true_type = {o.true_type} = bool
o.false_type = {o.false_type} = bool
o.t = {o.t} = bool
o.f = {o.f} = bool
$$ endblock
~~~

### File server.json

~~~
{
  "true": 12,
  "false": "hello"
}
~~~

### File shared.tea

~~~
o.true = "my true"
o.false = "my false"
o.true_type = type(true)
o.false_type = type(false)
o.t = type(bool(1))
o.f = type(bool(0))
~~~

### File result.expected

~~~
a = expected = expected
b = expected = expected
s.true = 12 = 12
s.false = hello = hello
o.true = my true = my true
o.false = my false = my false
d = 77 = 77 
d = 33 = 33

True = true = true
False = false = false
bool(0) = false = false
bool(1) = true = true
o.true_type = bool = bool
o.false_type = bool = bool
o.t = bool = bool
o.f = bool = bool
~~~

### File stdout.expected

~~~
~~~

### File stderr.expected

~~~
tmpl.txt(8): w194: You cannot assign true or false.
statement: true = 22
           ^
tmpl.txt(9): w194: You cannot assign true or false.
statement: false = 33
           ^
tmpl.txt(10): w194: You cannot assign true or false.
statement: l.true = 44
           ^
tmpl.txt(11): w194: You cannot assign true or false.
statement: l.false = 55
           ^
~~~

### Expected result == result.expected
### Expected stdout == stdout.expected
### Expected stderr == stderr.expected
