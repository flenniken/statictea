stf file, version 0.1.0

# IF Two Parameters

Test an IF statement with two parameters.

### File cmd.sh command nonZeroReturn

~~~
$statictea \
  -o shared.tea \
  -t tmpl.txt \
  -r result \
  >stdout 2>stderr
~~~


### File tmpl.txt

~~~
$$ block
$$ : a1 = if(true, 5)
$$ : a2 = if(false, 5)
$$ : a3 &= if(true, 5)
$$ : a3 &= if(false, 4)

a1 = {a1} = 5
a2 = {a2} = {{a2}
a3 = {a3} = [5]
$$ endblock

$$ block
$$ : if(true, 5)
$$ : if(false, 5)
$$ endblock

$$ block
$$ : if(true, warn("expected this"))
$$ : if(false, warn("unexpected 1"))
$$ endblock

$$ block
$$ : a = len(if(true, "tea"))
$$ : b = len(if(false, "tea"))
$$ endblock

$$ block
$$ : if(true, return("skip"))
unexpected 2
$$ endblock

$$ block
$$ : if(false, return("skip"))
I expect this.
$$ endblock

$$ block
$$ : a = if(true, return("skip"))
expect this because using return wrong
$$ endblock

$$ block
$$ : a = if(false, return("skip"))
a = {a} = {{a}
expect this because using return wrong2
$$ endblock
~~~

### File shared.tea

~~~
~~~

### File result.expected

~~~

a1 = 5 = 5
a2 = {a2} = {a2}
a3 = [5] = [5]





I expect this.

expect this because using return wrong

a = {a} = {a}
expect this because using return wrong2
~~~

### File stdout.expected

~~~
~~~

### File stderr.expected

~~~
tmpl.txt(8): w58: The replacement variable doesn't exist: a2.
tmpl.txt(18): expected this
tmpl.txt(23): w267: A two parameter IF function cannot be used as an argument.
statement: a = len(if(true, "tea"))
                                 ^
tmpl.txt(24): w267: A two parameter IF function cannot be used as an argument.
statement: b = len(if(false, "tea"))
                                  ^
tmpl.txt(38): w255: Invalid return; use a bare return in a user function or use it in a bare if statement.
statement: a = if(true, return("skip"))
                        ^
tmpl.txt(44): w58: The replacement variable doesn't exist: a.
~~~

### Expected result == result.expected
### Expected stdout == stdout.expected
### Expected stderr == stderr.expected
