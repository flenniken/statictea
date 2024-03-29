stf file, version 0.1.0

# String Type

Test the string type.

### File cmd.sh command

Run statictea template tmpl.txt:

~~~
$statictea \
  -l log.txt \
  -s server.json \
  -s shared.json \
  -t tmpl.txt \
  -r result.html \
  >stdout 2>stderr
~~~

### File log.sh command

Run a command over the log file that removes the time prefix then
extracts the lines generates by template commands ignoring the lines
generated by the system.

~~~
cat log.txt | cut -c 26- | grep "^tmpl.txt" >log.filtered | true
~~~

The following command can be used to remove the time and
filename prefix from the log lines. Use it in place of the other
log.sh command above.

~~~
cat log.txt | sed 's/^.*); //' >log.filtered
~~~

### File tmpl.txt

~~~
String readme example.

  A string is an immutable sequence of unicode characters. You
  define a literal string with double quotes.

$$ block str = "You can store black teas longer than green teas."
str => {str}
$$ endblock

Create an empty string, one with one character and one with two characters.
$$ block
$$ : a = ""
$$ : b = "1"
$$ : c = "12"
a => '{a}'
b => '{b}'
c => '{c}'
$$ endblock

Continue a long string.
$$ block str = "This is a long string 1+
$$ :        2 split between lines"
$$ : str2 = "This is a long string 1       2 split between lines"
str  => '{str}'
str2 => '{str2}
$$ endblock

Continue a long string with spaces.
$$ nextline str = " a b c +
$$ : d e f+
$$ :  g h i"
{str}
 a b c d e f g h i

$$ nextline str = "+
$$ : - \" -> quotation mark (U+0022)\n+
$$ : - \\ -> reverse solidus (U+005C)\n+
$$ : - \/ -> solidus (U+002F)\n+
$$ : - \n -> line feed (U+000A)\n+
$$ : - \t -> tab (U+0009)\n"
{str}
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
  "name2": "shared",
  "type2": "json"
}
~~~

### File result.expected

~~~
String readme example.

  A string is an immutable sequence of unicode characters. You
  define a literal string with double quotes.

str => You can store black teas longer than green teas.

Create an empty string, one with one character and one with two characters.
a => ''
b => '1'
c => '12'

Continue a long string.
str  => 'This is a long string 1       2 split between lines'
str2 => 'This is a long string 1       2 split between lines

Continue a long string with spaces.
 a b c d e f g h i
 a b c d e f g h i

- " -> quotation mark (U+0022)
- \ -> reverse solidus (U+005C)
- / -> solidus (U+002F)
- 
 -> line feed (U+000A)
- 	 -> tab (U+0009)

~~~

### Expected stdout == empty
### Expected stderr == empty
### Expected log.filtered == empty
### Expected result.html == result.expected
