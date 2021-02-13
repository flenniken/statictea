## Run a function.

import vartypes
import options
import warnings
import tables
import unicode
import strutils

type
  FunctionPtr* = proc (parameters: seq[Value]): FunResult

  FunResultKind* = enum
    frValue,
    frWarning

  FunResult* = ref FunResultObj
  FunResultObj* {.acyclic.} = object
    case kind*: FunResultKind
      of frValue:
        value*: Value       ## Return value of the function.
      of frWarning:
        warning*: Warning   ## Warning message id.
        parameter*: Natural ## Index of problem parameter.
        p1*: string         ## Extra warning info.
        p2*: string         ## Extra warning info.

var functions: Table[string, FunctionPtr]

proc newFunResultWarn*(warning: Warning, parameter: Natural = 0,
      p1: string = "", p2: string = ""): FunResult =
  result = FunResult(kind: frWarning, warning: warning,
             parameter: parameter, p1: p1, p2: p2)

proc newFunResult*(value: Value): FunResult =
  result = FunResult(kind: frValue, value: value)

proc `==`*(funResult1: FunResult, funResult2: FunResult): bool =
  if funResult1.kind == funResult2.kind:
    case funResult1.kind:
      of frValue:
        result = funResult1.value == funResult2.value
      else:
        if funResult1.warning == funResult2.warning and
           funResult1.parameter == funResult2.parameter and
           funResult1.p1 == funResult2.p1 and
           funResult1.p2 == funResult2.p2:
          result = true

func `$`*(funResult: FunResult): string =
  ## A string representation of FunResult.
  case funResult.kind
  of frValue:
    result = $funResult.value
  else:
    result = "warning: $1: $2 $3 $4" % [
      $funResult.warning, $funResult.parameter, funResult.p1, funResult.p2
    ]

proc cmpString*(a, b: string, ignoreCase: bool = false): int =
  ## Compares two UTF-8 strings and returns 0 when equal, 1 when a > b
  ## and -1 when a < b. Optionally Ignore case.
  var i = 0
  var j = 0
  var ar, br: Rune
  var ret: int
  while i < a.len and j < b.len:
    fastRuneAt(a, i, ar)
    fastRuneAt(b, j, br)
    if ignoreCase:
      ar = toLower(ar)
      br = toLower(br)
    ret = int(ar) - int(br)
    if ret != 0:
      break
  if ret == 0:
    ret = a.len - b.len
  if ret < 0:
    result = -1
  elif ret > 0:
    result = 1
  else:
    result = 0

proc funCmp*(parameters: seq[Value]): FunResult =
  ## The cmp function compares two variables, either numbers or
  ## strings (both the same type), and returns whether the first
  ## parameter is less than, equal to or greater than the second
  ## parameter. It returns -1 for less, 0 for equal and 1 for greater
  ## than. The optional third parameter compares strings case
  ## insensitive when it is 1. Added in version 0.1.0.
  if parameters.len() < 2 or parameters.len() > 3:
    result = newFunResultWarn(wTwoOrThreeParameters, 0)
    return
  let value1 = parameters[0]
  let value2 = parameters[1]
  if value1.kind != value2.kind:
    result = newFunResultWarn(wNotSameKind, 0)
    return
  var ret: int
  case value1.kind
    of vkString:
      var caseInsensitive: bool
      if parameters.len() == 3:
        let value3 = parameters[2]
        if value3.kind == vkInt and value3.intv == 1:
          caseInsensitive = true
      ret = cmpString(value1.stringv, value2.stringv, caseInsensitive)
    of vkInt:
      ret = cmp(value1.intv, value2.intv)
    of vkFloat:
      ret = cmp(value1.floatv, value2.floatv)
    else:
      result = newFunResultWarn(wNotNumberOrString, 0)
      return
  result = newFunResult(newValue(ret))

