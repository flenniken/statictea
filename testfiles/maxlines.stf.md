stf file, version 0.1.0

# t.maxLines

Test t.maxLines tea variable.

### File cmd.sh command nonZeroReturn

~~~
$statictea -t template.html -r result.html >stdout 2>stderr
~~~

### File template.html

~~~
Test t.maxLines.

Set max lines to 3 and use 2 lines.
$$ block t.maxLines = 3
$$ : line = "replacement-line"
{line} one
{line} two
$$ endblock

Set max lines to 3 and use 3 lines.
$$ block t.maxLines = 3
$$ : line = "replacement-line"
{line} one
{line} two
{line} three
$$ endblock

Set max lines to 3 and use 4 lines.
$$ block t.maxLines = 3
$$ : line = "replacement-line"
{line} one
{line} two
{line} three
{line} four
$$ endblock

Set max lines to 3 and use 5 lines.
$$ block t.maxLines = 3
$$ : line = "replacement-line"
{line} one
{line} two
{line} three
{line} four
{line} five
$$ endblock

Set max lines to 3 and use 6 lines.
$$ block t.maxLines = 3
$$ : line = "replacement-line"
{line} one
{line} two
{line} three
{line} four
{line} five
{line} six
$$ endblock

Set max lines to 2 and use 2 lines and repeat 2 times.
$$ block t.maxLines = 2
$$ : line = "replacement-line"
$$ : t.repeat = 2
{line} one
{line} two
$$ endblock

Set max lines to 2, use 5 lines and repeat 0.
$$ block t.maxLines = 2
$$ : line = "replacement-line"
$$ : t.repeat = 0
{line} one
{line} two
{line} three
{line} four
{line} five
$$ endblock

end of file
~~~

### File result.expected

~~~
Test t.maxLines.

Set max lines to 3 and use 2 lines.
replacement-line one
replacement-line two

Set max lines to 3 and use 3 lines.
replacement-line one
replacement-line two
replacement-line three

Set max lines to 3 and use 4 lines.
replacement-line one
replacement-line two
replacement-line three
{line} four
$$ endblock

Set max lines to 3 and use 5 lines.
replacement-line one
replacement-line two
replacement-line three
{line} four
{line} five
$$ endblock

Set max lines to 3 and use 6 lines.
replacement-line one
replacement-line two
replacement-line three
{line} four
{line} five
{line} six
$$ endblock

Set max lines to 2 and use 2 lines and repeat 2 times.
replacement-line one
replacement-line two
replacement-line one
replacement-line two

Set max lines to 2, use 5 lines and repeat 0.
{line} four
{line} five
$$ endblock

end of file
~~~

### File stderr.expected

~~~
template.html(24): w60: Read t.maxLines replacement block lines without finding the endblock.
template.html(25): w144: The endblock command does not have a matching block command.
template.html(33): w60: Read t.maxLines replacement block lines without finding the endblock.
template.html(35): w144: The endblock command does not have a matching block command.
template.html(43): w60: Read t.maxLines replacement block lines without finding the endblock.
template.html(46): w144: The endblock command does not have a matching block command.
template.html(62): w60: Read t.maxLines replacement block lines without finding the endblock.
template.html(65): w144: The endblock command does not have a matching block command.
~~~

### Expected result.html == result.expected
### Expected stdout == empty
### Expected stderr == stderr.expected
