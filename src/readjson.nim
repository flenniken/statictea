## Read json files.

import warnings
import warnenv
import logenv
import tables
import tpub
import streams
import vartypes
import json

proc readJson*(filename: string, vars: var Table[string, Value]) =
  ## Read a json file and add the variables to the given vars table.

  let stream = newFileStream(filename)
  var rootNode: JsonNode
  try:
     rootNode = parseJson(stream, filename)
  except:
    warn("read json", 0, wJsonParseError, filename)
    return

  case rootNode.kind
  of JObject:
# iterator pairs(node: JsonNode): tuple[key: string, val: JsonNode] {...}
    echo "object"
    for key, val in rootNode:
      echo key, $val
  else:
    warn("read json", 0, wInvalidJsonRoot, filename)

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
