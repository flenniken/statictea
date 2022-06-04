## Procedures for working with statictea variables.
## @:
## @:There is one dictionary to hold the logically separate dictionaries,
## @:g, h, s, t etc which makes passing them around easier.
## @:
## @:The language allows local variables to be specified without the l
## @:prefix and it allows functions to be specified without the f prefix.
## @:
import std/strutils
import std/options
import std/tables
import vartypes
import version
import messages
import warnings
import args
import opresultwarn

const
  outputValues* = ["result", "stdout", "stderr", "log", "skip"]
    ## Where the replacement block's output goes.
    ## @:* result -- output goes to the result file
    ## @:* stdout -- output goes to the standard output stream
    ## @:* stdout -- output goes to the standard error stream
    ## @:* log -- output goes to the log file
    ## @:* skip -- output goes to the bit bucket

type
  Variables* = VarsDict
    ## Dictionary holding all statictea variables in multiple distinct
    ## logical dictionaries.

  VariableData* = object
    ## The VariableData object holds the variable name, operator,
    ## @:and value which is the result of running a statement.
    ## @:
    ## @:For a bare if statement, the operator is "exit" when a return
    ## @:function ran, otherwise the operator is an empty string.
    ## @:
    ## @:* dotNameStr -- the dot name tells which dictionary contains
    ## @:the variable, i.e.: l.d.a
    ## @:* operator -- the statement's operator, either =, &=, "" or "exit".
    ## @:* value -- the variable's value
    dotNameStr*: string
    operator*: string
    value*: Value

  VariableDataOr* = OpResultWarn[VariableData]
    ## A VariableData object or a warning.

func newVariableDataOr*(warning: MessageId, p1 = "", pos = 0):
    VariableDataOr =
  ## Create an object containing a warning.
  let warningData = newWarningData(warning, p1, pos)
  result = opMessageW[VariableData](warningData)

func newVariableDataOr*(warningData: WarningData):
    VariableDataOr =
  ## Create an object containing a warning.
  result = opMessageW[VariableData](warningData)

func newVariableDataOr*(dotNameStr: string, operator = "=",
    value: Value): VariableDataOr =
  ## Create an object containing a VariableData object.
  let variableData = VariableData(dotNameStr: dotNameStr,
    operator: operator, value: value)
  result = opValueW[VariableData](variableData)

func `$`*(v: VariableData): string =
  ## Return a string representation of VariableData.
  result = "dotName='$1', operator='$2', value=$3" % [
    v.dotNameStr, v.operator, $v.value]

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

proc getParentDictToAddTo(variables: Variables, dotNameStr: string):
    VarsDictOr =
  ## Return the last component dictionary specified by the given dot
  ## name or, on error, return a warning.  For the dot name string
  ## "a.b.c.d" and the c dictionary is the result.

  let names = split(dotNameStr, '.')
  assert names.len > 1
  assert names[0] in ["g", "h", "l", "s"]

  var parentDict: VarsDict
  var dictNames: seq[string]
  var nameSpace = names[0]

  parentDict = variables[nameSpace].dictv
  if names.len == 2:
    return newVarsDictOr(parentDict)
  dictNames = names[1 .. ^2]

  # Loop through the dictionaries looking up each sub dict.
  for name in dictNames:
    if not (name in parentDict):
      # The variable '$1' does not exist.
      return newVarsDictOr(wVariableMissing, name)
    if parentDict[name].kind != vkDict:
      # Name, $1, is not a dictionary.
      return newVarsDictOr(wNotDict, name)
    parentDict = parentDict[name].dictv

  result = newVarsDictOr(parentDict)

func assignTeaVariable(variables: var Variables, dotNameStr: string,
    value: Value, operator: string = "="): Option[WarningData] =
  ## Assign a tea variable a value if possible, else return a
  ## warning. The operator parameter is either "=" or "&=".

  assert dotNameStr.len > 0

  let names = split(dotNameStr, '.')
  assert names[0] == "t"

  if names.len == 1:
    # You cannot assign to an existing variable.
    return some(newWarningData(wImmutableVars))

  let varName = names[1]
  var tea = variables["t"].dictv
  if varName in tea:
    if varName in ["row", "version", "args"]:
      # You cannot change the t.$1 tea variable.
      return some(newWarningData(wReadOnlyTeaVar, varName))
    # You cannot reassign a tea variable.
    return some(newWarningData(wTeaVariableExists))

  case varName:
    of "maxLines":
      # MaxLines must be an integer greater than 1.
      if value.kind != vkInt or value.intv < 2:
        # MaxLines must be an integer greater than 1.
        return some(newWarningData(wInvalidMaxCount))
    of "maxRepeat":
      # The maxRepeat variable must be a positive integer >= t.repeat.
      if value.kind != vkInt or value.intv < getTeaVarIntDefault(variables, "repeat"):
        # The maxRepeat value must be greater than or equal to t.repeat.
        return some(newWarningData(wInvalidMaxRepeat))
    of "content":
      # Content must be a string.
      if value.kind != vkString:
        # You must assign t.content a string.
        return some(newWarningData(wInvalidTeaContent))
    of "output":
      # Output must be a string of "result", etc.
      if value.kind != vkString or not outputValues.contains(value.stringv):
        # Invalid t.output value, use: "result", "stdout", "stderr", "log", or "skip".
        return some(newWarningData(wInvalidOutputValue))
    of "repeat":
      # Repeat is an integer >= 0 and <= t.maxRepeat.
      if value.kind != vkInt or value.intv < 0 or
          value.intv > getTeaVarIntDefault(variables, "maxRepeat"):
        # The variable t.repeat must be an integer between 0 and t.maxRepeat.
        return some(newWarningData(wInvalidRepeat))
    else:
      # Invalid tea variable: $1.
      return some(newWarningData(wInvalidTeaVar, varName))

  # You cannot append to a tea variable.
  if operator == "&=":
    # You cannot append to a tea variable.
    return some(newWarningData(wAppendToTeaVar))

  tea[varName] = value

