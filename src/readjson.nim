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

func jsonToValue(jsonNode: JsonNode): Value {.tpub.} =
  case jsonNode.kind
  of JNull:
    result = Value(kind: vkInt, intv: 0)
  of JBool:
    result = Value(kind: vkInt, intv: if jsonNode.getBool(): 1 else: 0)
  of JInt:
    result = Value(kind: vkInt, intv: jsonNode.getInt())
  of JFloat:
    result = Value(kind: vkFloat, floatv: jsonNode.getFloat())
  of JString:
    result = Value(kind: vkString, stringv: jsonNode.getStr())
  of JObject:
    var objectVars = initTable[string, Value]()
    for key, jnode in jsonNode:
      let value = jsonToValue(jnode)
      objectVars[key] = value
    result = Value(kind: vkDict, dictv: objectVars)
  of JArray:
    var listVars: seq[Value]
    for jnode in jsonNode:
      let value = jsonToValue(jnode)
      listVars.add(value)
    result = Value(kind: vkList, listv: listVars)

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
