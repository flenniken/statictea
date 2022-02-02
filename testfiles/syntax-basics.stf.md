stf file, version 0.1.0

# Readme Syntax

Test the readme syntax section.

### File cmd.sh command

~~~
$statictea -s=server.json \
  -t=template.html -r=result.html >stdout 2>stderr
~~~

### File template.html

~~~
prefix
|     command
|     |        statement
|     |        |         continuation
|     |        |         |
|     |        |         |postfix
|     | +------+         ||  newline
|     | |      |         ||  |


<!--$ nextline a = 5      -->
<!--$ : b = "tea"         -->
<!--$ : c = "The Earl of +-->
<!--$ : Grey"             -->
a = {a}, b = "{b}", c = "{c}"

$$nextline
blank1
$$ nextline
blank2
$$ nextline a=5
a => {a}
$$ nextline a = 5
a => {a}
$$ nextline num = len(s.tea_list)
num => {3}
$$ nextline num = len( s.tea_list )
num => {3}

<!--$ nextline com = "Bigelow Tea Company" -->
com => {com}
<!--$ nextline com = "Big+-->
<!--$ : elow Tea Company" -->
com => {com}

$$ nextline
$$ :
$$ : a = 5
a => {a}

Continue a string.
$$ nextline str = "abc+
$$ : def+
$$ : ghijk+
$$ : lmno"
{str}
abcdefghijklmno

Continue a string with spaces.
$$ nextline  str  =  " a b c +
$$ : d e f+
$$ :  g h i j k+
$$ :  l m n o"
{str}
 a b c d e f g h i j k l m n o
~~~

### File server.json

~~~
{
"tea_list": [
  "Black",
  "Green",
  "Oolong",
  "Sencha",
  "Herbal"
]
}
~~~

### File result.expected

~~~
prefix
|     command
|     |        statement
|     |        |         continuation
|     |        |         |
|     |        |         |postfix
|     | +------+         ||  newline
|     | |      |         ||  |


a = 5, b = "tea", c = "The Earl of Grey"

blank1
blank2
a => 5
a => 5
num => {3}
num => {3}

com => Bigelow Tea Company
com => Bigelow Tea Company

a => 5

Continue a string.
abcdefghijklmno
abcdefghijklmno

Continue a string with spaces.
 a b c d e f g h i j k l m n o
 a b c d e f g h i j k l m n o
~~~

### Expected result.expected == result.html
### Expected stdout == empty
### Expected stderr == empty

