stf file, version 0.1.0

# No Templates

Test with no templates on the command line.

### File cmd.sh command nonZeroReturn

~~~
$statictea -r result >stdout 2>stderr
~~~

### File stderr.expected

~~~
nofile(0): w88: No template name. Use -h for help.
~~~

### Expected stdout == empty
### Expected stderr == stderr.expected
