## Read json files.

import warnings
import warnenv
# import logenv
import tables
# import tpub
import streams
import vartypes
import json
import os

proc readJson*(filename: string, vars: var Table[string, Value]) =
  ## Read a json file and add the variables to the given vars table.

  if not fileExists(filename):
    warn("read json", 0, wFileNotFound, filename)
    return

  var stream: Stream
  try:
    stream = newFileStream(filename)
  except:
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

  echo "object"
  for key, val in rootNode:
    echo key, $val

# jsonNode.kind == JObject
#     getInt
#     getFloat
#     getStr
#     getBool
#     getFloat
#     getStr
#     getBool
# JsonNodeKind = enum
#   JNull, JBool, JInt, JFloat, JString, JObject, JArray

#   of JObject:
#       fields*: OrderedTable[string, JsonNode]

#   of JArray:
#       elems*: seq[JsonNode]
