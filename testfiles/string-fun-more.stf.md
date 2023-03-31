stf file, version 0.1.0

# String Functions

Test the first string function.

### File cmd.sh command

~~~
$statictea \
  -s server.json \
  -o shared.tea \
  -t tmpl.txt \
  -r result \
  >stdout 2>stderr
~~~


### File tmpl.txt

~~~
Show the s dictionary which is empty.
$$ block
$$ : empty_optional = string(s)
$$ : empty_rb = string(s, "rb")
$$ : empty_dn = string(s, "dn")
$$ : empty_json = string(s, "json")
default: {empty_optional}
     rb: {empty_rb}
     dn: {empty_dn}
   json: {empty_json}
$$ endblock

Strings are not quoted with rb but they are for the others.

$$ block str = "abc"
$$ : strRb = string(str, "rb")
$$ : strJson = string(str, "json")
$$ : strDn = string(str, "dn")
  rb: {strRb}
json: {strJson}
  dn: {strDn}
$$ endblock

When using dot-names with local variables, the l is left off.

$$ block
$$ : a = 5
$$ : b = dict()
$$ : g.strDn = string(l, "dn")
{g.strDn}
$$ endblock

You can show the l using the second string function.

$$ block
$$ : a = 5
$$ : b = dict()
$$ : g.strDn2 = string("l", l)
{g.strDn2}
$$ endblock

You can show the l using the second string function or not.

$$ block
$$ : a = 5
$$ : b = dict()
$$ : g.strDn3 = string("", l)
{g.strDn3}
$$ endblock
~~~

### File server.json

~~~
{
}
~~~

### File shared.tea

~~~ nim
o.name = "shared"
o.type = "json"
~~~

### File result.expected

~~~
Show the s dictionary which is empty.
default: {}
     rb: {}
     dn: 
   json: {}

Strings are not quoted with rb but they are for the others.

  rb: abc
json: "abc"
  dn: "abc"

When using dot-names with local variables, the l is left off.

a = 5
b = {}

You can show the l using the second string function.

l.a = 5
l.b = {}

You can show the l using the second string function or not.

a = 5
b = {}
~~~

### File stdout.expected

~~~
~~~

### File stderr.expected

~~~
~~~

### File log.filtered.expected

~~~
~~~

### File log.txt.expected

~~~
~~~

### Expected result == result.expected
### Expected stdout == stdout.expected
### Expected stderr == stderr.expected
