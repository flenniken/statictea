# parseMarkdown.nim

Parse the simple markdown used in the function descriptions and
highlight statictea code.


* [parseMarkdown.nim](../../src/parseMarkdown.nim) &mdash; Nim source code.
# Index

* type: [BlockElementTag](#blockelementtag) &mdash; The supported markdown elements.
* type: [BlockElement](#blockelement) &mdash; Parse markdown elements (parseBlockMarkdown and parseInlineMarkdown).
* type: [FragmentType](#fragmenttype) &mdash; Hightlight fragments.
* type: [Fragment](#fragment) &mdash; A fragment of a string.
* type: [InlineElementTag](#inlineelementtag) &mdash; The supported inline markdown elements.
* type: [InlineElement](#inlineelement) &mdash; Parse markdown elements (parseInlineMarkdown).
* type: [LinkItem](#linkitem) &mdash; A link item containing description and a link string and the start and end position in the text.
* [newLinkItem](#newlinkitem) &mdash; Create a LinkItem object 
* [newBlockElement](#newblockelement) &mdash; Create an Element object.
* [newInlineElement](#newinlineelement) &mdash; Create an Element object.
* [newFragment](#newfragment) &mdash; Create a new Fragment from start and end values.
* [newFragmentLen2](#newfragmentlen2) &mdash; Create a new Fragment from start and length values.
* [`$`](#) &mdash; Return a string representation of a Fragment.
* [`$`](#-1) &mdash; Return a string representation of a sequence of fragments.
* [parseBlockMarkdown](#parseblockmarkdown) &mdash; Parse the simple description markdown and return a list of elements.
* [`$`](#-2) &mdash; Return a string representation of an BlockElement.
* [`$`](#-3) &mdash; Return a string representation of a list of BlockElements.
* [`$`](#-4) &mdash; Return a string representation of an InlineElement.
* [`$`](#-5) &mdash; Return a string representation of a list of InlineElement.
* [atMultiline](#atmultiline) &mdash; Determine whether the start index points a the start of a multiline string.
* [lineEnd](#lineend) &mdash; Find the end of the line.
* [highlightCode](#highlightcode) &mdash; Identify all the fragments in the StaticTea code to highlight.
* [countStars](#countstars) &mdash; Count the number of contiguous stars (*) starting at pos.
* [parseLink](#parselink) &mdash; Parse the link at the given start position.
* [parseInlineMarkdown](#parseinlinemarkdown) &mdash; Parse the text looking for bold, italic, bold+italic and links.

# BlockElementTag

The supported markdown elements.

* nothing — not one of the other tags
* p — paragraph block
* code — code block
* bullets — one or more bullet points


~~~nim
BlockElementTag = enum
  nothing, p, code, bullets
~~~

# BlockElement

Parse markdown elements (parseBlockMarkdown and parseInlineMarkdown).


~~~nim
BlockElement = object
  tag*: BlockElementTag
  content*: seq[string]
~~~

# FragmentType

Hightlight fragments.

* hlOther — not one of the other types
* hlDotName — a dot name
* hlFuncCall — a dot name followed by a left parenthesis
* hlNumber — a literal number
* hlStringType — a literal string
* hlMultiline — a multiline literal string
* hlDocComment — a doc comment
* hlComment — a comment
* hlParamName — a parameter name
* hlParamType — int, float, string, list, dict, bool, func, any and optional


~~~nim
FragmentType = enum
  hlOther = "other", hlDotName = "dotName", hlFuncCall = "funcCall",
  hlNumber = "num", hlStringType = "str", hlMultiline = "multiline",
  hlDocComment = "doc", hlComment = "comment", hlParamName = "param",
  hlParamType = "type"
~~~

# Fragment

A fragment of a string.
* fragmentType — the type of fragment
* start — the index in the string where the fragment starts
* fEnd — the end of the fragment, [start, end) half-open interval


~~~nim
Fragment = object
  fragmentType*: FragmentType
  start*: Natural
  fEnd*: Natural
~~~

# InlineElementTag

The supported inline markdown elements.

* normal — unformatted inline text
* bold — bold inline text
* italic — italic inline text
* boldItalic — bold and italic inline text
* link — link


~~~nim
InlineElementTag = enum
  normal, bold, italic, boldItalic, link
~~~

# InlineElement

Parse markdown elements (parseInlineMarkdown).


~~~nim
InlineElement = object
  tag*: InlineElementTag
  content*: seq[string]
~~~

# LinkItem

A link item containing description and a link string and the
start and end position in the text.
[description](https://google.com)
^                                ^


~~~nim
LinkItem = object
  start*: Natural
  finish*: Natural
  description*: string
  link*: string
~~~

# newLinkItem

Create a LinkItem object


~~~nim
proc newLinkItem(start: Natural; finish: Natural; description: string;
                 link: string): LinkItem
~~~

# newBlockElement

Create an Element object.


~~~nim
proc newBlockElement(tag: BlockElementTag; content: seq[string]): BlockElement
~~~

# newInlineElement

Create an Element object.


~~~nim
proc newInlineElement(tag: InlineElementTag; content: seq[string]): InlineElement
~~~

# newFragment

Create a new Fragment from start and end values.


~~~nim
func newFragment(fragmentType: FragmentType; start: Natural; fEnd: Natural): Fragment
~~~

# newFragmentLen2

Create a new Fragment from start and length values.


~~~nim
func newFragmentLen2(fragmentType: FragmentType; start: Natural; length: Natural): Fragment
~~~

# `$`

Return a string representation of a Fragment.


~~~nim
func `$`(f: Fragment): string {.raises: [ValueError], tags: [].}
~~~

# `$`

Return a string representation of a sequence of fragments.


~~~nim
func `$`(fragments: seq[Fragment]): string {.raises: [ValueError], tags: [].}
~~~

# parseBlockMarkdown

Parse the simple description markdown and return a list of
elements.

elements:

* p — A paragraph element is one string, possibly containing
newlines.

* code — A code element is three strings. The first string is
the code start line, for example “~~~” or “~~~nim”.  The second
string contains the contents of the block containing newlines,
when none it’s empty.  The third string is the ending line, for
example “~~~”.

* bullets — A bullets element contains a string for each
bullet point and it may contain newlines.  The leading “* “ is
not part of the string.


~~~nim
func parseBlockMarkdown(desc: string): seq[BlockElement]
~~~

# `$`

Return a string representation of an BlockElement. Each item in the
content list starts with a colon on a new line.


~~~nim
func `$`(element: BlockElement): string {.raises: [ValueError], tags: [].}
~~~

# `$`

Return a string representation of a list of BlockElements.


~~~nim
func `$`(elements: seq[BlockElement]): string {.raises: [ValueError], tags: [].}
~~~

# `$`

Return a string representation of an InlineElement.
~~~
**text** => " bold text"
[desc](http) => " link desc http"
~~~


~~~nim
func `$`(element: InlineElement): string {.raises: [ValueError], tags: [].}
~~~

# `$`

Return a string representation of a list of InlineElement.


~~~nim
func `$`(elements: seq[InlineElement]): string {.raises: [ValueError], tags: [].}
~~~

# atMultiline

Determine whether the start index points a the start of a
multiline string. Return 0 when it doesn't. Return the position
after the triple quotes, either 4 or 5 depending on the line
endings.


~~~nim
func atMultiline(codeText: string; start: Natural): int
~~~

# lineEnd

Find the end of the line. It returns either one after the first
newline or after the end of the string.


~~~nim
func lineEnd(str: string; start: Natural): int
~~~

# highlightCode

Identify all the fragments in the StaticTea code to
highlight. Return a list of fragments that cover all the
code. Unlighted areas are in "other" fragments. HighlightCode
doesn't validate the code but it works for valid code.


~~~nim
func highlightCode(codeText: string): seq[Fragment]
~~~

# countStars

Count the number of contiguous stars (*) starting at pos.


~~~nim
func countStars(text: string; pos: Natural): Natural
~~~

# parseLink

Parse the link at the given start position.

~~~
[description](link)
^                  ^
~~~


~~~nim
func parseLink(text: string; start: Natural): Option[LinkItem]
~~~

# parseInlineMarkdown

Parse the text looking for bold, italic, bold+italic and
links. Return a list of inline elements.

Example:

~~~javascript
inline = parseMarkdown("**bold** and hyperlink [desc](link)", "inline")
inline => [
  ["bold", ["bold"]]
  ["normal", [" and a hyperlink "]]
  ["link", ["desc", "link"]]
]
~~~


~~~nim
func parseInlineMarkdown(text: string): seq[InlineElement]
~~~


---
⦿ Markdown page generated by [StaticTea](https://github.com/flenniken/statictea/) from nim doc comments. ⦿
