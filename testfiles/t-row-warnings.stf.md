stf file, version 0.1.0

# t.row Warnings

Test t row warnings.

### File cmd.sh command nonZeroReturn

~~~
$statictea \
  -l log.txt \
  -t tmpl.txt \
  -r result.html \
  >stdout 2>stderr
~~~

### File log.sh command

~~~
cat log.txt | cut -c 26- | grep "^tmpl.txt" >log.filtered | true
~~~


### File tmpl.txt

~~~
Assign 5 to t.row.
$$ block t.row = 5
{t.row}
$$ endblock
~~~


### File result.expected

~~~
Assign 5 to t.row.
0
~~~

### File stdout.expected

~~~
~~~

### File stderr.expected

~~~
tmpl.txt(2): w39: You cannot change the t.row tea variable.
statement: t.row = 5
           ^
~~~

### Expected stdout == stdout.expected
### Expected stderr == stderr.expected
### Expected log.filtered == empty
### Expected result.expected == result.html
