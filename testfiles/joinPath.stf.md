stf file, version 0.1.0

# Test joinPath

Test the joinPath function.

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
$$ endblock
~~~

### File shared.tea

~~~ nim
u.got-expected = func(got: string, expected: string) bool
  ## Test that got equals expected. When it does return true,
  ## else generate a warning and show the differences.
  pattern = """

     got: {got}
expected: {expected}
"""
  if((got != expected), warn(format(pattern)))
  return(true)

e &= u.got-expected(joinPath(["tea", "pot"]), "tea/pot")
e &= u.got-expected(joinPath(["tea", "hot", ""]), "tea/hot/")
e &= u.got-expected(joinPath(["", "tea", "cool"]), "/tea/cool")
e &= u.got-expected(joinPath(["", "tea", "cool", ""]), "/tea/cool/")
e &= u.got-expected(joinPath([]), "")
e &= u.got-expected(joinPath([""]), "/")
e &= u.got-expected(joinPath(["abc"]), "abc")
e &= u.got-expected(joinPath(["", "tea"]), "/tea")
e &= u.got-expected(joinPath(["tea", ""]), "tea/")
e &= u.got-expected(joinPath(["", "tea"], "/"), "/tea")
e &= u.got-expected(joinPath(["net:", "", "", "cold"], "\\"), "net:\\\\cold")
~~~

### File result.expected

~~~
~~~

### File stdout.expected

~~~
~~~

### File stderr.expected

~~~
~~~

### File log.filtered.expected

~~~
~~~

### File log.txt.expected

~~~
~~~

### Expected result == result.expected
### Expected stdout == stdout.expected
### Expected stderr == stderr.expected
