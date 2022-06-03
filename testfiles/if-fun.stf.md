stf file, version 0.1.0

# If Function

Test the if0 and if1 functions.

If the condition is 0, return the second parameter, else return
the third parameter. Return 0 for the else case when there is no
third parameter.

~~~
if0(condition: int, then: any, optional else: any) any
~~~

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
$$ : drink4 = if0(0, "tea")
$$ : drink5 = if0(8, "tea")
drink1: {drink1} = tea
drink2: {drink2} = beer
drink3: {drink3} = beer
drink4: {drink4} = tea
drink5: {drink5} = 0
$$ endblock

$$ block
$$ : drink1 = if1(0, "tea", "beer")
$$ : drink2 = if1(1, "tea", "beer")
$$ : drink3 = if1(4, "tea", "beer")
$$ : drink4 = if1(0, "tea")
$$ : drink5 = if1(1, "tea")
drink1: {drink1} = beer
drink2: {drink2} = tea
drink3: {drink3} = beer
drink4: {drink4} = 0
drink5: {drink5} = tea
$$ endblock

Warn that c is 0.
$$ block c = 0
$$ : if0(c, warn("c is 0"))
$$ : if1(c, warn("not hit"))
$$ endblock

Warn that c is 1.
$$ block c = 1
$$ : if1(c, warn("c is 1"))
$$ : if0(c, warn("not hit"))
$$ endblock
~~~

### File result.expected

~~~
drink1: tea = tea
drink2: beer = beer
drink3: beer = beer
drink4: tea = tea
drink5: 0 = 0

drink1: beer = beer
drink2: tea = tea
drink3: beer = beer
drink4: 0 = 0
drink5: tea = tea

Warn that c is 0.

Warn that c is 1.
~~~

### File stdout.expected

~~~
~~~

### File stderr.expected

~~~
tmpl.txt(29): c is 0
tmpl.txt(35): c is 1
~~~

### Expected result == result.expected
### Expected stdout == stdout.expected
### Expected stderr == stderr.expected
