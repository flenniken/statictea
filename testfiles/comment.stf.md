stf file, version 0.1.0

## The comment readme example.

### File cmd.sh command

~~~
$statictea -t=hello.html >stdout 2>stderr
~~~

### File hello.html noLastEnding

~~~
<!--$ # The main tea groups. -->
There are five main groups of teas:
white, green, oolong, black, and pu'erh.
You make Oolong Tea in five time
intensive steps.
~~~

### File stdout.expected noLastEnding

~~~
There are five main groups of teas:
white, green, oolong, black, and pu'erh.
You make Oolong Tea in five time
intensive steps.
~~~

### File stderr.expected

~~~
~~~

### Expected stdout.expected == stdout
### Expected stderr.expected == stderr

