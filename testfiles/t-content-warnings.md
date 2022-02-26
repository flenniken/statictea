stf file, version 0.1.0

# t.content Warnings

Test t.content warnings.

### File cmd.sh command nonZeroReturn

~~~
$statictea \
  -l log.txt \
  -t tmpl.txt \
  -r result.html >stdout 2>stderr
~~~

### File log.sh command

~~~
cat log.txt | cut -c 26- | grep "^tmpl.txt" >log.filtered | true
~~~

### File tmpl.txt

~~~
The t.content must be a string.
$$ nextline t.content = 5

The t.content must be a string.
$$ nextline t.content = t.args

The t.content doesn't exist by default.
$$ nextline
$$ : e = if1(exists(t, "content"), "exists", "does not exist")
t.content {e}

The t.content doesn't exist by default for the replace command.
$$ replace
$$ : e = if1(exists(t, "content"), "exists", "does not exist")
t.content {e}
$$ endblock
~~~

### File result.expected

~~~
The t.content must be a string.

The t.content must be a string.

The t.content doesn't exist by default.
t.content does not exist

The t.content doesn't exist by default for the replace command.
t.content does not exist
~~~

### File stderr.expected

~~~
tmpl.txt(2): w43: You must assign t.content a string.
statement: t.content = 5
           ^
tmpl.txt(5): w43: You must assign t.content a string.
statement: t.content = t.args
           ^
tmpl.txt(14): w68: The t.content variable is not set for the replace command, treating it like the block command.
~~~

### Expected stdout == empty
### Expected stderr == stderr.expected
### Expected log.filtered == empty
### Expected result.html == result.expected
