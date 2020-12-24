## Run a function.

import env
import vartypes
import options
import warnings
import variables

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

proc runFunction*(env: var Env, functionName: string,
    statement: Statement, start: Natural, variables: Variables,
    parameters: seq[Value]): Option[Value] =
  ## Call the given function and return its value.
  if functionName == "len":
    result = some(Value(kind: vkInt, intv: 3))
  elif functionName == "concat":
    result = funConcat(env, statement.lineNum, parameters)
  if not isSome(result):
    env.warnStatement(statement, wInvalidStatement, start)

