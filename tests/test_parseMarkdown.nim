import std/unittest
import std/strutils
import std/options
import std/strFormat
import parseMarkdown
import sharedtestcode
import compareLines
import unicodes

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
      result.add("""<pre class="nim-code">""" & "\n")
      let codeString = element.content[1]
      let fragments = highlightStaticTea(codeString)
      var begin = 0
      for fragment in fragments:
        var color: string
        case fragment.fragmentType
        of ftType:
          color = "red"
        of ftFunc:
          color = "blue"
        of ftVarName:
          color = "green"
        of ftNumber:
          color = "IndianRed"
        of ftString:
          color = "SeaGreen"
        of ftDocComment:
          color = "OrangeRed"
        of ftComment:
          color = "FireBrick"

        result.add(codeString[begin .. fragment.start-1])

        result.add(fmt"""<span style="color: {color};">""")
        let finish = fragment.start + fragment.length
        result.add(codeString[fragment.start .. finish-1])
        result.add("</span>")

        begin = finish

      result.add(codeString[begin .. ^1])
      result.add("</pre>\n")
    of bullets:
      result.add("<ul>\n")
      for nl_string in element.content:
        result.add("  <li>")
        result.add(strip(nl_string))
        result.add("</li>\n")
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

    # eFt: FragmentType, eStart: Natural, eLength: Natural): bool =

proc testMatchFragment(aLine: string, start: Natural, eFragmentO: Option[Fragment]): bool =
  ## Test matchFragment. a ! in the line is replaced with a quote (").
  let line = replace(aLine, '!', '"')
  let fragmentO = matchFragment(line, start)
  result = gotExpected($fragmentO, $eFragmentO)
  if not result:
    echo "start: $1" % $start
    echo startColumn(line, start, "┌─start")
    echo line
    if fragmentO.isSome:
      let f = fragmentO.get()
      echo startColumn(line, f.start + f.length, "└─got end")
    if eFragmentO.isSome:
      let f = eFragmentO.get()
      echo startColumn(line, f.start + f.length, "└─expected end")

proc testHighlightStaticTea(line: string, eFragments: seq[Fragment]): bool =
  let fragments = highlightStaticTea(line)
  if fragments == eFragments:
    return true
  echo linesSideBySide($fragments, $eFragments)
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
apple = 123
banana = "plant"
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
:apple = 123
banana = "plant"
:~~~
"""
    check testParseMarkdown(content, expected)

    let expectedHtml = """
<p>
This is a full test of all the
different elements.
</p>
<ul>
  <li>red</li>
  <li>green</li>
  <li>blue</li>
