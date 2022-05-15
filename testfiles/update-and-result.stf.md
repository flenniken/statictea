stf file, version 0.1.0

# Update with Result

Test the update option and specify a result file. The update option
changes the template file. It's an error to specify a result file
because it's easy to think update applies to the result file.

### File cmd.sh command nonZeroReturn

~~~
$statictea -u \
  -t tmpl.txt \
  -r result >stdout 2>stderr
~~~

### File tmpl.txt

~~~
Result file with the update option.
~~~

### File result

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
unnamed(0): w176: The result file is used with the update option.
~~~

### Expected result == result.expected
### Expected stdout == stdout.expected
### Expected stderr == stderr.expected
