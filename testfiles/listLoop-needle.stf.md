stf file, version 0.1.0

# Needle in a Haystack

Use listLoop to find a needle in a haystack.

### File cmd.sh command

~~~
$statictea \
  -o tea1.tea \
  -o tea2.tea \
  -t tmpl.txt \
  -r result \
  >stdout 2>stderr
~~~

### File tmpl.txt

~~~
$$ block
haystack = {o.tea1.haystack}
needle = {o.tea1.needle}
found: {o.tea1.found}

haystack = {o.tea2.haystack}

needle: {o.tea2.d.needle}
found: {o.tea2.d.found}
index: {o.tea2.d.ix}

needle: {o.tea2.d2.needle}
found: {o.tea2.d2.found}

needle: {o.tea2.d3.needle}
found: {o.tea2.d3.found}
index: {o.tea2.d3.ix}
$$ endblock
~~~

### File tea1.tea

How to tell whether an element exists in a list using listLoop.

~~~ nim
item-exists = func(ix: int, value: int, needle: int) bool
  ## Return true when needle equals value.
  return((needle == value))

haystack = [5,6,2,3,4,2]
needle = 2
found = listLoop(haystack, needle, l.item-exists)

o.tea1 = dict()
o.tea1.haystack = haystack
o.tea1.needle = needle
o.tea1.found = found
~~~

### File tea2.tea

How to determine the index of an item in a list.

~~~ nim
item-index = func(ix: int, value: int, d: dict) bool
  ## Set d.ix with the index of d.needle when found.
  if((value != d.needle), return(false))
  d.ix = ix
  return(true)

haystack = [5,6,2,3,4,2]
d = dict()
d.needle = 6
found = listLoop(haystack, d, l.item-index)

o.tea2 = dict()
o.tea2.haystack = haystack
o.tea2.d = d
o.tea2.d.found = found

d2 = dict()
d2.needle = 8
found2 = listLoop(haystack, d2, l.item-index)

o.tea2.d2 = d2
o.tea2.d2.found = found2

d3 = dict()
d3.needle = 2
found3 = listLoop(haystack, d3, l.item-index)

o.tea2.d3 = d3
o.tea2.d3.found = found3
~~~

### File result.expected

~~~
haystack = [5,6,2,3,4,2]
needle = 2
found: true

haystack = [5,6,2,3,4,2]

needle: 6
found: true
index: 1

needle: 8
found: false

needle: 2
found: true
index: 2
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
