stf file, version 0.1.0

# Stdin

Test a template coming from stdin.

### File cmd.sh command

~~~
$statictea -s hello.json -t stdin <hello.html >stdout 2>stderr
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

### Expected stdout == stdout.expected
### Expected stderr == empty

