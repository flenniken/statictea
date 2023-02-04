stf file, version 0.1.0

# If Two Parameters

Test the IF statement with two parameters.

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
$$ endblock
~~~

### File shared.tea

~~~
warn("todo: not done")
# if(true, warn("expected this"))
# if(false, warn("should not hit this"))

# a1 = if(true, warn("expected this"))
# a2 = if(false, warn("should not hit this"))

# a3 = if(true, 5)
# a4 = if(false, 6)

# teas &= if(true, "Eary Grey")
# teas &= if(false, "Beer")
~~~

### File result.expected

~~~
~~~

### File stdout.expected

~~~
~~~

### File stderr.expected

~~~
shared.tea(1): todo: not done
~~~

### Expected result == result.expected
### Expected stdout == stdout.expected
### Expected stderr == stderr.expected
