## Parse the command line.

import std/os
import std/tables
import std/strutils

type
  CmlMessageId* = enum
    cmlBareTwoDashes,         # c00
    cmlInvalidOption,         # c01
    cmlMissingParameter,      # c02
    cmlBareOneDash,           # c03
    cmlInvalidShortOption,    # c04
    cmlShortParamInList,      # c05
    cmlDupShortOption,        # c06
    cmlDupLongOption,         # c07
    cmlBareShortName,         # c08
    cmlAlphaNumericShort,     # c09
    cmlMissingBareParameter,  # c10
    cmlTooManyBareParameters, # c11

  ArgsOrMessageKind* = enum
    ## The kind of an ArgsOrMessage object, either args or a message.
    cmlArgs,
    cmlMessage

  CmlArgs* = OrderedTable[string, seq[string]]
    ## CmlArgs holds the parsed command line arguments in an ordered
    ## dictionary. The keys are the supported options found on the
    ## command line and each value is a list of associated parameters.
    ## An option without parameters will have an empty list.

  ArgsOrMessage* = object
    ## Contains the command line args or a message.
    case kind*: ArgsOrMessageKind
    of cmlArgs:
      args*: CmlArgs
    of cmlMessage:
      messageId*: CmlMessageId
      problemParam*: string

  CmlOptionType* = enum
    ## The option type.
    cmlParameter
      ## option with a parameter
    cmlNoParameter
      ## option without a parameter
    cmlOptionalParameter
      ## option with an optional parameter
    cmlBareParameter
      ## a parameter without an option

  CmlOption* = object
    # An option holds its type, long name and short name.
    optionType: CmlOptionType
    long: string
    short: char

const
  cmlMessages*: array[low(CmlMessageId)..high(CmlMessageId), string] = [
    #[c00]# "Two dashes must be followed by an option name.",
    #[c01]# "The option '--$1' is not supported.",
    #[c02]# "The option '$1' needs a parameter.",
    #[c03]# "One dash must be followed by a short option name.",
    #[c04]# "The short option '-$1' is not supported.",
    #[c05]# "The option '-$1' needs a parameter; use it by itself.",
    #[c06]# "Duplicate short option: '-$1'.",
    #[c07]# "Duplicate long option: '--$1'.",
    #[c08]# "Use the short name '_' instead of '$1' with a bare parameter.",
    #[c09]# "Use an alphanumeric ascii character for a short option name instead of '$1'.",
    #[c10]# "Missing '$1' parameter.",
    #[c11]# "Extra bare parameter.",
  ]
    ## Possible message numbers returned by cmdline.

func getMessage*(message: CmlMessageId, problemParam: string = ""): string =
  ## Return a message from a message id and problem parameter.
  result = cmlMessages[message] % [problemParam]

func newCmlOption*(long: string, short: char, optionType: CmlOptionType): CmlOption =
  ## Create a new CmlOption object.
  result = CmlOption(long: long, short: short, optionType: optionType)

func newArgsOrMessage(args: CmlArgs): ArgsOrMessage =
  ## Create a new ArgsOrMessage object containing arguments.
  result = ArgsOrMessage(kind: cmlArgs, args: args)

func newArgsOrMessage(messageId: CmlMessageId, problemParam = ""): ArgsOrMessage =
  ## Create a new ArgsOrMessage object containing a message id and
  ## optionally the problem parameter.
  result = ArgsOrMessage(kind: cmlMessage, messageId: messageId,
    problemParam: problemParam)

func `$`*(a: CmlOption): string =
  ## Return a string representation of an CmlOption object.
  return "option: long=$1, short=$2, optionType=$3" % [a.long, $a.short, $a.optionType]

func `$`*(a: ArgsOrMessage): string =
  ## Return a string representation of a ArgsOrMessage object.
  case a.kind
  of cmlArgs:
    if a.args.len == 0:
      result = "no arguments"
    else:
      var lines = newSeq[string]()
      lines.add("args:")
      for k, v in pairs(a.args):
       lines.add("$1: $2" % [k, $v])
      result = lines.join("\n")
  else:
    result = getMessage(a.messageId, a.problemParam)

proc commandLineEcho*() =
  ## Show the command line arguments.
  # The nim os module has two methods to access the command line options:
  # * paramCount() -- return one less than the number of args.  The first
  #   arg is the program being run.
  # * paramStr(index) -- return one of the args.
  echo "Command line arguments:"
  let count = paramCount() + 1
  for ix in 0 .. count - 1:
    echo "$1: $2" % [$ix, paramStr(ix)]
  echo ""

proc collectParams*(): seq[string] =
  ## Get the command line parameters from the system and return a
  ## list. Don't return the first one which is the app name. This is
  ## the list that cmdLine expects.
  let count = paramCount() + 1
  for ix in 1 .. count - 1:
    result.add(paramStr(ix))

proc addArg(args: var CmlArgs, optionName: string) =
  ## Add the given option name that doesn't have an associated
  ## parameter to args.
  if not (optionName in args):
    args[optionName] = newSeq[string]()

proc addArg(args: var CmlArgs, optionName: string, parameter: string) =
  ## Add the given option name and its parameter value to the args.
  if optionName in args:
    var parameters = args[optionName]
    parameters.add(parameter)
    args[optionName] = parameters
  else:
    args[optionName] = @[parameter]

