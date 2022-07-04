stf file, version 0.1.0

# Update Replace Block

Update the replace block in a template.

### File cmd.sh command

~~~
$statictea -u -o shared.tea -t template.html >stdout 2>stderr
~~~

### File shared.tea

~~~
o.header = "<html>\n"
~~~

### File template.html

~~~
line
<!--$ replace t.content = o.header -->
replacement block
<!--$ endblock -->
ending line
~~~

### File newtemplate

~~~
line
<!--$ replace t.content = o.header -->
<html>
<!--$ endblock -->
ending line
~~~

### Expected template.html == newtemplate
### Expected stdout == empty
### Expected stderr == empty

