stf file, version 0.1.0

# Multiple Json Files

Test with multiple json and code files.

### File cmd.sh command

~~~
$statictea \
  -s server1.json \
  -s server2.json \
  -o c1.tea \
  -o c2.tea \
  -t template.html \
  -r result.html \
  >stdout 2>stderr
~~~

### File template.html

~~~
<!--$ block -->
hello {s.data1}
hello {s.data2}
hello {o.data1}
hello {o.data2}
<!--$ endblock -->
~~~

### File server1.json

~~~
{
  "data1": "server1.json"
}
~~~

### File server2.json

~~~
{
  "data2": "server2.json"
}
~~~

### File c1.tea

~~~ nim
o.data1 = "c1.tea"
~~~

### File c2.tea

~~~ nim
o.data2 = "c2.tea"
~~~

### File result.expected

~~~
hello server1.json
hello server2.json
hello c1.tea
hello c2.tea
~~~

### Expected result.html == result.expected
### Expected stdout == empty
### Expected stderr == empty

