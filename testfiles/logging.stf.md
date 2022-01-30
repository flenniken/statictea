stf file, version 0.1.0

## Logging with Hello World.

# file line attributes: noLastEnding command nonZeroReturn

### File cmd.sh command

~~~
$statictea -l=log.txt -s=hello.json -t=hello.html >stdout 2>stderr
~~~

# Remove the time prefix from the log lines then extract the template lines.
# cat log.txt | cut -c 26- | grep "^tmpl.txt" >log.filtered
# Remove the time and filename prefix from the log lines.
# cat log.txt | sed 's/^.*); //' >log.filtered

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

### File stderr.expected

~~~
~~~

### File log.filtered.expected

~~~
Starting: argv: @["-l=log.txt", "-s=hello.json", "-t=hello.html"]
Version: 0.1.0
Warnings: 0
Return code: 0
Done
~~~

### File log.txt.expected

~~~
~~~

### Expected stdout.expected == stdout
### Expected stderr.expected == stderr
### Expected log.filtered.expected == log.filtered
#--- expected log.txt.expected == log.txt
