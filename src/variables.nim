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
import opresult

const
  outputValues* = ["result", "stdout", "stderr", "log", "skip"]
    ## Where the replacement block's output goes.
    ## @:* result -- output goes to the result file
    ## @:* stdout -- output goes to the standard output stream
    ## @:* stdout -- output goes to the standard error stream
    ## @:* log -- output goes to the log file
    ## @:* skip -- output goes to the bit bucket

type
  Operator* = enum
    ## The statement operator types.
    ## @:
    ## @:* opIgnore -- ignore the statement, e.g. comment or blank statement.
    ## @:* opAppendDict (=) -- append the value to the dictionary
    ## @:* opAppendList ($=) -- append the value to the list
    ## @:* opReturn -- stop or skip the current replacement iteration
    ## @:* opLog -- log a message
    opIgnore = "ignore",
    opEqual = "=",
    opAppendList = "&=",
    opReturn = "return",
    opLog = "log",

  VariableData* = object
    ## The VariableData object holds the variable name, operator,
    ## @:and value which is the result of running a statement.
    ## @:
    ## @:* dotNameStr -- the variable dot name tells which dictionary contains
    ## @:the variable, i.e.: l.d.a
    ## @:* operator -- the statement's operator; what to do with the variable and value.
    ## @:* value -- the variable's value
    dotNameStr*: string
    operator*: Operator
    value*: Value

  VariableDataOr* = OpResultWarn[VariableData]
    ## A VariableData object or a warning.

  NoPrefixDict* = enum
    ## The variable letter prefix to use when it's missing.
    ## @:
    ## @:* npLocal -- use the local (l) dictionary
    ## @:* npBuiltIn -- use the built in function (f) dictionary
    npLocal,
    npBuiltIn,

func newVariableDataOr*(warning: MessageId, p1 = "", pos = 0):
    VariableDataOr =
  ## Create an object containing a warning.
  let warningData = newWarningData(warning, p1, pos)
  result = opMessageW[VariableData](warningData)

func newVariableDataOr*(warningData: WarningData):
    VariableDataOr =
  ## Create an object containing a warning.
  result = opMessageW[VariableData](warningData)

func newVariableDataOr*(dotNameStr: string, operator: Operator,
    value: Value): VariableDataOr =
  ## Create an object containing a VariableData object.
  let variableData = VariableData(dotNameStr: dotNameStr,
    operator: operator, value: value)
  result = opValueW[VariableData](variableData)

func `$`*(v: VariableData): string =
  ## Return a string representation of VariableData.
  result = "dotName='$1', operator='$2', value=$3" % [
  v.dotNameStr, $v.operator, $v.value]

func startVariables*(server: VarsDict = nil, args: VarsDict = nil,
    funcs: VarsDict = nil): Variables =
  ## Create an empty variables object in its initial state.

  # Add the standard dictionaries in alphabetical order.
  result = newVarsDict()

  if funcs == nil:
    result["f"] = newValue(newVarsDict())
  else:
    result["f"] = newValue(funcs)

  # The g dictionary starts out immutable and becomes mutable after
  # the code files run and visa-versa for the o dictionary.
  result["g"] = newValue(newVarsDict())
  result["l"] = newValue(newVarsDict(), mutable = Mutable.append)
  result["o"] = newValue(newVarsDict(), mutable = Mutable.append)

  if server == nil:
    result["s"] = newValue(newVarsDict())
  else:
    result["s"] = newValue(server)

  # Tea variables.
  var tea = newVarsDict()
  if args == nil:
    tea["args"] = newValue(newVarsDict())
  else:
    tea["args"] = newValue(args)
  tea["row"] = newValue(0)
  tea["version"] = newValue(staticteaVersion)
  result["t"] = newValue(tea, mutable = Mutable.append)

