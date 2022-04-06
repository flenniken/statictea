## Statictea function signatures and parameter checking.

import std/tables
import vartypes
import funtypes
import options
import messages
# import strformat
import strutils

#[

We prefer the term parameter to mean information that is passed to a
function. However, inside a function we use parameter for the
variables in the function signature and argument as the values sent to
the function when called.

]#

const
  singleCodes = {'i', 'f', 's', 'l', 'd', 'a'}

# todo: support list types, li, lf, ls, ll, ld, la.

type
  ParamType* = char
    # Parameter type, one character of ifsldaIFSLDA.

  Param* = object
    ## Holds attributes for one parameter.
    name*: string
      ## The name of the parameter.
    paramTypes*: seq[ParamType]
      ## The type of the parameter.
    optional*: bool
      ## This is an optional parameter.
    returnType*: bool
      ## This is a return parameter.

type
  ShortName* = object
    ## Object to hold the state for the "next" function.
    ix: int

func newParam*(name: string, optional: bool, returnType: bool,
    paramTypes: seq[Paramtype]): Param =
  ## Create a new Param object.
  result = Param(name: name, optional: optional,
                 returnType: returnType, paramTypes: paramTypes)

func kindToParamType*(kind: ValueKind): ParamType =
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

func paramTypeString*(paramType: ParamType): string =
  ## Return a string representation of a ParamType object.
  case toLowerAscii(paramType):
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
  else:
    assert false, "Invalid paramType."
    discard

func `$`*(param: Param): string =
  ## Return a string representation of a Param object.
  var optional: string
  if param.optional:
    optional = "optional "
  else:
    optional = ""
  if param.returnType:
    result = paramTypeString(param.paramTypes[0])
  else:
    # name: int
    let typeString = paramTypeString(param.paramTypes[0])
    # result = fmt"{param.name}: {optional}{typeString}"
    result = "$1: $2$3" % [param.name, optional, typeString]

func sameType*(paramType: ParamType, valueKind: ValueKind): bool =
  ## Check whether the param type is the same type or compatible with
  ## the value.

  case toLowerAscii(paramType):
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
    else:
      assert false, "Invalid paramType"
      discard

func parmsToSignature*(params: seq[Param]): string =
  ## Create a signature from a list of Params.
  var inside: string
  if params.len > 1:
    inside = join(params[0 .. params.len-2], ", ")
  let returnType = $params[params.len-1]
  # result = fmt"({inside}) {returnType}"
  result = "($1) $2" % [inside, returnType]

# These are for working with signature strings.
# proc matchInsideAndReturn*(line: string): Option[Matches] =
#   ## Match a signature like: (a: int, b: int) int.  Return two groups:
#   ## "a: int, b: int" and "int"
#   let pattern = r"^\(([^\)]*)\)\s(.*)"
#   result = matchPatternCached(line, pattern)

# proc matchParamName*(line: string): Option[Matches] =
#   let pattern = r"^[a-zA-Z][a-zA-Z0-9_]{0,63}$"
#   result = matchPatternCached(line, pattern)

# func getParameters*(parameters: seq[Value], start: int, count: int): Option[seq[Value]] =
#   ## Return the number of parameters specified by count starting at
#   ## start index, if there are enough left.
#   if start < 0 or count <= 0 or start + count > parameters.len:
#     return
#   result = some(parameters[start .. start + count - 1])

proc next*(letterName: var ShortName): string =
  ## Get the next unique single letter name. It returns names a, b, c,
  ## ..., z then repeats a0, b0, c0,....

  let letters = "abcdefghijklmnopqurstuvwxyz"
  var num = 0
  var numString: string
  if letterName.ix > letters.len - 1:
    letterName.ix = 0
  if num > 0:
    numString = $num
  result = $letters[letterName.ix] & numString
  inc(letterName.ix)

func signatureCodeToParams*(signatureCode: string): Option[seq[Param]] =
  ## Convert the signature code to a list of Param objects.
  var params: seq[Param]

  let returnCode = signatureCode[signatureCode.len-1]
  var letterName = ShortName()
  var optional: bool
  var ix = 0

  while ix < signatureCode.len - 1:
    var code = signatureCode[ix]
    if code in singleCodes:
      params.add(newParam(letterName.next(), optional, false, @[code]))
      inc(ix)
    elif code == 'o':
      optional = true
      inc(ix)
    else:
      # Invalid signature code.
      return

  # Return the return parameter.
  params.add(newParam("result", false, true, @[returnCode]))
  result = some(params)

func mapParameters*(params: seq[Param], args: seq[Value]): FunResult =
  ## Create a dictionary of the parameters. The parameter names are
  ## the dictionary keys.  Return a FunResult object containing the
  ## dictionary or a warning when the parameters do not match the
  ## signature.  The last signature param is for the return type.

  var map = newVarsDict()

  # Determine the number of required parameters and whether the
  # signature contains an optional last element.
  var gotOptional: bool
  var requiredParams: int
  var loopParams: int
  if params.len >= 2:
    let lastParamIx = params.len - 2
    gotOptional = params[lastParamIx].optional
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
    # Not enough parameters, $1 required.
    return newFunResultWarn(kNotEnoughArgs, 0, $requiredParams)

  # Check there are not too many parameters.
  var limit: int
  if gotOptional:
    limit = requiredParams + 1
  else:
    limit = requiredParams
  if args.len > limit:
    # Too many arguments, expected at most $1."
    return newFunResultWarn(kTooManyArgs, 0, $requiredParams)

  # Loop through the parameters.
  for ix in countUp(0, loopParams - 1):
    var param = params[ix]
    var arg = args[ix]

    # Check the parameter is the correct type.
    if not sameType(param.paramTypes[0], arg.kind):
      let expected = paramTypeString(param.paramTypes[0])
      # Wrong parameter type, expected $1.
      return newFunResultWarn(kWrongType, ix, $expected)

    map[param.name] = arg

  result = newFunResult(newValue(map))
