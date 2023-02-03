stf file, version 0.1.0

# Test No Result File

Test when no result file is specified. Result goes to stdout.

### File cmd.sh command

~~~
$statictea \
  -t tmpl.txt \
  >stdout 2>stderr
~~~


### File tmpl.txt

~~~
$$ block name = "hello"
hello {name}
$$ endblock
going to stdout
~~~

### File stdout.expected

~~~
hello hello
going to stdout
~~~

### Expected stdout == stdout.expected
### Expected stderr == empty
