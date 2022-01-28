## OpResultId holds either a value or a message id.  It's similar to
## @:the Option type but instead of returning nothing, you return a
## @:message id that tells why you cannot return the value.
## @:
## @:For isMessage, isValue and object details see: @{OpResult}@(opresult.md).
## @:
## @:Example Usage:
## @:
## @:~~~
## @:import opresultid
## @:
## @:proc get_string(): OpResultId[string] =
## @:  if problem:
## @:    result = opMessage@{string}@(wUnknownArg)
## @:  else:
## @:    result = opValue@{string}@("string of char")
## @:
## @:let strOr = get_string()
## @:if strOr.isMessage:
## @:  echo show_message(strOr.message)
## @:else:
## @:  echo "value = " & $strOr.value
## @:~~~~

import messages
import opresult

# Export opresult so users of this module don't need to do it.
export opresult

type
  OpResultId*[T] = OpResult[T, MessageId]
    ## The OpResultId object holds a message id or a value T.

func opValue*[T](value: T): OpResultId[T] =
  ## Create a new OpResultId object containing a value T.
  result = OpResult[T, MessageId](kind: orValue, value: value)

func opMessage*[T](message: MessageId): OpResultId[T] =
  ## Create a new OpResultId object containing a message id.
  result = OpResult[T, MessageId](kind: orMessage, message: message)
