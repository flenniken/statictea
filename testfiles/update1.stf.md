stf file, version 0.1.0

## Update the replace block in a template.

### File cmd.sh command

~~~
$statictea -u -j=shared.json -t=template.html >stdout 2>stderr
~~~

### File shared.json

~~~
{
 "header": "<html>\n"
}
~~~

### File template.html

~~~
line
<!--$ replace t.content = h.header -->
replacement block
<!--$ endblock -->
ending line
~~~

### File newtemplate

~~~
line
<!--$ replace t.content = h.header -->
<html>
<!--$ endblock -->
ending line
~~~

### File stdout.expected

~~~
~~~

### File stderr.expected

~~~
~~~

### Expected newtemplate == template.html
### Expected stdout.expected == stdout
### Expected stderr.expected == stderr

