stf file, version 0.1.0

# Hello World Logging

Logging with Hello World.

### File cmd.sh command

~~~
$statictea -l log.txt -s hello.json -t hello.html >stdout 2>stderr
~~~

### File log.sh command

~~~
cat log.txt | sed 's/^.*); //' >log.filtered
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

### File log.filtered.expected

~~~
Starting: argv: @["-l", "log.txt", "-s", "hello.json", "-t", "hello.html"]
Version: 0.1.0
Warnings: 0
Return code: 0
Done
~~~

### Expected stdout == stdout.expected
### Expected stderr == empty
### Expected log.filtered == log.filtered.expected
