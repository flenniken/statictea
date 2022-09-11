stf file, version 0.1.0

# len

Test the len function.

### File cmd.sh command nonZeroReturn

~~~
$statictea \
  -t tmpl.txt \
  -r result.html >stdout 2>stderr
~~~

### File tmpl.txt

~~~
$$ block
$$ : str0 = len("")
$$ : list0 = len(list())
$$ : dict0 = len(dict())
$$ : str1 = len("a")
$$ : list1 = len(list(1))
$$ : dict1 = len(dict(list("a", 1)))
$$ : str2 = len("ab")
$$ : list2 = len(list(1, 2))
$$ : dict2= len(dict(list("a", 1, "b", 1)))

str0 => {str0}
list0 => {list0}
dict0 => {dict0}

str1 => {str1}
list1 => {list1}
dict1 => {dict1}

str2 => {str2}
list2 => {list2}
dict2 => {dict2}
$$ endblock

$$ block
$$ : a = len(0)
$$ : b = len(1.0)
$$ : c = len("tea")
$$ : d = len("añyóng")
len("tea") => {c}
len("añyóng") => {d}
$$ endblock
~~~

### File result.expected

~~~

str0 => 0
list0 => 0
dict0 => 0

str1 => 1
list1 => 1
dict1 => 1

str2 => 2
list2 => 2
dict2 => 2

len("tea") => 3
len("añyóng") => 6
~~~

### File stderr.expected

~~~
tmpl.txt(26): w120: Wrong argument type, expected dict.
statement: a = len(0)
                   ^
tmpl.txt(27): w120: Wrong argument type, expected dict.
statement: b = len(1.0)
                   ^
~~~


### Expected result.html == result.expected
### Expected stdout == empty
### Expected stderr == stderr.expected
