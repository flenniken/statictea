stf file, version 0.1.0

## A template coming from stdin.

### File cmd.sh command

~~~
$statictea -s=hello.json -t=stdin <hello.html >stdout 2>stderr
~~~

### File hello.html

~~~
<!--$ nextline -->
hello {s.name}
~~~

### File hello.json

~~~
{"name": "world"}
~~~

### File stdout.expected

~~~
hello world
~~~

### File stderr.expected

~~~
~~~

### Expected stdout.expected == stdout
### Expected stderr.expected == stderr

