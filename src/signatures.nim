## Statictea function signatures and parameter checking.

import std/tables
import vartypes
import funtypes
import options
import warnings
import strformat
import strutils

#[

We prefer the term parameter to mean information that is passed to a
function. However, inside a function we use parameter for the
variables in the function signature and argument as the values sent to
the function when called.

]#

const
  singleCodes = {'i', 'f', 's', 'l', 'd', 'a'}
  varargCodes = {'I', 'F', 'S', 'L', 'D', 'A'}

# todo: support list types, li, lf, ls, ll, ld, la.

type
  ParamType* = char
    # Parameter type, one character of ifsldaIFSLDA.

  Param* = object
    ## Holds attributes for one parameter.
    name*: string
      ## The name of the parameter.
    paramTypes*: seq[ParamType]
      ## The type of the parameter(s). Varargs can have multiple types.
    optional*: bool
      ## This is an optional parameter.
    varargs*: bool
      ## This is a varargs parameter.
    returnType*: bool
      ## This is a return parameter.

type
  ShortName* = object
    ## Object to hold the state for the "next" function.
    ix: int

func newParam*(name: string, optional: bool, varargs: bool, returnType: bool,
    paramTypes: seq[Paramtype]): Param =
  ## Create a new Param object.
  result = Param(name: name, optional: optional, varargs: varargs,
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
  if param.varargs:
    # name: varargs(int, string)
    var types: seq[string]
    for paramType in param.paramTypes:
      types.add(paramTypeString(paramType))
    let paramTypes = join(types, ", ")
    result = fmt"{param.name}: {optional}varargs({paramTypes})"
  elif param.returnType:
    result = paramTypeString(param.paramTypes[0])
  else:
    # name: int
    let typeString = paramTypeString(param.paramTypes[0])
    result = fmt"{param.name}: {optional}{typeString}"

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
  result = fmt"({inside}) {returnType}"

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
      params.add(newParam(letterName.next(), optional, false, false, @[code]))
      inc(ix)
    elif code == 'o':
      optional = true
      inc(ix)
    elif code in varargCodes:
      # Collect the varargs group of types. Since varargs are last
      # collect to the end.
      var paramTypes: seq[ParamType]
      while ix < signatureCode.len - 1:
        var code = signatureCode[ix]
        assert code in varargCodes
        paramTypes.add(code)
        inc(ix)
      params.add(newParam(letterName.next(), optional, true, false, paramTypes))
      break # done
    else:
      # Invalid signature code.
      return

  # Return the return parameter.
  params.add(newParam("result", false, false, true, @[returnCode]))
  result = some(params)

func mapParameters*(params: seq[Param], args: seq[Value]): FunResult =
  ## Create a dictionary of the parameters. The parameter names are
  ## the dictionary keys.  Varargs parameters turn into a list.
  ## Return a FunResult object containing the dictionary or a warning
  ## when the parameters to not match the signature.  The last
  ## signature param is for the return type.

  var map = newVarsDict()

  # Determine the number of required parameters and whether the
  # signature contains an optional or varargs last element.
  var gotVarargs: bool
  var gotOptional: bool
  var requiredParams: int
  var loopParams: int
  if params.len >= 2:
    let lastParamIx = params.len - 2
    gotVarargs = params[lastParamIx].varargs
    gotOptional = params[lastParamIx].optional
    if gotOptional:
      if gotVarargs:
        requiredParams = lastParamIx - 1
        if args.len > lastParamIx:
          loopParams = lastParamIx
        else:
          loopParams = lastParamIx
      else:
        requiredParams = lastParamIx
        if args.len > lastParamIx:
          loopParams = lastParamIx + 1
        else:
          loopParams = lastParamIx
    else:
      if gotVarargs:
        # Require varargs, need at least one group.
        requiredParams = lastParamIx + params[lastParamIx].paramTypes.len
        loopParams = params.len - 2
      else:
        requiredParams = params.len - 1
        loopParams = params.len - 1
  else:
    # No parameters case.
    gotVarargs = false
    gotOptional = false
    requiredParams = 0
    loopParams = 0

  # Check there are enough parameters.
  if args.len < requiredParams:
    # Not enough parameters, expected {requiredParams} got {args.len}."
    return newFunResultWarn(kNotEnoughArgs, 0, $requiredParams, $args.len)

  # Check there are not too many parameters.
  if not gotVarargs:
    var limit: int
    if gotOptional:
      limit = requiredParams + 1
    else:
      limit = requiredParams
    if args.len > limit:
      # Too many parameters, expected {requiredParams} got {args.len}."
      return newFunResultWarn(kTooManyArgs, 0, $requiredParams, $args.len)

  # Loop through the parameters except the vararg ones.
  for ix in countUp(0, loopParams - 1):
    var param = params[ix]
    var arg = args[ix]

    # Check the parameter is the correct type.
    if not sameType(param.paramTypes[0], arg.kind):
      let expected = paramTypeString(param.paramTypes[0])
      let got = $arg.kind
      # Wrong parameter type, expected {expected} got {got}.
      return newFunResultWarn(kWrongType, ix, $expected, $got)

    map[param.name] = arg

  # Handle the vararg element.
  if gotVarargs:
    var varargIx = loopParams
    var argsLeft = args.len - varargIx
    let varargParam = params[varargIx]
    var varargNum = varargParam.paramTypes.len

    var varargList: seq[Value]
    if argsLeft > 0:
      # Collect the remaining parameters into a list.
      while argsLeft > 0:

        # Check there are enough parameters for the vararg group.
        if argsLeft < varargNum:
          # Expected {varargNum} varargs got {argsLeft}.
          return newFunResultWarn(kNotEnoughVarargs, varargIx, $varargNum, $argsLeft)

        for ix in countUp(0, varargNum - 1):
          var arg = args[varargIx + ix]
          var paramType = varargParam.paramTypes[ix]

          if not sameType(paramType, arg.kind):
            let expected = paramTypeString(paramType)
            let got = $arg.kind
            # Wrong parameter type, expected {expected} got {got}.
            return newFunResultWarn(kWrongType, varargIx + ix, $expected, $got)

          dec(argsLeft)
          varargList.add(arg)

        varargIx = varargIx + varargNum

    map[varargParam.name] = newValue(varargList)

  result = newFunResult(newValue(map))
