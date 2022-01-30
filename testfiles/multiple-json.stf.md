stf file, version 0.1.0

## Test multiple json files.


# file line attributes: noLastEnding command nonZeroReturn

### File cmd.sh command

~~~
$statictea -s=server.json -j=j1.json -j=j2.json \
  -t=template.html -r=result.html >stdout 2>stderr
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

### File stdout.expected

~~~
~~~

### File stderr.expected

~~~
~~~

### Expected result.expected == result.html
### Expected stdout.expected == stdout
### Expected stderr.expected == stderr

