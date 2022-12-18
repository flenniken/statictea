## Statictea function signatures and parameter checking.

import std/tables
import vartypes
import messages

# Function parameters are the names listed in the function's definition.
# Function arguments are the real values passed to the function.

func paramCodeString*(paramCode: ParamCode): string =
  ## Return a string representation of a ParamCode object.

  case paramCode:
  of 'i':
    result = $vkInt
  of 'f':
    result = $vkFloat
  of 's':
    result = $vkString
  of 'l':
    result = $vkList
  of 'd':
    result = $vkDict
  of 'b':
    result = $vkBool
  of 'p':
    result = $vkFunc
  of 'a':
    result = "any"
  else:
    assert(false, "invalid ParamCode")
    result = $vkInt

func kindToParamCode*(kind: ValueKind): ParamCode =
  ## Convert a value type to a parameter type.
  case kind:
    of vkInt:
      result = 'i'
    of vkFloat:
      result = 'f'
    of vkString:
      result = 's'
    of vkList:
      result = 'l'
    of vkDict:
      result = 'd'
    of vkBool:
      result = 'b'
    of vkFunc:
      # p for procedure
      result = 'p'

func sameType*(paramCode: ParamCode, valueKind: ValueKind): bool =
  ## Check whether the param type is the same type or compatible with
  ## the value.

  case paramCode:
    of 'a':
      return true
    of 'i':
      if valueKind == vkInt:
        return true
    of 'f':
      if valueKind == vkFloat:
        return true
    of 's':
      if valueKind == vkString:
        return true
    of 'l':
      if valueKind == vkList:
        return true
    of 'd':
      if valueKind == vkDict:
        return true
    of 'b':
      if valueKind == vkBool:
        return true
    of 'p':
      if valueKind == vkFunc:
        return true
    else:
      assert false, "Invalid paramCode"
      discard

func sameType*(paramType: ParamType, valueKind: ValueKind): bool =
  ## Check whether the param type is the same type or compatible with
  ## the value.

  if ord(paramType) == ord(valueKind):
    result = true
  elif paramType == ptAny:
    result = true
  else:
    result = false

func mapParameters*(signature: Signature, args: seq[Value]): FunResult =
  ## Create a dictionary of the arguments. The parameter names become
  ## the dictionary keys.  Return a FunResult object containing the
  ## dictionary or a warning when the arguments do not match the
  ## signature.  When they do not match, the warning parameter tells
  ## the first non-matching argument.

  var map = newVarsDict()

  # Loop through the parameters and compare to the arguments.
  var numParams = signature.params.len
  for ix, param in signature.params:

    if ix >= args.len:
      var message: MessageId
      var requiredArgs: Natural
      if signature.kind == skNormal:
        requiredArgs = numParams
        # Not enough arguments, $1 required.
        message = wNotEnoughArgs
      else: # optional
        if ix == args.len and ix == numParams - 1:
          break # matched all required
        # The function requires at least $1 arguments.
        message = wNotEnoughArgsOpt
        requiredArgs = numParams - 1
      return newFunResultWarn(message, parameter=ix, p1 = $requiredArgs)

    let arg = args[ix]

    # Check the parameter and argument types match.
    if not sameType(param.paramType, arg.kind):
      # Wrong argument type, expected $1.
      return newFunResultWarn(wWrongType, parameter=ix, p1 = $param.paramType)

    map[param.name] = arg

  if args.len > numParams:
    var message: MessageId
    var requiredArgs: Natural
    if signature.kind == skNormal:
      # The function requires $1 arguments.
      message = wTooManyArgs
      requiredArgs = numParams
    else: # optional
      # The function requires at most $1 arguments.
      message = wTooManyArgsOpt
      requiredArgs = numParams
    return newFunResultWarn(message, parameter=numParams, p1 = $requiredArgs)

  result = newFunResult(newValue(map))