func cmdLine*(options: openArray[CmlOption], parameters: openArray[string]): ArgsOrMessage =
  ## Parse the command line parameters.  You pass in the list of
  ## supported options and the parameters to parse. The arguments
  ## found are returned. If there is a problem with the parameters,
  ## args contains a message telling the problem. Use collectParams()
  ## to generate parameters.

  # shortOptions maps a short option letter to a long option name.
  var shortOptions: OrderedTable[char, string]

  # longOptions maps a long name to its option.
  var longOptions: OrderedTable[string, CmlOption]

  # bareParameterNames is a list of each bare name in the order specified.
  var bareParameterNames = newSeq[string]()

  # Populate shortOptions, longOptions and bareParameterNames.
  var bareIx = 0
  for option in options:
    if option.long in longOptions:
      # c07, Duplicate long option: '--$1'.
      return newArgsOrMessage(cmlDupLongOption, $option.long)
    longOptions[option.long] = option
    if option.optionType == cmlBareParameter:
      bareParameterNames.add(option.long)
      if option.short != '_':
        # c08, Use the short name '_' instead of '$1' with a bare parameter.
        return newArgsOrMessage(cmlBareShortName, $option.short)
    else:
      if not isAlphaNumeric(option.short):
        # c09, Use an alphanumeric ascii character for a short option name instead of '$1'.
        return newArgsOrMessage(cmlAlphaNumericShort, $option.short)
      if option.short in shortOptions:
        # c06, Duplicate short option: '-$1'.
        return newArgsOrMessage(cmlDupShortOption, $option.short)
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
  var args: CmlArgs
  var ix = 0
  var state: State
  var parameter: string
  var optionName: string
  while true:
    if ix >= parameters.len:
      break
    parameter = parameters[ix]

    case state:
    of start:
      if parameter.startsWith("--"):
        state = longOption
      elif parameter.startsWith("-"):
        state = shortOption
      else:
        # c11, Extra bare parameter.
        if bareIx >= bareParameterNames.len:
          return newArgsOrMessage(cmlTooManyBareParameters)

        let name = bareParameterNames[bareIx]
        addArg(args, name, parameter)
        inc(ix)
        inc(bareIx)

    of longOption:
      if parameter.len < 3:
        # c00, Two dashes must be followed by an option name.
        return newArgsOrMessage(cmlBareTwoDashes)
      optionName = parameter[2 .. parameter.len - 1]
      if not (optionName in longOptions):
        # c01, The option '--$1' is not supported.
        return newArgsOrMessage(cmlInvalidOption, optionName)

      let option = longOptions[optionName]
      case option.optionType:
      of cmlNoParameter:
        state = start
        addArg(args, optionName)
        inc(ix)
      of cmlOptionalParameter:
        state = optionalParameter
        inc(ix)
      of cmlParameter:
        state = needParameter
        inc(ix)
      of cmlBareParameter:
        assert(false, "got a bare parameter long option combination somehow")
        inc(ix)

    of shortOption:
      if parameter.len < 2:
        # c03, One dash must be followed by a short option name.
        return newArgsOrMessage(cmlBareOneDash)
      if parameter.len > 2:
        state = multipleShortOptions
        continue

      let shortOptionName = parameter[1]
      if not (shortOptionName in shortOptions):
        # c04, The short option '-$1' is not supported.
        return newArgsOrMessage(cmlInvalidShortOption, $shortOptionName)

      optionName = shortOptions[shortOptionName]
      let option = longOptions[optionName]
      case option.optionType:
      of cmlNoParameter:
        state = start
        addArg(args, optionName)
        inc(ix)
      of cmlOptionalParameter:
        state = optionalParameter
        inc(ix)
      of cmlParameter:
        state = needParameter
        inc(ix)
      of cmlBareParameter:
        assert(false, "got a bare parameter short option combination somehow")
        inc(ix)

    of needParameter:
      if parameter.startsWith("-"):
        # c02, The option '$1' needs a parameter.
        return newArgsOrMessage(cmlMissingParameter, optionName)
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
          # c04, The short option '-$1' is not supported.
          return newArgsOrMessage(cmlInvalidShortOption, $shortOptionName)

        optionName = shortOptions[shortOptionName]
        let option = longOptions[optionName]
        if option.optionType == cmlParameter:
          # c05, The option '-$1' needs a parameter; use it by itself.
          return newArgsOrMessage(cmlShortParamInList, $shortOptionName)
        addArg(args, optionName)

      state = start
      inc(ix)

  if state == needParameter:
    # c02, The option '$1' needs a parameter.
    return newArgsOrMessage(cmlMissingParameter, optionName)

  if bareIx < bareParameterNames.len:
    # c10, Missing bare parameter: '$1'.
    return newArgsOrMessage(cmlMissingBareParameter, bareParameterNames[bareIx])

  if state == optionalParameter:
    addArg(args, optionName)

  result = newArgsOrMessage(args)

when isMainModule:
  echo """
This is an parsing example where a fictional command takes 5 parameters.

[-h] [-u name] [-l [filename]] source dest

* -h, --help
* -u, --user name
* -l, --log [filename]

"""

  commandLineEcho()

  var options = newSeq[CmlOption]()
  options.add(newCmlOption("help", 'h', cmlNoParameter))
  options.add(newCmlOption("log", 'l', cmlOptionalParameter))
  options.add(newCmlOption("source", '_', cmlBareParameter))
  options.add(newCmlOption("dest", '_', cmlBareParameter))
  let args = cmdline(options, collectParams())
  echo $args
  echo ""
