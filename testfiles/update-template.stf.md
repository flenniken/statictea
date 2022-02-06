stf file, version 0.1.0

# Update Template

Test updating a template with the update option.

### File cmd.sh command

~~~
$statictea -u -j=shared.json -t=template.html >stdout 2>stderr
~~~

### File template.html

~~~
<!--$ replace t.content = h.header -->
this is where the header goes
<!--$ endblock -->

<!--$ replace t.content = h.menu -->
the menu goes here
<!--$ endblock -->

<!--$ replace t.content = h.footer -->
footer location
<!--$ endblock -->
~~~

### File shared.json

~~~
{
  "header": "=== header ===\n",
  "menu": "pick an option\n",
  "footer": "=== footer ===\n"
}
~~~

### File template.expected

~~~
<!--$ replace t.content = h.header -->
=== header ===
<!--$ endblock -->

<!--$ replace t.content = h.menu -->
pick an option
<!--$ endblock -->

<!--$ replace t.content = h.footer -->
=== footer ===
<!--$ endblock -->
~~~

### Expected template.html == template.expected
### Expected stdout == empty
### Expected stderr == empty