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
  ## Concatentate the string parameters.
  ## Added in version 0.1.0.
  var str = ""
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
  ## Get an item from a list or dictionary. The first parameter is the
  ## list or dictionary. The second parameter is the list index or the
  ## dictionary key. The third optional parameter is the value to use
  ## when the item doesn't exists.  Added in version 0.1.0.

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
      if index < 0 or index >= container.listv.len:
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

const
  functionsList = [
    ("len", funLen),
    ("concat", funConcat),
    ("get", funGet),
    ("cmp", funCmp),
  ]

proc getFunction*(functionName: string): Option[FunctionPtr] =
  ## Return the function pointer for the given function name.

  if functions.len == 0:
    for item in functionsList:
      var (name, fun) = item
      functions[name] = fun

  var function = functions.getOrDefault(functionName)
  if function != nil:
    result = some(function)
