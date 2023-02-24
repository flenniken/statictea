import std/unittest
import std/strutils
import parseMarkdown
import sharedtestcode
import compareLines

proc markdownHtml(elements: seq[Element]): string =
  ## Generate HTML from the markdown elements.
  for element in elements:
    case element.tag
    of nothing:
      discard
    of p:
      result.add("<p>\n")
      result.add(strip(element.content[0]))
      result.add("\n</p>\n")
    of code:
      result.add("<pre>\n")
      if element.content.len == 3:
        result.add(element.content[1])
      result.add("</pre>\n")
    of bullets:
      result.add("<ul>\n")
      for nl_string in element.content:
        result.add("  <ls>")
        result.add(strip(nl_string))
        result.add("</ls>\n")
      result.add("</ul>\n")

proc markdownString(elements: seq[Element]): string =
  ## Recreate the markdown string from the markdown elements.
  for element in elements:
    case element.tag
    of nothing:
      assert false
      discard
    of p:
      assert element.content.len == 1
      result.add(element.content[0])
    of code:
      assert element.content.len == 3
      for nl_string in element.content:
        result.add(nl_string)
    of bullets:
      for nl_string in element.content:
        result.add("* ")
        result.add(nl_string)

proc testParseMarkdown(content: string, expected: string): bool =
  ## Test parseMarkdown
  let elements = parseMarkdown(content)

  let roundtrip = markdownString(elements)
  if content != roundtrip:
    echo "roundtrip:"
    echo linesSideBySide(roundtrip, content)
    return false

  let got = $elements
  if got == expected:
    return true
  echo linesSideBySide(got, expected)
  return false

suite "parseMarkdown.nim":

  test "newElement":
    check gotExpected($newElement(p, @[]), """
---p---
""")
    check gotExpected($newElement(p, @["abc"]), """
---p---
:abc""")
    check gotExpected($newElement(p, @["abc\n"]), """
---p---
:abc
""")
    check gotExpected($newElement(p, @["abc\n", "def\n"]), """
---p---
:abc
:def
""")
  test "elements string repr":
    var elements = newSeq[Element]()
    check gotExpected($elements, "")

    elements.add(newElement(p, @["hello\n"]))
    elements.add(newElement(p, @["there\n"]))
    check gotExpected($elements, """
---p---
:hello
---p---
:there
""")

  test "parseMarkdown empty":
    let content = ""
    let expected = ""
    check testParseMarkdown(content, expected)

  test "parseMarkdown p":
    let content = """
This is a test.
"""
    let expected = """
---p---
:This is a test.
"""
    check testParseMarkdown(content, expected)

  test "parseMarkdown few p lines":
    let content = """
This is a paragraph with
several lines
in it.
"""
    let expected = """
---p---
:This is a paragraph with
several lines
in it.
"""
    check testParseMarkdown(content, expected)

  test "parseMarkdown few p":
    let content = """
This is a paragraph with
several lines
in it.

And here is another p.
"""
    let expected = """
---p---
:This is a paragraph with
several lines
in it.

---p---
:And here is another p.
"""
    check testParseMarkdown(content, expected)

  test "parseMarkdown code":
    let content = """
~~~
a = 5
~~~
"""
    let expected = """
---code---
:~~~
:a = 5
:~~~
"""
    check testParseMarkdown(content, expected)

  test "parseMarkdown code 2":
    let content = """
~~~
a = 5
b = 6
c = 7
~~~
"""
    let expected = """
---code---
:~~~
:a = 5
b = 6
c = 7
:~~~
"""
    check testParseMarkdown(content, expected)

  test "parseMarkdown code type":
    let content = """
~~~nim
a = 5
b = 6
~~~
"""
    let expected = """
---code---
:~~~nim
:a = 5
b = 6
:~~~
"""
    check testParseMarkdown(content, expected)

  test "code out of lines":
    let content = """
~~~
a = 5
b = 6
c = 7
"""
    let expected = """
---code---
:~~~
:a = 5
b = 6
c = 7
:"""
    check testParseMarkdown(content, expected)

  test "empty block":
    let content = """
~~~
~~~
"""
    let expected = """
---code---
:~~~
::~~~
"""
    check testParseMarkdown(content, expected)

  test "code fake bullet":
    let content = """
~~~
* fake bullet
"""
    let expected = """
---code---
:~~~
:* fake bullet
:"""
    check testParseMarkdown(content, expected)

  test "bullets":
    let content = """
* red
"""
    let expected = """
---bullets---
:red
"""
    check testParseMarkdown(content, expected)

  test "bullets 2":
    let content = """
* red
* green
* blue
"""
    let expected = """
---bullets---
:red
:green
:blue
"""
    check testParseMarkdown(content, expected)

  test "bullets multiline":
    let content = """
* red and some
other colors
* green with a little
yellow
* blue by itself
"""
    let expected = """
---bullets---
:red and some
other colors
:green with a little
yellow
:blue by itself
"""
    check testParseMarkdown(content, expected)

  test "bullets then code":
    let content = """
* red
* green
~~~
a = 5
~~~
"""
    let expected = """
---bullets---
:red
:green
---code---
:~~~
:a = 5
:~~~
"""
    check testParseMarkdown(content, expected)

  test "all":
    let content = """
This is a full test of all the
different elements.

* red
* green
* blue

Examples:

~~~
a = 5
b = 6
~~~
"""
    let expected = """
---p---
:This is a full test of all the
different elements.

---bullets---
:red
:green
:blue

---p---
:Examples:

---code---
:~~~
:a = 5
b = 6
:~~~
"""
    check testParseMarkdown(content, expected)

    let expectedHtml = """
<p>
This is a full test of all the
different elements.
</p>
<ul>
  <ls>red</ls>
  <ls>green</ls>
  <ls>blue</ls>
</ul>
<p>
Examples:
</p>
<pre>
a = 5
b = 6
</pre>
"""
    let elements = parseMarkdown(content)
    let html =  markdownHtml(elements)
    if html != expectedHtml:
      echo linesSideBySide(html, expectedHtml)
      fail
