## Language variable methods.

#[
There is one dictionary to hold the logically separate dictionaries,
g, h, s, t etc which makes passing them around easier.

The language allows local variables to be specified without the l
prefix and it allows functions to be specified without the f prefix.

Dot names ie: l.d.a can be used on the left hand side of the equal sign.
]#

import std/strutils
import std/options
import std/tables
import vartypes
import version
import messages
import warnings
import tostring
import args

const
  outputValues* = ["result", "stderr", "log", "skip"]
    ## Tea output variable values.

type
  Variables* = VarsDict
    ## Dictionary holding all statictea variables in multiple distinct
    ## logical dictionaries.

  VariableData* = object
    ## A variable name and value. The dotNameStr tells where the
    ## variable is stored, i.e.: l.d.a
    dotNameStr*: string
    value*: Value

  ParentDictKind* = enum
    ## The kind of a ParentDict object, either a dict or warning.
    fdDict,
    fdWarning

  ParentDict* = object
    ## Contains the result of calling getParentDictToAddTo, either a dictionary
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

func emptyVariables*(server: VarsDict = nil, shared: VarsDict = nil,
    args: VarsDict = nil): Variables =
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

  var tea = newVarsDict()
  tea["row"] = newValue(0)
  tea["version"] = newValue(staticteaVersion)
  if args == nil:
    tea["args"] = newValue(newVarsDict())
  else:
    tea["args"] = newValue(args)
  result["t"] = newValue(tea)

func newVariableData*(dotNameStr: string, value: Value): VariableData =
  ## Create a new VariableData object.
  result = VariableData(dotNameStr: dotNameStr, value: value)

func getTeaVarIntDefault*(variables: Variables, varName: string): int64 =
  ## Return the int value of one of the tea dictionary integer
  ## items. If the value does not exist, return its default value.
  assert varName in ["row", "repeat", "maxRepeat", "maxLines"]
  var tea = variables["t"].dictv
  if varName in tea:
    let value = tea[varName]
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

  var tea = variables["t"].dictv
  if varName in tea:
    let value = tea[varName]
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

  # Delete some of the tea variables.
  let teaVars = ["content", "maxRepeat", "maxLines", "repeat", "output"]
  if "t" in variables:
    var tea = variables["t"].dictv
    for teaVar in teaVars:
      if teaVar in tea:
        tea.del(teaVar)

  variables["l"] = newValue(newVarsDict())

proc getParentDictToAddTo(variables: Variables, dotNameStr: string): ParentDict =
  ## Return the last component dictionary specified by the given names
  ## or, on error, return a warning.  For the dot name string
  ## "a.b.c.d" and the c dictionary is the result.

  let names = split(dotNameStr, '.')
  assert names.len > 1
  assert names[0] in ["g", "h", "l", "s"]

  var parentDict: VarsDict
  var dictNames: seq[string]
  var nameSpace = names[0]

  parentDict = variables[nameSpace].dictv
  if names.len == 2:
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

func assignTeaVariable(variables: var Variables, dotNameStr: string,
    value: Value, operator: string = "="): Option[WarningData] =
  ## Assign a tea variable if possible, else return a warning.

  assert dotNameStr.len > 0

  let names = split(dotNameStr, '.')
  assert names[0] == "t"

  if names.len == 1:
    return some(newWarningData(wImmutableVars))

  let varName = names[1]
  var tea = variables["t"].dictv
  if varName in tea:
    if varName in ["row", "version", "args"]:
        return some(newWarningData(wReadOnlyTeaVar, varName))
    # You cannot reassign a tea variable.
    return some(newWarningData(wTeaVariableExists))

  case varName:
    of "maxLines":
      # MaxLines must be an integer greater than 1.
      if value.kind != vkInt or value.intv < 2:
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

  # You cannot append to a tea variable.
  if operator == "&=":
    return some(newWarningData(wAppendToTeaVar))

  tea[varName] = value

