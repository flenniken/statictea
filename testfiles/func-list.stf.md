stf file, version 0.1.0

# Func List

Test calling a list of user functions.

### File cmd.sh command

~~~
$statictea \
  -s server.json \
  -o shared.tea \
  -t tmpl.txt \
  -r result \
  >stdout 2>stderr
~~~

### File tmpl.txt

~~~
$$ nextline
$$ : msg = o.myfunc("world")
$$ : num = o.myfunc(2)
{msg} {num}
~~~

### File server.json

~~~
{}
~~~

### File shared.tea

~~~
hello = func(msg: string) string
  ## Format hello message.
  str = format("hello {msg}")
  return(str)

double = func(num: int) int
  ## Return twice the number passed in.
  return(add(num, num))

o.myfunc = [hello, double]
~~~

### File result.expected

~~~
hello world 4
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
