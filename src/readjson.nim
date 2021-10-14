## Read json content.

import std/streams
import std/os
import std/options
import std/json
import std/tables
import std/unicode
import warnings
import tpub
import vartypes

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
  StringPos* = object
    str*: string
    pos*: Natural
    message*: string

func newStringPos*(str: string, pos: Natural, message = ""): StringPos =
  ## Create a new StringPos object.
  result = StringPos(str: str, pos: pos, message: message)

# Json spec:
# https://datatracker.ietf.org/doc/html/rfc8259

proc unescapePopularChar*(popular: char): char =
  ## Unescape the popular char and return its value. If the char is
  ## not a popular char, return 0.

# Popular characters and their escape values:
#
# character  name          uncode
#
# 0x22  "  quotation mark  U+0022
# 0x5C  \  reverse solidus U+005C
# 0x2F  /  solidus         U+002F
# 0x62  b  backspace       U+0008
# 0x66  f  form feed       U+000C
# 0x6E  n  line feed       U+000A
# 0x72  r  carriage return U+000D
# 0x74  t  tab             U+0009

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

proc parseHexUnicode16*(text: string, pos: var Natural, num: var int32): string =
  ## Return the unicode number given a 4 character unicode escape
  ## string like u1234 and advance the pos and return "". On error,
  ## return a message.  Pos is pointing at the u.
  const
    errorMsg = r"A \u must be followed by 4 hex digits."
  inc(pos)
  num = 0
  for shift in [8, 4, 2, 0]:
    # 0000 0000
    let digit = text[pos]
    let digitOrd = int32(ord(digit))
    case digit
    of char(0):
      # Hit the ending null terminator.
      return errorMsg
    of '0'..'9':
      num = num or (digitOrd - int32(ord('0')) shl shift)
    of 'a'..'z':
      num = num or ((digitOrd - int32(ord('a')) + 10) shl shift)
    of 'A'..'Z':
      num = num or ((digitOrd - int32(ord('A')) + 10) shl shift)
    else:
      return errorMsg
    inc(pos)

proc parseHexUnicode*(text: string, pos: var Natural, parsedString: var string): string =
  ## Add the json unicode escape characters to the parsed string and
  ## advance the pos and return "". On error, return a message.
  ## Pos is pointing at the u.
  ## u1234 or u1234\u1234

  var num: int32
  let msg = parseHexUnicode16(text, pos, num)
  if msg != "":
    return msg

  # If not a surrogate pair, add the character and return.
  if (num and 0xfc00) != 0xd800:
    parsedString.add(char(num))
    return

  if text[pos] != '\\' or text[pos+1] != 'u':
    return "Missing the second surrogate pair."

  inc(pos)
  var second: int32
  let m = parseHexUnicode16(text, pos, second)
  if m != "":
    return m

  # Make sure second is a second surrogate pair.
  if (second and 0xfc00) != 0xdc00:
    return "Not matching surrogate pair."

  num = 0x10000 + (((num - 0xd800) shl 10) or (second - 0xdc00))
  parsedString.add(char(num))

proc parseJsonStr*(text: string, startPos: Natural): StringPos =
  ## Parse the quoted json string literal. On success return the
  ## string value, the ending position, and an empty message. On
  ## failure return the string value, the ending position where
  ## parsing stopped and a message telling what's wrong. The startPos
  ## points one past the leading double quote.

  type
    State = enum
      ## Parsing states.
      middle, slash

  var state = middle
  var parsedString = newStringOfCap(text.len - startPos)
  var pos = startPos
  var message: string

  # Loop through the text one unicode character at a time and add to
  # the result string.
  while true:
    case state
    of middle:
      case text[pos]:
      of '\\':
        state = slash
        inc(pos)
      of '"':
        # Found ending quote, done.
        break
      of char(0):
        # Nim strings are null terminated and 0 must be escaped in a
        # json string. If we get a 0, it's an error, assume we hit the
        # terminating 0.
        message = "No ending double quote."
      of char(1)..char(0x1f):
        message = "Controls characters must be escaped."
        break
      else:
        # Add the unicode character to the result string.
        let rune = runeAt(text, pos)
        let str = toUtf8(rune)
        parsedString.add(str)
        pos += str.len
    of slash:
      case text[pos]
      of 'u':
        message = parseHexUnicode(text, pos, parsedString)
        if message == "":
          break
      else:
        let ch = unescapePopularChar(text[pos])
        if ch == char(0):
          message = """A slash must be followed by one letter from: nr"t\bf/."""
          break
        parsedString.add(ch)
        inc(pos)
      state = middle

  result = newStringPos(parsedString, pos, message)
