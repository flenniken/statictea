stf file, version 0.1.0

# Multiple Json Files

Test with multiple json files.

### File cmd.sh command

~~~
$statictea -s server.json -j j1.json -j j2.json \
  -t template.html -r result.html >stdout 2>stderr
~~~

### File template.html

~~~
<!--$ block -->
hello {s.data}, hello {h.data1}, hello {h.data2}
<!--$ endblock -->
~~~

### File server.json

~~~
{
  "data": "server.json"
}
~~~

### File j1.json

~~~
{
  "data1": "j1.json"
}
~~~

### File j2.json

~~~
{
  "data2": "j2.json"
}
~~~

### File result.expected

~~~
hello server.json, hello j1.json, hello j2.json
~~~

### Expected result.html == result.expected
### Expected stdout == empty
### Expected stderr == empty

