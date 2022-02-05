stf file, version 0.1.0

# Global Variables

Test global variables.

Like local variables, you create global variables with template
statements.  All commands have access to them and they are stored in
the g dictionary.

### File cmd.sh command nonZeroReturn

~~~
$statictea -t=template.html -r=result.html >stdout 2>stderr
~~~

### File template.html

~~~
Use the undefined global.
$$ nextline
g.name => {g.name}

$$ # Define the g.name global.
$$ block g.name = "tea"
$$ endblock

Use the global variable.
$$ nextline
g.name => {g.name}


Use the global variable again.
$$ nextline
g.name => {g.name}
~~~

### File result.expected

~~~
Use the undefined global.
g.name => {g.name}


Use the global variable.
g.name => tea


Use the global variable again.
g.name => tea
~~~

### File stderr.expected

~~~
template.html(3): w58: The replacement variable doesn't exist: g.name.
~~~

### Expected result.html == result.expected
### Expected stdout == empty
### Expected stderr == stderr.expected
