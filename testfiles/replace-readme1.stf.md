stf file, version 0.1.0

## The first replace readme example.

### File cmd.sh command

~~~
$statictea -j=replace.json -t=replace.html >stdout 2>stderr
~~~

### File replace.html

~~~
<!--$ replace t.content=h.header -->
<!--$ endblock -->
~~~

### File replace.json

~~~
{
  "header": "<!doctype html>\n<html lang=\"en\">\n"
}
~~~

### File stdout.expected

~~~
<!doctype html>
<html lang="en">
~~~

### File stderr.expected

~~~
~~~

### Expected stdout.expected == stdout
### Expected stderr.expected == stderr

