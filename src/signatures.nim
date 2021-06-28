## Statictea function signatures and parameter checking.

import vartypes
import funtypes
import options
import warnings
import regexes
import strformat
import strutils

type
  ParamType* = enum
    ## The parameter types.
    ptInt = "int",
    ptFloat = "float",
    ptString = "string",
    ptList = "list",
    ptDict = "dict",
    ptAny = "any"

  Param* = object
    ## Holds parameter attributes.
    name*: string
      ## The name of the parmeter. "result" is use for the function's
      ## return parameter.
    paramTypes*: seq[ParamType]
      ## Varargs can have multiple types.
    optional*: bool
    varargs*: bool

func newParam*(name: string, optional: bool, varargs: bool,
    paramTypes: seq[Paramtype]): Param =
  result = Param(name: name, optional: optional, varargs: varargs,
                 paramTypes: paramTypes)

func `$`*(param: Param): string =
  ## Return a string representation of a Param's type.
  var optional: string
  if param.optional:
    optional = "optional "
  else:
    optional = ""
  if param.varargs:
    # name: varargs(int, string)
    let paramTypes = join(param.paramTypes, ", ")
    result = fmt"{param.name}: {optional}varargs({paramTypes})"
  else:
    # name: int
    result = fmt"{param.name}: {optional}{param.paramTypes[0]}"

func codeToParamType*(code: char): ParamType =
  case code:
    of 'i':
      result = ptInt
    of 'f':
      result = ptFloat
    of 's':
      result = ptString
    of 'l':
      result = ptList
    of 'd':
      result = ptDict
    else:
      result = ptAny

proc matchInsideAndReturn*(line: string): Option[Matches] =
  ## Match a signature like: (a: int, b: int) int.  Return two groups:
  ## "a: int, b: int" and "int"
  let pattern = r"^\(([^\)]*)\)\s(.*)"
  result = matchPatternCached(line, pattern)

proc matchParamName*(line: string): Option[Matches] =
  let pattern = r"^[a-zA-Z][a-zA-Z0-9_]{0,63}$"
  result = matchPatternCached(line, pattern)

# func parseSignature*(signature: string): Option[seq[Param]] =
#   ## Parse the function signature and return a list of Param objects
#   ## containing the parameter details.

#   # add: (nums: varargs(int)): int
#   # add: (nums: varargs(float)): float
#   # cmp: (a: int, b: int) int
#   # cmp: (a: float, b: float) int
#   # cmp: (a: string , b: string, insensitive: optional int) int
#   # dup: (str: string, count: int) string
#   # dict: (varargs[string, any]) dict
#   # case: (mainCondition: int, cases: vararg[int, any], default: optional any) any

#   var matchO = matchInsideAndReturn(signature)
#   if not matchO.isSome():
#     return some(newFunResultWarn(kInvalidSignature))

#   result = seq[Param]
#   let match = matchO.get()
#   let (inside, returnTypeString) = match.get2Groups()
#   let insideParts = inside.split(',')
#   for insidePart in insideParts:
#     let leftRight = insidePart.split(':')
#     if leftRight.len != 2:
#       return some(newFunResultWarn(kInvalidSignature))

#     let left = leftRight[0].strip()
#     let right = leftRight[1].strip()

#     var name0 = matchParamName(left)
#     if not name0.isSome():
#       return some(newFunResultWarn(kInvalidSignature))
#     let name = nameO.get()

#     var rightMatchO = matchParamRight(left)
#     if not rightMatchO.isSome():
#       return some(newFunResultWarn(kInvalidSignature))
#     let rightMatch = rightMatchO.get()
#     let (optionalString, paramTypeString, varargsString) = rightMatch
#     var optional: bool
#     if optionalString == "optional":
#       optional = true
#     var paramType: Paramtype
#     case paramTypeString:
#       of "int":
#         paramType = ptInt
#       of "float":
#         paramType = ptFloat
#       of "string":
#         paramType = ptString
#       of "list":
#         paramType = ptList
#       of "dict":
#         paramType = ptDict
#       of "any":
#         paramType = ptAny
#       else:
#         return some(newFunResultWarn(kInvalidParamType))

#     let parm = newParam(paramType, name, value, optional, varargsTypes)
#     result.add(parm)


func checkParameters*(signature: string, parameters: seq[Value]): Option[FunResult] =
  ## Check that the parameters match the signature for number of
  ## parameters and their types. Return a FunResult object containing
  ## a warning when the signature does not match.
  if parameters.len() != 1:
    return some(newFunResultWarn(wOneParameter))

  if parameters[0].kind != vkString:
    return some(newFunResultWarn(wExpectedString))

