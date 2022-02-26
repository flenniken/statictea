stf file, version 0.1.0

# Duplicate Json Vars

Test duplicate json variables.

### File cmd.sh command nonZeroReturn

~~~
$statictea -s server.json -s server2.json \
  -t template.html -r result.html >stdout 2>stderr
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

### File stderr.expected

~~~
template.html(0): w132: Duplicate json variable 'name' skipped.
~~~

### Expected result.html == result.expected
### Expected stdout == empty
### Expected stderr == stderr.expected