proc assignVariable*(
    variables: var Variables,
    dotNameStr: string,
    value: Value,
    operator: string = "="
  ): Option[WarningData] =
  ## Assign the variable the given value if possible, else return a
  ## warning.

  # -- You cannot overwrite an existing variable.
  # -- You can only assign to known tea variables.
  # -- You can assign new values to the local and global dictionaries
  #    but not the others (except for the previous rule).
  # -- You can append to local and global lists but not others.
  # -- You can specify local variables without the l prefix.

  assert dotNameStr.len > 0
  var parentDict: ParentDict
  let names = split(dotNameStr, '.')

  let nameSpace = names[0]
  case nameSpace
  of "t":
    return assignTeaVariable(variables, dotNameStr, value, operator)
  of "s", "h":
    if names.len == 1:
      return some(newWarningData(wImmutableVars))
    return some(newWarningData(wReadOnlyDictionary))
  of "g", "l":
    if names.len == 1:
      return some(newWarningData(wImmutableVars))
    parentDict = getParentDictToAddTo(variables, dotNameStr)
  of "f", "i", "j", "k", "m", "n", "o", "p", "q", "r", "u":
    return some(newWarningData(wReservedNameSpaces))
  else:
    # It must be a local variable, add the missing l.
    parentDict = getParentDictToAddTo(variables, "l." & dotNameStr)

  if parentDict.kind == fdWarning:
    return some(parentDict.warningData)

  let lastName = names[^1]
  if operator == "=":
    # Assign the value to the dictionary.
    if lastName in parentDict.dict:
      return some(newWarningData(wImmutableVars))
    parentDict.dict[lastName] = value
  else:
    assert operator == "&="

    # Append to a list, or create then append.

    # If the variable doesn't exists, create an empty list.
    if not (lastName in parentDict.dict):
      parentDict.dict[lastName] = newEmptyListValue()

    let lastItem = parentDict.dict[lastName]
    if lastItem.kind != vkList:
      # You can only append to a list, got $1.
      return some(newWarningData(wAppendToList, $lastItem.kind))

    # Append the value to the list.
    lastItem.listv.add(value)

func lookUpVar(variables: Variables, names: seq[string]): ValueOrWarning =
  ## Return the variable when it exists.
  var next = variables
  var ix = 0
  while true:
    let name = names[ix]
    if not (name in next):
      return newValueOrWarning(wMissingVarName, name)
    let value = next[name]
    inc(ix)
    if ix >= names.len:
      return newValueOrWarning(value)
    if value.kind != vkDict:
      return newValueOrWarning(wNotDict, name)
    next = value.dictv

proc getVariable*(variables: Variables, dotNameStr: string): ValueOrWarning =
  ## Look up the variable and return its value when found, else return
  ## a warning.
  var names = split(dotNameStr, '.')
  let nameSpace = names[0]
  case nameSpace
  of "g", "h", "l", "s", "t":
    discard
  of "f", "i", "j", "k", "m", "n", "o", "p", "q", "r", "u":
    return newValueOrWarning(wReservedNameSpaces)
  else:
    # It must be a local variable, add the missing l.
    names.insert("l", 0)

  result = lookUpVar(variables, names)

func argsPrepostList*(prepostList: seq[Prepost]): seq[seq[string]] =
  ## Create a prepost list of lists for t.args.
  for prepost in prepostList:
    result.add(@[prepost.prefix, prepost.postfix])

func getTeaArgs*(args: Args): Value =
  ## Create the t.args dictionary from the statictea arguments.
  var varsDict = newVarsDict()
  varsDict["help"] = newValue(args.help)
  varsDict["version"] = newValue(args.version)
  varsDict["update"] = newValue(args.update)
  varsDict["log"] = newValue(args.log)
  varsDict["serverList"] = newValue(args.serverList)
  varsDict["sharedList"] = newValue(args.sharedList)
  varsDict["resultFilename"] = newValue(args.resultFilename)
  varsDict["templateList"] = newValue(args.templateList)
  varsDict["logFilename"] = newValue(args.logFilename)
  varsDict["prepostList"] = newValue(argsPrepostList(args.prepostList))
  result = newValue(varsDict)