proc assignVariable*(
    variables: var Variables,
    dotNameStr: string,
    value: Value,
    operator: string = "="
  ): Option[WarningData] =
  ## Assign the variable the given value if possible, else return a
  ## warning. The operator parameter is either "=" or "&=".

  # -- You cannot overwrite an existing variable.
  # -- You can only assign to known tea variables.
  # -- You can assign new values to the local and global dictionaries
  #    but not the others (except for the previous rule).
  # -- You can append to local and global lists but not others.
  # -- You can specify local variables without the l prefix.

  assert dotNameStr.len > 0
  var varsDictOr: VarsDictOr
  let names = split(dotNameStr, '.')

  let nameSpace = names[0]
  case nameSpace
  of "t":
    return assignTeaVariable(variables, dotNameStr, value, operator)
  of "s", "h":
    if names.len == 1:
      # You cannot assign to an existing variable.
      return some(newWarningData(wImmutableVars))
    # You cannot overwrite the server or shared variables.
    return some(newWarningData(wReadOnlyDictionary))
  of "g", "l":
    if names.len == 1:
      # You cannot assign to an existing variable.
      return some(newWarningData(wImmutableVars))
    varsDictOr = getParentDictToAddTo(variables, dotNameStr)
  of "f", "i", "j", "k", "m", "n", "o", "p", "q", "r", "u":
    return some(newWarningData(wReservedNameSpaces))
  else:
    # It must be a local variable, add the missing l.
    varsDictOr = getParentDictToAddTo(variables, "l." & dotNameStr)

  if varsDictOr.isMessage:
    return some(varsDictOr.message)

  let lastName = names[^1]
  if operator == "=":
    # Assign the value to the dictionary.
    if lastName in varsDictOr.value:
      # You cannot assign to an existing variable.
      return some(newWarningData(wImmutableVars))
    varsDictOr.value[lastName] = value
  else:
    assert operator == "&="

    # Append to a list, or create then append.

    # If the variable doesn't exists, create an empty list.
    if not (lastName in varsDictOr.value):
      varsDictOr.value[lastName] = newEmptyListValue()

    let lastItem = varsDictOr.value[lastName]
    if lastItem.kind != vkList:
      # You can only append to a list, got $1.
      return some(newWarningData(wAppendToList, $lastItem.kind))

    # Append the value to the list.
    lastItem.listv.add(value)

func lookUpVar(variables: Variables, names: seq[string]): ValueOr =
  ## Return the variable when it exists.
  var next = variables
  var ix = 0
  while true:
    let name = names[ix]
    if not (name in next):
      # The variable '$1' does not exist.
      return newValueOr(wVariableMissing, name)
    let value = next[name]
    inc(ix)
    if ix >= names.len:
      return newValueOr(value)
    if value.kind != vkDict:
      # Name, $1, is not a dictionary.
      return newValueOr(wNotDict, name)
    next = value.dictv

proc getVariable*(variables: Variables, dotNameStr: string): ValueOr =
  ## Look up the variable and return its value when found, else return
  ## a warning.
  var names = split(dotNameStr, '.')
  let nameSpace = names[0]
  case nameSpace
  of "g", "h", "l", "s", "t":
    discard
  of "f", "i", "j", "k", "m", "n", "o", "p", "q", "r", "u":
    # The variables f, i - k, m - r, u are reserved variable names.
    return newValueOr(wReservedNameSpaces)
  else:
    # It must be a local variable, add the missing l.
    names.insert("l", 0)

  result = lookUpVar(variables, names)

func argsPrepostList*(prepostList: seq[Prepost]): seq[seq[string]] =
  ## Create a prepost list of lists for t args.
  for prepost in prepostList:
    result.add(@[prepost.prefix, prepost.postfix])

func getTeaArgs*(args: Args): Value =
  ## Create the t args dictionary from the statictea arguments.
  var varsDict = newVarsDict()
  varsDict["help"] = newValue(args.help)
  varsDict["version"] = newValue(args.version)
  varsDict["update"] = newValue(args.update)
  varsDict["log"] = newValue(args.log)
  varsDict["serverList"] = newValue(args.serverList)
  varsDict["sharedList"] = newValue(args.sharedList)
  varsDict["resultFilename"] = newValue(args.resultFilename)
  varsDict["templateFilename"] = newValue(args.templateFilename)
  varsDict["logFilename"] = newValue(args.logFilename)
  varsDict["prepostList"] = newValue(argsPrepostList(args.prepostList))
  result = newValue(varsDict)