proc funConcat*(parameters: seq[Value]): FunResult =
  ## Concatentate the string parameters. You pass 2 or more string
  ## parameters.  Added in version 0.1.0.
  var str = ""
  if parameters.len() < 2:
    result = newFunResultWarn(wTwoOrMoreParameters, 0)
    return
  for ix, value in parameters:
    if value.kind != vkString:
      result = newFunResultWarn(wExpectedString, ix)
      return
    str.add(value.stringv)
  result = newFunResult(newValue(str))

proc funLen*(parameters: seq[Value]): FunResult =
  ## The len function takes one parameter and returns the number of
  ## characters in a string (not bytes), the number of elements in a
  ## list or the number of elements in a dictionary.  Added in version
  ## 0.1.0.
  if parameters.len() != 1:
    result = newFunResultWarn(wOneParameter, 0)
    return
  var retValue: Value
  let value = parameters[0]
  case value.kind
    of vkString:
      retValue = newValue(runeLen(value.stringv))
    of vkList:
      retValue = newValue(value.listv.len)
    of vkDict:
      retValue = newValue(value.dictv.len)
    else:
      result = newFunResultWarn(wStringListDict, 0)
      return
  result = newFunResult(retValue)

proc funGet*(parameters: seq[Value]): FunResult =
  ## You use the get function to return a list or dictionary element.
  ## You pass two or three parameters, the first is the dictionary or
  ## list to use, the second is the dictionary key name or the list
  ## index, and the third optional parameter is the default value when
  ## the element doesn't exist.
  ##
  ## If you don't specify the default, a warning is generated when the
  ## element doesn't exist and the statement is skipped.
  ##
  ## -p1: dictionary or list
  ## -p2: string or int
  ## -p3: optional, any type
  ##
  ## Added in version 0.1.0.

  if parameters.len() < 2 or parameters.len() > 3:
    return newFunResultWarn(wGetTakes2or3Params, 0)

  let container = parameters[0]
  case container.kind
    of vkList:
      let p2 = parameters[1]
      if p2.kind != vkInt:
        return newFunResultWarn(wExpectedIntFor2, 1, $p2.kind)
      var index = p2.intv
      if index < 0:
        return newFunResultWarn(wInvalidIndex, 1, $index)
      if index >= container.listv.len:
        if parameters.len == 3:
          return newFunResult(parameters[2])
        return newFunResultWarn(wMissingListItem, 1, $index)
      return newFunResult(newValue(container.listv[index]))
    of vkDict:
      let p2 = parameters[1]
      if p2.kind != vkString:
        return newFunResultWarn(wExpectedStringFor2, 1, $p2.kind)
      var key = p2.stringv
      if key in container.dictv:
        return newFunResult(container.dictv[key])
      if parameters.len == 3:
        return newFunResult(newValue(parameters[2]))
      return newFunResultWarn(wMissingDictItem, 1, key)
    else:
      return newFunResultWarn(wExpectedListOrDict, 0)

proc funIf*(parameters: seq[Value]): FunResult =
  ## You use the if function to return a value based on a condition.
  ## It has three parameters, the condition, the true case and the
  ## false case.
  ##
  ## 1. Condition is an integer.
  ## 2. True case, is the value returned when condition is 1.
  ## 3. Else case, is the value returned when condition is not 1.
  ##
  ## Added in version 0.1.0.

  if parameters.len() != 3:
    result = newFunResultWarn(wThreeParameters, 0)
    return

  let condition = parameters[0]
  if condition.kind != vkInt:
    result = newFunResultWarn(wExpectedInteger, 0)
    return

  if condition.intv == 1:
    result = newFunResult(parameters[1])
  else:
    result = newFunResult(parameters[2])

{.push overflowChecks: on, floatChecks: on.}

