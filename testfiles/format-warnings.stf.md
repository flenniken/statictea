stf file, version 0.1.0

# Format Warnings

Test the format function's warning messages.

### File cmd.sh command nonZeroReturn

~~~
$statictea \
  -t tmpl.txt \
  -r result >stdout 2>stderr
~~~

### File tmpl.txt

~~~
$$ block
$$ : v = format("this is {missing}")
$$ : a = "abc"
$$ : b = "def"
$$ : c = 5
$$ : v2 = format("{a} {missing}")
$$ : v3 = format("{a")
$$ : v4 = format("{123}")
$$ : v5 = format("{c}")
$$ : v6 = format("{c$w}")
The var is "{v}".
v2: "{v2}".
v5: "{v5}".
$$ endblock
~~~

### File result.expected

~~~
The var is "{v}".
v2: "{v2}".
v5: "5".
~~~

### File stderr.expected

~~~
tmpl.txt(2): w205: The variable 'missing' wasn't found in the l or f dictionaries.
statement: v = format("this is {missing}")
                      ^
tmpl.txt(6): w205: The variable 'missing' wasn't found in the l or f dictionaries.
statement: v2 = format("{a} {missing}")
                       ^
tmpl.txt(7): w192: No ending bracket.
statement: v3 = format("{a")
                       ^
tmpl.txt(8): w190: Invalid variable name; names start with an ascii letter.
statement: v4 = format("{123}")
                       ^
tmpl.txt(10): w191: Invalid variable name; names contain letters, digits or underscores.
statement: v6 = format("{c$w}")
                       ^
tmpl.txt(11): w58: The replacement variable doesn't exist: v.
tmpl.txt(12): w58: The replacement variable doesn't exist: v2.
~~~

### Expected result == result.expected
### Expected stdout == empty
### Expected stderr == stderr.expected
