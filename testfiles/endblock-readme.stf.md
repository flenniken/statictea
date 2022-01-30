stf file, version 0.1.0

# Readme Endblock

The endblock readme example.

### File cmd.sh command

~~~
$statictea -t=template.html >stdout 2>stderr
~~~

### File template.html

~~~
<!--$ block -->
<!--$ # this is not a comment, just text -->
fake nextline
<!--$ nextline -->
<!--$ endblock -->
~~~

### File stdout.expected

~~~
<!--$ # this is not a comment, just text -->
fake nextline
<!--$ nextline -->
~~~

### Expected stdout.expected == stdout
### Expected empty == stderr

