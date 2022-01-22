## OpResultId holds either a value or a message id.  It's similar to
## @:the Option type but instead of returning nothing, you return a
## @:message id that tells why you cannot return the value.
## @:
## @:Example Usage:
## @:
## @:~~~
## @:proc get_string(): OpResultId[string] =
## @:  if problem:
## @:    result = opMessage@{string}@(wUnknownArg)
## @:  else:
## @:    result = opValue@{string}@("string of char")
## @:
## @:let strOr = get_string()
## @:if strOr.isMessage():
## @:  echo show_message(strOr.message)
## @:else:
## @:  str = strOr.value
## @:~~~~

import messages
import opresult

type
  OpResultId*[T] = OpResult[T, MessageId]

func opValue*[T](value: T): OpResultId[T] =
  result = OpResult[T, MessageId](kind: orValue, value: value)

func opMessage*[T](message: MessageId): OpResultId[T] =
  result = OpResult[T, MessageId](kind: orMessage, message: message)
