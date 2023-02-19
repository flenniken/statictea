## Parse the simple markdown used in the function descriptions.

import std/strutils
import lineBuffer

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
  ## @:* p -- a paragraph
  ## @:* code -- a code block
  ## @:* bullets -- a list of bullet points

  # result = [
  #   ["p", [nl-string],
  #   ["code", [~~~line, nl-string, ~~~line],
  #   ["bullets", [nl-string, nl-string, nl-string, ...],
  # ]

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
        if newLineString != "":
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
