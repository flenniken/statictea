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
import args
import vartypes

# todo: test the the order is preserved.
# todo: test that the last duplicate wins.

# todo: increase the depth limit and document it. Make it a parameter?
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
    value = Value(kind: vkInt, intv: jsonNode.getInt())
  of JFloat:
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

proc readJsonContent*(stream: Stream, filename: string = ""): ValueOrWarning =
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

  # todo: allow any kind of object?
  if rootNode.kind != JObject:
    return newValueOrWarning(wInvalidJsonRoot, filename)

  var dict = newVarsDict()
  for key, jnode in rootNode:
    let valueO = jsonToValue(jnode)
    assert valueO.isSome
    dict[key] = valueO.get()

  result = newValueOrWarning(newValue(dict))

proc readJsonContent*(content: string, filename: string = ""): ValueOrWarning =
  ## Read a json string and return the variables.  If there is an
  ## error, return a warning. The filename is used in warning
  ## messages.
  var stream = newStringStream(content)
  result = readJsonContent(stream, filename)

proc readJson*(filename: string): ValueOrWarning =
  ## Read a json string and return the variables.  If there is an
  ## error, return a warning. The filename is used in warning
  ## messages.

  if not fileExists(filename):
    return newValueOrWarning(wFileNotFound, filename)

  var stream: Stream
  stream = newFileStream(filename)
  if stream == nil:
    return newValueOrWarning(wUnableToOpenFile, filename)

  result = readJsonContent(stream, filename)

proc readJsonFiles*(env: var Env, filenames: seq[string]): VarsDict =
  ## Read the json files and return the variables in one
  ## dictionary. The last file wins on duplicates.

  result = newVarsDict()
  for filename in filenames:
    let valueOrWarning = readJson(filename)
    if valueOrWarning.kind == vwWarning:
      env.warn(0, valueOrWarning.warningData)
    else:
      # Merge in the variables.
      for k, v in valueOrWarning.value.dictv.pairs:
        result[k] = v

proc readServerVariables*(env: var Env, args: Args): VarsDict =
  ## Read the server json.
  result = readJsonFiles(env, args.serverList)

proc readSharedVariables*(env: var Env, args: Args): VarsDict =
  ## Read the shared json.
  result = readJsonFiles(env, args.sharedList)
