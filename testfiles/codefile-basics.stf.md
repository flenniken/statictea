stf file, version 0.1.0

# Test Code File

Test using a code file.

### File cmd.sh command nonZeroReturn

~~~
$statictea \
  -o codefile.tea \
  -o codefile2.tea \
  -t tmpl.txt \
  -r result >stdout 2>stderr
~~~


### File tmpl.txt

~~~
$$ block
o.a = {o.a}
o.b = {o.b}
o.c = {o.c}
o.d = {o.d}
o.e = {o.e}
o.x = {o.x}
o.xLen = {o.xLen}
o.sum = {o.sum}
$$ endblock

$$ block o.hello = "not allowed"
$$ endblock
~~~

### File codefile.tea

~~~
# codefile.tea

o.a = 5
o.b = 3.4
o.c = "string"
o.d = dict(["g", 1, "h", 2])
o.e = [1, 2, 3]
o.x = """
Black
Green
White"""
o.xLen = len(o.x)
o.sum = add(o.a, int(o.b))
~~~

### File codefile2.tea

~~~
# You can stop in a code file but not skip or other values.
return(1)
return("skip")
echo("after skip")
return("stop")
echo("after stop")
~~~

### File result.expected

~~~
o.a = 5
o.b = 3.4
o.c = string
o.d = {"g":1,"h":2}
o.e = [1,2,3]
o.x = Black
Green
White
o.xLen = 17
o.sum = 8

~~~

### File stdout.expected

~~~
after skip
~~~

### File stderr.expected

~~~
codefile2.tea(2): w177: Expected 'skip' or 'stop' for the return function value.
statement: return(1)
           ^
codefile2.tea(3): w187: Use '...return("stop")...' in a code file.
statement: return("skip")
           ^
tmpl.txt(12): w182: You can only change code variables (o dictionary) in code files.
statement: o.hello = "not allowed"
           ^
~~~

### Expected result == result.expected
### Expected stdout == stdout.expected
### Expected stderr == stderr.expected
