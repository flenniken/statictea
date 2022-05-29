stf file, version 0.1.0

# Slice Warnings

Test the slice functions warning cases.

### File cmd.sh command nonZeroReturn

~~~
$statictea -t tmpl.txt \
  -r result >stdout 2>stderr
~~~

### File tmpl.txt

slice(str: string, start: int, optional length: int) string

~~~
Wrong number of parameters.
$$ block
$$ : s = slice()
$$ : s = slice("string")
$$ : s = slice("string", 0, 4, 3)
$$ : s = slice("string", 0, 4, 3, 7)
$$ endblock

Wrong kind of parameters.
$$ block
$$ : s = slice(5, 0)
$$ : s = slice("string", 2.2)
$$ : s = slice("string", 0, "a")
$$ endblock

Invalid start index.
$$ block
$$ : s = slice("string", -1)
$$ : s = slice("string", 6)
$$ endblock

Invalid length.
$$ block
$$ : s = slice("string", 0, -2)
$$ : s = slice("string", 0, 7)
$$ : s = slice("string", 3, 4)
$$ endblock

~~~

### File result.expected

~~~
Wrong number of parameters.

Wrong kind of parameters.

Invalid start index.

Invalid length.

~~~

### File stdout.expected

~~~
~~~

### File stderr.expected

~~~
tmpl.txt(3): w179: The function requires at least 2 arguments.
statement: s = slice()
                     ^
tmpl.txt(4): w179: The function requires at least 2 arguments.
statement: s = slice("string")
                     ^
tmpl.txt(5): w180: The function requires at most 3 arguments.
statement: s = slice("string", 0, 4, 3)
                                     ^
tmpl.txt(6): w180: The function requires at most 3 arguments.
statement: s = slice("string", 0, 4, 3, 7)
                                     ^
tmpl.txt(11): w120: Wrong parameter type, expected string.
statement: s = slice(5, 0)
                     ^
tmpl.txt(12): w120: Wrong parameter type, expected int.
statement: s = slice("string", 2.2)
                               ^
tmpl.txt(13): w120: Wrong parameter type, expected int.
statement: s = slice("string", 0, "a")
                                  ^
tmpl.txt(18): w154: The start position is less than 0.
statement: s = slice("string", -1)
                               ^
tmpl.txt(19): w152: The start position is greater then the number of characters in the string.
statement: s = slice("string", 6)
                               ^
tmpl.txt(24): w181: The length must be a positive number.
statement: s = slice("string", 0, -2)
                                  ^
tmpl.txt(25): w153: The length is greater then the possible number of characters in the slice.
statement: s = slice("string", 0, 7)
                                  ^
tmpl.txt(26): w153: The length is greater then the possible number of characters in the slice.
statement: s = slice("string", 3, 4)
                                  ^
~~~

### Expected result == result.expected
### Expected stdout == stdout.expected
### Expected stderr == stderr.expected
