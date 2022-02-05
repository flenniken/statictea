stf file, version 0.1.0

# substr

Test the substr function.

Extract a substring from a string by its position. You pass the
string, the substring's start index then its end index+1.  The end
index is optional and defaults to the end of the string+1.

The range is half-open which includes the start position but not the
end position. For example, [3, 7) includes 3, 4, 5, 6. The end minus
the start is equal to the length of the substring.

~~~
substr(str: string, start: int, optional end: int) string
~~~~
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
$$ : zero &= substr("", 0)
$$ : zero &= substr("", 0, 0)
$$ : zero &= substr("a", 0, 0)
$$ : zero &= substr("a", 1)
$$ : zero &= substr("a", 1, 1)
$$ : zero &= substr("ab", 0, 0)
$$ : zero &= substr("ab", 1, 1)
$$ : zero &= substr("ab", 2, 2)
$$ : zero &= substr("ab", 2)
zero => {zero}
$$ endblock
$$ block
$$ : one &= substr("a", 0, 1)
$$ : one &= substr("a", 0)
$$ : one &= substr("ab", 0, 1)
$$ : one &= substr("ab", 1, 2)
$$ : one &= substr("ab", 1)
one => {one}
$$ endblock
$$ block
$$ : two &= substr("ab", 0, 2)
$$ : two &= substr("ab", 0)
two => {two}
$$ endblock
$$ block
$$ : three &= substr("abcdef", 0, 3)
$$ : three &= substr("abcdef", 1, 4)
$$ : three &= substr("abcdef", 2, 5)
$$ : three &= substr("abcdef", 3, 6)
$$ : three &= substr("abcdef", 3)
three => {three}
$$ endblock
$$ block
$$ : uc &= substr("añyóng", 0, 1)
$$ : uc &= substr("añyóng", 1, 2)
$$ : uc &= substr("añyóng", 2, 3)
$$ : uc &= substr("añyóng", 4, 5)
$$ : uc &= substr("añyóng", 5, 6)
uc => {uc}
$$ endblock

$$ block
$$ : x = substr("Earl Grey", 1, 4)
$$ : y = substr("Earl Grey", 6)
$$ : z = substr("añyóng", 0, 3)
substr("Earl Grey", 1, 4) => {x}
substr("Earl Grey", 6) => {y}
substr("añyóng", 0, 3) => {z}
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
zero => ["","","","","","","","",""]
one => ["a","a","a","b","b"]
two => ["ab","ab"]
three => ["abc","bcd","cde","def","def"]
uc => ["a","ñ","y","n","g"]

substr("Earl Grey", 1, 4) => arl
substr("Earl Grey", 6) => rey
substr("añyóng", 0, 3) => añy
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
