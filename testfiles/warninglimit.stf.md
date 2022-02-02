stf file, version 0.1.0

# Warning Limit

Test that warnings stop after 11.

### File cmd.sh command nonZeroReturn

~~~
$statictea -t=template.html -r=result.html >stdout 2>stderr
~~~

### File template.html

~~~
$$ nextline
$$ : t.repeat = 12
$$ : num = add(t.row, 1)
{num}. {name}
~~~

### File result.expected

~~~
1. {name}
2. {name}
3. {name}
4. {name}
5. {name}
6. {name}
7. {name}
8. {name}
9. {name}
10. {name}
11. {name}
12. {name}
~~~

### File stdout.expected

~~~
~~~

### File stderr.expected

~~~
template.html(4): w58: The replacement variable doesn't exist: name.
template.html(4): w58: The replacement variable doesn't exist: name.
template.html(4): w58: The replacement variable doesn't exist: name.
template.html(4): w58: The replacement variable doesn't exist: name.
template.html(4): w58: The replacement variable doesn't exist: name.
template.html(4): w58: The replacement variable doesn't exist: name.
template.html(4): w58: The replacement variable doesn't exist: name.
template.html(4): w58: The replacement variable doesn't exist: name.
template.html(4): w58: The replacement variable doesn't exist: name.
template.html(4): w58: The replacement variable doesn't exist: name.
template.html(4): w116: You reached the maximum number of warnings, suppressing the rest.
~~~

### Expected result.html == result.expected
### Expected stdout == stdout.expected
### Expected stderr == stderr.expected
