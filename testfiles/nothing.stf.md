stf file, version 0.1.0

# No Args Return Code

Test that the return code for no arguments is not 0.

### File cmd.sh command nonZeroReturn

~~~
$statictea >stdout 2>stderr
~~~

### File stderr.expected

~~~
unnamed(0): w88: No template name. Use -h for help.
~~~

### Expected stdout == empty
### Expected stderr == stderr.expected

