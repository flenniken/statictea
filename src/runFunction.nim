## Run a function.

import env
import vartypes
import options
import warnings
import variables
import tables

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

const
  functionsList = [
    ("len", funLen),
    ("concat", funConcat),
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

proc runFunction*(env: var Env, functionName: string,
    statement: Statement, start: Natural, variables: Variables,
    parameters: seq[Value]): Option[Value] =
  ## Call the given function and return its value. When the function
  ## does not return a value, show the statement and the warning
  ## position.

  var functionO = getFunction(functionName)
  if not isSome(functionO):
    env.warnStatement(statement, wInvalidFunction, start)
    return
  var function = functionO.get()
  result = function(env, statement.lineNum, parameters)
  if not isSome(result):
    env.warnStatement(statement, wInvalidStatement, start)
