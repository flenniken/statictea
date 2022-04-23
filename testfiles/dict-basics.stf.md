stf file, version 0.1.0

# Dictionary

Test the dictionary type.

### File cmd.sh command nonZeroReturn

~~~
$statictea \
  -s server.json \
  -t tmpl.txt \
  -r result >stdout 2>stderr
~~~

### File tmpl.txt

~~~
$$ block
$$ : d = dict(["a", 9, "b", 8, "c", 7])
$$ : a = get(d, "d")
$$ : b = get(d, -1)
$$ : c = get(d, 3)
$$ : e = get(d, 2.2)
Use invalid keys and indexes.
d = {d}
{4} -- 4 is not a variable, no error
d.missing = {d.missing}
$$ endblock

$$ block
Use a dictionary from the server json file.
name = {s.name}
x = {s.d.x}
y = {s.d.y}
$$ endblock

$$ block
$$ : name = get(s, "name")
$$ : x = get(s.d, "x")
$$ : y = get(s.d, "y")
Get the dictionary values by name.
name = {name}
x = {x}
y = {y}
$$ endblock

$$ block
$$ : name = get(s, 0)
$$ : d = get(s, 1)
Get the dictionary values by index.
name = {name}
x = {d.x}
y = {d.y}
$$ endblock

$$ block
$$ : d = dict(["a", 9, "b", 8, "c", 7])
Create a new dictionary.
d = {d}
d.a = {d.a}
d.b = {d.b}
d.c = {d.c}
$$ endblock

~~~

### File server.json

~~~
{
  "name": "server",
  "d": {
    "x": "100",
    "y": "200"
  }
}
~~~

### File result.expected

~~~
Use invalid keys and indexes.
d = {"a":9,"b":8,"c":7}
{4} -- 4 is not a variable, no error
d.missing = {d.missing}

Use a dictionary from the server json file.
name = server
x = 100
y = 200

Get the dictionary values by name.
name = server
x = 100
y = 200

Get the dictionary values by index.
name = server
x = 100
y = 200

Create a new dictionary.
d = {"a":9,"b":8,"c":7}
d.a = 9
d.b = 8
d.c = 7

~~~

### File stdout.expected

~~~
~~~

### File stderr.expected

~~~
tmpl.txt(3): w56: The dictionary does not have an item with key d.
statement: a = get(d, "d")
                      ^
tmpl.txt(4): w74: Index values must greater than or equal to 0, got: -1.
statement: b = get(d, -1)
                      ^
tmpl.txt(5): w172: The dictionary does not have an item with index 3.
statement: c = get(d, 3)
                      ^
tmpl.txt(6): w120: Wrong parameter type, expected string.
statement: e = get(d, 2.2)
                      ^
tmpl.txt(10): w58: The replacement variable doesn't exist: d.missing.
~~~

### Expected result == result.expected
### Expected stdout == stdout.expected
### Expected stderr == stderr.expected