func getTeaVarIntDefault*(variables: Variables, varName: string): int64 =
  ## Return the int value of one of the tea dictionary integer
  ## items. If the value does not exist, return its default value.
  assert varName in ["row", "repeat", "maxRepeat", "maxLines"]
  var tea = variables["t"].dictv.dict
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

  var tea = variables["t"].dictv.dict
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
    var tea = variables["t"].dictv.dict
    for teaVar in teaVars:
      if teaVar in tea:
        tea.del(teaVar)

  variables["l"] = newValue(newVarsDict(), mutable = Mutable.append)

proc getParentDictToAddTo(variables: Variables, dotNameList: openArray[string]):
    ValueOr =
  ## Return the last component dictionary specified by the given dot
  ## name list or, on error, return a warning.  For the dot name string
  ## "a.b.c.d" and the c dictionary is the result.

  assert(dotNameList.len > 1, "No namespace for '$1'." % dotNameList.join("."))
  assert dotNameList[0] in ["f", "g", "h", "l", "s", "o"]

  var parentDict: Value
  var dictNames: seq[string]
  var nameSpace = dotNameList[0]

  parentDict = variables[nameSpace]
  if dotNameList.len == 2:
    return newValueOr(parentDict)
  dictNames = dotNameList[1 .. ^2]

  # Loop through the dictionaries looking up each sub dict.
  for name in dictNames:
    if not (name in parentDict.dictv.dict):
      # The variable '$1' does not exist.
      return newValueOr(wVariableMissing, name)
    if parentDict.dictv.dict[name].kind != vkDict:
      # Name, $1, is not a dictionary.
      return newValueOr(wNotDict, name)
    parentDict = parentDict.dictv.dict[name]
  result = newValueOr(parentDict)

func assignTeaVariable(variables: var Variables, dotNameStr: string,
    value: Value, operator = opEqual): Option[WarningData] =
  ## Assign a tea variable a value if possible, else return a
  ## warning.

  assert dotNameStr.len > 0

  let names = split(dotNameStr, '.')
  assert names[0] == "t"

  if names.len == 1:
    # You cannot assign to an existing variable.
    return some(newWarningData(wImmutableVars))

  let varName = names[1]
  var tea = variables["t"].dictv.dict
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

  case operator:
  of opEqual:
    tea[varName] = value
  of opAppendList:
    # You cannot append to a tea variable.
    return some(newWarningData(wAppendToTeaVar))
  of opIgnore, opReturn, opLog:
    discard

