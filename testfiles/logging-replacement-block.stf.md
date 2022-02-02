stf file, version 0.1.0

# Replacement Block Logging

Test logging the replacement block.

### File cmd.sh command

~~~
$statictea -l=log.txt -t=tmpl.txt -r=result.txt >stdout 2>stderr
~~~

### File log.sh command

Remove the time prefix from the log lines then extract the template lines.

~~~
cat log.txt | cut -c 26- | grep "^tmpl.txt" >log.filtered
~~~

### File tmpl.txt

~~~
Log the replacement block.
$$ block t.output = "log"
┌─────────┐
│log block│
└─────────┘
$$ endblock

Log the replacement block containing a variable.
$$ block t.output = "log"
t.output = {t.output}
$$ endblock

Log the replacement block two times.
$$ block t.output = "log"
$$ : t.repeat = 2
t.row = {t.row}
$$ endblock

Log the nextline replacement block.
$$ nextline t.output = "log"
nextline replacement block

Log the replace command's replacement block.
$$ replace t.output = "log"
$$ : t.content = "replace command\n"
not used line
$$ endblock

~~~


### File result.expected

~~~
Log the replacement block.

Log the replacement block containing a variable.

Log the replacement block two times.

Log the nextline replacement block.

Log the replace command's replacement block.

~~~

### File log.filtered.expected

~~~
tmpl.txt(3); ┌─────────┐
tmpl.txt(4); │log block│
tmpl.txt(5); └─────────┘
tmpl.txt(10); t.output = log
tmpl.txt(16); t.row = 0
tmpl.txt(16); t.row = 1
tmpl.txt(21); nextline replacement block
tmpl.txt(26); replace command
~~~

### Expected result.txt == result.expected
### Expected stdout == empty
### Expected stderr == empty
### Expected log.filtered == log.filtered.expected

