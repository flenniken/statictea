## Statictea function types and supporting routines.

import vartypes
import warnings
import tostring
import strutils

type
  FunctionPtr* = proc (parameters: seq[Value]): FunResult {.noSideEffect.}
    ## Signature of a statictea function. It takes any number of values
    ## and returns a value or a warning message.

  FunResultKind* = enum
    ## The kind of a FunResult object, either a value or warning.
    frValue,
    frWarning

  FunResult* = object
    ## Contains the result of calling a function, either a value or a
    ## warning.
    case kind*: FunResultKind
      of frValue:
        value*: Value       ## Return value of the function.
      of frWarning:
        parameter*: Natural ## Index of problem parameter.
        warningData*: WarningData

func newFunResultWarn*(warning: Warning, parameter: Natural = 0,
      p1: string = "", p2: string = ""): FunResult =
  ## Return a new FunResult object. It contains a warning, the index of
  ## the problem parameter, and the two optional strings that go with
  ## the warning.
  let warningData = newWarningData(warning, p1, p2)
  result = FunResult(kind: frWarning, parameter: parameter,
                     warningData: warningData)

func newFunResultWarn*(warningData: Warningdata, parameter: Natural = 0): FunResult =
  ## Return a new FunResult object containing a warning.
  result = FunResult(kind: frWarning, parameter: parameter,
                     warningData: warningData)

func newFunResult*(value: Value): FunResult =
  ## Return a new FunResult object containing a value.
  result = FunResult(kind: frValue, value: value)

func `==`*(r1: FunResult, r2: FunResult): bool =
  ## Compare two FunResult objects and return true when equal.
  if r1.kind == r2.kind:
    case r1.kind:
      of frValue:
        result = r1.value == r2.value
      else:
        if r1.warningData == r2.warningData and
           r1.parameter == r2.parameter:
          result = true

func `$`*(funResult: FunResult): string =
  ## Return a string representation of a FunResult object.
  case funResult.kind
  of frValue:
    result = $funResult.value
  else:
    result = "warning: $1: $2" % [
      $funResult.warningData, $funResult.parameter
    ]
