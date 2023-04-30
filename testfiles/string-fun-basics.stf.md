stf file, version 0.1.0

# String Function

Test the string function.

### File cmd.sh command

~~~
$statictea \
  -o shared.tea \
  -t tmpl.txt \
  -r result \
  >stdout 2>stderr
~~~

### File shared.tea

~~~ nim
o.name = "tea"
o.num = 5
o.realnum = 3.14158
o.list = [1, 2, 3, [], dict()]
d = dict()
d.a = "apple"
d.b = "banana"
d.c = dict()
d.d = []
o.table = d
o.cmp = get(f, "cmp", 0)
~~~

### File tmpl.txt

~~~
The o dictionary variables:

$$ block vars = string(o, "dn", "o")
{vars}
$$ endblock

$$ block
$$ : ooh = "o"
$$ : a = 5
$$ : localDict = dict(["a", 1])
$$ : emptyLocalDict = dict()
$$ : g.dotNames = string(l, "dn", "l")
$$ : g.dotNames2 = string(l, "dn", "")
$$ : g.varsJson = string(l, "json")
The local variables as rb:

{l}

The local variables as dot-names:

{g.dotNames}

The local variables as dot-names2:

{g.dotNames2}

The local variables as json:

{g.varsJson}
$$ endblock
~~~

### File server.json

~~~
{
}
~~~

### File result.expected

~~~
The o dictionary variables:

o.name = "tea"
o.num = 5
o.realnum = 3.14158
o.list = [1,2,3,[],{}]
o.table.a = "apple"
o.table.b = "banana"
o.table.c = {}
o.table.d = []
o.cmp = ["cmp","cmp","cmp"]

The local variables as rb:

{"ooh":"o","a":5,"localDict":{"a":1},"emptyLocalDict":{}}

The local variables as dot-names:

l.ooh = "o"
l.a = 5
l.localDict.a = 1
l.emptyLocalDict = {}

The local variables as dot-names2:

ooh = "o"
a = 5
localDict.a = 1
emptyLocalDict = {}

The local variables as json:

{"ooh":"o","a":5,"localDict":{"a":1},"emptyLocalDict":{}}
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
