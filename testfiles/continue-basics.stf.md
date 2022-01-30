stf file, version 0.1.0

## The continue readme example.

### File cmd.sh command

~~~
$statictea -t=comment.html >stdout 2>stderr
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

### File stderr.expected

~~~
~~~

### Expected stdout.expected == stdout
### Expected stderr.expected == stderr