proc assignVariable*(
    variables: var Variables,
    dotNameStr: string,
    value: Value,
    operator = opEqual,
  ): Option[WarningData] =
  ## Assign the variable the given value if possible, else return a
  ## warning.

  # -- You cannot overwrite an existing variable.
  # -- You can only assign to known tea variables.
  # -- You can assign new values to the local and global dictionaries
  #    but not the others (except for the previous rule).
  # -- You can append to local and global lists but not others.
  # -- You can specify local variables without the l prefix.
  # -- You cannot assign true and false.
  # -- You can assign new values to the code dictonary when in code files.
  # -- You cannot assign or append to a immutable dict or list.

  assert dotNameStr.len > 0
  var dotNameList = split(dotNameStr, '.')

  # Make sure the variable can be added. Determine the full variable
  # dot name by adding the default prefix when missing.
  case dotNameList[0]
  of "t":
    return assignTeaVariable(variables, dotNameStr, value, operator)
  of "o":
    if variables["o"].dictv.mutable == Mutable.immutable:
      # You can only change code variables (o dictionary) in code files.
      return some(newWarningData(wReadOnlyCodeVars))
  of "s":
    # You cannot overwrite the server variables.
    return some(newWarningData(wReadOnlyDictionary))
  of "g":
    if variables["g"].dictv.mutable == Mutable.immutable:
      # You can only change global variables (g dictionary) in template files.
      return some(newWarningData(wNoGlobalInCodeFile))
  of "l":
    if dotNameStr == "l.true" or dotNameStr == "l.false":
      # You cannot assign true or false.
      return some(newWarningData(wAssignTrueFalse))
  of "f":
    # You cannot assign to the functions dictionary.
    return some(newWarningData(wReadOnlyFunctions))
  of "h", "i", "j", "k", "m", "n", "p", "q", "r", "u":
    # The variables f, h - k, m - r, u are reserved variable names.
    return some(newWarningData(wReservedNameSpaces))
  else:
    # It must be a "local" variable.

    if dotNameStr == "true" or dotNameStr == "false":
      # You cannot assign true or false.
      return some(newWarningData(wAssignTrueFalse))

    # Add the default l prefix to the variable name.
    dotNameList.insert("l", 0)

  if dotNameList.len == 1 and dotNameList[0] in ["l", "g", "o"]:
    # You cannot assign to an existing variable.
    return some(newWarningData(wImmutableVars))

  # Determine the dictionary to add the variable.
  let valueOr = getParentDictToAddTo(variables, dotNameList)
  if valueOr.isMessage:
    return some(valueOr.message)

  # Assign the last name to its dictionary.
  let lastName = dotNameList[^1]
  case operator
  of opEqual:
    if lastName in valueOr.value.dictv.dict:
      # You cannot assign to an existing variable.
      return some(newWarningData(wImmutableVars))

    if valueOr.value.dictv.mutable == Mutable.immutable:
      # You cannot assign to an immutable dictionary.
      return some(newWarningData(wImmutableDict))

    # Assign the value to the dictionary.
    valueOr.value.dictv.dict[lastName] = value

  of opAppendList:
    # Append to a list, or create then append.

    # If the variable doesn't exists, create an empty list.
    if not (lastName in valueOr.value.dictv.dict):
      # Make sure the parent element is mutable.
      if valueOr.value.dictv.mutable == Mutable.immutable:
        # You cannot create a new list element in the immutable dictionary.
        return some(newWarningData(wNewListInDict))

      # Create a new list dictionary element.
      valueOr.value.dictv.dict[lastName] = newEmptyListValue(mutable = Mutable.append)

    let lastComponent = valueOr.value.dictv.dict[lastName]
    if lastComponent.kind != vkList:
      # You can only append to a list, got $1.
      return some(newWarningData(wAppendToList, $lastComponent.kind))

    if lastComponent.listv.mutable == Mutable.immutable:
      # You cannot append to an immutable list.
      return some(newWarningData(wImmutableList))

    # Append the value to the list.
    lastComponent.listv.list.add(value)
  of opIgnore, opReturn, opLog:
    assert(false, "You cannot assign using the $1 operator." % $operator)
    discard

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
    next = value.dictv.dict

proc assignVariable*(
  variables: var Variables,
  variableData: VariableData,
  ): Option[WarningData] =
  ## Assign the variable the given value if possible, else return a
  ## warning.
  result = assignVariable(variables, variableData.dotNameStr, variableData.value,
      variableData.operator)

proc getVariable*(variables: Variables, dotNameStr: string,
    noPrefixDict: NoPrefixDict): ValueOr =
  ## Look up the variable and return its value when found, else return
  ## a warning. When no prefix is specified, look in the noPrefixDict
  ## dictionary.
  assert variables != nil

  if dotNameStr == "true":
    return newValueOr(newValue(true))
  elif dotNameStr == "false":
    return newValueOr(newValue(false))

  var names = split(dotNameStr, '.')
  let nameSpace = names[0]
  case nameSpace
  of "g", "l", "s", "t", "o", "f":
    result = lookUpVar(variables, names)
  of "h", "i", "j", "k", "m", "n", "p", "q", "r", "u":
    # The variables f, h - k, m - r, u are reserved variable names.
    result = newValueOr(wReservedNameSpaces)
  else:
    # Non-prefix variable, look it up in its default dictionary.
    var prefix: string
    case noPrefixDict
    of npLocal:
      prefix = "l"
    of npBuiltIn:
      prefix = "f"

    var varNames = @[prefix] & names
    result = lookUpVar(variables, varNames)
    if result.isMessage:
      # The variable isn't in the x dictionary.
      var messageId: MessageId
      case noPrefixDict
      of npLocal:
        messageId = wNotInL
      of npBuiltIn:
        messageId = wNotInF
      result = newValueOr(messageId, dotNameStr)
