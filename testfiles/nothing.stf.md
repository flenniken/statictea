stf file, version 0.1.0

## Test that the return code for no arguments is not 0.

### File cmd.sh command nonZeroReturn

~~~
$statictea >stdout 2>stderr
~~~

### File stderr.expected

~~~
unnamed(0): w88: No template name. Use -h for help.
~~~

### File stdout.expected

~~~
~~~

### Expected stdout.expected == stdout
### Expected stderr.expected == stderr

