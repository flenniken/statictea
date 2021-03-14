
import env
import args
import vartypes
import readjson
import tables
import options
import version
import warnings

type
  Variables* = VarsDict
    ## Dictionary holding variables.

  VariableData* = object
    nameSpace*: string
    varName*: string
    value*: Value

  WarningDataPos* = object
    warningData*: WarningData
    firstPos*: bool

proc newVariableData*(nameSpace: string, varName: string, value: Value): VariableData =
  result = VariableData(nameSpace: nameSpace, varName: varName, value: value)

proc newWarningDataPos*(warning: Warning, p1: string = "", p2: string = "",
    firstPos: bool = true): WarningDataPos =
  ## Create a WarningDataPos containing the warning information.
  let warningData = WarningData(warning: warning, p1: p1, p2: p2)
  result = WarningDataPos(warningData: warningData, firstPos: firstPos)

proc getNamespaceDict*(variables: Variables, nameSpace: string): Option[VarsDict] =
  ## Get the dictionary for the given namespace.
  case nameSpace:
    of "":
      result = some(variables["local"].dictv)
    of "s.":
      result = some(variables["server"].dictv)
    of "h.":
      result = some(variables["shared"].dictv)
    of "g.":
      result = some(variables["global"].dictv)
    of "t.":
      result = some(variables)
    else:
      discard

proc getVariable*(variables: Variables, namespace: string, varName:
                  string): Option[Value] =
  ## Look up the variable and return its value.

  let dictO = getNamespaceDict(variables, namespace)
  if isSome(dictO):
    let dict = dictO.get()
    if varName in dict:
      result = some(dict[varName])

proc getTeaVarInt*(variables: Variables, varName: string): int64 =
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
        result = 10
      of "maxRepeat":
        result = 100
      else:
        result = 0

proc getTeaVarString*(variables: Variables, varName: string): string =
  ## Return the string value of one of the tea dictionary string items.
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

proc readServerVariables*(env: var Env, args: Args): VarsDict =
  ## Read the server json.
  result = getEmptyVars()
  for filename in args.serverList:
    readJson(env, filename, result)

proc readSharedVariables*(env: var Env, args: Args): VarsDict =
  ## Read the shared json.
  result = getEmptyVars()
  for filename in args.sharedList:
    readJson(env, filename, result)

proc resetVariables*(variables: var Variables) =
  ## Clear the local variables and reset the tea variables for running
  ## a command.

  # Delete the tea variables.
  let teaVars = ["content", "maxRepeat", "maxLines", "repeat", "output"]
  for teaVar in teaVars:
    if teaVar in variables:
      variables.del(teaVar)

  var varsDict: VarsDict
  variables["local"] = newValue(varsDict)

proc newVariables*(server: VarsDict, shared: VarsDict): Variables =
  ## Create the "tea" variables in their initial state.
  var emptyVarsDict: VarsDict
  result["server"] = newValue(server)
  result["shared"] = newValue(shared)
  result["local"] = newValue(emptyVarsDict)
  result["global"] = newValue(emptyVarsDict)
  result["row"] = newValue(0)
  result["version"] = newValue(staticteaVersion)

when defined(test):
  func getTestVariables*(): Variables =
    ## Get the variables for testing with some values filled in.
    # s.test = "hello"
    # h.test = "there"
    # five = 5
    # t.five = 5
    # g.aboutfive = 5.11
    var emptyVarsDict: VarsDict
    result = newVariables(emptyVarsDict, emptyVarsDict)
    result["server"].dictv["test"] = Value(kind: vkString, stringv: "hello")
    result["shared"].dictv["test"] = Value(kind: vkString, stringv: "there")
    result["local"].dictv["five"] = Value(kind: vkInt, intv: 5)
    result["five"] = Value(kind: vkInt, intv: 5)
    result["global"].dictv["aboutfive"] = Value(kind: vkFloat, floatv: 5.11)

  proc echoVariables*(variables: Variables) =
    echo "---tea variables:"
    for k, v in variables.pairs():
      echo k, ": ", $v
    echo "---server variables:"
    for k, v in variables["server"].dictv.pairs():
      echo k, ": ", $v
    echo "---shared variables:"
    for k, v in variables["shared"].dictv.pairs():
      echo k, ": ", $v
    echo "---local variables:"
    for k, v in variables["local"].dictv.pairs():
      echo k, ": ", $v
    echo "---global variables:"
    for k, v in variables["global"].dictv.pairs():
      echo k, ": ", $v

