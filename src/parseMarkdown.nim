## Parse the simple markdown used in the function descriptions and
## highlight statictea code.

import std/strutils
import std/options
import lineBuffer
import matches
import regexes

type
  BlockElementTag* = enum
    ## The supported markdown elements.
    ##
    ## * nothing — not one of the other tags
    ## * p — paragraph block
    ## * code — code block
    ## * bullets — one or more bullet points
    nothing,
    p,
    code,
    bullets,

  BlockElement* = object
    ## Parse markdown elements (parseBlockMarkdown and parseInlineMarkdown).
    tag*: BlockElementTag
    content*: seq[string]

  FragmentType* = enum
    ## Hightlight fragments.
    ##
    ## * hlOther — not one of the other types
    ## * hlDotName — a dot name
    ## * hlFuncCall — a dot name followed by a left parenthesis
    ## * hlNumber — a literal number
    ## * hlStringType — a literal string
    ## * hlMultiline — a multiline literal string
    ## * hlDocComment — a doc comment
    ## * hlComment — a comment
    ## * hlParamName — a parameter name
    ## * hlParamType — int, float, string, list, dict, bool, func, any and optional
    hlOther = "other",
    hlDotName = "dotName",
    hlFuncCall = "funcCall",
    hlNumber = "num",
    hlStringType = "str",
    hlMultiline = "multiline"
    hlDocComment = "doc",
    hlComment = "comment",
    hlParamName = "param",
    hlParamType = "type",

  Fragment* = object
    ## A fragment of a string.
    ## * fragmentType — the type of fragment
    ## * start — the index in the string where the fragment starts
    ## * fEnd — the end of the fragment, [start, end) half-open interval
    fragmentType*: FragmentType
    start*: Natural
    fEnd*: Natural

  InlineElementTag* = enum
    ## The supported inline markdown elements.
    ##
    ## * normal — unformatted inline text
    ## * bold — bold inline text
    ## * italic — italic inline text
    ## * boldItalic — bold and italic inline text
    ## * link — link
    normal,
    bold,
    italic,
    boldItalic,
    link

  InlineElement* = object
    ## Parse markdown elements (parseInlineMarkdown).
    tag*: InlineElementTag
    content*: seq[string]

  LinkItem* = object
    ## A link item containing description and a link string and the
    ## start and end position in the text.
    ## [description](https://google.com)
    ## ^                                ^
    start*: Natural
    finish*: Natural
    description*: string
    link*: string

proc newLinkItem*(start: Natural, finish: Natural, description: string, link: string): LinkItem =
  ## Create a LinkItem object
  result = LinkItem(start: start, finish: finish, description: description, link: link)

proc newBlockElement*(tag: BlockElementTag, content: seq[string]): BlockElement =
  ## Create an Element object.
  result = BlockElement(tag: tag, content: content)

proc newInlineElement*(tag: InlineElementTag, content: seq[string]): InlineElement =
  ## Create an Element object.
  result = InlineElement(tag: tag, content: content)

proc clear(list: var seq[string]) =
  ## Clear (empty) the list.
  list.setLen(0)

func newFragment*(fragmentType: FragmentType, start: Natural, fEnd: Natural): Fragment =
  ## Create a new Fragment from start and end values.
  result = Fragment(fragmentType: fragmentType, start: start, fEnd: fEnd)

func newFragmentLen2*(fragmentType: FragmentType, start: Natural, length: Natural): Fragment =
  ## Create a new Fragment from start and length values.
  result = Fragment(fragmentType: fragmentType, start: start, fEnd: start+length)

func `$`*(f: Fragment): string =
  ## Return a string representation of a Fragment.
  result.add("$1, start: $2, end: $3" % [$f.fragmentType, $f.start, $f.fEnd])

func `$`*(fragments: seq[Fragment]): string =
  ## Return a string representation of a sequence of fragments.
  if fragments.len == 0:
    return "no fragments"
  for f in fragments:
    result.add("$1, start: $2, fEnd: $3\n" % [$f.fragmentType, $f.start, $f.fEnd])

