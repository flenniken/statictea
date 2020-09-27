## Read json files.

import warnings
import warnenv
# import logenv
import tables
import tpub
import streams
import vartypes
import json
import os
import json

func jsonToValue(val: JsonNode): Value {.tpub.} =
  case val.kind
  of JNull:
    result = nil
  of JBool:
    result = Value(kind: vkInt, intv: if val.getBool(): 1 else: 0)
  of JInt:
    result = Value(kind: vkInt, intv: val.getInt())
  of JFloat:
    result = Value(kind: vkFloat, floatv: val.getFloat())
  of JString:
    result = Value(kind: vkString, stringv: val.getStr())
  of JObject:
    result = nil
  of JArray:
    result = nil

proc readJson*(filename: string, vars: var Table[string, Value]) =
  ## Read a json file and add the variables to the given vars table.

  if not fileExists(filename):
    warn("read json", 0, wFileNotFound, filename)
    return

  var stream: Stream
  stream = newFileStream(filename)
  if stream == nil:
    warn("read json", 0, wUnableToOpenFile, filename)
    return

  var rootNode: JsonNode
  try:
     rootNode = parseJson(stream, filename)
  except:
    warn("read json", 0, wJsonParseError, filename)
    return

  if rootNode.kind != JObject:
    warn("read json", 0, wInvalidJsonRoot, filename)
    return

  for key, val in rootNode:
    # echo "$1 = $2" % [key, $val]
    let value = jsonToValue(val)
    if value != nil:
      vars[key] = value

# jsonNode.kind == JObject
#     getInt
#     getFloat
#     getStr
#     getBool
# JsonNodeKind = enum
#   JNull, JBool, JInt, JFloat, JString, JObject, JArray

#   of JObject:
#       fields*: OrderedTable[string, JsonNode]

#   of JArray:
#       elems*: seq[JsonNode]