proc validateTeaVariable*(variables: Variables, varName: string, value: Value): Option[WarningDataPos] =
  ## Validate the setting the tea variable with the given
  ## value. Return a warning if it is invalid, else return none.

  case varName:
    of "maxLines":
      # The maxLines variable must be an integer >= 0.
      if value.kind == vkInt and value.intv >= 0:
        return
      result = some(newWarningDataPos(wInvalidMaxCount, firstPos = false))
    of "maxRepeat":
      # The maxRepeat variable must be an integer >= t.repeat.
      if value.kind == vkInt and value.intv >= getTeaVarInt(variables, "repeat"):
        return
      result = some(newWarningDataPos(wInvalidMaxRepeat, firstPos = false))
    of "content":
      # Content must be a string.
      if value.kind == vkString:
        return
      result = some(newWarningDataPos(wInvalidTeaContent, firstPos = false))
    of "output":
      # Output must be a string of "result", etc.
      if value.kind == vkString:
        if value.stringv in outputValues:
          return
      result = some(newWarningDataPos(wInvalidOutputValue, firstPos = false))
    of "repeat":
      # Repeat is an integer >= 0 and <= t.maxRepeat.
      if value.kind == vkInt and value.intv >= 0 and
         value.intv <= getTeaVarInt(variables, "maxRepeat"):
        return
      result = some(newWarningDataPos(wInvalidRepeat, firstPos = false))
    of "server", "shared", "local", "global", "row", "version":
      result = some(newWarningDataPos(wReadOnlyTeaVar, varName, firstPos = true))
    else:
      result = some(newWarningDataPos(wInvalidTeaVar, varName, firstPos = true))

# todo: clean up discards below.
proc assignTeaVariable*(variables: var Variables, varName: string, value: Value) =
  ## Assign the given tea variable with the given value.

  case varName:
    of "maxLines":
      # The maxLines variable must be an integer >= 0.
      if value.kind == vkInt and value.intv >= 0:
        variables["maxLines"] = value
      else:
        discard
    of "maxRepeat":
      # The maxRepeat variable must be an integer >= t.repeat.
      if value.kind == vkInt and value.intv >= getTeaVarInt(variables, "repeat"):
        variables["maxRepeat"] = value
      else:
        discard
    of "content":
      # Content must be a string.
      if value.kind == vkString:
        variables["content"] = value
      else:
        discard
    of "output":
      # Output must be a string of "result", etc.
      if value.kind == vkString:
        if value.stringv in outputValues:
          variables["output"] = value
          return
      discard
    of "repeat":
      # Repeat is an integer >= 0 and <= t.maxRepeat.
      if value.kind == vkInt and value.intv >= 0 and
         value.intv <= getTeaVarInt(variables, "maxRepeat"):
        variables["repeat"] = value
      else:
        discard
    of "server", "shared", "local", "global", "row", "version":
      discard
    else:
      discard

proc validateVariable*(variables: Variables, nameSpace: string, varName: string,
                       value: Value): Option[WarningDataPos] =
  ## Assign the variable to its dictionary or show a warning message.
  case nameSpace:
    of "":
      discard
    of "g.":
      discard
    of "t.":
      result = validateTeaVariable(variables, varName, value)
    of "s.", "h.":
      result = some(newWarningDataPos(wReadOnlyDictionary, firstPos = true))
    else:
      result = some(newWarningDataPos(wInvalidNameSpace, nameSpace, firstPos = true))

proc assignVariable*(variables: var Variables, nameSpace: string,
    varName: string, value: Value) =
  ## Assign the variable to its dictionary.
  case nameSpace:
    of "":
      variables["local"].dictv[varName] = value
    of "g.":
      variables["global"].dictv[varName] = value
    of "t.":
      assignTeaVariable(variables, varName, value)
    of "s.", "h.":
      discard
    else:
      discard