</ul>
<p>
Examples:
</p>
<pre class="nim-code">
<span style="color: green;">apple</span> = <span style="color: IndianRed;">123</span>
<span style="color: green;">banana</span> = <span style="color: SeaGreen;">"plant"</span>
</pre>
"""
    let elements = parseMarkdown(content)
    let html =  markdownHtml(elements)
    # echo html
    if html != expectedHtml:
      echo linesSideBySide(html, expectedHtml)
      fail

  test "matchFragment type":
    check testMatchFragment("", 0, none(Fragment))
    check testMatchFragment("true", 0, some(newFragment(ftType, 0, 4)))
    check testMatchFragment(" true", 1, some(newFragment(ftType, 1, 4)))
    check testMatchFragment(" true ", 1, some(newFragment(ftType, 1, 4)))
    check testMatchFragment("abctrue ", 3, some(newFragment(ftType, 3, 4)))
    check testMatchFragment("false", 0, some(newFragment(ftType, 0, 5)))
    check testMatchFragment("int", 0, some(newFragment(ftType, 0, 3)))
    check testMatchFragment("float", 0, some(newFragment(ftType, 0, 5)))
    check testMatchFragment("string", 0, some(newFragment(ftType, 0, 6)))
    check testMatchFragment("dict", 0, some(newFragment(ftType, 0, 4)))
    check testMatchFragment("list", 0, some(newFragment(ftType, 0, 4)))
    check testMatchFragment("any", 0, some(newFragment(ftType, 0, 3)))

  test "matchFragment function":
    check testMatchFragment("a(", 0, some(newFragment(ftFunc, 0, 2)))
    check testMatchFragment("abc(", 0, some(newFragment(ftFunc, 0, 4)))
    check testMatchFragment(" abc(", 1, some(newFragment(ftFunc, 1, 4)))
    check testMatchFragment("s.aAZz-4_3(", 0, some(newFragment(ftFunc, 0, 11)))

  test "matchFragment var name":
    check testMatchFragment("", 0, none(Fragment))
    check testMatchFragment("a", 0, some(newFragment(ftVarName, 0, 1)))
    check testMatchFragment("s.d", 0, some(newFragment(ftVarName, 0, 3)))
    check testMatchFragment(r"a\bc(", 0, some(newFragment(ftVarName, 0, 1)))
    check testMatchFragment("trueabc", 0, some(newFragment(ftVarName, 0, 7)))
    check testMatchFragment(" tru", 1, some(newFragment(ftVarName, 1, 3)))
    check testMatchFragment(" True", 1, some(newFragment(ftVarName, 1, 4)))
    check testMatchFragment("f.cmp", 0, some(newFragment(ftVarName, 0, 5)))

  test "matchFragment number":
    check testMatchFragment(r"1", 0, some(newFragment(ftNumber, 0, 1)))
    check testMatchFragment(r"-1", 0, some(newFragment(ftNumber, 0, 2)))
    check testMatchFragment(r"1.2", 0, some(newFragment(ftNumber, 0, 3)))
    check testMatchFragment(r"123.24", 0, some(newFragment(ftNumber, 0, 6)))

  test "matchFragment string":
    check testMatchFragment("!!", 0, some(newFragment(ftString, 0, 2)))
    check testMatchFragment("!a!", 0, some(newFragment(ftString, 0, 3)))
    check testMatchFragment("!123!", 0, some(newFragment(ftString, 0, 5)))
    check testMatchFragment(" !123!", 1, some(newFragment(ftString, 1, 5)))
    check testMatchFragment(r"!1\n23!", 0, some(newFragment(ftString, 0, 7)))
    check testMatchFragment(r"!1\\23!", 0, some(newFragment(ftString, 0, 7)))
    check testMatchFragment(r"!1\!23!", 0, some(newFragment(ftString, 0, 7)))
    check testMatchFragment(r"!1\b23!", 0, some(newFragment(ftString, 0, 7)))
    check testMatchFragment("!", 0, none(Fragment))
    check testMatchFragment("!  ", 0, none(Fragment))

  test "matchFragment doc comment":
    check testMatchFragment("##", 0, some(newFragment(ftDocComment, 0, 2)))
    check testMatchFragment("## asdf", 0, some(newFragment(ftDocComment, 0, 7)))

  test "matchFragment comment":
    check testMatchFragment("#", 0, some(newFragment(ftComment, 0, 1)))
    check testMatchFragment("# asdf", 0, some(newFragment(ftComment, 0, 6)))

  test "matchFragment highlightStaticTea":
    check testHighlightStaticTea("true", @[newFragment(ftType, 0, 4)])
    check testHighlightStaticTea("true false", @[
      newFragment(ftType, 0, 4),
      newFragment(ftType, 5, 5),
    ])
    check testHighlightStaticTea("a = true", @[
      newFragment(ftVarName, 0, 1),
      newFragment(ftType, 4, 4),
    ])
    check testHighlightStaticTea("""a = len("abc")""", @[
      newFragment(ftVarName, 0, 1),
      newFragment(ftFunc, 4, 4),
      newFragment(ftString, 8, 5),
    ])
    check testHighlightStaticTea("""a = 35""", @[
      newFragment(ftVarName, 0, 1),
      newFragment(ftNumber, 4, 2),
    ])
    check testHighlightStaticTea("""a = process(35, 44, true)""", @[
      newFragment(ftVarName, 0, 1),
      newFragment(ftFunc, 4, 8),
      newFragment(ftNumber, 12, 2),
      newFragment(ftNumber, 16, 2),
      newFragment(ftType, 20, 4),
    ])
    check testHighlightStaticTea("""  #a = process(35, 44, true)""", @[
      newFragment(ftComment, 2, 26),
    ])
    check testHighlightStaticTea("""  ## this is a doc comment""", @[
      newFragment(ftDocComment, 2, 24),
    ])
    check testHighlightStaticTea("""a = 5 # comment""", @[
      newFragment(ftVarName, 0, 1),
      newFragment(ftNumber, 4, 1),
      newFragment(ftComment, 6, 9),
    ])
