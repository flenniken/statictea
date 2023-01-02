stf file, version 0.1.0

# User Function Details

Test the user function details function.

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
$$ block
$$ : d1 = string(functionDetails(o.fn1), "dn")
$$ : d2 = functionDetails(o.fn1)
$$ : p1n = d2.signature.paramNames[0]
$$ : p1t = d2.signature.paramTypes[0]
$$ : rt = d2.signature.returnType
$$ : docComments = join(d2.docComments, "\n")
$$ : statements = join(d2.statements, "\n")
{d1}

a = func("{d2.signature.name}({p1n}: {p1t}) {rt}")
{docComments}
{statements}

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
o.fn1 = func("fn1(num: int, str: string) dict")
  ## Simple function that returns a dictionary.
  dict = dict("one", num, "two", str)
  return(dict)

~~~

### File result.expected

~~~
builtIn = false
signature.optional = false
signature.name = "fn1"
signature.paramNames = ["num","str"]
signature.paramTypes = ["int","string"]
signature.returnType = "dict"
docComments = ["  ## Simple function that returns a dictionary."]
filename = "shared.tea"
lineNum = 1
numLines = 3
statements = ["  dict = dict(\"one\", num, \"two\", str)","  return(dict)"]

a = func("fn1(num: int) dict")
  ## Simple function that returns a dictionary.
  dict = dict("one", num, "two", str)
  return(dict)

~~~

### File stdout.expected

~~~
~~~

### File stderr.expected

~~~
~~~

### Expected result == result.expected
### Expected stdout == stdout.expected
### Expected stderr == stderr.expected
