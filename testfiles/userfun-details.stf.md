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
$$ : fd = functionDetails(o.fn1)
$$ : # fd.mutate = 5
$$ : d1 = string(fd, "dn")
$$ : d2 = functionDetails(o.fn1)
$$ : p1n = d2.signature.paramNames[0]
$$ : p1t = d2.signature.paramTypes[0]
$$ : rt = d2.signature.returnType
$$ : docComment = d2.docComment
$$ : # todo: add a stripEnding function?
$$ : statements = join(d2.statements, "\n")
{d1}

a = func({p1n}: {p1t}) {rt}
{docComment}{statements}

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
o.fn1 = func(num: int, str: string) dict
  ## Simple function that returns a dictionary.
  dict = dict("one", num, "two", str)
  return(dict)

~~~

### File result.expected

~~~
builtIn = false
signature.optional = false
signature.name = "o.fn1"
signature.paramNames = ["num","str"]
signature.paramTypes = ["int","string"]
signature.returnType = "dict"
docComment = "  ## Simple function that returns a dictionary.\n"
filename = "shared.tea"
lineNum = 1
numLines = 3
statements = ["  dict = dict(\"one\", num, \"two\", str)","  return(dict)"]

a = func(num: int) dict
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
