## Read json files.

import warnings
import env
import tables
import tpub
import streams
import vartypes
import json
import os
import json
import options

var depth_limit = 3

func getEmptyVars*(): VarsDict =
  result = initOrderedTable[string, Value]()

proc jsonToValue(jsonNode: JsonNode, depth: int = 0): Option[Value] {.tpub.} =
  if depth > depth_limit:
    return none(Value)
  var value: Value
  case jsonNode.kind
  of JNull:
    value = Value(kind: vkInt, intv: 0)
  of JBool:
    value = Value(kind: vkInt, intv: if jsonNode.getBool(): 1 else: 0)
  of JInt:
    value = Value(kind: vkInt, intv: jsonNode.getInt())
  of JFloat:
    value = Value(kind: vkFloat, floatv: jsonNode.getFloat())
  of JString:
    value = Value(kind: vkString, stringv: jsonNode.getStr())
  of JObject:
    var objectVars = getEmptyVars()
    for key, jnode in jsonNode:
      let option = jsonToValue(jnode, depth + 1)
      if option.isSome():
        objectVars[key] = option.get()
    value = Value(kind: vkDict, dictv: objectVars)
  of JArray:
    var listVars: seq[Value]
    for jnode in jsonNode:
      let option = jsonToValue(jnode, depth)
      assert option.isSome
      listVars.add(option.get())
    value = Value(kind: vkList, listv: listVars)
  result = some(value)

proc readJson*(env: var Env, filename: string, vars: var VarsDict) =
  ## Read a json file and add the variables to the vars dictionary.

  if not fileExists(filename):
    env.warn(0, wFileNotFound, filename)
    return

  var stream: Stream
  stream = newFileStream(filename)
  if stream == nil:
    env.warn(0, wUnableToOpenFile, filename)
    return

  var rootNode: JsonNode
  try:
    rootNode = parseJson(stream, filename)
  except:
    let message =  getCurrentExceptionMsg()
    env.log(message)
    env.warn(0, wJsonParseError, filename)
    return

  if rootNode.kind != JObject:
    env.warn(0, wInvalidJsonRoot, filename)
    return

  for key, jnode in rootNode:
    let valueO = jsonToValue(jnode)
    assert valueO.isSome
    vars[key] = valueO.get()
