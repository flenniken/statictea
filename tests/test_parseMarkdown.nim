import std/unittest
import parseMarkdown
import sharedtestcode
import compareLines

proc testParseMarkdown(content: string, expected: string): bool =
  ## Test parseMarkdown
  let elements = parseMarkdown(content)
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
:
"""
    check testParseMarkdown(content, expected)

  test "code out of lines":
    let content = """
~~~
~~~
"""
    let expected = """
---code---
:~~~
:~~~
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
:
"""
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