func parseBlockMarkdown*(desc: string): seq[BlockElement] =
  ## Parse the simple description markdown and return a list of
  ## elements.
  ##
  ## elements:
  ##
  ## * p — A paragraph element is one string, possibly containing
  ## newlines.
  ##
  ## * code — A code element is three strings. The first string is
  ## the code start line, for example “~~~” or “~~~nim”.  The second
  ## string contains the contents of the block containing newlines,
  ## when none it’s empty.  The third string is the ending line, for
  ## example “~~~”.
  ##
  ## * bullets — A bullets element contains a string for each
  ## bullet point and it may contain newlines.  The leading “* “ is
  ## not part of the string.

  # The current tag.
  var tag = nothing

  # The current element lines.
  var newLineString = ""
  var content = newSeq[string]()

  for line in yieldContentLine(desc):
    case tag
    of nothing:
      if line.startsWith("~~~"):
        # code started
        tag = code
        content.add(line)
      elif line.startsWith("* "):
        # bullets started
        tag = bullets
        newLineString.add(line[2 .. ^1])
      else:
        # p started
        tag = p
        newLineString.add(line)
    of p:
      if line.startsWith("\n"):
        # p ended
        newLineString.add(line)
        result.add(newBlockElement(tag, @[newLineString]))
        tag = nothing
        newLineString = ""
      elif line.startsWith("~~~"):
        result.add(newBlockElement(tag, @[newLineString]))
        # code started
        content.add(line)
        newLineString = ""
        tag = code
      elif line.startsWith("* "):
        result.add(newBlockElement(tag, @[newLineString]))
        # bullets started
        newLineString = line[2 .. ^1]
        tag = bullets
      else:
        newLineString.add(line)

    of code:
      if line.startsWith("~~~"):
        # code ended
        content.add(newLineString)
        content.add(line)
        result.add(newBlockElement(tag, content))
        content.clear()
        tag = nothing
        newLineString = ""
        content.clear()
      else:
        newLineString.add(line)

    of bullets:
      if line.startsWith("\n"):
        # bullets ended
        newLineString.add(line)
        content.add(newLineString)
        result.add(newBlockElement(tag, content))
        content.clear()
        newLineString = ""
        tag = nothing
      elif line.startsWith("* "):
        # nested bullet
        content.add(newLineString)
        newLineString = line[2 .. ^1]
      elif line.startsWith("~~~"):
        content.add(newLineString)
        result.add(newBlockElement(tag, content))
        newLineString = ""
        content.clear()
        # code started
        content.add(line)
        newLineString = ""
        tag = code
      else:
        newLineString.add(line)

  # Close any started elements.
  case tag
  of nothing:
    discard
  of p:
    # p ended
    result.add(newBlockElement(tag, @[newLineString]))
  of code:
    # code ended
    content.add(newLineString)
    content.add("")
    result.add(newBlockElement(tag, content))
  of bullets:
    # bullets ended
    content.add(newLineString)
    result.add(newBlockElement(tag, content))

func `$`*(element: BlockElement): string =
  ## Return a string representation of an BlockElement. Each item in the
  ## content list starts with a colon on a new line.
  result.add("---$1---\n" % $element.tag)
  for line in element.content:
    result.add(":$1" % line)

func `$`*(elements: seq[BlockElement]): string =
  ## Return a string representation of a list of BlockElements.
  for element in elements:
    result.add($element)

func `$`*(element: InlineElement): string =
  ## Return a string representation of an InlineElement.
  ## ~~~
  ## **text** => " bold text"
  ## [desc](http) => " link desc http"
  ## ~~~
  result.add(" $1" % $element.tag)
  for ix, line in element.content:
    result.add(" $1" % line)

func `$`*(elements: seq[InlineElement]): string =
  ## Return a string representation of a list of InlineElement.
  for element in elements:
    result.add($element)

func atMultiline*(codeText: string, start: Natural): int =
  ## Determine whether the start index points a the start of a
  ## multiline string. Return 0 when it doesn't. Return the position
  ## after the triple quotes, either 4 or 5 depending on the line
  ## endings.
  # Look for """\n or """\r\n at start.
  if codeText.len < 4:
    return 0
  if not (codeText[start] == '"' and codeText[start+1] == '"' and
          codeText[start+2] == '"'):
    return 0
  if codeText[start+3] == '\n':
    return 4
  if codeText.len < 5:
    return 0
  if codeText[start+3] == '\r' and codeText[start+4] == '\n':
    return 5
  return 0

