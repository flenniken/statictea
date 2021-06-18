## Language variable methods.
## @:
## @: Here are the tea variables:
## @:
## @: - t.content -- content of the replace block.
## @: - t.maxLines -- maximum number of replacement block lines (lines before endblock).
## @: - t.maxRepeat -- maximum number of times to repeat the block.
## @: - t.output -- where the block output goes.
## @: - t.repeat -- controls how many times the block repeats.
## @: - t.row -- the current row number of a repeating block.
## @: - t.version -- the StaticTea version number.
## @:
## @: Here are the tea variables grouped by type:
## @:
## @: Constant:
## @:
## @: - t.version
## @:
## @: Dictionaries:
## @:
## @: - t -- tea system variables
## @: - l -- local variables
## @: - s -- read only server json variables
## @: - h -- read only shared json variables
## @: - f -- reserved
## @: - g -- global variables
## @:
## @: Integers:
## @:
## @: - t.maxLines -- default when not set: 50
## @: - t.maxRepeat -- default when not set: 100
## @: - t.repeat -- default when not set: 1
## @: - t.row -- 0 read only, automatically increments
## @:
## @: String:
## @:
## @: - t.content -- default when not set: ""
## @:
## @: String enum t.output:
## @:
## @: - "result" -- the block output goes to the result file (default)
## @: - "stderr" -- the block output goes to standard error
## @: - "log" -- the block output goes to the log file
## @: - "skip" -- the block is skipped

# The variables are stored in logically separate name spaces, g, h, s,
# t. Since we allow local variables without a namespace, we don't
# allow local variables called g, h, s and t so it is clear which name
# space each variable belongs to.  It would be confusing to allow a t
# local variable which is a dictionary then t.row would mean two
# different things.
#
# We implement the name spaces by storing them all in the same
# variables dictionary to make it easy to pass around.

import std/strutils
import std/options
import std/tables
import vartypes
import version
import warnings
import tostring

const
  outputValues* = ["result", "stderr", "log", "skip"]
    ## Tea output variable values.

type
  Variables* = VarsDict
    ## Dictionary holding all statictea variables.

  VariableData* = object
    ## A variable name and value. The names tells where the
    ## variable is stored, i.e.: s.varName
    # todo: using dotNameStr instead of sequence of names?
    names*: seq[string]
    value*: Value

  ParentDictKind* = enum
    ## The kind of a ParentDict object, either a dict or warning.
    fdDict,
    fdWarning

  ParentDict* = object
    ## Contains the result of calling getParentDict, either a dictionary
    ## or a warning.
    case kind*: ParentDictKind
      of fdDict:
        dict*: VarsDict
      of fdWarning:
        warningData*: WarningData

func `$`*(parentDict: ParentDict): string =
  ## Return a string representation of ParentDict.
  var msg: string
  case parentDict.kind
  of fdDict:
    msg = $parentDict.dict
  of fdWarning:
    msg = $parentDict.warningData
  result = "ParentDict: $1, $2" % [$parentDict.kind, msg]

func `==`*(s1: ParentDict, s2: ParentDict): bool =
  ## Return true when the two ParentDict are equal.
  if s1.kind == s2.kind:
    case s1.kind
    of fdDict:
      if s1.dict == s2.dict:
        result = true
    of fdWarning:
      if s1.warningData == s2.warningData:
        result = true

func newParentDictWarn*(warning: Warning, p1: string = "", p2: string = ""): ParentDict =
  ## Return a new ParentDict object of the warning kind. It contains a
  ## warning and the two optional strings that go with the warning.
  let warningData = newWarningData(warning, p1, p2)
  result = ParentDict(kind: fdWarning, warningData: warningData)

func newParentDict*(dict: VarsDict): ParentDict =
  ## Return a new ParentDict object containing a dict.
  result = ParentDict(kind: fdDict, dict: dict)

func emptyVariables*(server: VarsDict = nil, shared: VarsDict = nil): Variables =
  ## Create an empty variables object in its initial state.
  result = newVarsDict()
  if server == nil:
    result["s"] = newValue(newVarsDict())
  else:
    result["s"] = newValue(server)
  if shared == nil:
    result["h"] = newValue(newVarsDict())
  else:
    result["h"] = newValue(shared)
  result["l"] = newValue(newVarsDict())
  result["g"] = newValue(newVarsDict())
  result["row"] = newValue(0)
  result["version"] = newValue(staticteaVersion)

func newVariableData*(dotNameStr: string, value: Value): VariableData =
  ## Create a new VariableData object.
  let names = split(dotNameStr, '.')
  result = VariableData(names: names, value: value)

func getTeaVarIntDefault*(variables: Variables, varName: string): int64 =
  ## Return the int value of one of the tea dictionary integer
  ## items. If the value does not exist, return its default value.
  assert varName in ["row", "repeat", "maxRepeat", "maxLines"]
  if varName in variables:
    let value = variables[varName]
    assert value.kind == vkInt
    result = value.intv
  else:
    case varName:
      of "row":
        result = 0
      of "repeat":
        result = 1
      of "maxLines":
        result = 50
      of "maxRepeat":
        result = 100
      else:
        result = 0

func getTeaVarStringDefault*(variables: Variables, varName: string): string =
  ## Return the string value of one of the tea dictionary string
  ## items. If the value does not exist, return its default value.
  assert varName in ["output"]

  if varName in variables:
    let value = variables[varName]
    assert value.kind == vkString
    result = value.stringv
  else:
    case varName:
      of "output":
        result = "result"
      else:
        result = ""

