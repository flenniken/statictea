##[
Module for variables.

Here are the tea variables:

-t.content -- content of the replace block.
-t.global -- dictionary containing the global variables.
-t.local -- dictionary containing the current command's local variables.
-t.maxLines -- maximum number of replacement block lines (lines before endblock).
-t.maxRepeat -- maximum number of times to repeat the block.
-t.output -- where the block output goes.
-t.repeat -- controls how many times the block repeats.
-t.row -- the current row number of a repeating block.
-t.server -- dictionary containing the server json variables.
-t.shared -- dictionary containing the shared json variables.
-t.version -- the StaticTea version number.

Here are the tea variables grouped by type:

Constant:

-t.version

Dictionaries:

-t.global
-t.local
-t.server -- read only
-t.shared -- read only

Integers:

-t.maxLines -- default when not set: 10
-t.maxRepeat -- default when not set: 100
-t.repeat -- default when not set: 1
-t.row -- 0 read only, automatically increments

String:

-t.content -- default when not set: ""

String enum t.output:

- "result" -- the block output goes to the result file (default)
- "stderr" -- the block output goes to standard error
- "log" -- the block output goes to the log file
- "skip" -- the block is skipped

]##

import vartypes
import tables
import options
import version
import warnings
import strutils

const
  outputValues* = ["result", "stderr", "log", "skip"]
    ## Tea output variable values.

type
  Variables* = VarsDict
    ## Dictionary holding variables.

  VariableData* = object
    ## A variable namespace, name and value.
    nameSpace*: string
    varName*: string
    value*: Value

  WarningSide* = enum
    ## Tells which side of the assignment the warning applies to.
    wsVarName,
    wsValue

  WarningDataPos* = object
    ## A warning and the side it applies to.
    warningData*: WarningData
    warningSide*: WarningSide

func emptyVariables*(): Variables =
  ## Create an empty variables object in its initial state.
  var emptyVarsDict: VarsDict
  result["local"] = newValue(emptyVarsDict)
  result["global"] = newValue(emptyVarsDict)
  result["row"] = newValue(0)
  result["version"] = newValue(staticteaVersion)

func newVariableData*(nameSpace: string, varName: string, value: Value): VariableData =
  ## Create a new VariableData object.
  result = VariableData(nameSpace: nameSpace, varName: varName, value: value)

func newWarningDataPos*(warning: Warning, p1: string = "", p2: string = "",
    warningSide: WarningSide): WarningDataPos =
  ## Create a WarningDataPos object containing the given warning information.
  let warningData = WarningData(warning: warning, p1: p1, p2: p2)
  result = WarningDataPos(warningData: warningData, warningSide: warningSide)

func `$`*(warningDataPos: WarningDataPos): string =
  ## Return a string representation of WarningDataPos.
  result = "$1 $2" % [$warningDataPos.warningData, $warningDataPos.warningSide]

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
        result = 10
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

  var varsDict: VarsDict
  variables["local"] = newValue(varsDict)

func validateTeaVariable(variables: Variables, varName: string, value: Value): Option[WarningDataPos] =
  ## Validate that it is ok to set the tea variable with the given
  ## value. Return a warning if it is invalid and tell whether the
  ## warning applies to the left hand side or the right hand side.

  if varName in variables:
    if varName in ["server", "shared", "local", "global", "row", "version"]:
        return some(newWarningDataPos(wReadOnlyTeaVar, varName, warningSide = wsVarName))
    return some(newWarningDataPos(wImmutableVars, warningSide = wsVarName))

  case varName:
    of "maxLines":
      # The maxLines variable must be an integer >= 0.
      if value.kind != vkInt or value.intv < 0:
        result = some(newWarningDataPos(wInvalidMaxCount, warningSide = wsValue))
    of "maxRepeat":
      # The maxRepeat variable must be a positive integer >= t.repeat.
      if value.kind != vkInt or value.intv < getTeaVarIntDefault(variables, "repeat"):
        result = some(newWarningDataPos(wInvalidMaxRepeat, warningSide = wsValue))
    of "content":
      # Content must be a string.
      if value.kind != vkString:
        result = some(newWarningDataPos(wInvalidTeaContent, warningSide = wsValue))
    of "output":
      # Output must be a string of "result", etc.
      if value.kind != vkString or not outputValues.contains(value.stringv):
        result = some(newWarningDataPos(wInvalidOutputValue, warningSide = wsValue))
    of "repeat":
      # Repeat is an integer >= 0 and <= t.maxRepeat.
      if value.kind != vkInt or value.intv < 0 or value.intv > getTeaVarIntDefault(variables, "maxRepeat"):
        result = some(newWarningDataPos(wInvalidRepeat, warningSide = wsValue))
    else:
      result = some(newWarningDataPos(wInvalidTeaVar, varName, warningSide = wsVarName))

func validateVariable*(variables: Variables, nameSpace: string, varName: string,
                       value: Value): Option[WarningDataPos] =
  ## Validate that it is ok to set the variable with the given
  ## value. Return a warning if it is invalid and tell whether it
  ## applies to the variable name or to the value.

  var dictName: string
  case nameSpace:
    of "":
      dictName = "local"
    of "g.":
      dictName = "global"
    of "t.":
      return validateTeaVariable(variables, varName, value)
    of "s.", "h.":
      return some(newWarningDataPos(wReadOnlyDictionary, warningSide = wsVarName))
    else:
      return some(newWarningDataPos(wInvalidNameSpace, nameSpace, warningSide = wsVarName))

  if varName in variables[dictName].dictv:
    return some(newWarningDataPos(wImmutableVars, warningSide = wsVarName))

proc assignVariable*(variables: var Variables, nameSpace: string,
    varName: string, value: Value) =
  ## Assign the variable to its dictionary.
  case nameSpace:
    of "":
      variables["local"].dictv[varName] = value
    of "s.":
      if "server" in variables:
        variables["server"].dictv[varName] = value
    of "h.":
      if "shared" in variables:
        variables["shared"].dictv[varName] = value
    of "g.":
      variables["global"].dictv[varName] = value
    of "t.":
      variables[varName] = value
    else:
      discard

proc getVariable*(variables: Variables, namespace: string, varName:
                  string): Option[Value] =
  ## Look up the variable and return its value when found.
  var dictName: string
  case nameSpace:
    of "":
      dictName = "local"
    of "s.":
      dictName = "server"
    of "h.":
      dictName = "shared"
    of "g.":
      dictName = "global"
    of "t.":
      if varName in variables:
        return some(variables[varName])
    else:
      return
  if dictName in variables:
    if varName in variables[dictName].dictv:
      result = some(variables[dictName].dictv[varName])

when defined(test):
  proc echoVariables*(variables: Variables) =
    echo "---tea variables:"
    for k, v in variables.pairs():
      echo k, ": ", $v
    if "shared" in variables:
      echo "---server variables:"
      for k, v in variables["server"].dictv.pairs():
        echo k, ": ", $v
    if "shared" in variables:
      echo "---shared variables:"
      for k, v in variables["shared"].dictv.pairs():
        echo k, ": ", $v
    echo "---local variables:"
    for k, v in variables["local"].dictv.pairs():
      echo k, ": ", $v
    echo "---global variables:"
    for k, v in variables["global"].dictv.pairs():
      echo k, ": ", $v
