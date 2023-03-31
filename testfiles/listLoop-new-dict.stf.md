stf file, version 0.1.0

# List Loop Dict

Test the listLoop function where it creates a dictionary.

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
$$ block dn = string("container", o.container)
{dn}
$$ endblock
~~~

### File shared.tea

~~~ nim
callback = func(ix: int, value: int, container: dict) bool
  ## Add key for each value mapping to its index.
  key = concat("a", string(value))
  container[key] = ix
  return(false)

o.container = dict()
list = [2,4,5,1]
stopped = listLoop(list, o.container, callback)
~~~

### File result.expected

~~~
container.a2 = 0
container.a4 = 1
container.a5 = 2
container.a1 = 3
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