proc resetVariables*(variables: var Variables) =
  ## Clear the local variables and reset the tea variables for running
  ## a command.

  # Delete the tea variables.
  let teaVars = ["content", "maxRepeat", "maxLines", "repeat", "output"]
  for teaVar in teaVars:
    if teaVar in variables:
      variables.del(teaVar)

  variables["l"] = newValue(newVarsDict())

proc getParentDict*(variables: Variables, names: seq[string]): ParentDict =
  ## Return the last component dictionary specified by the given names
  ## or, on error, return a warning.  The sequence [a, b, c, d]
  ## corresponds to the dot name string "a.b.c.d" and the c dictionary
  ## is the result.

  assert names.len > 0

  var parentDict: VarsDict
  var dictNames: seq[string]
  var nameSpace = names[0]

  if nameSpace == "t":
    if names.len == 1:
      # t by itself is a special case we don't allow.
      return newParentDictWarn(wReservedNameSpaces)
    if names.len != 2:
      # All tea variables have two components.
      # todo: pass in dotNameStr instead of sequence everywhere?
      let dotNameStr = names.join(".")
      return newParentDictWarn(wInvalidTeaVar, dotNameStr)
    return newParentDict(variables)
  else:
    var localVar = false
    case nameSpace:
      of "s", "h", "g":
        discard
      of "f":
        return newParentDictWarn(wReservedNameSpaces)
      else:
        nameSpace = "l"
        localVar = true
    assert nameSpace in variables
    if localVar:
      parentDict = variables[nameSpace].dictv
      if names.len == 1:
        return newParentDict(parentDict)
      dictNames = names[0 .. ^2]
    else:
      parentDict = variables[nameSpace].dictv
      if names.len == 1 or names.len == 2:
        # Namespace f, g, h, l, s by themself or with one other subvar.
        return newParentDict(parentDict)
      dictNames = names[1 .. ^2]

  # Loop through the dictionaries looking up each sub dict.
  for name in dictNames:
    if not (name in parentDict):
      # Name doesn't exist in the parent dictionary. # wMissingVarName
      return newParentDictWarn(wMissingVarName, name)
    if parentDict[name].kind != vkDict:
      # "Name, $1, is not a dictionary.", # wNotDict
      return newParentDictWarn(wNotDict, name)
    parentDict = parentDict[name].dictv

  result = newParentDict(parentDict)

func assignTeaVariable(variables: var Variables, dotNameStr: string, value: Value):
     Option[WarningData] =
  ## Assign a tea variable if possible, else return a warning.

  assert dotNameStr.len > 0

  let names = split(dotNameStr, '.')
  if names.len != 2 or names[0] != "t":
    return some(newWarningData(wInvalidTeaVar, dotNameStr))

  let varName = names[1]
  if varName in variables:
    # The model has independent namespaces, so don't expose these. Use
    # s, h, l, g instead.
    if varName in ["s", "h", "l", "g", "f"]:
        return some(newWarningData(wInvalidTeaVar, varName))
    if varName in ["row", "version"]:
        return some(newWarningData(wReadOnlyTeaVar, varName))
    return some(newWarningData(wImmutableVars))

  case varName:
    of "maxLines":
      # The maxLines variable must be an integer >= 0.
      if value.kind != vkInt or value.intv < 0:
        return some(newWarningData(wInvalidMaxCount))
    of "maxRepeat":
      # The maxRepeat variable must be a positive integer >= t.repeat.
      if value.kind != vkInt or value.intv < getTeaVarIntDefault(variables, "repeat"):
        return some(newWarningData(wInvalidMaxRepeat))
    of "content":
      # Content must be a string.
      if value.kind != vkString:
        return some(newWarningData(wInvalidTeaContent))
    of "output":
      # Output must be a string of "result", etc.
      if value.kind != vkString or not outputValues.contains(value.stringv):
        return some(newWarningData(wInvalidOutputValue))
    of "repeat":
      # Repeat is an integer >= 0 and <= t.maxRepeat.
      if value.kind != vkInt or value.intv < 0 or
          value.intv > getTeaVarIntDefault(variables, "maxRepeat"):
        return some(newWarningData(wInvalidRepeat))
    else:
      return some(newWarningData(wInvalidTeaVar, varName))

  variables[varName] = value

proc assignVariable*(variables: var Variables, dotNameStr: string,
    value: Value): Option[WarningData] =
  ## Assign the variable the given value if possible, else return a
  ## warning.
  assert dotNameStr.len > 0

  let names = split(dotNameStr, '.')
  let nameSpace = names[0]
  if nameSpace == "t":
    return assignTeaVariable(variables, dotNameStr, value)

  if nameSpace in ["s", "h"]:
    return some(newWarningData(wReadOnlyDictionary))

  var parentDict = getParentDict(variables, names)
  if parentDict.kind == fdWarning:
    return some(parentDict.warningData)

  # All variables are immutable.
  let varName = names[^1]
  if varName in parentDict.dict:
    return some(newWarningData(wImmutableVars))
  parentDict.dict[varName] = value

proc getVariable*(variables: Variables, dotNameStr: string): ValueOrWarning =
  ## Look up the variable and return its value when found, else return
  ## a warning.
  let names = split(dotNameStr, '.')
  var parentDict = getParentDict(variables, names)
  if parentDict.kind == fdWarning:
    return newValueOrWarning(parentDict.warningData)

  let varName = names[^1]
  if not (varName in parentDict.dict):
    return newValueOrWarning(wMissingVarName, varName)

  result = newValueOrWarning(parentDict.dict[varName])
