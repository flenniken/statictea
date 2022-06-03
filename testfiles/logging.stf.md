stf file, version 0.1.0

# Hello World Logging

Logging with Hello World.

### File cmd.sh command

~~~
$statictea -l log.txt -s hello.json -t hello.html >stdout 2>stderr
~~~

### File log.sh command

Remove the time and filename from the start of the log lines.
Ignore the duration line.

~~~
cat log.txt | sed 's/^.*); //' | grep -v "Duration: " >log.filtered
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
Json filename: hello.json
Json file size: 18
Template lines: 2
Warnings: 0
~~~

### Expected stdout == stdout.expected
### Expected stderr == empty
### Expected log.filtered == log.filtered.expected
Expected log.txt == empty