func lineEnd*(str: string, start: Natural): int =
  ## Find the end of the line. It returns either one after the first
  ## newline or after the end of the string.
  let pos  = find(str[start .. ^1], '\n')
  if pos == -1:
    result = str.len
  else:
    result = start + pos + 1

func highlightCode*(codeText: string): seq[Fragment] =
  ## Identify all the fragments in the StaticTea code to
  ## highlight. Return a list of fragments that cover all the
  ## code. Unlighted areas are in "other" fragments. HighlightCode
  ## doesn't validate the code but it works for valid code.

  type
    State = enum
      ## Parsing states.
      other, dotName, number, multiLine, beforeParam,
      beforeType, param, paramType, optionalType,
      beforeReturnType, returnType, strLiteral, slash

  template addFrag(fragmentType2: FragmentType) =
    if currentPos > start:
      let frag = newFragment(fragmentType2, start, currentPos)
      # debugEcho "--- $1, '$2'" % [$fragmentType2, codeText[start .. currentPos-1]]
      result.add(frag)
    start = currentPos

  var state = other
  var start = 0
  var currentPos = 0

  # Loop through the text one byte at a time.
  while true:
    if currentPos > codeText.len - 1:
      break
    let ch = codeText[currentPos]
    # debugEcho "state = $1, ch = $2" % [$state, $ch]
    case state
    of other:
      case ch
      of '0'..'9', '-':
        # We have a number.
        addFrag(hlOther)
        state = number

      of 'a'..'z', 'A'..'Z':
        # We have a dot name, function call or a function definition.
        addFrag(hlOther)
        state = dotName

      of '#':
        # We have a comment or doc comment.
        addFrag(hlOther)

        # Find the end of the current line (plus 1).
        let lineEnd = lineEnd(codeText, currentPos)

        # Determine whether it is a doc comment or comment.
        var tag: FragmentType
        let plus1 = currentPos + 1
        if plus1 < codeText.len and codeText[plus1] == '#':
          tag = hlDocComment
        else:
          tag = hlComment

        # Add the doc comment or comment fragment.
        currentPos = lineEnd
        addFrag(tag)
        state = other
        # Continue so currentPos equals start and isn't incremented at the end.
        continue

      of '"':
        # We have a string type or multiline string.
        addFrag(hlOther)

        let mLen = atMultiline(codeText, currentPos)
        if mLen != 0:
          currentPos += mLen
          state = multiline
        else:
          state = strLiteral
      else:
        # Stay in the other state.
        discard

    of strLiteral:
      case ch
      of '"':
        inc(currentPos)
        addFrag(hlStringType)
        state = other
      of '\\':
        state = slash
      else:
        discard

    of slash:
      state = strLiteral

    of number:
      case ch
      of '0'..'9', '.':
        discard
      else:
        addFrag(hlNumber)
        state = other

    of dotName:
      case ch
      of 'a'..'z', 'A'..'Z', '0'..'9', '.', '_', '-':
        discard
      of '(':
        # Function call.
        let name = codeText[start .. currentPos - 1]
        if name == "func":
          state = beforeParam
        else:
          state = other
        addFrag(hlFuncCall)
      else:
        # Dot name.
        addFrag(hlDotName)
        state = other

    of multiLine:
      let mLen = atMultiline(codeText, currentPos)
      if mLen != 0:
        currentPos += mLen
        addFrag(hlMultiline)
        state = other

    of beforeParam:
      case ch
      of ')':
        state = beforeReturnType
      of 'a'..'z', 'A'..'Z':
        addFrag(hlOther)
        state = param
      else:
        discard

    of param:
      case ch
      of 'a'..'z', 'A'..'Z', '0'..'9', '_', '-':
        discard
      else:
        addFrag(hlParamName)
        state = beforeType

    of beforeType:
      case ch
      of 'o':
        addFrag(hlOther)
        state = optionalType
      of 'a'..'n', 'p'..'z':
        addFrag(hlOther)
        state = paramType
      else:
        discard

    of paramType:
      case ch
      of ')':
        addFrag(hlParamType)
        state = beforeReturnType
      # int, float, bool, string, dict, list, any
      of 'a'..'z':
        discard
      else:
        addFrag(hlParamType)
        state = beforeParam

    of optionalType:
      case ch
      # optional a-t
      of 'a'..'t':
        discard
      else:
        addFrag(hlParamType)
        state = beforeType

    of beforeReturnType:
      case ch
      of 'a'..'z':
        addFrag(hlOther)
        state = returnType
      else:
        discard

    of returnType:
      case ch
      of 'a'..'z':
        discard
      else:
        addFrag(hlParamType)
        state = other

    inc(currentPos)

  if start < codeText.len:
    addFrag(hlOther)

