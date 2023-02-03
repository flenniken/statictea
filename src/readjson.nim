## Read json content.

import std/streams
import std/os
import std/json
import std/tables
import vartypes
import messages
import unicodes
import utf8decoder
import opresult

# Json spec:
# https://datatracker.ietf.org/doc/html/rfc8259

# Test code can set the max depth.
when defined(test):
  var maxDepth* = 16
else:
  const
    maxDepth* = 16
      ## The maximum depth you can nest items.

func jsonToValue*(jsonNode: JsonNode, depth: int = 0, mutable = Mutable.immutable): ValueOr =
  ## Convert a Nim json node to a statictea value. The mutable
  ## variable determines whether lists and dictionaries are mutable.

  # When testing remove the side effect so the function can be defined
  # as func.
  when defined(test):
    {.cast(noSideEffect).}:
      if depth > maxDepth:
        # The maximum JSON depth of $1 was exceeded.
        return newValueOr(wMaxDepthExceeded, $maxDepth)
  else:
    if depth > maxDepth:
      # The maximum JSON depth of $1 was exceeded.
      return newValueOr(wMaxDepthExceeded, $maxDepth)

  var value: Value
  case jsonNode.kind
  of JNull:
    # JSON nulls become 0.
    value = newValue(0)
  of JBool:
    value = newValue(jsonNode.getBool())
  of JInt:
    value = newValue(jsonNode.getInt())
  of JFloat:
    value = newValue(jsonNode.getFloat())
  of JString:
    value = newValue(jsonNode.getStr())
  of JObject:
    var newDepth = depth + 1
    var dict = newVarsDict()
    for key, jnode in jsonNode:
      let valueOr = jsonToValue(jnode, newDepth, mutable)
      if valueOr.isMessage:
        return valueOr
      dict[key] = valueOr.value
    value = newValue(dict, mutable)
  of JArray:
    var newDepth = depth + 1
    var list: seq[Value]
    for jnode in jsonNode:
      let valueOr = jsonToValue(jnode, newDepth, mutable)
      if valueOr.isMessage:
        return valueOr
      list.add(valueOr.value)
    value = newValue(list, mutable)
  result = newValueOr(value)

func readJsonStream*(stream: Stream, mutable = Mutable.immutable): ValueOr =
  ## Read a json stream and return the parsed data in a value object
  ## or return a warning. The mutable variable determines whether
  ## lists and dictionaries are mutable.
  if stream == nil:
    return newValueOr(wJsonParseError)

  var rootNode: JsonNode
  try:
    {.cast(noSideEffect).}:
      rootNode = parseJson(stream, "")
  except:
    # Unable to parse the JSON.
    return newValueOr(wJsonParseError)
  result = jsonToValue(rootNode, mutable = mutable)

func readJsonString*(content: string, mutable = Mutable.immutable): ValueOr =
  ## Read a json string and return the parsed data in a value object
  ## or return a warning. The mutable variable determines whether
  ## lists and dictionaries are mutable.
  var stream = newStringStream(content)
  if stream == nil:
    # Unable to create a stream object.
    return newValueOr(wUnableCreateStream)
  result = readJsonStream(stream, mutable)

proc readJsonFile*(filename: string, mutable = Mutable.immutable): ValueOr =
  ## Read a json file and return the parsed data in a value object or
  ## return a warning. A warning is returned when the root object is
  ## not a dictionary.

  if not fileExists(filename):
    # File not found: $1.
    return newValueOr(wFileNotFound, filename)

  # Create a stream out of the file.
  var stream: Stream
  stream = newFileStream(filename)
  if stream == nil:
    # Unable to open file: $1.
    return newValueOr(wUnableToOpenFile, filename)
  defer:
    # Close the stream and file at the end.
    stream.close()

  result = readJsonStream(stream, mutable)
  if result.isValue:
    if result.value.kind != vkDict:
      # The root json element must be an object (dictionary).
      result = newValueOr(wInvalidJsonRoot)

