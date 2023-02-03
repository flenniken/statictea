stf file, version 0.1.0

# Test Format Function

Test the format function.

### File cmd.sh command

~~~
$statictea \
  -t tmpl.txt \
  -r result \
  >stdout 2>stderr
~~~

### File tmpl.txt

~~~
$$ block
$$ : name = "Earl Grey"
$$ : greeting = format("Hello {name}")
$$ : a = "apple"
$$ : b = "banana"
$$ : line = format("{a}, {b}")
Hello {name}
{greeting}
Line: {line}
$$ endblock
~~~

### File result.expected

~~~
Hello Earl Grey
Hello Earl Grey
Line: apple, banana
~~~

### Expected result == result.expected
### Expected stdout == empty
### Expected stderr == empty
