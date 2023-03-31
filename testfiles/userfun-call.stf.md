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
  -r result \
  >stdout 2>stderr
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

~~~ nim
o.get5 = func() int
  ## Return 5.
  return(5)

u.get6 = func() int
  ## Return 6.
  return(6)

o.nested = func(o: dict) int
  ## Return get5 value.
  length = len("tea")
  # You have access to u functions without passing them in.
  v = u.get6()

  return(l.o.get5())

o.internalVars = func(intNum: int, floatNum: float, str: string) dict
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

get5 = "o.get5"
nested = "o.nested"
internalVars = "o.internalVars"
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
