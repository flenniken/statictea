import std/unittest
import std/strutils
import std/strFormat
import std/options
import parseMarkdown
import sharedtestcode
import compareLines
import unicodes

const
  tripleQuotes = "\"\"\""

proc markdownHtml(elements: seq[BlockElement]): string =
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
      let fragments = highlightCode(codeString)
      for fragment in fragments:
        var color: string
        case fragment.fragmentType
        of hlOther:
          color = ""
        of hlParamName:
          color = ""
        of hlParamType:
          color = "red"
        of hlMultiline:
          color = "green"
        of hlFuncCall:
          color = "blue"
        of hlDotName:
          color = "green"
        of hlNumber:
          color = "IndianRed"
        of hlStringType:
          color = "SeaGreen"
        of hlDocComment:
          color = "OrangeRed"
        of hlComment:
          color = "FireBrick"

        if color != "":
          result.add(fmt"""<span style="color: {color};">""")
        result.add(codeString[fragment.start .. fragment.fEnd-1])
        if color != "":
          result.add("</span>")
      result.add("</pre>\n")

    of bullets:
      result.add("<ul>\n")
      for nl_string in element.content:
        result.add("  <li>")
        result.add(strip(nl_string))
        result.add("</li>\n")
      result.add("</ul>\n")

proc roundTripElements(elements: seq[BlockElement]): string =
  ## Recreate, round trip, the markdown string from the markdown
  ## elements.
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
  ## Test parseBlockMarkdown
  let elements = parseBlockMarkdown(content)

  let roundtrip = roundTripElements(elements)
  if content != roundtrip:
    echo "roundtrip:"
    echo linesSideBySide(roundtrip, content)
    return false

  let got = $elements
  if got == expected:
    return true
  echo linesSideBySide(got, expected)
  return false

    # of hlOther:
    # of hlDotName:
    # of hlFuncCall:
    # of hlNumber:
    # of hlStringType:
    # of hlMultiline:
    # of hlDocComment:
    # of hlComment:
    # of hlParamName:
    # of hlParamType:

proc roundTripFragments(codeText: string, fragments: seq[Fragment]): string =
  ## Recreate, round trip, the code text from the highlight fragments.
  for f in fragments:
    result.add(codeText[f.start .. f.fEnd - 1])

proc testHighlightCode(code: string, expected: string): bool =
  ## Test highlightCode.
  let fragments = highlightCode(code)
  var got: string
  for f in fragments:
    let codeFrag = visibleControl(code[f.start .. f.fEnd - 1], spacesToo=true)
    got.add(fmt("{f.fragmentType}: {codeFrag}") & "\n")

  if got == expected:
    let roundTrip = roundTripFragments(code, fragments)
    if roundTrip != code:
      echo "highlight round trip failed"
      echo linesSideBySide(roundTrip, code)
      return false
    return true
  echo "---code:"
  for line in splitNewLines(code):
    echo visibleControl(line)
  if expected == "":
    echo "---got:"
    echo got
    echo "---"
  else:
    echo linesSideBySide(got, expected)
  return false

proc testParseInlineMarkdown(text: string, expected: string): bool =
  let elements = parseInlineMarkdown(text)
  let got = $elements
  if got == expected:
    return true
  echo linesSideBySide(got, expected)
  return false

proc testParseLink(text: string, start: Natural, expected: Option[LinkItem]): bool =
  let linkItem = parseLink(text, start)
  if linkItem == expected:
    return true
  echo linesSideBySide($linkItem, $expected)
  return false

