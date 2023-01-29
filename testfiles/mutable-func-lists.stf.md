stf file, version 0.1.0

# Mutating Function Lists

Test that you cannot mutate the lists returned by the built-in
functions (except the list function).

# todo: why not allow mutation here?

### File cmd.sh command nonZeroReturn

~~~
$statictea \
  -o shared.tea \
  -t tmpl.txt \
  -r result >stdout 2>stderr
~~~

### File tmpl.txt

~~~
$$ block
{o.anchors} = ["a","b"]
{o.key-list} = ["one","two","three"]
{o.list} = [6,7,8,9]
{o.sortedList} = [4,5,9]
{o.values-list} = [1,2,3]
$$ endblock
~~~

### File shared.tea

~~~
o.anchors = githubAnchor(["a", "b"])
o.anchors &= "c"

d = dict(["one", 1,"two", 2, "three", 3])
o.key-list = keys(d)
o.key-list &= "four"

o.list = list(6, 7, 8)
o.list &= 9

o.sortedList = sort([5, 4, 9], "ascending")
o.sortedList &= 3

o.values-list = values(d)
o.values-list &= 5
~~~

### File result.expected

~~~
["a","b"] = ["a","b"]
["one","two","three"] = ["one","two","three"]
[6,7,8,9] = [6,7,8,9]
[4,5,9] = [4,5,9]
[1,2,3] = [1,2,3]
~~~

### File stdout.expected

~~~
~~~

### File stderr.expected

~~~
shared.tea(2): w262: You cannot append to an immutable list.
statement: o.anchors &= "c"
           ^
shared.tea(6): w262: You cannot append to an immutable list.
statement: o.key-list &= "four"
           ^
shared.tea(12): w262: You cannot append to an immutable list.
statement: o.sortedList &= 3
           ^
shared.tea(15): w262: You cannot append to an immutable list.
statement: o.values-list &= 5
           ^
~~~

### Expected result == result.expected
### Expected stdout == stdout.expected
### Expected stderr == stderr.expected
