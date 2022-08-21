stf file, version 0.1.0

# Local Variables

Test the readme local variables section.

You create local variables with template statements.  They are local
to the command where they are defined. You do not have to specify a
prefix for local variables but you can use l. They are stored in the l
dictionary. The local variables are cleared and recalculated for each
repeated block.

### File cmd.sh command nonZeroReturn

~~~
$statictea -t template.html -r result.html >stdout 2>stderr
~~~

### File template.html

~~~
$$ block
$$ : tea = "black"
$$ : l.a = 5
tea => {tea}
l.tea => {l.tea}
a => {a}
l.a => {l.a}
$$ endblock

# The local variables are not defined in this block.
$$ block
tea => {tea}
l.tea => {l.tea}
a => {a}
l.a => {l.a}
$$ endblock

# The local variables are cleared and recalculated for each repeated
# block.
$$ block t.repeat = 2
$$ : before = if0(cmp(bool(1),exists(l, "x")), "exists", "doesn't exist")
$$ : x = add(t.row, 1)
$$ : after = if0(cmp(bool(1),exists(l, "x")), "exists", "doesn't exist")

{x}. Before defining x it {before}.
{x}. After defining x it {after}.
$$ endblock
~~~

### File result.expected

~~~
tea => black
l.tea => black
a => 5
l.a => 5

# The local variables are not defined in this block.
tea => {tea}
l.tea => {l.tea}
a => {a}
l.a => {l.a}

# The local variables are cleared and recalculated for each repeated
# block.

1. Before defining x it doesn't exist.
1. After defining x it exists.

2. Before defining x it doesn't exist.
2. After defining x it exists.
~~~

### File stderr.expected

~~~
template.html(12): w58: The replacement variable doesn't exist: tea.
template.html(13): w58: The replacement variable doesn't exist: l.tea.
template.html(14): w58: The replacement variable doesn't exist: a.
template.html(15): w58: The replacement variable doesn't exist: l.a.
~~~

### Expected result.html == result.expected
### Expected stdout == empty
### Expected stderr == stderr.expected

