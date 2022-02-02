stf file, version 0.1.0

# Update Replace Block

Update the replace block in a template.

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

### Expected template.html == newtemplate
### Expected stdout == empty
### Expected stderr == empty

