stf file, version 0.1.0

# Update and stdin

Test update when stdin is used for the template. The output goes to
stdout.

~~~
noLastEnding command nonZeroReturn
~~~

### File cmd.sh command

~~~
$statictea \
  -u \
  --code shared.tea \
  -t stdin <tmpl.txt \
  >stdout 2>stderr
~~~

### File tmpl.txt

~~~
$$ replace t.content = o.content
replace me
$$ endblock
~~~

### File shared.tea

~~~ nim
o.content = "shared content"
~~~

### File stdout.expected

~~~
$$ replace t.content = o.content
shared content
$$ endblock
~~~

### File stderr.expected

~~~
~~~

### Expected stdout == stdout.expected
### Expected stderr == stderr.expected
