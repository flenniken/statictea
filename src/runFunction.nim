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
  ## Get the length of the parameter, either the character length of a
  ## string, or the number of elements in list or dictionary.  Added
  ## in version 0.1.0.
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
