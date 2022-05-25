stf file, version 0.1.0

# Test Json Get

Test that you can access non-variable name keys with get.

### File cmd.sh command

~~~
$statictea \
  -s server.json \
  -t tmpl.txt \
  -r result >stdout 2>stderr
~~~

### File tmpl.txt

~~~
$$ block name = get(s, "1-;56abc: 5")
hello {name}
$$ endblock
~~~

### File server.json

~~~
{
  "1-;56abc: 5": "server",
}
~~~

### File result.expected

~~~
hello server
~~~

### Expected result == result.expected
### Expected stdout == empty
### Expected stderr == empty
