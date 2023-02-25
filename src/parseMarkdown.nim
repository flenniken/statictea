## Parse the simple markdown used in the function descriptions.

import std/strutils
import std/options
import lineBuffer
import regexes

type
  ElementTag* = enum
    nothing,
    p,
    code,
    bullets,

  Element* = object
    tag*: ElementTag
    content*: seq[string]

proc newElement*(tag: ElementTag, content: seq[string]): Element =
  ## Create an Element object.
  result = Element(tag: tag, content: content)

proc clear(list: var seq[string]) =
  ## Clear (empty) the list.
  list.setLen(0)

func parseMarkdown*(desc: string): seq[Element] =
  ## Parse the description markdown and return a list of
  ## elements.
  ## @:
  ## @:elements:
  ## @:
  ## @:* p -- A paragraph element is one string, possibly containing
  ## @:newlines.
  ## @:
  ## @:* code -- A code element is three strings. The first string is
  ## @:the code start line, for example “~~~” or “~~~nim”.  The second
  ## @:string contains the contents of the block, when none it’s empty.
  ## @:The third string is the ending line, for example “~~~”.
  ## @:
  ## @:* bullets -- A bullets element contains a string for each
  ## @:bullet point and it may contain newlines.  The leading “* “ is
  ## @:not part of the string.

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
        result.add(newElement(tag, @[newLineString]))
        tag = nothing
        newLineString = ""
      elif line.startsWith("~~~"):
        result.add(newElement(tag, @[newLineString]))
        # code started
        content.add(line)
        newLineString = ""
        newLineString.add(line)
        tag = code
      elif line.startsWith("* "):
        result.add(newElement(tag, @[newLineString]))
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
        result.add(newElement(tag, content))
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
        result.add(newElement(tag, content))
        content.clear()
        newLineString = ""
        tag = nothing
      elif line.startsWith("* "):
        # nested bullet
        content.add(newLineString)
        newLineString = line[2 .. ^1]
      elif line.startsWith("~~~"):
        content.add(newLineString)
        result.add(newElement(tag, content))
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
    result.add(newElement(tag, @[newLineString]))
  of code:
    # code ended
    content.add(newLineString)
    content.add("")
    result.add(newElement(tag, content))
  of bullets:
    # bullets ended
    content.add(newLineString)
    result.add(newElement(tag, content))

func `$`*(element: Element): string =
  ## Return a string representation of an Element.
  result.add("---$1---\n" % $element.tag)
  for line in element.content:
    result.add(":$1" % line)

func `$`*(elements: seq[Element]): string =
  ## Return a string representation of a list of Elements.
  for element in elements:
    result.add($element)

type
  FragmentType* = enum
    ## Hightlight fragments.
    ## @:
    ## @:* ftType -- int, float, string, list, dict, bool, any, true, false
    ## @:* ftFunc -- a variable name followed by a left parenthesis
    ## @:* ftVarName -- a variable name
    ## @:* ftNumber -- a literal number
    ## @:* ftString -- a literal string
    ## @:* ftDocComment -- a ## to the end of the line
    ## @:* ftComment -- a # to the end of the line
    ftType
    ftFunc
    ftVarName
    ftNumber
    ftString
    ftDocComment
    ftComment

  Fragment* = object
    ## A fragment of a string.
    ## @:* kind -- the type of fragment
    ## @:* start -- the index in the string where the fragment starts
    ## @:* length -- the number of ascii characters in the fragment
    fragmentType*: FragmentType
    start*: Natural
    length*: Natural

func newFragment*(fragmentType: FragmentType, start: Natural, length: Natural): Fragment =
  result = Fragment(fragmentType: fragmentType, start: start, length: length)

func `$`*(f: Fragment): string =
  ## Return a string representation of a Fragment.
  result.add("$1, start: $2, length: $3" % [$f.fragmentType, $f.start, $f.length])

func `$`*(fragments: seq[Fragment]): string =
  ## Return a string representation of a sequence of fragments.
  if fragments.len == 0:
    return "no fragments"
  for f in fragments:
    result.add("$1, start: $2, length: $3\n" % [$f.fragmentType, $f.start, $f.length])

proc matchFragment*(line: string, start: Natural): Option[Fragment] =
  ## Match a highlight fragment starting at the given position.

  let numGroups = 7
  let typeP = r"(true|false|int|string|float|dict|list|any|bool)\b"
  let funcP = r"([a-zA-Z]+[a-zA-Z0-9\.\-_]*)\("
  let varNameP = r"([a-zA-Z]+[a-zA-Z0-9\.\-_]*)\b"
  let numP = r"(\-*[.0-9]*)\b"
  let stringP = r"($1(?:\\.|[^\$1])*$1)" % "\""
  let docCommentP = r"(##.*)"
  let commentP = r"(#.*)"
  let pattern = "$1|$2|$3|$4|$5|$6|$7" % [typeP, funcP, varNameP, numP, stringP, docCommentP, commentP]
  let matchesO = matchPatternCached(line, pattern, start, numGroups)
  if not matchesO.isSome:
    return
  let groups = getGroups(matchesO.get(), numGroups)
  for ix, group in groups:
    if group != "":
      let fragmentType = FragmentType(ix)
      return some(newFragment(fragmentType, start, matchesO.get().length))

proc highlightStaticTea*(codeLine: string): seq[Fragment] =
  ## Identify all the fragments in the StaticTea code line to
  ## highlight.
  var ix = 0
  while true:
    if ix >= codeLine.len:
      break
    let fragmentO = matchFragment(codeLine, ix)
    if fragmentO.isSome:
      let fragment = fragmentO.get()
      result.add(fragment)
      ix = ix + fragment.length
    else:
      inc(ix)
