## Run a function.

import env
import vartypes
import options
import warnings
import variables

proc funConcat*(env: var Env, lineNum: Natural, parameters:
               seq[Value]): Option[Value] =
  ## Concatentate the string parameters.
  var string = ""
  for ix, value in parameters:
    if value.kind != vkString:
      env.warn(lineNum, wExpectedStrings, $(ix+1))
      return
    string.add(value.stringv)
  result = some(newStringValue(string))

proc runFunction*(env: var Env, functionName: string,
    statement: Statement, start: Natural, variables: Variables,
    parameters: seq[Value]): Option[Value] =
  ## Call the given function and return its value.
  if functionName == "len":
    result = some(Value(kind: vkInt, intv: 3))
  elif functionName == "concat":
    result = funConcat(env, statement.lineNum, parameters)

