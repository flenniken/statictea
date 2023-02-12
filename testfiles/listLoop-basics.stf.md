stf file, version 0.1.0

# List Loop

Test the listLoop function example in the function documentation.

### File cmd.sh command

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
o.container => {o.container}
$$ endblock
~~~

### File shared.tea

~~~
b5 = func(ix: int, value: int, container: list) bool
  ## Collect values greater than 5.
  if( (value <= 5), return(false))
  container &= value
  return(false)

o.container = []
list = [2,4,6,8]
stopped = listLoop(list, o.container, b5)
~~~

### File result.expected

~~~
o.container => [6,8]
~~~

### File stdout.expected

~~~
~~~

### File stderr.expected

~~~
~~~

### Expected result == result.expected
### Expected stdout == stdout.expected
### Expected stderr == stderr.expected