suite "parseBlockMarkdown.nim":

  test "newBlockElement":
    check gotExpected($newBlockElement(p, @[]), """
---p---
""")
    check gotExpected($newBlockElement(p, @["abc"]), """
---p---
:abc""")
    check gotExpected($newBlockElement(p, @["abc\n"]), """
---p---
:abc
""")
    check gotExpected($newBlockElement(p, @["abc\n", "def\n"]), """
---p---
:abc
:def
""")
  test "elements string repr":
    var elements = newSeq[BlockElement]()
    check gotExpected($elements, "")

    elements.add(newBlockElement(p, @["hello\n"]))
    elements.add(newBlockElement(p, @["there\n"]))
    check gotExpected($elements, """
---p---
:hello
---p---
:there
""")

  test "parseBlockMarkdown empty":
    let content = ""
    let expected = ""
    check testParseMarkdown(content, expected)

  test "parseBlockMarkdown p":
    let content = """
This is a test.
"""
    let expected = """
---p---
:This is a test.
"""
    check testParseMarkdown(content, expected)

  test "parseBlockMarkdown few p lines":
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

  test "parseBlockMarkdown few p":
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

  test "parseBlockMarkdown code":
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

  test "parseBlockMarkdown code 2":
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

  test "parseBlockMarkdown code 3":
    let content = """
Example:
~~~
a = 5
~~~
"""
    let expected = """
---p---
:Example:
---code---
:~~~
:a = 5
:~~~
"""
    check testParseMarkdown(content, expected)

  test "parseBlockMarkdown code type":
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

  test "parseBlockMarkdown p bullet":
    let content = """
Example:
* a
* b
* c
"""
    let expected = """
---p---
:Example:
---bullets---
:a
:b
:c
"""
    check testParseMarkdown(content, expected)

  test "parseBlockMarkdown bullet code":
    let content = """
* a
* b
* c
~~~
my code
~~~
"""
    let expected = """
---bullets---
:a
:b
:c
---code---
:~~~
:my code
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
    let elements = parseBlockMarkdown(content)
    let html =  markdownHtml(elements)
    # echo html
    if html != expectedHtml:
      echo linesSideBySide(html, expectedHtml)
      fail

  test "atMultiline":
      check atMultiline("$1\n" % tripleQuotes, 0) == 4
      check atMultiline(" $1\n" % tripleQuotes, 1) == 4
      check atMultiline(" $1\n  " % tripleQuotes, 1) == 4
      check atMultiline("$1\r\n" % tripleQuotes, 0) == 5
      check atMultiline(" $1\r\n" % tripleQuotes, 1) == 5
      check atMultiline(" $1\r\n  " % tripleQuotes, 1) == 5

  test "atMultiline false":
      check atMultiline("", 0) == 0
      check atMultiline("a", 0) == 0
      check atMultiline("\"", 0) == 0
      check atMultiline("\"\n", 0) == 0
      check atMultiline("\"\"\n", 0) == 0
      check atMultiline("\"\"\"", 0) == 0
      check atMultiline("\"\"\r\n", 0) == 0
      check atMultiline("\"\"\"\r", 0) == 0

  test "lineEnd":
    check lineEnd("", 0) == 0
    check lineEnd("a", 0) == 1
    check lineEnd("ab", 0) == 2
    check lineEnd("ab\n", 0) == 3
    check lineEnd("ab\r\n", 0) == 4
                  #01 234 5678
    check lineEnd("ab\nde\nfg", 0) == 3
    check lineEnd("ab\nde\nfg", 1) == 3
    check lineEnd("ab\nde\nfg", 2) == 3
    check lineEnd("ab\nde\nfg", 3) == 6
    check lineEnd("ab\nde\nfg", 4) == 6
    check lineEnd("ab\nde\nfg", 5) == 6
    check lineEnd("ab\nde\nfg", 6) == 8
    check lineEnd("ab\nde\nfg", 7) == 8

  test "highlightCode empty":
    check testHighlightCode("", "")

  test "highlightCode one other":
    let code = "**!@"
    let expected = """
other: **!@
"""
    check testHighlightCode(code, expected)

  test "highlightCode symbols":
    let code = """
*!
@$
"""
    let expected = """
other: *!␊@$␊
"""
    check testHighlightCode(code, expected)

  test "highlightCode a = 5":
    let code = """
a = 5
"""
    let expected = """
dotName: a
other: ␠=␠
num: 5
other: ␊
"""
    check testHighlightCode(code, expected)

  test "highlightCode func, string, comment":
    let code = """
d.tea = len("Earl Gray") # comment
"""
    let expected = """
dotName: d.tea
other: ␠=␠
funcCall: len
other: (
str: "Earl␠Gray"
other: )␠
comment: #␠comment␊
"""
    check testHighlightCode(code, expected)

  test "highlightCode int func":
    let code = """
tea = int(4.3)
"""
    let expected = """
dotName: tea
other: ␠=␠
funcCall: int
other: (
num: 4.3
other: )␊
"""
    check testHighlightCode(code, expected)

  test "highlightCode var, string":
    let code = """
tea = "tea"
# hello
asdf = join(["a", "b"])
"""
    let expected = """
dotName: tea
other: ␠=␠
str: "tea"
other: ␊
comment: #␠hello␊
dotName: asdf
other: ␠=␠
funcCall: join
other: ([
str: "a"
other: ,␠
str: "b"
other: ])␊
"""
    check testHighlightCode(code, expected)

  test "highlightCode spaces":
    let code = """
a =  add(   456  , 321   )
"""
    let expected = """
