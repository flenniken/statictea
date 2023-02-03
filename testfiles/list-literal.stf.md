stf file, version 0.1.0

# Literal Lists

Test literal lists.

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
$$ : a &= []
$$ : a &= [ ]
$$ : a &= [  ]
$$ : a &= [  ] # comment
$$ : b &= [1]
$$ : b &= list( 1 ) # comment
$$ : b &= [1 ]
$$ : b &= [ 1]
$$ : b &= [ 1 ]
$$ : b &= [ 1 ]  # comment
$$ :
$$ : # 1, 2 spaces with 2 elements
$$ : c &=[1,2]
$$ : c &= [1, 2]
$$ : c &= [1,2]
$$ : c &= [ 1 , 2 ]
$$ :
$$ : # lists with three elements
$$ : a3 &= [1, 2.2, "3"]
$$ : a3 &= [1, [2], "3"]
$$ : a3 &= [1, len("3"), "len"]

a = {a}
b = {b}
c = {c}
a3 = {a3}
$$ endblock
~~~


### File result.expected

~~~

a = [[],[],[],[]]
b = [[1],[1],[1],[1],[1],[1]]
c = [[1,2],[1,2],[1,2],[1,2]]
a3 = [[1,2.2,"3"],[1,[2],"3"],[1,1,"len"]]
~~~

### Expected result == result.expected
### Expected stdout == empty
### Expected stderr == empty
