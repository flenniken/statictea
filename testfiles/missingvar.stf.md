stf file, version 0.1.0

# Missing Replacement Variable

Test with a missing replacement variable.

### File cmd.sh command nonZeroReturn

~~~
$statictea -t template.md >stdout 2>stderr
~~~

### File template.md

~~~
$$ nextline
hello {s.name}
$$ block
{s.block}
$$ endblock
~~~

### File stdout.expected

~~~
hello {s.name}
{s.block}
~~~

### File stderr.expected

~~~
template.md(2): w58: The replacement variable doesn't exist: s.name.
template.md(4): w58: The replacement variable doesn't exist: s.block.
~~~

### Expected stdout == stdout.expected
### Expected stderr == stderr.expected

