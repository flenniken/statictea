stf file, version 0.1.0

# Echo

Test the echo function.

### File cmd.sh command

~~~
$statictea \
  -o shared.tea \
  -t tmpl.txt \
  -r result \
  >stdout 2>stderr
~~~

### File tmpl.txt

~~~
$$ nextline echo("tmpl.txt")
$$ : echo("continue")
$$ : c = echo("continue2")
a line: {c}
$$ block t.repeat = 3
$$ : echo(format("row = {t.row}"))
$$ : if((t.row == 2), echo("the 2 row"))
block {t.row}
$$ endblock
~~~

### File shared.tea

~~~
echo("shared.tea")
~~~

### File result.expected

~~~
a line: continue2
block 0
block 1
block 2
~~~

### File stdout.expected

~~~
shared.tea
tmpl.txt
continue
continue2
row = 0
row = 1
row = 2
the 2 row
~~~

### File stderr.expected

~~~
~~~

### Expected result == result.expected
### Expected stdout == stdout.expected
### Expected stderr == stderr.expected
