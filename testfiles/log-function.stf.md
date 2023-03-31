stf file, version 0.1.0

# Log Function

Test the log function.

Here are the file line attributes:

~~~
noLastEnding command nonZeroReturn
~~~

### File cmd.sh command

~~~
$statictea \
  -l log.txt \
  -o shared.tea \
  -t tmpl.txt \
  -r result >stdout 2>stderr
~~~

Run a command over the log file that removes the time prefix then
extracts the lines that do not contain ".nim".

### File log.sh command


~~~
cat log.txt | cut -c 26- | grep -v '\.nim' >log.filtered | true
~~~

### File tmpl.txt

~~~
$$ block
$$ : log("test log message")
$$ endblock
~~~

### File shared.tea

~~~ nim
log("log inside shared.tea")
if(false, log("not hit"))
if(true, log("hello"))
~~~

### File result.expected

~~~
~~~

### File stdout.expected

~~~
~~~

### File stderr.expected

~~~
~~~

### File log.filtered.expected

~~~
shared.tea(1); log inside shared.tea
shared.tea(3); hello
tmpl.txt(2); test log message
~~~

### Expected result == result.expected
### Expected stdout == stdout.expected
### Expected stderr == stderr.expected
### Expected log.filtered == log.filtered.expected
