stf file, version 0.1.0

# Update Template

Test updating a template with the update option.

### File cmd.sh command

~~~
$statictea -u \
  -o shared.tea \
  -t template.html \
  >stdout 2>stderr
~~~

### File template.html

~~~
<!--$ replace t.content = o.header -->
this is where the header goes
<!--$ endblock -->

<!--$ replace t.content = o.menu -->
the menu goes here
<!--$ endblock -->

<!--$ replace t.content = o.footer -->
footer location
<!--$ endblock -->
~~~

### File shared.tea

~~~ nim
o.header = "=== header ==="
o.menu = "pick an option"
o.footer = "=== footer ==="
~~~

### File template.expected

~~~
<!--$ replace t.content = o.header -->
=== header ===
<!--$ endblock -->

<!--$ replace t.content = o.menu -->
pick an option
<!--$ endblock -->

<!--$ replace t.content = o.footer -->
=== footer ===
<!--$ endblock -->
~~~

### Expected template.html == template.expected
### Expected stdout == empty
### Expected stderr == empty
