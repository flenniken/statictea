## OpResult holds either a value or a message.  It's similar to the
## Option type but instead of returning nothing, you return a message
## that tells why you cannot return the value.

import messages

type
  OpResultKind* = enum
    ## The kind of OpResult object, either a message or a value.
    orMessage,
    orValue

  OpResult*[T, T2] = object
    ## Contains either a value or a message. Defaults to an empty
    ## message.
    case kind*: OpResultKind
      of orValue:
        value*: T
      of orMessage:
        message*: T2

func isMessage*(opResult: OpResult): bool =
  ## Return true when the OpResult object contains a message.
  if opResult.kind == orMessage:
    result = true

func isValue*(opResult: OpResult): bool =
  ## Return true when the OpResult object contains a value.
  if opResult.kind == orValue:
    result = true

func `$`*(opResult: OpResult): string =
  ## Return a string representation of an OpResult object.
  if opResult.kind == orValue:
    result = "Value: " & $opResult.value
  else:
    result = "Message: " & $opResult.message

type
  OpResultWarn*[T] = OpResult[T, WarningData]
    ## OpResultWarn holds either a value or warning data.  It's similar to
    ## the Option type but instead of returning nothing, you return a
    ## warning that tells why you cannot return the value.
    ##
    ## Example Usage:
    ##
    ## ~~~ nim
    ## import opresult
    ##
    ## proc get_string(): OpResultWarn[string] =
    ##   if problem:
    ##     result = opMessage[string](newWarningData(wUnknownArg))
    ##   else:
    ##     result = opValue[string]("string of char")
    ##
    ## let strOr = get_string()
    ## if strOr.isMessage:
    ##   echo show_message(strOr.message)
    ## else:
    ##   echo "value = " & $strOr.value
    ## ~~~

func opValueW*[T](value: T): OpResultWarn[T] =
  ## Create a new OpResultWarn object containing a value T.
  result = OpResult[T, WarningData](kind: orValue, value: value)

func opMessageW*[T](message: WarningData): OpResultWarn[T] =
  ## Create a new OpResultWarn object containing a warning.
  result = OpResult[T, WarningData](kind: orMessage, message: message)

type
  OpResultId*[T] = OpResult[T, MessageId]
    ## OpResultId holds either a value or a message id.  It's similar to
    ## the Option type but instead of returning nothing, you return a
    ## message id that tells why you cannot return the value.
    ##
    ## Example Usage:
    ##
    ## ~~~ nim
    ## import opresult
    ##
    ## proc get_string(): OpResultId[string] =
    ##   if problem:
    ##     result = opMessage[string](wUnknownArg)
    ##   else:
    ##     result = opValue[string]("string of char")
    ##
    ## let strOr = get_string()
    ## if strOr.isMessage:
    ##   echo show_message(strOr.message)
    ## else:
    ##   echo "value = " & $strOr.value
    ## ~~~

func opValue*[T](value: T): OpResultId[T] =
  ## Create a new OpResultId object containing a value T.
  result = OpResult[T, MessageId](kind: orValue, value: value)

func opMessage*[T](message: MessageId): OpResultId[T] =
  ## Create a new OpResultId object containing a message id.
  result = OpResult[T, MessageId](kind: orMessage, message: message)
