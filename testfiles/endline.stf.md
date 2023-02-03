stf file, version 0.1.0

# ReadMeFun Extra Lines

Test there are no extra lines for the readmefun case.

### File cmd.sh command

~~~
$statictea \
  -p "# $" \
  -t endline.org \
  >stdout 2>stderr
~~~

### File endline.org

~~~
# $ block name = "endline"
# $ : t.repeat = 2
# $ : description = "looking for extra newlines"
** {name}()
:PROPERTIES:
:CUSTOM_ID: {name}
:END:

{description}
# $ endblock
===
~~~

### File stdout.expected

~~~
** endline()
:PROPERTIES:
:CUSTOM_ID: endline
:END:

looking for extra newlines
** endline()
:PROPERTIES:
:CUSTOM_ID: endline
:END:

looking for extra newlines
===
~~~

### Expected stdout == stdout.expected
### Expected stderr == empty

