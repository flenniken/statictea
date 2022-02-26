stf file, version 0.1.0

# t.content

Test the t.content variable.

### File cmd.sh command

~~~
$statictea -s server.json  \
  -t template.html -r result.html >stdout 2>stderr
~~~

### File template.html

~~~
Block command with t.content.
$$ block t.content = "something\n"
hello
$$ endblock

Nextline command with t.content.
$$ nextline t.content = "something\n"
hello there

Replace command with t.content.
$$ replace t.content = "something\n"
not used
$$ endblock

Replace t.content from the server.
$$ replace t.content = s.line_with_newline
not used
$$ endblock
After endblock.

Replace t.content from the server without ending newline.
$$ replace t.content = s.line_without_newline
not used
$$ endblock
After endblock.

Replace: t.content empty string.
$$ replace t.content = ""
not used
$$ endblock
After endblock.

Replace: t.content newline.
$$ replace t.content = "\n"
not used
$$ endblock
After endblock.

Replace: t.content one line.
$$ replace t.content = "one\n"
not used
$$ endblock
After endblock.

Replace: t.content one line no ending newline.
$$ replace t.content = "one"
not used
$$ endblock
After endblock.

Replace: t.content three lines.
$$ replace t.content = "one\ntwo\nthree\n"
not used
$$ endblock
After endblock.

Replace: t.content three lines no ending newline.
$$ replace t.content = "one\ntwo\nthree"
not used
$$ endblock
After endblock.
~~~

### File server.json

~~~
{
  "line_with_newline": "This line has a newline at the end.\n",
  "line_without_newline": "This line does not have a newline at the end.",
}
~~~

### File result.expected

~~~
Block command with t.content.
hello

Nextline command with t.content.
hello there

Replace command with t.content.
something

Replace t.content from the server.
This line has a newline at the end.
After endblock.

Replace t.content from the server without ending newline.
This line does not have a newline at the end.After endblock.

Replace: t.content empty string.
After endblock.

Replace: t.content newline.

After endblock.

Replace: t.content one line.
one
After endblock.

Replace: t.content one line no ending newline.
oneAfter endblock.

Replace: t.content three lines.
one
two
three
After endblock.

Replace: t.content three lines no ending newline.
one
two
threeAfter endblock.
~~~

### Expected result.expected == result.html
### Expected empty == stdout
### Expected empty == stderr

