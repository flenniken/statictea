stf file, version 0.1.0

## Replacement variable is missing.

### File cmd.sh command nonZeroReturn

~~~
$statictea -t=template.md >stdout 2>stderr
~~~

### Expected stdout.expected == stdout
### Expected stderr.expected == stderr

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



