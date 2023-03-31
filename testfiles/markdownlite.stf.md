stf file, version 0.1.0

# MarkdownLite

Example using markdownLite.

### File cmd.sh command

~~~
$statictea \
  -o shared.tea \
  -t tmpl.txt \
  -r result \
  >stdout 2>stderr
~~~

noLastEnding

### File tmpl.txt 

~~~
$$ block 
$$ : str = string(o.fragments, "vl")
doc = """
{o.md}
"""

fragments = markdownLite(doc)
fragments => [
$$ endblock
$$ block
$$ : t.repeat = len(o.fragments)
$$ : line = string(o.fragments[t.row], "json")
  {line}
$$ endblock
]
~~~

### File shared.tea

``` nim
o.md = """
A subset of markdown which contains paragraphs,
bullets and code blocks.

~~~ statictea
markdownLite = func(mdText: string) list
~~~

* p -- a paragraph
* code -- code block
* bullets -- bullets"""

o.fragments = markdownLite(o.md)
```

### File result.expected

```
doc = """
A subset of markdown which contains paragraphs,
bullets and code blocks.

~~~ statictea
markdownLite = func(mdText: string) list
~~~

* p -- a paragraph
* code -- code block
* bullets -- bullets
"""

fragments = markdownLite(doc)
fragments => [
  ["p",["A subset of markdown which contains paragraphs,\nbullets and code blocks.\n\n"]]
  ["code",["~~~ statictea\n","markdownLite = func(mdText: string) list\n","~~~\n"]]
  ["p",["\n"]]
  ["bullets",["p -- a paragraph\n","code -- code block\n","bullets -- bullets"]]
]
```

### File stdout.expected

~~~
~~~

### File stderr.expected

~~~
~~~

### Expected result == result.expected
### Expected stdout == stdout.expected
### Expected stderr == stderr.expected
