stf file, version 0.1.0

# If Three Parameters

Test the three parameter if functions.

### File cmd.sh command nonZeroReturn

~~~
$statictea \
  -t tmpl.txt \
  -r result \
  >stdout 2>stderr
~~~

### File tmpl.txt

~~~
Test three parameter if.
$$ block
$$ : drink1 = if(true, "tea", "beer")
$$ : drink2 = if(false, "tea", "beer")
{drink1} = tea
{drink2} = beer
$$ endblock

Test three parameter if0.
$$ block
$$ : drink1 = if0(0, "tea", "beer")
$$ : drink2 = if0(1, "tea", "beer")
$$ : drink3 = if0(4, "tea", "beer")
{drink1} = tea
{drink2} = beer
{drink3} = beer
$$ endblock

Test three parameter if as an argument.
$$ block
$$ : drink1 = len(if0(0, "tea", "beer"))
$$ : drink2 = len(if0(1, "tea", "beer"))
{drink1} = 3
{drink2} = 4
$$ endblock

Test bare three parameter if, expect warning.
$$ block
$$ : if(true, "tea", "beer")
$$ endblock

Test with 4 args, expect warnings.
$$ block
$$ : a = if(true, "tea", "beer", "wine")
$$ : if(true, "tea", "beer", "wine")
$$ endblock

Test with 1 args, expect warnings.
$$ block
$$ : a = if(true)
$$ : if(true)
$$ : a = if(false)
$$ : if(false)
$$ endblock
~~~

### File result.expected

~~~
Test three parameter if.
tea = tea
beer = beer

Test three parameter if0.
tea = tea
beer = beer
beer = beer

Test three parameter if as an argument.
3 = 3
4 = 4

Test bare three parameter if, expect warning.

Test with 4 args, expect warnings.

Test with 1 args, expect warnings.
~~~

### File stdout.expected

~~~
~~~

### File stderr.expected

~~~
tmpl.txt(29): w213: A bare IF without an assignment takes two arguments.
statement: if(true, "tea", "beer")
                         ^
tmpl.txt(34): w203: No matching end right parentheses.
statement: a = if(true, "tea", "beer", "wine")
                                     ^
tmpl.txt(35): w213: A bare IF without an assignment takes two arguments.
statement: if(true, "tea", "beer", "wine")
                         ^
tmpl.txt(40): w179: The function requires at least 2 arguments.
statement: a = if(true)
                  ^
tmpl.txt(41): w213: A bare IF without an assignment takes two arguments.
statement: if(true)
              ^
tmpl.txt(42): w179: The function requires at least 2 arguments.
statement: a = if(false)
                  ^
tmpl.txt(43): w213: A bare IF without an assignment takes two arguments.
statement: if(false)
              ^
~~~

### Expected result == result.expected
### Expected stdout == stdout.expected
### Expected stderr == stderr.expected
