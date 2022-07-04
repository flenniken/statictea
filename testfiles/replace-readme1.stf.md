stf file, version 0.1.0

# Readme Replace 1

The first replace readme example.

### File cmd.sh command

~~~
$statictea -o replace.tea -t replace.html >stdout 2>stderr
~~~

### File replace.html

~~~
<!--$ replace t.content=o.header -->
<!--$ endblock -->
~~~

### File replace.tea

~~~
o.header = """
<!doctype html>
<html lang="en">
"""
~~~

### File stdout.expected

~~~
<!doctype html>
<html lang="en">
~~~

### Expected stdout == stdout.expected
### Expected stderr == empty

