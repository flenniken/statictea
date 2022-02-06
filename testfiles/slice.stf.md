stf file, version 0.1.0

# slice

Test the slice function.

Extract a substring from a string by its position. You pass the
string, the substring's start index and its length.  The length
is optional. When not specified, the slice returns the characters
from the start to the end of the string.

The start index is by unicode characters not bytes.

~~~
slice(str: string, start: int, optional length: int) string
~~~

todo: test error cases. nonZeroReturn

### File cmd.sh command 

~~~
$statictea \
  -t=tmpl.txt \
  -r=result >stdout 2>stderr
~~~

### File tmpl.txt

~~~
$$ block
$$ : zero &= slice("", 0)
$$ : zero &= slice("", 0, 0)
$$ : zero &= slice("a", 0, 0)
$$ : zero &= slice("a", 1)
$$ : zero &= slice("a", 1, 0)
$$ : zero &= slice("ab", 0, 0)
$$ : zero &= slice("ab", 1, 0)
$$ : zero &= slice("ab", 2, 0)
$$ : zero &= slice("ab", 2)
zero => {zero}
$$ endblock
$$ block
$$ : one &= slice("a", 0, 1)
$$ : one &= slice("a", 0)
$$ : one &= slice("ab", 0, 1)
$$ : one &= slice("ab", 1, 1)
$$ : one &= slice("ab", 1)
one => {one}
$$ endblock
$$ block
$$ : two &= slice("ab", 0, 2)
$$ : two &= slice("ab", 0)
two => {two}
$$ endblock
$$ block
$$ : three &= slice("abcdef", 0, 3)
$$ : three &= slice("abcdef", 1, 3)
$$ : three &= slice("abcdef", 2, 3)
$$ : three &= slice("abcdef", 3, 3)
$$ : three &= slice("abcdef", 3)
three => {three}
$$ endblock
$$ block
$$ : uc &= slice("añyóng", 0, 1)
$$ : uc &= slice("añyóng", 1, 1)
$$ : uc &= slice("añyóng", 2, 1)
$$ : uc &= slice("añyóng", 4, 1)
$$ : uc &= slice("añyóng", 5, 1)
uc => {uc}
$$ endblock

$$ block
$$ : x = slice("Earl Grey", 1, 4)
$$ : y = slice("Earl Grey", 6)
$$ : z = slice("añyóng", 0, 3)
slice("Earl Grey", 1, 3) => {x}
slice("Earl Grey", 6) => {y}
slice("añyóng", 0, 3) => {z}
$$ endblock
~~~

### File server.json

~~~
{
  "name": "server",
  "type": "json"
}
~~~

### File shared.json

~~~
{
  "name": "shared",
  "type": "json"
}
~~~

### File result.expected

~~~
zero => ["","","","a","","","","","ab"]
one => ["a","a","a","b","b"]
two => ["ab","ab"]
three => ["abc","bcd","cde","def","def"]
uc => ["a","ñ","y","n","g"]

slice("Earl Grey", 1, 3) => arl 
slice("Earl Grey", 6) => rey
slice("añyóng", 0, 3) => añy
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
