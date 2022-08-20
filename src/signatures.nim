## Statictea function signatures and parameter checking.

import std/tables
import std/strutils
import vartypes
import funtypes
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
  singleCodes = {'i', 'f', 's', 'l', 'd', 'a', 'b'}

type
  ParamCode* = char
    ## Parameter type, one character of "ifslda" corresponding to int,
    ## float, string, list, dict, any.

  ParamKind* = enum
    ## The kind of parameter.
    ## * pkNormal -- a normal parameter
    ## * pkOptional -- an optional parameter. It must be last.
    ## * pkReturn -- a return parameter.
    pkNormal, pkOptional, pkReturn

  Param* = object
    ## Holds attributes for one parameter.
    ## @:* name -- the parameter name
    ## @:* paramCode -- the parameter code, one of: ifslda
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
    result = "int"
  of 'f':
    result = "float"
  of 's':
    result = "string"
  of 'l':
    result = "list"
  of 'd':
    result = "dict"
  of 'a':
    result = "any"
  of 'b':
    result = "bool"
  else:
    assert false, "Invalid paramCode."
    discard

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
  ## Create a dictionary of the parameters. The parameter names are
  ## the dictionary keys.  Return a FunResult object containing the
  ## dictionary or a warning when the parameters do not match the
  ## signature.  The last signature parameter is for the return type.

  var map = newVarsDict()

  # Determine the number of required parameters and whether the
  # signature contains an optional last element.
  var gotOptional: bool
  var requiredParams: int
  var loopParams: int
  if params.len >= 2:
    let lastParamIx = params.len - 2
    gotOptional = (params[lastParamIx].paramKind == pkOptional)
    if gotOptional:
      requiredParams = lastParamIx
      if args.len > lastParamIx:
        loopParams = lastParamIx + 1
      else:
        loopParams = lastParamIx
    else:
      requiredParams = params.len - 1
      loopParams = params.len - 1
  else:
    # No parameters case.
    gotOptional = false
    requiredParams = 0
    loopParams = 0

  # Check there are enough parameters.
  if args.len < requiredParams:
    if gotOptional:
      # The function requires at least $1 arguments.
      return newFunResultWarn(wNotEnoughArgsOpt, 0, $requiredParams)
    else:
      # Not enough parameters, $1 required.
      return newFunResultWarn(wNotEnoughArgs, 0, $requiredParams)

  # Check there are not too many parameters.
  var limit: int
  if gotOptional:
    limit = requiredParams + 1
  else:
    limit = requiredParams
  if args.len > limit:
    if gotOptional:
      # The function requires at most $1 arguments.
      return newFunResultWarn(wTooManyArgsOpt, limit, $limit)
    else:
      # The function requires $1 arguments.
      return newFunResultWarn(wTooManyArgs, limit, $limit)

  # Loop through the parameters.
  for ix in countUp(0, loopParams - 1):
    var param = params[ix]
    var arg = args[ix]

    # Check the parameter is the correct type.
    if not sameType(param.paramCode, arg.kind):
      let expected = paramCodeString(param.paramCode)
      # Wrong argument type, expected $1.
      return newFunResultWarn(wWrongType, ix, $expected)

    map[param.name] = arg

  result = newFunResult(newValue(map))
