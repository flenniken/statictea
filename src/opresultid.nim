## OpResultId either a value or a message id. The default is a
## value. It's similar to the Option type but instead of returning
## nothing, you return a message id that tells why you cannot return
## the value.

import messages

type
  OpResultIdKind = enum
    ## The kind of OpResultId object, either a value or a message id.
    orValue,
    orMessageId

  OpResultId*[T] = object
    ## Contains either a value or a return code (rc). The default is a
    ## value.
    case kind*: OpResultIdKind
      of orValue:
        value*: T
      of orMessageId:
        messageId*: MessageId

func isMessageId*(opResult: OpResultId): bool =
  ## Return true when the OpResultId object contains a message id.
  if opResult.kind == orMessageId:
    result = true

func isValue*(opResult: OpResultId): bool =
  ## Return true when the OpResultId object contains a value.
  if opResult.kind == orValue:
    result = true

func newOpResultId*[T](value: T): OpResultId[T] =
  ## Create an OpResultId value object.
  return OpResultId[T](kind: orValue, value: value)

func newOpResultIdId*[T](messageId: MessageId): OpResultId[T] =
  ## Create an OpResultId message id object.
  return OpResultId[T](kind: orMessageId, messageId: messageId)

func `$`*(optionRc: OpResultId): string =
  ## Return a string representation of an OpResultId object.
  if optionRc.kind == orValue:
    result = "Value: " & $optionRc.value
  else:
    result = "Message id: " & $optionRc.messageId
