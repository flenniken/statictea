## Parse the command line.

import std/os
import std/strformat
import std/tables
import std/strutils

type
  ClMessageId* = enum
    ## Possible message numbers returned by cmdline.
    clmBareTwoDashes,
      ## Two dashes must be followed by an option name.
    clmInvalidOption,
      ## "--{optionName}" is not an option.
    clmMissingRequiredParameter,
      ## Missing {optionName}'s parameter.
    clmBareOneDash,
      ## One dash must be followed by a short option name.
    clmInvalidShortOption,
      ## "--{shortOptionName}" is not an option.
    clmShortParamInList,
      ## Missing -{shortOptionName}'s parameter; use by itself.
    clmDupShortOption,
      ## Duplicate short option name: -{option.short}.
    clmDupLongOption,
      ## Duplicate long option name: -{option.long}.
    clmBareShortName,
      ## Use the short name '_' with a bare parameter.
    clmAlphaNumericShort,
      ## Use an alphanumeric ascii character for a short option name.
    clmMissingBareParameter,
      ## Missing bare parameter(s).
    clmTooManyBareParameters,
      ## Too many bare parameters.


  ArgsOrMessageKind* = enum
    ## The kind of an ArgsOrMessage object, either args or a message.
    clArgs,
    clMessage

  ClArgs* = OrderedTable[string, seq[string]]
    ## ClArgs holds the parsed command line arguments in an ordered
    ## dictionary. The keys are the supported options found on the
    ## command line and each value is a list of associated parameters.
    ## An option without parameters will have an empty list.

  ArgsOrMessage* = object
    ## Contains the command line args or a message.
    case kind*: ArgsOrMessageKind
    of clArgs:
      args*: ClArgs
    of clMessage:
      messageId*: ClMessageId
      problemParam*: string

  ClOptionType* = enum
    ## The option type.
    clParameter,
      ## option with a parameter
    clNoParameter,
      ## option without a parameter
    clOptionalParameter
      ## option with an optional parameter
    clBareParameter
      ## no switch, just a bare parameter. Use '_' for the short name.

  ClOption* = object
    # An option holds its type, long name and short name.
    optionType: ClOptionType
    long: string
    short: char

func newClOption*(long: string, short: char, optionType: ClOptionType): ClOption =
  ## Create a new ClOption object.
  result = ClOption(long: long, short: short, optionType: optionType)

func newArgsOrMessage(args: ClArgs): ArgsOrMessage =
  ## Create a new ArgsOrMessage object containing arguments.
  result = ArgsOrMessage(kind: clArgs, args: args)

func newArgsOrMessage(messageId: ClMessageId, problemParam = ""): ArgsOrMessage =
  ## Create a new ArgsOrMessage object containing a message id and
  ## optionally the problem parameter.
  result = ArgsOrMessage(kind: clMessage, messageId: messageId,
    problemParam: problemParam)

func `$`*(a: ClOption): string =
  ## Return a string representation of an ClOption object.
  return fmt"option: {a.long}, {a.short}, {a.optionType}"

func `$`*(a: ArgsOrMessage): string =
  ## Return a string representation of a ArgsOrMessage object.
  case a.kind
  of clArgs:
    if a.args.len == 0:
      result = "no arguments"
    else:
      var lines = newSeq[string]()
      lines.add("args:")
      for k, v in pairs(a.args):
        lines.add(fmt"{k}: {v}")
      result = lines.join("\n") & "\n"
  else:
    if a.problemParam == "":
      result = fmt"message: {a.messageId}"
    else:
      result = fmt"message: {a.messageId} for {a.problemParam}."

proc commandLineEcho*() =
  ## Show the command line arguments.
  # The nim os module has two methods to access the command line options:
  # * paramCount() -- return one less than the number of args.  The first
  #   arg is the program being run.
  # * paramStr(index) -- return one of the args.
  let count = paramCount() + 1
  for ix in 0 .. count - 1:
    echo fmt"{ix}: {paramStr(ix)}"

proc collectParams*(): seq[string] =
  ## Get the command line parameters from the system and return a
  ## list. Don't return the first one which is the app name. This is
  ## the list that cmdLine expects.
  let count = paramCount() + 1
  for ix in 1 .. count - 1:
    result.add(paramStr(ix))

proc addArg(args: var ClArgs, optionName: string) =
  ## Add the given option name that doesn't have an associated
  ## parameter to args.
  if not (optionName in args):
    args[optionName] = newSeq[string]()

proc addArg(args: var ClArgs, optionName: string, parameter: string) =
  ## Add the given option name and its parameter value to the args.
  if optionName in args:
    var parameters = args[optionName]
    parameters.add(parameter)
    args[optionName] = parameters
  else:
    args[optionName] = @[parameter]

