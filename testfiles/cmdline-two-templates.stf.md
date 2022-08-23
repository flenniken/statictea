stf file, version 0.1.0

# Two Templates

Test with two templates on the command line.

### File cmd.sh command nonZeroReturn

~~~
$statictea -t tmpl.txt -t tmpl2.txt \
  -r result >stdout 2>stderr
~~~

### File stderr.expected

~~~
nofile(0): w169: One 'template' argument is allowed.
~~~

### Expected stdout == empty
### Expected stderr == stderr.expected
