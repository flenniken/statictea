stf file, version 0.1.0

# Fibonacci Sequence

# Test recursion using the fibonacci sequence.

>>> def fibonacci_of(n):
...     if n in {0, 1}:  # Base case
...         return n
...     return fibonacci_of(n - 1) + fibonacci_of(n - 2)  # Recursive case


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
fig(0) = {o.fib0}
fig(1) = {o.fib1}
fig(2) = {o.fib2}
fig(3) = {o.fib3}
fig(4) = {o.fib4}
$$ endblock
~~~

### File shared.tea

~~~
cache = dict(["t0", 0, "t1", 1])
u.fib = func(term: int, cache: dict) int
  ## Return the nth term of the fibonacci sequence.
  key = format("t{term}")
  if(exists(cache, key), return(cache[key]))
  value = add(u.fib(sub(term, 1), cache), u.fib(sub(term, 2), cache))
  cache[key] = value
  return(value)

o.fib0 = u.fib(0, cache)
o.fib1 = u.fib(1, cache)
o.fib2 = u.fib(2, cache)
o.fib3 = u.fib(3, cache)
o.fib4 = u.fib(4, cache)

fib = u.fib(25, cache)
echo(string(values(cache)))

~~~

### File result.expected

~~~
fig(0) = 0
fig(1) = 1
fig(2) = 1
fig(3) = 2
fig(4) = 3
~~~

### File stdout.expected

~~~
[0,1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,1597,2584,4181,6765,10946,17711,28657,46368,75025]
~~~

### File stderr.expected

~~~
~~~

### Expected result == result.expected
### Expected stdout == stdout.expected
### Expected stderr == stderr.expected
