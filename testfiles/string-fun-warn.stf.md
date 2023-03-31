stf file, version 0.1.0

# String Function Warnings

Test the string function warnings.

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
$$ block x = string(o, "other")
$$ endblock
~~~

### File server.json

~~~
{}
~~~

### File shared.tea

~~~ nim
o.name = "tea"
o.num = 5
o.realnum = 3.14158
o.list = [1,2,3,[],dict()]
o.table = dict()
o.table.a = "apple"
o.table.b = "banana"
o.table.c = dict()
o.table.d = []
~~~

### File result.expected

~~~
~~~

### File stderr.expected

~~~
tmpl.txt(1): w189: Invalid string type, expected rb, json or dn.
statement: x = string(o, "other")
                         ^
~~~

### Expected result == result.expected
### Expected stdout == empty
### Expected stderr == stderr.expected
