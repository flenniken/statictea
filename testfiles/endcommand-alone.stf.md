stf file, version 0.1.0

# Test Endcommand

Test endcommand without a block command.

### File cmd.sh command nonZeroReturn

~~~
$statictea \
  -t tmpl.txt \
  -r result >stdout 2>stderr
~~~

### File tmpl.txt

~~~
some text
without a block command in site
$$ endblock
$$ endblock
asdf

$$ endblock
~~~


### File result.expected

~~~
some text
without a block command in site
$$ endblock
$$ endblock
asdf

$$ endblock
~~~

### File stderr.expected

~~~
tmpl.txt(3): w144: The endblock command does not have a matching block command.
tmpl.txt(4): w144: The endblock command does not have a matching block command.
tmpl.txt(7): w144: The endblock command does not have a matching block command.
~~~

### Expected result == result.expected
### Expected stdout == empty
### Expected stderr == stderr.expected
