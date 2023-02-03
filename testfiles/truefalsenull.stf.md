stf file, version 0.1.0

# True False Null

Test json true, false and null.

### File cmd.sh command

~~~
$statictea \
  -s server.json \
  -t template.html \
  >stdout 2>stderr
~~~

### File template.html

~~~
$$ block
true => {s.true}
false => {s.false}
null => {s.null}
$$ endblock
~~~

### File server.json

~~~
{
  "true": true,
  "false": false,
  "null": null,
}
~~~

### File stdout.expected

~~~
true => true
false => false
null => 0
~~~

### Expected stdout == stdout.expected
### Expected stderr == empty

