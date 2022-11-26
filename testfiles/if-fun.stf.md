stf file, version 0.1.0

# If Functions

Test the if functions.



### File cmd.sh command nonZeroReturn

~~~
$statictea -t tmpl.txt -r result >stdout 2>stderr
~~~

### File tmpl.txt

~~~
$$ block
$$ : drink1 = if0(0, "tea", "beer")
$$ : drink2 = if0(1, "tea", "beer")
$$ : drink3 = if0(4, "tea", "beer")
$$ : if0(0, "tea")
$$ : if0(8, "tea")
drink1: {drink1} = tea
drink2: {drink2} = beer
drink3: {drink3} = beer
$$ endblock

$$ block
$$ : drink1 = if0(1, "tea", "beer")
$$ : drink2 = if0(0, "tea", "beer")
$$ : drink3 = if0(4, "tea", "beer")
$$ : if0(1, "tea")
$$ : if0(0, "tea")
drink1: {drink1} = beer
drink2: {drink2} = tea
drink3: {drink3} = beer
$$ endblock

Warn that c is 0.
$$ block c = 0
$$ : if0(c, warn("c is 0"))
$$ : if0(cmp(1,c), warn("not hit"))
$$ endblock

Warn that c is 1.
$$ block c = 1
$$ : if0(cmp(1,c), warn("c is 1"))
$$ : if0(c, warn("not hit"))
$$ endblock

$$ nextline a = if(true, 1)
$$ : if(true, 1, 2)
assignment or not

Test number of args.
$$ block
$$ : # No return version takes two arguments:
$$ : if(true, 1, 2)
$$ : # Return version takes three arguments:
$$ : a = if(true, 1)
$$ endblock
~~~

### File result.expected

~~~
drink1: tea = tea
drink2: beer = beer
drink3: beer = beer

drink1: beer = beer
drink2: tea = tea
drink3: beer = beer

Warn that c is 0.

Warn that c is 1.

assignment or not

Test number of args.
~~~

### File stdout.expected

~~~
~~~

### File stderr.expected

~~~
tmpl.txt(25): c is 0
tmpl.txt(31): c is 1
tmpl.txt(35): w212: An if with an assignment takes three arguments.
statement: a = if(true, 1)
                         ^
tmpl.txt(36): w213: An if without an assignment takes two arguments.
statement: if(true, 1, 2)
                     ^
tmpl.txt(42): w213: An if without an assignment takes two arguments.
statement: if(true, 1, 2)
                     ^
tmpl.txt(44): w212: An if with an assignment takes three arguments.
statement: a = if(true, 1)
                         ^
~~~

### Expected result == result.expected
### Expected stdout == stdout.expected
### Expected stderr == stderr.expected
