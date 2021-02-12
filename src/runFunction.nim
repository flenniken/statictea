## Run a function.

import env
import vartypes
import options
import warnings
import tables
import unicode

type
  FunctionPtr* = proc (env: var Env, lineNum: Natural, parameters: seq[Value]): Option[Value]

var functions: Table[string, FunctionPtr]

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

proc funCmp*(env: var Env, lineNum: Natural, parameters:
               seq[Value]): Option[Value] =
  ## The cmp function compares two variables, either numbers or
  ## strings (both the same type), and returns whether the first
  ## parameter is less than, equal to or greater than the second
  ## parameter. It returns -1 for less, 0 for equal and 1 for greater
  ## than. The optional third parameter compares strings case
  ## insensitive when it is 1. Added in version 0.1.0.
  if parameters.len() < 2 or parameters.len() > 3:
    env.warn(lineNum, wTwoOrThreeParameters)
    return
  let value1 = parameters[0]
  let value2 = parameters[1]
  if value1.kind != value2.kind:
    env.warn(lineNum, wNotSameKind)
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
      env.warn(lineNum, wNotNumberOrString)
      return
  result = some(newValue(ret))


proc funConcat*(env: var Env, lineNum: Natural, parameters:
               seq[Value]): Option[Value] =
  ## Concatentate the string parameters. You pass 2 or more string
  ## parameters.  Added in version 0.1.0.
  var str = ""
  if parameters.len() < 2:
    env.warn(lineNum, wTwoOrMoreParameters)
    return
  for ix, value in parameters:
    if value.kind != vkString:
      env.warn(lineNum, wExpectedStrings, $(ix+1))
      return
    str.add(value.stringv)
  result = some(newValue(str))

proc funLen*(env: var Env, lineNum: Natural, parameters:
               seq[Value]): Option[Value] =
  ## The len function takes one parameter and returns the number of
  ## characters in a string (not bytes), the number of elements in a
  ## list or the number of elements in a dictionary.  Added in version
  ## 0.1.0.
  if parameters.len() != 1:
    env.warn(lineNum, wOneParameter)
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
      env.warn(lineNum, wStringListDict)
      return
  result = some(retValue)

proc funGet*(env: var Env, lineNum: Natural, parameters:
               seq[Value]): Option[Value] =
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
    env.warn(lineNum, wGetTakes2or3Params)
    return

  let container = parameters[0]
  case container.kind
    of vkList:
      let p2 = parameters[1]
      if p2.kind != vkInt:
        env.warn(lineNum, wExpectedIntFor2, $p2.kind)
        return
      var index = p2.intv
      if index < 0:
        env.warn(lineNum, wInvalidIndex, $index)
        return
      if index >= container.listv.len:
        if parameters.len == 3:
          return some(newValue(parameters[2]))
        env.warn(lineNum, wMissingListItem, $index)
        return
      return some(newValue(container.listv[index]))
    of vkDict:
      let p2 = parameters[1]
      if p2.kind != vkString:
        env.warn(lineNum, wExpectedStringFor2, $p2.kind)
        return
      var key = p2.stringv
      if key in container.dictv:
        return some(container.dictv[key])
      if parameters.len == 3:
        return some(newValue(parameters[2]))
      env.warn(lineNum, wMissingDictItem, $key)
    else:
      env.warn(lineNum, wExpectedListOrDict)

proc funIf*(env: var Env, lineNum: Natural, parameters:
               seq[Value]): Option[Value] =
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
    env.warn(lineNum, wThreeParameters)
    return

  let condition = parameters[0]
  if condition.kind != vkInt:
    env.warn(lineNum, wExpectedInteger)
    return

  if condition.intv == 1:
    result = some(parameters[1])
  else:
    result = some(parameters[2])

{.push overflowChecks: on, floatChecks: on.}

proc funAdd*(env: var Env, lineNum: Natural, parameters:
    seq[Value]): Option[Value] =
  ## The add function returns the sum of its two or more
  ## parameters. The parameters must be all integers or all floats.  A
  ## warning is generated on overflow and the statement is skipped.
  ##
  ## Added in version 0.1.0.

  if parameters.len() < 2:
    env.warn(lineNum, wTwoOrMoreParameters)
    return

  let first = parameters[0]
  if first.kind != vkInt and first.kind != vkFloat:
    env.warn(lineNum, wAllIntOrFloat)
    return

  for value in parameters[1..^1]:
    if value.kind != first.kind:
      env.warn(lineNum, wAllIntOrFloat)
      return

    try:
      if first.kind == vkInt:
        first.intv = first.intv + value.intv
      else:
        first.floatv = first.floatv + value.floatv
    except:
      env.warn(lineNum, wOverflow)
      return

  result = some(first)

{.pop.}

proc funExists*(env: var Env, lineNum: Natural, parameters:
    seq[Value]): Option[Value] =
  ## Return 1 when a variable exists in the given dictionary, else
  ## return 0. The first parameter is the dictionary to check and the
  ## second parameter is the name of the variable.
  ##
  ## -p1: dictionary: The dictionary to use.
  ## -p2: string: The name (key) to use.
  ##
  ## Added in version 0.1.0.

  if parameters.len() != 2:
    env.warn(lineNum, wTwoParameters)
    return

  let container = parameters[0]
  if container.kind != vkDict:
    env.warn(lineNum, wExpectedDictionary)
    return

  let key = parameters[1]
  if key.kind != vkString:
    env.warn(lineNum, wExpectedString)
    return

  var num: int
  if key.stringv in container.dictv:
    num = 1
  result = some(newValue(num))

proc funCase*(env: var Env, lineNum: Natural, parameters:
    seq[Value]): Option[Value] =
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
    env.warn(lineNum, wFourParameters)
    return

  let mainCondition = parameters[0]
  if mainCondition.kind != vkString and mainCondition.kind != vkInt:
    env.warn(lineNum, wInvalidMainType)
    return

  # Make sure each condition type matches the main condition. We do
  # this before comparing to catch lurking error edge cases.
  for ix in countUp(2, parameters.len-1, 2):
    var condition = parameters[ix]
    if condition.kind != mainCondition.kind:
      env.warn(lineNum, wInvalidCondition)
      return

  for ix in countUp(2, parameters.len-1, 2):
    var condition = parameters[ix]
    if condition.kind == vkString:
      if condition.stringv == mainCondition.stringv:
        return some(parameters[ix+1])
    else:
      if condition.intv == mainCondition.intv:
        return some(parameters[ix+1])

  return some(parameters[1])

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
