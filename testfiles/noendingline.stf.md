stf file, version 0.1.0

## Test with no ending newline at the bottom of the file.

### File cmd.sh command

~~~
$statictea -t=template.html -r=result.html >stdout 2>stderr
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

### File stdout.expected

~~~
~~~

### File stderr.expected

~~~
~~~

### Expected result.expected == result.html
### Expected stdout.expected == stdout
### Expected stderr.expected == stderr

