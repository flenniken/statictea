stf file, version 0.1.0

## Test duplicate json variables.

### File cmd.sh command nonZeroReturn

~~~
$statictea -s=server.json -s=server2.json \
  -t=template.html -r=result.html >stdout 2>stderr
~~~

### File server.json

~~~
{
  "name": "Earl",
}
~~~

### File server2.json

~~~
{
  "name": "Grey",
}
~~~

### File template.html

~~~
$$ nextline
{s.name}
~~~

### File result.expected

~~~
Earl
~~~

### File stdout.expected

~~~
~~~

### File stderr.expected

~~~
template.html(0): w132: Duplicate json variable 'name' skipped.
~~~

### Expected result.expected == result.html
### Expected stdout.expected == stdout
### Expected stderr.expected == stderr

