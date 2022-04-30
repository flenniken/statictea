## Read json content.

import std/streams
import std/os
import std/json
import std/tables
import vartypes
import messages
import warnings
import unicodes
import utf8decoder
import opresultwarn

# Json spec:
# https://datatracker.ietf.org/doc/html/rfc8259

when defined(test):
  var maxDepth* = 16
else:
  const 
    maxDepth = 16
      ## The maximum depth you can nest items.

type
  StrAndPos* = object
    ## StrAndPos holds the result of parsing a string literal, the
    ## @:string and the ending position.
    ## @:
    ## @:* str -- resulting parsed string
    ## @:* pos -- the position after the last trailing whitespace
    str*: string
    pos*: Natural

  StrAndPosOr* = OpResultWarn[StrAndPos]

func newStrAndPosOr*(warning: Warning, p1: string = "", pos = 0):
     StrAndPosOr =
  ## Return a new StrAndPosOr object containing a warning.
  let warningData = newWarningData(warning, p1, pos)
  result = opMessageW[StrAndPos](warningData)

func newStrAndPosOr*(warningData: WarningData): StrAndPosOr =
  ## Return a new StrAndPosOr object containing a warning.
  result = opMessageW[StrAndPos](warningData)

func newStrAndPosOr*(str: string, pos: Natural): StrAndPosOr =
  ## Return a new StrAndPosOr object containing a StrAndPos object.
  result = opValueW[StrAndPos](StrAndPos(str: str, pos: pos))

proc jsonToValue*(jsonNode: JsonNode, depth: int = 0): ValueOr =
  ## Convert a Nim json node to a statictea value.
  if depth > maxDepth:
    # The maximum JSON depth of $1 was exceeded.
    return newValueOr(wMaxDepthExceeded, $maxDepth)
  var value: Value
  case jsonNode.kind
  of JNull:
    # JSON nulls become 0.
    value = newValue(0)
  of JBool:
    # JSON true becomes 1 and false becomes 0.
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
      let valueOr = jsonToValue(jnode, newDepth)
      if valueOr.isMessage:
        return valueOr
      dict[key] = valueOr.value
    value = newValue(dict)
  of JArray:
    var newDepth = depth + 1
    var list: seq[Value]
    for jnode in jsonNode:
      let valueOr = jsonToValue(jnode, newDepth)
      if valueOr.isMessage:
        return valueOr
      list.add(valueOr.value)
    value = newValue(list)
  result = newValueOr(value)

proc readJsonStream*(stream: Stream): ValueOr =
  ## Read a json stream and return the variables in a dictionary
  ## value.
  assert stream != nil

  var rootNode: JsonNode
  try:
    rootNode = parseJson(stream, "")
  except:
    # Unable to parse the JSON.
    return newValueOr(wJsonParseError)
  result = jsonToValue(rootNode)

proc readJsonString*(content: string): ValueOr =
  ## Read a json string and return the variables in a dictionary
  ## value.
  var stream = newStringStream(content)
  assert stream != nil
  result = readJsonStream(stream)

proc readJsonFile*(filename: string): ValueOr =
  ## Read a json file and return the variables in a dictionary value.

  if not fileExists(filename):
    # File not found: $1.
    return newValueOr(wFileNotFound, filename)

  # Create a stream out of the file.
  var stream: Stream
  stream = newFileStream(filename)
  if stream == nil:
    # Unable to open file: $1.
    return newValueOr(wUnableToOpenFile, filename)

  result = readJsonStream(stream)
  if result.isValue:
    if result.value.kind != vkDict:
      # The root json element must be an object (dictionary).
      result = newValueOr(wInvalidJsonRoot)

proc unescapePopularChar*(popular: char): char =
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


  # Order by popularity.
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

func parseJsonStr*(text: string, startPos: Natural): StrAndPosOr =
  ## Parse the quoted json string literal. The startPos points one
  ## @:past the leading double quote.  Return the parsed string value
  ## @:and the ending position one past the trailing whitespace. On
  ## @:failure, the ending position points at the invalid character and
  ## @:the message id tells what went wrong.
  ## @:
  ## @:~~~
  ## @:a = "test string"  \\n
  ## @:     ^             ^
  ## @:~~~~

  assert(startPos < text.len, "startPos is greater than the text len")
  assert(startPos >= 0, "startPos is less than 0")

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

  # Loop through the text one unicode character at a time and add to
  # the result string.
  while true:
    case state
    of middle:
      # Get the text byte at pos. Return 0 when pos is past the end of
      # the string. Zeros are allowed in strings but they must be
      # quoted.
      case getChar(text, pos):
      of '\0':
        # No ending double quote.
        return newStrAndPosOr(wNoEndingQuote, "", pos)
      of '\\':
        state = slash
        inc(pos)
      of '"':
        state = whitespace
        inc(pos)
      of char(1)..char(0x1f):
        # Controls characters must be escaped.
        return newStrAndPosOr(wControlNotEscaped, "", pos)
      else:
        # Get the unicode character at pos.
        let str = utf8CharString(text, pos)
        if str.len == 0:
          # Invalid UTF-8 unicode character.
          return newStrAndPosOr(wInvalidUtf8, "", pos)

        # Add the unicode character to the result string.
        newStr.add(str)
        pos += str.len()
    of slash:
      case getChar(text, pos)
      of 'u':
        let strOrc = parseHexUnicodeToString(text, pos)
        if strOrc.isMessage:
          return newStrAndPosOr(strOrc.message, "", pos)
        newStr.add(strOrc.value)
      else:
        let ch = unescapePopularChar(getChar(text, pos))
        if ch == '\0':
          # A slash must be followed by one letter from: nr"t\bf/.
          return newStrAndPosOr(wNotPopular, "", pos)
        newStr.add(ch)
        inc(pos)
      state = middle
    of whitespace:
      case getChar(text, pos):
      of ' ', '\t':
        inc(pos)
      else:
        break

  result = newStrAndPosOr(newStr, pos)
