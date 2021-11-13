## Read json content.

import std/streams
import std/os
import std/options
import std/json
import std/tables
import std/unicode
import tpub
import vartypes
import messages
import opresultid
import unicodes

# Json spec:
# https://datatracker.ietf.org/doc/html/rfc8259

# todo: test the the order is preserved.

var depth_limit = 3

proc jsonToValue(jsonNode: JsonNode, depth: int = 0): Option[Value] {.tpub.} =
  ## Convert a json value to a statictea value.
  if depth > depth_limit:
    # todo: test the depth limit.
    # todo: display warning when limit exceeded.
    # todo: document the depth limit.
    return none(Value)
  var value: Value
  case jsonNode.kind
  of JNull:
    value = Value(kind: vkInt, intv: 0)
  of JBool:
    value = Value(kind: vkInt, intv: if jsonNode.getBool(): 1 else: 0)
  of JInt:
    # todo: range check int to 64 bit.
    value = Value(kind: vkInt, intv: jsonNode.getInt())
  of JFloat:
    # todo: range check float to 64 bit.
    value = Value(kind: vkFloat, floatv: jsonNode.getFloat())
  of JString:
    value = Value(kind: vkString, stringv: jsonNode.getStr())
  of JObject:
    var dict = newVarsDict()
    for key, jnode in jsonNode:
      let option = jsonToValue(jnode, depth + 1)
      if option.isSome():
        dict[key] = option.get()
    value = Value(kind: vkDict, dictv: dict)
  of JArray:
    var listVars: seq[Value]
    for jnode in jsonNode:
      let option = jsonToValue(jnode, depth)
      assert option.isSome
      listVars.add(option.get())
    value = Value(kind: vkList, listv: listVars)
  result = some(value)

proc readJsonStream*(stream: Stream, filename: string = ""): ValueOrWarning =
  ## Read a json stream and return the variables.  If there is an
  ## error, return a warning. The filename is used in warning
  ## messages.

  if stream == nil:
    return newValueOrWarning(wUnableToOpenFile, filename)

  var rootNode: JsonNode
  try:
    rootNode = parseJson(stream, filename)
  except:
    return newValueOrWarning(wJsonParseError, filename)

  # todo: allow any kind of object.
  if rootNode.kind != JObject:
    return newValueOrWarning(wInvalidJsonRoot, filename)

  var dict = newVarsDict()
  for key, jnode in rootNode:
    let valueO = jsonToValue(jnode)
    assert valueO.isSome
    dict[key] = valueO.get()

  result = newValueOrWarning(newValue(dict))

proc readJsonString*(content: string, filename: string = ""): ValueOrWarning =
  ## Read a json string and return the variables.  If there is an
  ## error, return a warning. The filename is used in warning
  ## messages.
  var stream = newStringStream(content)
  result = readJsonStream(stream, filename)

proc readJsonFile*(filename: string): ValueOrWarning =
  ## Read a json file and return the variables.  If there is an
  ## error, return a warning.

  if not fileExists(filename):
    return newValueOrWarning(wFileNotFound, filename)

  var stream: Stream
  stream = newFileStream(filename)
  if stream == nil:
    return newValueOrWarning(wUnableToOpenFile, filename)

  result = readJsonStream(stream, filename)

type
  ParsedString* = object
    ## ParsedString holds the result of parsing a string literal. The
    ## resulting parsed string and the ending string position.
    str*: string  ## Resulting parsed string.
    pos*: Natural ## The position after the last trailing whitespace
                  ## or the position at the first invalid character.
    messageId*: MessageId ## Message id is 0 when the string was
                          ## successfully parsed, else it is the
                          ## message id telling what went wrong.

func newParsedString*(str: string, pos: Natural, messageId: MessageId): ParsedString =
  ## Create a new ParsedString object.
  result = ParsedString(str: str, pos: pos, messageId: messageId)

proc unescapePopularChar*(popular: char): char =
  ## Unescape the popular char and return its value. If the char is
  ## not a popular char, return 0.

  # Popular characters and their escape values:
  #
  # character  name    uncode
  # --+---------------+------
  # "  quotation mark  U+0022
  # \  reverse solidus U+005C
  # /  solidus         U+002F
  # b  backspace       U+0008
  # f  form feed       U+000C
  # n  line feed       U+000A
  # r  carriage return U+000D
  # t  tab             U+0009

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

