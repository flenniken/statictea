stf file, version 0.1.0

# Return Code

Test the return code for -l -h is 0.

### File cmd.sh command

~~~
$statictea -l -h >stdout 2>stderr
~~~

### Expected stderr == empty

