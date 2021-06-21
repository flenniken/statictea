## Read json content.

import std/streams
import std/os
import std/options
import std/json
import std/tables
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

proc readJsonFiles*(filenames: seq[string]): ValueOrWarning =
  ## Read json files and return the variables. If there is an error,
  ## return a warning. A duplicate variable is skipped and it
  ## generates a warning.

  var varsDict = newVarsDict()
  for filename in filenames:
    let valueOrWarning = readJsonFile(filename)
    if valueOrWarning.kind == vwWarning:
      return valueOrWarning

    # Merge in the variables.
    for k, v in valueOrWarning.value.dictv.pairs:
      varsDict[k] = v

  # todo: geneate a warning on duplicate variables.
  result = newValueOrWarning(newValue(varsDict))