proc parseHexUnicode16*(text: string, start: Natural): OpResultId[int32] =
  ## Return the unicode number given a 4 character unicode escape
  ## string like u1234. Start is pointing at the u. On error, return a
  ## message id telling what went wrong.

  if start + 5 > text.len:
    return newOpResultIdId[int32](wFourHexDigits)

  var pos = start
  inc(pos)

  var num = 0i32
  for shift in [12, 8, 4, 0]:
    # 0000 0000 0000 0000
    #u   f    f    f    f
    let digit = text[pos]
    let digitOrd = int32(ord(digit))
    case digit
    of '0'..'9':
      num = num or ((digitOrd - int32(ord('0'))) shl shift)
    of 'a'..'f':
      num = num or ((digitOrd - int32(ord('a')) + 10) shl shift)
    of 'A'..'F':
      num = num or ((digitOrd - int32(ord('A')) + 10) shl shift)
    else:
      # A \u must be followed by 4 hex digits.
      return newOpResultIdId[int32](wFourHexDigits)
    inc(pos)
  result = newOpResultId[int32](num)

proc parseHexUnicode*(text: string, pos: var Natural): OpResultId[int32] =
  ## Return the unicode number given a 4 or 8 character unicode escape
  ## string like u1234 or u1234\u1234 and advance the pos. Pos is
  ## initially pointing at the u. On error, return the message id
  ## telling what went wrong.

  let numOrc = parseHexUnicode16(text, pos)
  if numOrc.isMessageId:
    return numOrc
  var num = numOrc.value
  pos += 5

  if (num and 0xfc00) != 0xd800:
    if (num and 0xfc00) == 0xdc00:
      # Invalid leading surrogate pair.
      return newOpResultIdId[int32](wLowSurrogateFirst)
    if num == 0xff or num == 0xfe or num == 0xffff or num == 0xfffe:
      # Invalid utf-8 bytes.
      return newOpResultIdId[int32](wInvalidUtf8)
    # Add the character and return.
    return newOpResultId[int32](num)

  if pos + 6 > text.len or text[pos] != '\\' or text[pos+1] != 'u':
    # Missing the second surrogate pair.
    return newOpResultIdId[int32](wMissingSurrogatePair)

  inc(pos)

  let secondOrc = parseHexUnicode16(text, pos)
  if secondOrc.isMessageId:
    return secondOrc
  var second = secondOrc.value
  pos += 5

  if (second and 0xfc00) != 0xdc00:
    # The second value is not a matching surrogate pair.
    return newOpResultIdId[int32](wNotMatchingSurrogate)

  if second == 0xDC00 or second == 0xDFFF:
    # Invalid paired surrogate.
    return newOpResultIdId[int32](wPairedSurrogate)

  num = 0x10000 + (((num - 0xd800) shl 10) or (second - 0xdc00))
  result = newOpResultId[int32](num)

proc parseJsonStr*(text: string, startPos: Natural): ParsedString =
  ## Parse the quoted json string literal. The startPos points one
  ## past the leading double quote.  Return the parsed string value
  ## and the ending position one past the trailing whitespace. On
  ## failure, the ending position points at the invalid character and
  ## the message id tells what went wrong.

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
        return newParsedString("", pos, wNoEndingQuote)
      of '\\':
        state = slash
        inc(pos)
      of '"':
        state = whitespace
        inc(pos)
      of char(1)..char(0x1f):
        # Controls characters must be escaped.
        return newParsedString("", pos, wControlNotEscaped)
      else:
        # Get the unicode character at pos and increment pos one past
        # it.
        let str = utf8CharString(text, pos)
        if str.len == 0:
          # Invalid utf-8 unicode character.
          return newParsedString("", pos, wInvalidUtf8)

        # Add the unicode character to the result string.
        newStr.add(str)
    of slash:
      case getChar(text, pos)
      of 'u':
        let numOrc = parseHexUnicode(text, pos)
        if numOrc.isMessageId:
          return newParsedString("", pos, numOrc.messageId)
        let str = toUtf8(Rune(numOrc.value))
        newStr.add(str)
      else:
        let ch = unescapePopularChar(getChar(text, pos))
        if ch == '\0':
          # A slash must be followed by one letter from: nr"t\bf/.
          return newParsedString("", pos, wNotPopular)
        newStr.add(ch)
        inc(pos)
      state = middle
    of whitespace:
      case getChar(text, pos):
      of ' ', '\t':
        inc(pos)
      else:
        break

  result = newParsedString(newStr, pos, wSuccess)
