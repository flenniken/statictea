stf file, version 0.1.0

# Continue Line

The continue readme example.

### File cmd.sh command

~~~
$statictea -t comment.html >stdout 2>stderr
~~~

### File comment.html

~~~
$$ nextline
$$ : tea = "Earl Grey"
$$ : tea2 = "Masala chai"
{tea}, {tea2}
~~~

### File stdout.expected

~~~
Earl Grey, Masala chai
~~~

### Expected stdout == stdout.expected
### Expected stderr == empty

