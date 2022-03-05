stf file, version 0.1.0

# Template Template

Test inline comments.

Here are the file line attributes:

~~~
noLastEnding command nonZeroReturn
~~~

### File cmd.sh command

~~~
$statictea \
  -t tmpl.txt \
  -r result >stdout 2>stderr
~~~

### File tmpl.txt

~~~
$$ block # comment
$$ : a = 5 # comment
$$ :
$$ : # test # in string
$$ : b = "string with #"
$$ :
$$ : # test escaped quotes in string
$$ : c = "string \"quote\" #"
$$ :
$$ : # test # in string
$$ : d = "# string\n" # comment
a = {a}
b = {b}
c = {c}
d = {d}
end
$$ endblock
~~~

### File result.expected

~~~
a = 5
b = string with #
c = string "quote" #
d = # string

end
~~~

### Expected result == result.expected
### Expected stdout == empty
### Expected stderr == empty
