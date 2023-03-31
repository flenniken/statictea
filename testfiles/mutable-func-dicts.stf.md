stf file, version 0.1.0

# Mutable Function Dicts

Test that you cannot change the dictionaries returned by built-in
functions, except the dict function.

### File cmd.sh command nonZeroReturn

~~~
$statictea \
  -o shared.tea \
  -t tmpl.txt \
  -r result >stdout 2>stderr
~~~

### File tmpl.txt

~~~
$$ block path = string(o.path, "dn")
$$ : d = string(o.d, "dn")
$$ : signature = string("signature", o.fd.signature)
Path:

{path}

Signature:

{signature}

Statements:

{o.fd.statements}

d:

{d}
$$ endblock
~~~

### File shared.tea

~~~ nim
o.path = path("filename.tif")
o.path.abc = 5

o.fd = functionDetails(f.cmp[0])
o.fd.extra = 4
o.fd.signature.paramNames &= 5
o.fd.signature.paramTypes &= 6

o.fd.signature.abc &= 7

o.fd.signature.def &= 8
o.fd.statements &= 9

o.d = dict(["a", "apple"])
o.d.b = "banana"
~~~

### File result.expected

~~~
Path:

filename = "filename.tif"
basename = "filename"
ext = ".tif"
dir = ""

Signature:

signature.optional = false
signature.name = "cmp"
signature.paramNames = ["a","b"]
signature.paramTypes = ["float","float"]
signature.returnType = "int"

Statements:

[]

d:

a = "apple"
b = "banana"
~~~

### File stdout.expected

~~~
~~~

### File stderr.expected

~~~
shared.tea(2): w261: You cannot assign to an immutable dictionary.
statement: o.path.abc = 5
           ^
shared.tea(5): w261: You cannot assign to an immutable dictionary.
statement: o.fd.extra = 4
           ^
shared.tea(6): w262: You cannot append to an immutable list.
statement: o.fd.signature.paramNames &= 5
           ^
shared.tea(7): w262: You cannot append to an immutable list.
statement: o.fd.signature.paramTypes &= 6
           ^
shared.tea(9): w263: You cannot create a new list element in the immutable dictionary.
statement: o.fd.signature.abc &= 7
           ^
shared.tea(11): w263: You cannot create a new list element in the immutable dictionary.
statement: o.fd.signature.def &= 8
           ^
shared.tea(12): w262: You cannot append to an immutable list.
statement: o.fd.statements &= 9
           ^
~~~

### Expected result == result.expected
### Expected stdout == stdout.expected
### Expected stderr == stderr.expected
