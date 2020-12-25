## Run a function.

import env
import vartypes
import options
import warnings
import variables
import tables

type
  functionPtr* = proc (env: var Env, lineNum: Natural, parameters: seq[Value]): Option[Value]

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
  ## Get the byte length of a string, or the number of elements in
  ## list or dictionary.  One parameter. Added in version 0.1.0.
  if parameters.len() != 1:
    env.warn(lineNum, wOneParameter)
    return
  var retValue: Value
  let value = parameters[0]
  case value.kind
    of vkString:
      retValue = newValue(value.stringv.len)
    of vkList:
      retValue = newValue(value.listv.len)
    of vkDict:
      retValue = newValue(value.dictv.len)
    else:
      env.warn(lineNum, wStringListDict)
      return
  result = some(retValue)

# todo: use a table for the functions.
proc getFunction*(functionName: string): Option[functionPtr] =
  ## Return the function pointer for the given function name.
  var function: functionPtr
  case functionName
  of "len":
    function = funLen
  of "concat":
    function = funConcat
  else:
    return
  result = some(function)

proc runFunction*(env: var Env, functionName: string,
    statement: Statement, start: Natural, variables: Variables,
    parameters: seq[Value]): Option[Value] =
  ## Call the given function and return its value.
  var functionO = getFunction(functionName)
  if not isSome(functionO):
    env.warnStatement(statement, wInvalidFunction, start)
    return
  var function = functionO.get()
  result = function(env, statement.lineNum, parameters)
  if not isSome(result):
    env.warnStatement(statement, wInvalidStatement, start)

