stf file, version 0.1.0

# User Functions

Test user functions.

### File cmd.sh command

~~~
$statictea \
  -l log.txt \
  -s server.json \
  -o shared.tea \
  -t tmpl.txt \
  -r result >stdout 2>stderr
~~~

### File tmpl.txt

~~~
$$ block
$$ : a = o.get5()
$$ : b = o.nested(o)
$$ : o_vars = string(o, "dn")
$$ : myvars = o.internalVars(1, 2.2, "hello")
{a} == 5 == {b}

The o dictionary local variables:

{o.locals}

The o dictionary variables:

{o_vars}

The variables available inside "internalVars" function.

{myvars}

$$ endblock
~~~

### File server.json

~~~
{
  "name": "server",
  "type": "json"
}
~~~

### File shared.tea

~~~
o.get5 = func("get5() int")
  ## Return 5.
  return(5)

o.nested = func("nested(o: dict) int")
  ## Return get5 value.
  return(l.o.get5())

o.internalVars = func("internalVars(intNum: int, floatNum: float, str: string) dict")
  ## Return the variables available in this function.
  return(l)

name = "shared.tea"
five = 5

o.locals = string(l, "dn")
~~~

### File result.expected

~~~
5 == 5 == 5

The o dictionary local variables:

name = "shared.tea"
five = 5

The o dictionary variables:

get5 = "get5"
nested = "nested"
internalVars = "internalVars"
locals = "name = \"shared.tea\"\nfive = 5"

The variables available inside "internalVars" function.

{"intNum":1,"floatNum":2.2,"str":"hello"}

~~~

### File stdout.expected

~~~
~~~

### File stderr.expected

~~~
~~~

Expected gotFile == expectedFile

### Expected result == result.expected
### Expected stdout == stdout.expected
### Expected stderr == stderr.expected
