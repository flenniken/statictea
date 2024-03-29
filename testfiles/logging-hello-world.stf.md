stf file, version 0.1.0

# Hello World Logging

Test logging with Hello World.

### File cmd.sh command

~~~
$statictea \
  -s hello.json \
  -t hello.html \
  >stdout 2>stderr
$statictea \
  -l log.txt \
  -s hello.json \
  -t hello.html \
  >stdout 2>stderr
~~~

### File log.sh command

Remove the time and filename from the start of the log lines.
Ignore the duration and version lines.

~~~
cat log.txt | sed 's/^.*); //' | grep -v "Duration: " | grep -v "Version: " >log.filtered
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

### File log.expected

~~~
Starting: argv: @["-l", "log.txt", "-s", "hello.json", "-t", "hello.html"]
Json filename: hello.json
Json file size: 18
Number of template lines: 2
Warnings: 0
~~~

### Expected stdout == stdout.expected
### Expected stderr == empty
### Expected log.filtered == log.expected
Expected log.txt == empty
