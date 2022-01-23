## OpResult holds either a value or a message.  It's similar to
## @:the Option type but instead of returning nothing, you return a
## @:message that tells why you cannot return the value.
## @:
## @:You use this to make particular OpResult objects. See @{OpResultId}@(opresultid.md).

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
