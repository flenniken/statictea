stf file, version 0.1.0

# Template warn-no-warn

Test there is no warning when the warn is not run.

### File cmd.sh command

~~~
$statictea \
  -t tmpl.txt \
  -r result \
  >stdout 2>stderr
~~~

### File tmpl.txt

~~~
$$ block a = if(false, warn("shouldn't run"), "OK")
{a}
$$ endblock
~~~

### File result.expected

~~~
OK
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
