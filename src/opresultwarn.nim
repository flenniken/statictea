## OpResultWarn holds either a value or warning data.  It's similar to
## @:the Option type but instead of returning nothing, you return a
## @:warning that tells why you cannot return the value.
## @:
## @:For isMessage, isValue and object details see: @{OpResult}@(opresult.md).
## @:
## @:Example Usage:
## @:
## @:~~~
## @:import opresultwarn
## @:
## @:proc get_string(): OpResultWarn[string] =
## @:  if problem:
## @:    result = opMessage@{string}@(newWarningData(wUnknownArg))
## @:  else:
## @:    result = opValue@{string}@("string of char")
## @:
## @:let strOr = get_string()
## @:if strOr.isMessage:
## @:  echo show_message(strOr.message)
## @:else:
## @:  echo "value = " & $strOr.value
## @:~~~~

import warnings
import opresult

# Export opresult so users of this module don't need to do it.
export opresult

type
  OpResultWarn*[T] = OpResult[T, WarningData]
    ## The OpResultWarn object holds a warning or a value T.

func opValueW*[T](value: T): OpResultWarn[T] =
  ## Create a new OpResultWarn object containing a value T.
  result = OpResult[T, WarningData](kind: orValue, value: value)

func opMessageW*[T](message: WarningData): OpResultWarn[T] =
  ## Create a new OpResultWarn object containing a warning.
  result = OpResult[T, WarningData](kind: orMessage, message: message)
