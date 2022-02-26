stf file, version 0.1.0

# No Ending Newline

Test with no ending newline at the bottom of the file.

### File cmd.sh command

~~~
$statictea -t template.html -r result.html >stdout 2>stderr
~~~

### File template.html noLastEnding

~~~
Test with no ending newline at the bottom of the file.

$$ nextline t.repeat = 3
$$ : line = "Replacement"
{line}
~~~

### File result.expected noLastEnding

~~~
Test with no ending newline at the bottom of the file.

ReplacementReplacementReplacement
~~~

### Expected result.expected == result.html
### Expected stdout == empty
### Expected stderr == empty