func cmdLine*(options: openArray[ClOption], parameters: openArray[string]): ArgsOrMessage =
  ## Parse the command line parameters.  You pass in the list of
  ## supported options and the parameters to parse. The arguments
  ## found are returned. If there is a problem with the parameters,
  ## args contains a message telling the problem. Use collectParams()
  ## to generate parameters.

  # shortOptions maps a short option letter to a long option name.
  var shortOptions: OrderedTable[char, string]

  # longOptions maps a long name to its option.
  var longOptions: OrderedTable[string, ClOption]

  # bareParameterNames is a list of each bare name in the order specified.
  var bareParameterNames = newSeq[string]()

  # Populate shortOptions, longOptions and bareParameterNames.
  var bareIx = 0
  for option in options:
    if option.long in longOptions:
      # -{option.long} is a duplicate long option name.
      return newArgsOrMessage(clmDupLongOption, $option.long)
    longOptions[option.long] = option
    if option.optionType == clBareParameter:
      bareParameterNames.add(option.long)
      if option.short != '_':
        # Use short name '_' with a bare parameter.
        return newArgsOrMessage(clmBareShortName, $option.short)
    else:
      if not isAlphaNumeric(option.short):
        # Use alphanumeric ascii for a short option name.
        return newArgsOrMessage(clmAlphaNumericShort, $option.short)
      if option.short in shortOptions:
        # -{option.short} is a duplicate short option name.
        return newArgsOrMessage(clmDupShortOption, $option.short)
      shortOptions[option.short] = option.long

  type
    State = enum
      ## Finite state machine states.
      start,
      longOption,
      shortOption,
      needParameter,
      optionalParameter,
      multipleShortOptions,

  # Loop over the parameters and populate args.
  var args: ClArgs
  var ix = 0
  var state: State
  var parameter: string
  var optionName: string
  while true:
    if ix >= parameters.len:
      break
    parameter = parameters[ix]
    # debugEcho fmt"{ix} {parameter}"

    case state:
    of start:
      if parameter.startsWith("--"):
        state = longOption
      elif parameter.startsWith("-"):
        state = shortOption
      else:
        # Too many bare parameters.
        if bareIx >= bareParameterNames.len:
          return newArgsOrMessage(clmTooManyBareParameters)

        let name = bareParameterNames[bareIx]
        addArg(args, name, parameter)
        inc(ix)
        inc(bareIx)

    of longOption:
      if parameter.len < 3:
        # Two dashes must be followed by an option name.
        return newArgsOrMessage(clmBareTwoDashes)
      optionName = parameter[2 .. parameter.len - 1]
      if not (optionName in longOptions):
        # "--{optionName}" is not supported.
        return newArgsOrMessage(clmInvalidOption, optionName)

      let option = longOptions[optionName]
      case option.optionType:
      of clNoParameter:
        state = start
        addArg(args, optionName)
        inc(ix)
      of clOptionalParameter:
        state = optionalParameter
        inc(ix)
      of clParameter:
        state = needParameter
        inc(ix)
      of clBareParameter:
        assert(false, "got a bare parameter long option combination somehow")
        inc(ix)

    of shortOption:
      if parameter.len < 2:
        # One dash must be followed by a short option name.
        return newArgsOrMessage(clmBareOneDash)
      if parameter.len > 2:
        state = multipleShortOptions
        continue

      let shortOptionName = parameter[1]
      if not (shortOptionName in shortOptions):
        # "--{shortOptionName}" is not an option.
        return newArgsOrMessage(clmInvalidShortOption, $shortOptionName)

      optionName = shortOptions[shortOptionName]
      let option = longOptions[optionName]
      case option.optionType:
      of clNoParameter:
        state = start
        addArg(args, optionName)
        inc(ix)
      of clOptionalParameter:
        state = optionalParameter
        inc(ix)
      of clParameter:
        state = needParameter
        inc(ix)
      of clBareParameter:
        assert(false, "got a bare parameter short option combination somehow")
        inc(ix)

    of needParameter:
      if parameter.startsWith("-"):
        # {optionName} requires a parameter.
        return newArgsOrMessage(clmMissingRequiredParameter, optionName)
      addArg(args, optionName, parameter)
      state = start
      inc(ix)

    of optionalParameter:
      if parameter.startsWith("-"):
        addArg(args, optionName)
      else:
        addArg(args, optionName, parameter)
        inc(ix)
      state = start

    of multipleShortOptions:

      for shortOptionName in parameter[1 .. parameter.len - 1]:
        if not (shortOptionName in shortOptions):
          # "-{shortOptionName}" is not an option.
          return newArgsOrMessage(clmInvalidShortOption, $shortOptionName)

        optionName = shortOptions[shortOptionName]
        let option = longOptions[optionName]
        if option.optionType == clParameter:
          # "-{shortOptionName}" requires a parameter, use by itself.
          return newArgsOrMessage(clmShortParamInList, $shortOptionName)
        addArg(args, optionName)

      state = start
      inc(ix)

  if state == needParameter:
    # {optionName} requires a parameter.
    return newArgsOrMessage(clmMissingRequiredParameter, optionName)

  if bareIx < bareParameterNames.len:
    # Missing bare parameter(s).
    return newArgsOrMessage(clmMissingBareParameter)

  if state == optionalParameter:
    addArg(args, optionName)

  result = newArgsOrMessage(args)

when isMainModule:
  # commandLineEcho()
  echo fmt"let parameters = {collectParams()}"
