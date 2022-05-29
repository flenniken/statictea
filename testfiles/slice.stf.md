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

### File cmd.sh command 

~~~
$statictea \
  -t tmpl.txt \
  -r result >stdout 2>stderr
~~~

### File tmpl.txt

~~~
$$ block
$$ : zero &= slice("", 0)
$$ : zero &= slice("", 0, 0)
$$ : zero &= slice("", 0, 8)
$$ : zero &= slice("abc", 0, 0)
$$ :
$$ : zero &= slice("a", 0, 0)
$$ : zero &= slice("a", 1, 0)
$$ : zero &= slice("a", 4, 0)
$$ :
$$ : zero &= slice("ab", 0, 0)
$$ : zero &= slice("ab", 1, 0)
$$ : zero &= slice("ab", 2, 0)
$$ : zero &= slice("ab", 8, 0)
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
$$ : str = "añyóng"
$$ : uc &= slice(str, 0, 1)
$$ : uc &= slice(str, 1, 1)
$$ : uc &= slice(str, 2, 1)
$$ : uc &= slice(str, 3, 1)
$$ : uc &= slice(str, 4, 1)
$$ : uc &= slice(str, 5, 1)
{str}
uc => {uc}
$$ endblock

$$ block
$$ : str = "aÂâð♘☺🃞"
$$ : a0 = slice(str, 0, 1)
$$ : a1 = slice(str, 1, 2)
$$ : a2 = slice(str, 2, 3)
$$ : a3 = slice(str, 3, 3)
$$ : a4 = slice(str, 4, 1)
slice({str}, 0, 1) => {a0}
slice({str}, 1, 2) => {a1}
slice({str}, 2, 3) => {a2}
slice({str}, 3, 3) => {a3}
slice({str}, 4, 1) => {a4}
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
zero => ["","","","","","","","","","",""]

one => ["a","a","a","b","b"]

two => ["ab","ab"]

three => ["abc","bcd","cde","def","def"]

añyóng
uc => ["a","ñ","y","ó","n","g"]

slice(aÂâð♘☺🃞, 0, 1) => a
slice(aÂâð♘☺🃞, 1, 2) => Ââ
slice(aÂâð♘☺🃞, 2, 3) => âð♘
slice(aÂâð♘☺🃞, 3, 3) => ð♘☺
slice(aÂâð♘☺🃞, 4, 1) => ♘

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