proc funAdd*(parameters: seq[Value]): FunResult =
  ## The add function returns the sum of its two or more
  ## parameters. The parameters must be all integers or all floats.  A
  ## warning is generated on overflow and the statement is skipped.
  ##
  ## Added in version 0.1.0.

  if parameters.len() < 2:
    result = newFunResultWarn(wTwoOrMoreParameters, 0)
    return

  let first = parameters[0]
  if first.kind != vkInt and first.kind != vkFloat:
    result = newFunResultWarn(wAllIntOrFloat, 0)
    return

  for ix, value in parameters[1..^1]:
    if value.kind != first.kind:
      result = newFunResultWarn(wAllIntOrFloat, 0)
      return

    try:
      if first.kind == vkInt:
        first.intv = first.intv + value.intv
      else:
        first.floatv = first.floatv + value.floatv
    except:
      result = newFunResultWarn(wOverflow, ix)
      return

  result = newFunResult(first)

{.pop.}

proc funExists*(parameters: seq[Value]): FunResult =
  ## Return 1 when a variable exists in the given dictionary, else
  ## return 0. The first parameter is the dictionary to check and the
  ## second parameter is the name of the variable.
  ##
  ## -p1: dictionary: The dictionary to use.
  ## -p2: string: The name (key) to use.
  ##
  ## Added in version 0.1.0.

  if parameters.len() != 2:
    result = newFunResultWarn(wTwoParameters, 0)
    return

  let container = parameters[0]
  if container.kind != vkDict:
    result = newFunResultWarn(wExpectedDictionary, 0)
    return

  let key = parameters[1]
  if key.kind != vkString:
    result = newFunResultWarn(wExpectedString, 1)
    return

  var num: int
  if key.stringv in container.dictv:
    num = 1
  result = newFunResult(newValue(num))

proc funCase*(parameters: seq[Value]): FunResult =
  ## The case function returns a value from multiple choices.
  ##
  ## It requires at least four parameters, the main condition, the
  ## "else" value and a case pair. You can have any number of case
  ## pairs.
  ##
  ## The first parameter of a case pair is the case condition and the
  ## second is the return value when that condition matches the main
  ## condition.
  ##
  ## When none of the cases match the main condition, the "else" value
  ## is returned.  The conditions must be all strings or all ints and
  ## the return values any be any type.
  ##
  ## The function compares the conditions left to right and returns
  ## when it finds the first match.
  ##
  ## -p1: The main condition value.
  ## -p2: The "else" value.
  ##
  ## -p3: The first case condition.
  ## -p4: Return value when p3 equals p1.
  ## ...
  ## -pnc: The last case condition.
  ## -pnv: Return value when pnc equals p1.
  ##
  ## Added in version 0.1.0.

  # At least four parameters and an even number of them.
  if parameters.len() < 4 or parameters.len() mod 2 == 1:
    result = newFunResultWarn(wFourParameters, 0)
    return

  let mainCondition = parameters[0]
  if mainCondition.kind != vkString and mainCondition.kind != vkInt:
    result = newFunResultWarn(wInvalidMainType, 0)
    return

  # Make sure each condition type matches the main condition. We do
  # this before comparing to catch lurking error edge cases.
  for ix in countUp(2, parameters.len-1, 2):
    var condition = parameters[ix]
    if condition.kind != mainCondition.kind:
      result = newFunResultWarn(wInvalidCondition, ix)
      return

  var ixRet = 1
  for ix in countUp(2, parameters.len-1, 2):
    var condition = parameters[ix]
    if condition.kind == vkString:
      if condition.stringv == mainCondition.stringv:
        ixRet = ix+1
        break
    else:
      if condition.intv == mainCondition.intv:
        ixRet = ix+1
        break

  result = newFunResult(parameters[ixRet])

const
  functionsList = [
    ("len", funLen),
    ("concat", funConcat),
    ("get", funGet),
    ("cmp", funCmp),
    ("if", funIf),
    ("add", funAdd),
    ("exists", funExists),
    ("case", funCase),
  ]

# todo: add function to get the list of functions? or check whether one exists?

proc getFunction*(functionName: string): Option[FunctionPtr] =
  ## Return the function pointer for the given function name.

  # Build a table of functions.
  if functions.len == 0:
    for item in functionsList:
      var (name, fun) = item
      functions[name] = fun

  var function = functions.getOrDefault(functionName)
  if function != nil:
    result = some(function)