func unescapePopularChar*(popular: char): char =
  ## Unescape the popular char and return its value. If the char is
  ## @:not a popular char, return 0.
  ## @:
  ## @: Popular characters and their escape values:
  ## @:
  ## @:@!char      @! name           @! unicode@!
  ## @:@!----------@!----------------@!--------@!
  ## @:@!"         @! quotation mark @! U+0022 @!
  ## @:@!\\        @! reverse solidus@! U+005C @!
  ## @:@!/         @! solidus        @! U+002F @!
  ## @:@!b         @! backspace      @! U+0008 @!
  ## @:@!f         @! form feed      @! U+000C @!
  ## @:@!n         @! line feed      @! U+000A @!
  ## @:@!r         @! carriage return@! U+000D @!
  ## @:@!t         @! tab            @! U+0009 @!

  # Order by popularity: nr"t\bf/
  case popular
  of 'n':
    result = char(0x0a)
  of 'r':
    result = char(0x0d)
  of '"':
    result = '"'
  of 't':
    result = char(0x09)
  of '\\':
    result = '\\'
  of 'b':
    result = char(0x08)
  of 'f':
    result = char(0x0c)
  of '/':
    result = '/'
  else:
    # Invalid popular character, return 0.
    result = char(0)

func parseJsonStr*(text: string, startPos: Natural): ValuePosSiOr =
  ## Parse the quoted json string literal. The startPos points one
  ## @:past the leading double quote.  Return the parsed string value
  ## @:and the ending position after the trailing whitespace. On
  ## @:failure, the ending position points at the invalid character and
  ## @:the message id tells what went wrong.
  ## @:
  ## @:~~~
  ## @:a = "test string"  # test
  ## @:     ^             ^
  ## @:~~~~

  if startPos >= text.len:
    return newValuePosSiOr(wStartPosTooBig, "", startPos)

  type
    State = enum
      ## Parsing states.
      middle, slash, whitespace

  func getChar(text: string, pos: Natural): char =
    ## Get the char at the given position. If pos is past the end of
    ## the text, return 0.
    if pos < text.len:
      result = text[pos]
    else:
      result = '\0'

  var state = middle
  var newStr = newStringOfCap((text.len - startPos) * 2)
  var pos = startPos

  # Loop through the text one byte or one unicode character at a time
  # and add to the result string.
  while true:
    case state
    of middle:
      # Get the text byte at pos. Return 0 when pos is past the end of
      # the string. Zeros are allowed in strings but they must be
      # quoted.
      case getChar(text, pos):
      of '\0':
        # No ending double quote.
        return newValuePosSiOr(wNoEndingQuote, "", pos)
      of '\\':
        state = slash
        inc(pos)
      of '"':
        state = whitespace
        inc(pos)
      of char(1)..char(0x1f):
        # Controls characters must be escaped.
        return newValuePosSiOr(wControlNotEscaped, "", pos)
      else:
        # Get the unicode character at pos.
        let str = utf8CharString(text, pos)
        if str.len == 0:
          # Invalid UTF-8 byte sequence at position $1.
          return newValuePosSiOr(wInvalidUtf8ByteSeq, $pos, pos)

        # Add the unicode character to the result string.
        newStr.add(str)
        pos += str.len()
    of slash:
      case getChar(text, pos)
      of 'u':
        let strOrc = parseHexUnicodeToString(text, pos)
        if strOrc.isMessage:
          return newValuePosSiOr(strOrc.message, "", pos)
        newStr.add(strOrc.value)
      else:
        let ch = unescapePopularChar(getChar(text, pos))
        if ch == '\0':
          # A slash must be followed by one letter from: nr"t\bf/.
          return newValuePosSiOr(wNotPopular, "", pos)
        newStr.add(ch)
        inc(pos)
      state = middle
    of whitespace:
      case getChar(text, pos):
      of ' ', '\t', '\n', '\r':
        inc(pos)
      else:
        break

  result = newValuePosSiOr(newValue(newStr), pos)
