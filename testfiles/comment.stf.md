stf file, version 0.1.0

# Readme Command Example

The readme comment example.

### File cmd.sh command

~~~
$statictea -t hello.html >stdout 2>stderr
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

### Expected stdout == stdout.expected
### Expected stderr == empty

