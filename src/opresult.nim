## OpResult is similar to the Option type but instead of returning
## nothing, you return a message that tells why you cannot return the
## value.

type
  OpResultKind = enum
    ## The kind of OpResult object, either a value or message.
    okValue,
    okMessage

  OpResult*[T] = object
    ## Contains either a value or a message string. The default is a
    ## value. It's similar to the Option type but instead of returning
    ## nothing, you return a message that tells why you cannot return
    ## the value.
    case kind: OpResultKind
      of okValue:
        value*: T
      of okMessage:
        message*: string

func isMessage*(opResult: OpResult): bool =
  ## Return true when the OpResult object contains a message.
  if opResult.kind == okMessage:
    result = true

func isValue*(opResult: OpResult): bool =
  ## Return true when the OpResult object contains a value.
  if opResult.kind == okValue:
    result = true

func opValue*[T](value: T): OpResult[T] =
  ## Create an OpResult value object.
  ##@: 
  ##@: The following example returns a OpResult[RunArgs] object with a
  ##@: value.
  ##@: 
  ##@: ~~~
  ##@: result = opValue[RunArgs](runArgs)
  ##@: ~~~~
  result = OpResult[T](kind: okValue, value: value)

func opMessage*[T](message: string): OpResult[T] =
  ## Create an OpResult message object.
  ##@: 
  ##@: The following example returns a OpResult[RunArgs] object with a
  ##@: message.
  ##@: 
  ##@: ~~~
  ##@: result = opMessage[RunArgs]("Unknown switch: " & key)
  ##@: ~~~~
  result = OpResult[T](kind: okMessage, message: message)

