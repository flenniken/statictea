stf file, version 0.1.0

# Test Update Readonly

Test update with a read only template.

Here are the file line attributes:

### File readonly.sh command

Set the template file read only.

~~~
chmod 444 tmpl.txt
chmod 444 test.txt
~~~

### File test.txt

Extra file to make sure the chmod works.

~~~
just another test file
~~~

### File cmd.sh command nonZeroReturn

~~~
$statictea -u -t tmpl.txt >stdout 2>stderr
~~~

### File tmpl.txt

~~~
$$ replace t.content = "my shared content"
asdf
$$ endblock
~~~

### File tmpl.expected

~~~
$$ replace t.content = "my shared content"
asdf
$$ endblock
~~~

### File stderr.expected

~~~
nofile(0): w178: Cannot update the readonly template.
~~~

### Expected tmpl.txt == tmpl.expected
### Expected stdout == empty
### Expected stderr == stderr.expected
