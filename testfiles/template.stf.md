stf file, version 0.1.0

# Stf Template

This stf file is used as a template by the newstf nimble task.

### File cmd.sh command

~~~
$statictea \
  -s server.json \
  -o shared.tea \
  -t tmpl.txt \
  -r result \
  >stdout 2>stderr
~~~

### File tmpl.txt

~~~
~~~

### File server.json

~~~
{}
~~~

### File shared.tea

~~~
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

### Expected result == result.expected
### Expected stdout == stdout.expected
### Expected stderr == stderr.expected
