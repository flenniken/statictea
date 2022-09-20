## Statictea function signatures and parameter checking.

import std/tables
import std/strutils
import vartypes
import options
import messages

# * Function parameters are the names listed in the function's definition.
# * Function arguments are the real values passed to the function.
#
# proc myFunction(parameter: string):
#   echo parameter
#
# const argument = 'foo';
# myFunction(argument);

const
  singleCodes = {'a', 'i', 'f', 's', 'l', 'd', 'b', 'p'}

static:
  # Generate a compile error when the single code list doesn't have a
  # letter for each type of value excluding "a".
  const numCodes = len(singleCodes)-1
  const numKinds = ord(high(ValueKind))+1
  when numCodes != numKinds:
    const message = "Update singleCodes:\nnumCode = $1, numKinds = $2\n" % [$numCodes, $numKinds]
    {.error: message .}

type
  ParamCode* = char
    ## Parameter type, one character of "ifsldpa" corresponding to int,
    ## float, string, list, dict, func, any.

  ParamKind* = enum
    ## The kind of parameter.
    ## * pkNormal -- a normal parameter
    ## * pkOptional -- an optional parameter. It must be last.
    ## * pkReturn -- a return parameter.
    pkNormal, pkOptional, pkReturn

  Param* = object
    ## Holds attributes for one parameter.
    ## @:* name -- the parameter name
    ## @:* paramCode -- the parameter code, one of: ifsldpa
    ## @:* paramKind -- whether it is normal, optional or a return
    name*: string
    paramCode*: ParamCode
    paramKind*: ParamKind

func newParam*(name: string, paramKind: ParamKind,
    paramCode: ParamCode): Param =
  ## Create a new Param object.
  result = Param(name: name, paramKind: paramKind, paramCode: paramCode)

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

func `$`*(param: Param): string =
  ## Return a string representation of a Param object.
  var optional: string
  if param.paramKind == pkOptional:
    optional = "optional "
  else:
    optional = ""
  if param.paramKind == pkReturn:
    result = paramCodeString(param.paramCode)
  else:
    # name: int
    let typeString = paramCodeString(param.paramCode)
    result = "$1: $2$3" % [param.name, optional, typeString]

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

func parmsToSignature*(params: seq[Param]): string =
  ## Create a signature from a list of Params.
  assert len(params) > 0
  var inside: string
  if params.len > 1:
    inside = join(params[0 .. params.len-2], ", ")
  let returnType = $params[params.len-1]
  result = "($1) $2" % [inside, returnType]

proc shortName*(index: Natural): string =
  ## Return a short name based on the given index value. Return a for
  ## 0, b for 1, etc.  It returns names a, b, c, ..., z then repeats
  ## a0, b0, c0,....

  let letters = "abcdefghijklmnopqrstuvwxyz"
  assert len(letters) == 26
  let remainder = index mod len(letters)
  let num = index div len(letters)
  let numString = if num == 0: "" else: $num
  result = $letters[remainder] & numString
  # debugEcho("index $1, num $2, remainder $3, result $4" % [
  #   $index, $num, $remainder, result])

func signatureCodeToParams*(signatureCode: string): Option[seq[Param]] =
  ## Convert the signature code to a list of Param objects.
  var params: seq[Param]
  var paramKind: ParamKind
  var nameIx = 0
  if len(signatureCode) < 1:
    return
  for ix in countUp(0, signatureCode.len - 2):
    var code = signatureCode[ix]
    if code in singleCodes:
      params.add(newParam(shortName(nameIx), paramKind, code))
      paramKind = pkNormal
      inc(nameIx)
    elif code == 'o':
      paramKind = pkOptional
    else:
      # Invalid signature code.
      return

  let returnCode = signatureCode[signatureCode.len-1]
  params.add(newParam("result", pkReturn, returnCode))
  result = some(params)

func mapParameters*(params: seq[Param], args: seq[Value]): FunResult =
  ## Create a dictionary of the arguments. The parameter names become
  ## the dictionary keys.  Return a FunResult object containing the
  ## dictionary or a warning when the arguments do not match the
  ## signature.  When they do not match, the warning parameter tells
  ## the first non-matching argument.

  var map = newVarsDict()

  # Determine whether the signature contains an optional last element.
  # The last signature parameter is for the return type.
  var gotOptional: bool
  if params.len >= 2:
    let lastParamIx = params.len - 2
    gotOptional = (params[lastParamIx].paramKind == pkOptional)
  else:
    # No parameters case.
    gotOptional = false

  # Loop through the parameters and compare to the arguments.
  var lastIx: int
  for ix in countUp(0, params.len - 2):
    lastIx = ix
    let param = params[ix]

    if ix == args.len and gotOptional and param.paramKind == pkOptional:
      break

    if ix >= args.len:
      let warning = if gotOptional: wNotEnoughArgsOpt else: wNotEnoughArgs
      let requiredArgs = if gotOptional: params.len - 2 else: params.len - 1
      # The function requires at least $1 arguments.
      # Not enough arguments, $1 required.
      return newFunResultWarn(warning, parameter=ix, p1 = $requiredArgs)

    let arg = args[ix]

    # Check the parameter and argument match.
    if not sameType(param.paramCode, arg.kind):
      let expected = paramCodeString(param.paramCode)
      # Wrong argument type, expected $1.
      return newFunResultWarn(wWrongType, parameter=ix, p1 = $expected)

    map[param.name] = arg

  if args.len > params.len - 1:
    let warning = if gotOptional: wTooManyArgsOpt else: wTooManyArgs
      # The function requires at most $1 arguments.
      # The function requires $1 arguments.
    return newFunResultWarn(warning, parameter=lastIx+1, p1 = $(params.len - 1))

  result = newFunResult(newValue(map))
