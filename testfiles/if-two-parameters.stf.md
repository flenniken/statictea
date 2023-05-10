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

~~~ nim
if(true, warn("expected this"))
if(false, warn("should not hit this"))

a1 = if(true, warn("expected this"))
if(exists(l, "a1"), warn("failed"))

a2 = if(false, warn("should not hit this"))
if(exists(l, "a2"), warn("failed"))

a3 = if(true, 5)
if((a3 != 5), warn("failed"))

a4 = if(false, 6)
if(exists(l, "a4"), warn("failed"))

teas &= if(true, "Eary Grey")
teas &= if(false, "Beer")

echo(string(teas))
~~~

### File result.expected

~~~
~~~

### File stdout.expected

~~~
["Eary Grey"]
~~~

### File stderr.expected

~~~
shared.tea(1): expected this
shared.tea(4): expected this
~~~

### Expected result == result.expected
### Expected stdout == stdout.expected
### Expected stderr == stderr.expected