func countStars*(text: string, pos: Natural): Natural =
  ## Count the number of contiguous stars (*) starting at pos.
  var vpos = pos
  while vpos < text.len and text[vpos] == '*':
    inc(result)
    inc(vpos)

func parseLink*(text: string, start: Natural): Option[LinkItem] =
  ## Parse the link at the given start position.
  ##
  ## ~~~
  ## [description](link)
  ## ^                  ^
  ## ~~~
  let matchesO = matchMarkdownLink(text, start)
  if isSome(matchesO):
    let matches = matchesO.get()
    let (desc, link) = matchesO.get2Groups()
    result = some(newLinkItem(start, start + matches.length, desc, link))

func parseInlineMarkdown*(text: string): seq[InlineElement] =
  ## Parse the text looking for bold, italic, bold+italic and
  ## links. Return a list of inline elements.
  ##
  ## Example:
  ##
  ## ~~~ statictea
  ## inline = parseMarkdown("**bold** and hyperlink [desc](link)", "inline")
  ## inline => [
  ##   ["bold", ["bold"]]
  ##   ["normal", [" and a hyperlink "]]
  ##   ["link", ["desc", "link"]]
  ## ]
  ## ~~~

  type
    State = enum
      ## Parsing states.
      sNormal, sBold, sItalic, sBoldItalic

  var state = sNormal
  var currentPos = 0
  var span = ""

  # Loop through the text one byte at a time.
  while true:
    if currentPos > text.len - 1:
      break
    var ch = text[currentPos]
    case state
    of sNormal:
      case ch
      of '[':
        let linkItemO = parseLink(text, currentPos)
        if linkItemO.isSome:
          let linkItem = linkItemO.get()
          var list = newSeq[string]()
          list.add(linkItem.description)
          list.add(linkItem.link)
          result.add(newInlineElement(link, list))
          currentPos = linkItem.finish - 1
        else:
          span.add(ch)
      of '*':
        if span != "":
          result.add(newInlineElement(normal, @[span]))
          span = ""
        let stars = countStars(text, currentPos)
        case stars:
        of 1:
          state = sItalic
        of 2:
          state = sBold
          inc(currentPos)
        else:
          state = sBoldItalic
          inc(currentPos)
          inc(currentPos)
      else:
        span.add(ch)

    of sItalic:
      case ch
      of '*':
        if span != "":
          result.add(newInlineElement(italic, @[span]))
          span = ""
        state = sNormal
      else:
        span.add(ch)

    of sBold:
      case ch
      of '*':
        let stars = countStars(text, currentPos)
        if stars >= 2:
          if span != "":
            result.add(newInlineElement(bold, @[span]))
            span = ""
          state = sNormal
          inc(currentPos)
        else:
          span.add(ch)
      else:
        span.add(ch)

    of sBoldItalic:
      case ch
      of '*':
        let stars = countStars(text, currentPos)
        if stars >= 3:
          if span != "":
            result.add(newInlineElement(boldItalic, @[span]))
            span = ""
          state = sNormal
          inc(currentPos)
          inc(currentPos)
        else:
          span.add(ch)
      else:
        span.add(ch)

    inc(currentPos)

  case state
  of sItalic:
    span.insert("*")
  of sBold:
    span.insert("**")
  of sBoldItalic:
    span.insert("***")
  of sNormal:
    discard
  if span != "":
    result.add(newInlineElement(normal, @[span]))