dotName: a
other: ␠=␠␠
funcCall: add
other: (␠␠␠
num: 456
other: ␠␠,␠
num: 321
other: ␠␠␠)␊
"""
    check testHighlightCode(code, expected)

  test "highlightCode multiline":
    let code = """
multi = $1
123
abc
"hello" asdf
$1
""" % tripleQuotes
    let expected = """
dotName: multi
other: ␠=␠
multiline: $1␊123␊abc␊"hello"␠asdf␊$1␊
""" % tripleQuotes
    check testHighlightCode(code, expected)

  test "highlightCode signature":
    let code = """
a = func(num: int) int
  ## test function
  return(0)
""" % tripleQuotes
    let expected = """
dotName: a
other: ␠=␠
funcCall: func
other: (
param: num
other: :␠
type: int
other: )␠
type: int
other: ␊␠␠
doc: ##␠test␠function␊
other: ␠␠
funcCall: return
other: (
num: 0
other: )␊
""" % tripleQuotes
    check testHighlightCode(code, expected)

  test "highlightCode sig types":
    let code = """
a = func(num: int, str: string, d: dict, ls: optional list) any
  ## test function
  return(0)
""" % tripleQuotes
    let expected = """
dotName: a
other: ␠=␠
funcCall: func
other: (
param: num
other: :␠
type: int
other: ,␠
param: str
other: :␠
type: string
other: ,␠
param: d
other: :␠
type: dict
other: ,␠
param: ls
other: :␠
type: optional
other: ␠
type: list
other: )␠
type: any
other: ␊␠␠
doc: ##␠test␠function␊
other: ␠␠
funcCall: return
other: (
num: 0
other: )␊
""" % tripleQuotes
    check testHighlightCode(code, expected)

  test "highlightCode drink me":
    let code = "drink = $1\nme\n$1" % "\""
    let expected = """
dotName: drink
other: ␠=␠
str: "␊me␊"
"""
    check testHighlightCode(code, expected)

  test "countStars":
    check countStars("", 0) == 0
    check countStars("", 1) == 0
    check countStars("a", 0) == 0
    check countStars("a", 1) == 0
    check countStars("ab", 0) == 0
    check countStars("ab", 1) == 0
    check countStars("ab", 2) == 0

    check countStars("a*", 0) == 0
    check countStars("a*", 1) == 1
    check countStars("a*b", 1) == 1
    check countStars("a*b*", 1) == 1
    check countStars("a**b", 1) == 2

    check countStars("*", 0) == 1
    check countStars("**", 0) == 2
    check countStars("***", 0) == 3
    check countStars("****", 0) == 4

    check countStars("**", 1) == 1
    check countStars("***", 1) == 2
    check countStars("****", 1) == 3

  test "parseInlineMarkdown":
    check testParseInlineMarkdown("", "")
    check testParseInlineMarkdown("a", " normal a")
    check testParseInlineMarkdown("abc", " normal abc")
    check testParseInlineMarkdown("*b*", " italic b")
    check testParseInlineMarkdown("**b**", " bold b")
    check testParseInlineMarkdown("***b***", " boldItalic b")
    # check testParseInlineMarkdown("[text](link)", ""
    check testParseInlineMarkdown("a\nb", " normal a\nb")
    check testParseInlineMarkdown("a **b** c", " normal a  bold b normal  c")

    check testParseInlineMarkdown("*i* **b** ***bi***", " italic i normal   bold b normal   boldItalic bi")
    check testParseInlineMarkdown("*i***b*****bi***", " italic i bold b boldItalic bi")
    check testParseInlineMarkdown("*a**b**c*", " italic a italic b italic c")
    check testParseInlineMarkdown("**a**\n*c*", " bold a normal \n italic c")

    check testParseInlineMarkdown("* b", " normal * b")
    check testParseInlineMarkdown("** b", " normal ** b")
    check testParseInlineMarkdown("*** b", " normal *** b")

    check testParseInlineMarkdown("**b*", " normal **b*")
    check testParseInlineMarkdown("*b**", " italic b normal *")

    check testParseInlineMarkdown("[desc](link)", " link desc link")
    check testParseInlineMarkdown("[desc](link) -- **a**", " link desc link normal  --  bold a")

    check testParseInlineMarkdown("something [desc](http) more",
      " normal something  link desc http normal  more")

  test "parseLink":
    check testParseLink("[desc](link)", 0, some(newLinkItem(0, 12, "desc", "link")))
    check testParseLink("  [desc](link)", 2, some(newLinkItem(2, 14, "desc", "link")))
    check testParseLink("[desc](link", 0, none(LinkItem))
