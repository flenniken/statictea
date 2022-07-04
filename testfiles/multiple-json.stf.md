stf file, version 0.1.0

# Multiple Json Files

Test with multiple json files.

### File cmd.sh command

~~~
$statictea -s server.json -o c1.tea -o c2.tea \
  -t template.html -r result.html >stdout 2>stderr
~~~

### File template.html

~~~
<!--$ block -->
hello {s.data}, hello {o.data1}, hello {o.data2}
<!--$ endblock -->
~~~

### File server.json

~~~
{
  "data": "server.json"
}
~~~

### File c1.tea

~~~
o.data1 = "c1.tea"
~~~

### File c2.tea

~~~
o.data2 = "c2.tea"
~~~

### File result.expected

~~~
hello server.json, hello c1.tea, hello c2.tea
~~~

### Expected result.html == result.expected
### Expected stdout == empty
### Expected stderr == empty

