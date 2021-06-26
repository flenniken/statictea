## Statictea function signatures and parameter checking.

import vartypes
import funtypes
import options
import warnings

func checkParameters*(signature: string, parameters: seq[Value]): Option[FunResult] =
  ## Check that the parameters match the signature for number of
  ## parameters and their types. Return a FunResult object containing
  ## a warning when the signature does not match.
  if parameters.len() != 1:
    return some(newFunResultWarn(wOneParameter))

  if parameters[0].kind != vkString:
    return some(newFunResultWarn(wExpectedString))

template tCheckParameters*(signature: string, parameters: seq[Value]) =
  let warnResultO = checkParameters(signature, parameters)
  if warnResultO.isSome:
    return warnResultO.get()

template tSetParameterNames*(signature: string, parameters: seq[Value]) =
  let name {.inject.} = parameters[0].stringv

template tCheckParametersSetNames*(signature: string, parameters: seq[Value]) =
  tCheckParameters(signature, parameters)
  tSetParameterNames(signature, parameters)