func getParameters*(parameters: seq[Value], start: int, count: int): Option[seq[Value]] =
  ## Return the number of parameters specified by count starting at
  ## start index, if there are enough left.
  if start < 0 or count <= 0 or start + count > parameters.len:
    return
  result = some(parameters[start .. start + count - 1])

func charDigit*(digit: char): int =
  ## Return the integer value of the digit type character, i.e
  ## '1' -> 1. Return 0 when not a digit.
  result = int(digit) - int('0')
  if result < 0 or result > 9:
    result = 0

type
  Names* = object
    ix*: int

proc getNextName*(names: var Names): string =
  let letters = "abcdefghijklmnopqurstuvwxyz"
  if names.ix > letters.len - 1:
    return ""
  result = $letters[names.ix]
  inc(names.ix)

iterator yieldParam*(signatureCode: string): Option[Param] =
  ## Yield each code from the given signature code.
  var names = Names()
  var ix = 0
  var optional: bool
  while ix < signatureCode.len:
    var code = signatureCode[ix]
    case code:
      of 'i', 'f', 's', 'l', 'd', 'a':
        yield(some(newParam(getNextName(names), optional, false,
                            @[codeToParamType(code)])))
        inc(ix)
        optional = false
      of 'o':
        optional = true
        inc(ix)
      of 'r':
        inc(ix)
        var count = charDigit(signatureCode[ix])
        if count == 0:
          break
        inc(ix)
        var paramTypes: seq[ParamType]
        for _ in countup(1, count):
          paramTypes.add(codeToParamType(signatureCode[ix]))
          inc(ix)
        yield(some(newParam(getNextName(names), optional, true, paramTypes)))
      else:
        break

  # signature code string:
  # i: int
  # f: float
  # s: string
  # n: function
  # d: dict
  # l: list
  # o: next parameter is optional
  # rx: repeat the following x parameters
  # a: any
  # return type last
  # add_r1ii
  # add_r1ff
  # case-ir2iaoai
  # cmp-iii
  # cmp-ffi
  # cmp-ssi

#   # todo: Remove the result type from the signature code.

#   # states: start, single, optional, repeat
#   var state: string
#   if signature.len == 0:
#     if parameters.len != 0
#       return some(newFunResultWarn(wExpectedNoParameters))

#   int ix = 0
#   for ch in signature:

#     if state == "start":
#       case ch:
#         of 'i', 'f', 's', 'l', 'd':
#           state = "single"
#         of 'o':
#           state = "optional"
#           continue
#         of 'r':
#           state = "varargs"
#           continue
#         else:
#           return some(newFunResultWarn(wInvalidSignatureCode))

#     case state:
#     of "single":
#       if ix >= parameters.len:
#         return some(newFunResultWarn(wMissingParameter))
#       let value = parameters[ix]
#       inc(ix)

#       case ch:
#         of 'i', 'f', 's', 'l', 'd':
#           let funResultWarnO = checkParameter(ch, value)
#           if funResultWarnO.isSome:
#             return funResultWarnO
#         of 'a':
#           discard
#         of 'o':
#           state = "optional"
#         of 'r':
#           state = "repeat"
#         else:
#           return some(newFunResultWarn(wInvalidSignatureCode))

#     of "optional":
#       if ix >= parameters.len:
#         # The optional parameter was not specified. The optional
#         # parameter comes last so we're done.
#         return
#       state = "single"

#     of "repeat":
#       # Get the repeat count.
#       count = int(ch) - int('0')
#       if count < 0 or count > 9:
#         return some(newFunResultWarn(wInvalidSignatureCode))
#       # Get the types of the repeat group.
#       var group: seq[char] = @[]
#       for groupIx in 0 .. count-1:
#         group.add(signature[groupIx+asdf])
#       # Rrepeat looking for group parameter items.
#       return


template tCheckParameters*(signature: string, parameters: seq[Value]) =
  let warnResultO = checkParameters(signature, parameters)
  if warnResultO.isSome:
    return warnResultO.get()

template tSetParameterNames*(signature: string, parameters: seq[Value]) =
  let name {.inject.} = parameters[0].stringv

template tCheckParametersSetNames*(signature: string, parameters: seq[Value]) =
  tCheckParameters(signature, parameters)
  tSetParameterNames(signature, parameters)
