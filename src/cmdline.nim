## Parse the command line.

import std/os
import std/tables
import std/strutils

type
  CmlMessageId* = enum
    ## Possible message IDs returned by cmdline. The number in the
    ## name is the same as its ord value.  Since the message handling
    ## is left to the caller, it is important for these values to be
    ## stable. New values are added to the end and this is a minor
    ## version change. It is ok to leave unused values in the list and
    ## this is backward compatible. If items are removed or reordered,
    ## that is a major version change.
    cml_00_BareTwoDashes,
    cml_01_InvalidOption,
    cml_02_MissingParameter,
    cml_03_BareOneDash,
    cml_04_InvalidShortOption,
    cml_05_ShortParamInList,
    cml_06_DupShortOption,
    cml_07_DupLongOption,
    cml_08_BareShortName,
    cml_09_AlphaNumericShort,
    cml_10_MissingBareParameter,
    cml_11_TooManyBareParameters,

  ArgsOrMessageKind* = enum
    ## The kind of an ArgsOrMessage object, either args or a message.
    cmlArgsKind,
    cmlMessageKind

  CmlArgs* = OrderedTable[string, seq[string]]
    ## CmlArgs holds the parsed command line arguments in an ordered
    ## dictionary. The keys are the supported options found on the
    ## command line and each value is a list of associated parameters.
    ## An option without parameters will have an empty list.

  ArgsOrMessage* = object
    ## Contains the command line args or a message.
    case kind*: ArgsOrMessageKind
    of cmlArgsKind:
      args*: CmlArgs
    of cmlMessageKind:
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

func newCmlOption*(long: string, short: char, optionType: CmlOptionType): CmlOption =
  ## Create a new CmlOption object.
  result = CmlOption(long: long, short: short, optionType: optionType)

func newArgsOrMessage(args: CmlArgs): ArgsOrMessage =
  ## Create a new ArgsOrMessage object containing arguments.
  result = ArgsOrMessage(kind: cmlArgsKind, args: args)

func newArgsOrMessage(messageId: CmlMessageId, problemParam = ""): ArgsOrMessage =
  ## Create a new ArgsOrMessage object containing a message id and
  ## optionally the problem parameter.
  result = ArgsOrMessage(kind: cmlMessageKind, messageId: messageId,
    problemParam: problemParam)

func `$`*(a: CmlOption): string =
  ## Return a string representation of an CmlOption object.
  return "option: long=$1, short=$2, optionType=$3" % [a.long, $a.short, $a.optionType]

func `$`*(a: ArgsOrMessage): string =
  ## Return a string representation of a ArgsOrMessage object.
  case a.kind
  of cmlArgsKind:
    if a.args.len == 0:
      result = "no arguments"
    else:
      var lines = newSeq[string]()
      for k, v in pairs(a.args):
       lines.add("argsOrMessage.args[$1] = $2" % [k, $v])
      result = lines.join("\n")
  else:
    var lines = newSeq[string]()
    lines.add("argsOrMessage.messageId = $1" % $a.messageId)
    lines.add("argsOrMessage.problemParam = '$1'" % $a.problemParam)
    result = lines.join("\n")

proc commandLineEcho*() =
  ## Show the command line arguments.
  # The nim os module has two methods to access the command line options:
  # * paramCount() -- return one less than the number of args.  The first
  #   arg is the program being run.
  # * paramStr(index) -- return one of the args.
  echo "Command line arguments:"
  echo ""
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
      return newArgsOrMessage(cml_07_DupLongOption, $option.long)
    longOptions[option.long] = option
    if option.optionType == cmlBareParameter:
      bareParameterNames.add(option.long)
      if option.short != '_':
        # c08, Use the short name '_' instead of '$1' with a bare parameter.
        return newArgsOrMessage(cml_08_BareShortName, $option.short)
    else:
      if not isAlphaNumeric(option.short):
        # c09, Use an alphanumeric ascii character for a short option name instead of '$1'.
        return newArgsOrMessage(cml_09_AlphaNumericShort, $option.short)
      if option.short in shortOptions:
        # c06, Duplicate short option: '-$1'.
        return newArgsOrMessage(cml_06_DupShortOption, $option.short)
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
          return newArgsOrMessage(cml_11_TooManyBareParameters)

        let name = bareParameterNames[bareIx]
        addArg(args, name, parameter)
        inc(ix)
        inc(bareIx)

    of longOption:
      if parameter.len < 3:
        # c00, Two dashes must be followed by an option name.
        return newArgsOrMessage(cml_00_BareTwoDashes)
      optionName = parameter[2 .. parameter.len - 1]
      if not (optionName in longOptions):
        # c01, The option '--$1' is not supported.
        return newArgsOrMessage(cml_01_InvalidOption, optionName)

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
        return newArgsOrMessage(cml_03_BareOneDash)
      if parameter.len > 2:
        state = multipleShortOptions
        continue

      let shortOptionName = parameter[1]
      if not (shortOptionName in shortOptions):
        # c04, The short option '-$1' is not supported.
        return newArgsOrMessage(cml_04_InvalidShortOption, $shortOptionName)

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
        return newArgsOrMessage(cml_02_MissingParameter, optionName)
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
          return newArgsOrMessage(cml_04_InvalidShortOption, $shortOptionName)

        optionName = shortOptions[shortOptionName]
        let option = longOptions[optionName]
        if option.optionType == cmlParameter:
          # c05, The option '-$1' needs a parameter; use it by itself.
          return newArgsOrMessage(cml_05_ShortParamInList, $shortOptionName)
        addArg(args, optionName)

      state = start
      inc(ix)

  if state == needParameter:
    # c02, The option '$1' needs a parameter.
    return newArgsOrMessage(cml_02_MissingParameter, optionName)

  if bareIx < bareParameterNames.len:
    # c10, Missing bare parameter: '$1'.
    return newArgsOrMessage(cml_10_MissingBareParameter, bareParameterNames[bareIx])

  if state == optionalParameter:
    addArg(args, optionName)

  result = newArgsOrMessage(args)

when defined(Test) or isMainModule:

  const
    cmlMessages*: array[low(CmlMessageId)..high(CmlMessageId), string] = [
      #[_00_]# "Two dashes must be followed by an option name.",
      #[_01_]# "The option '--$1' is not supported.",
      #[_02_]# "The option '$1' needs a parameter.",
      #[_03_]# "One dash must be followed by a short option name.",
      #[_04_]# "The short option '-$1' is not supported.",
      #[_05_]# "The option '-$1' needs a parameter; use it by itself.",
      #[_06_]# "Duplicate short option: '-$1'.",
      #[_07_]# "Duplicate long option: '--$1'.",
      #[_08_]# "Use the short name '_' instead of '$1' with a bare parameter.",
      #[_09_]# "Use an alphanumeric ascii character for a short option name instead of '$1'.",
      #[_10_]# "Missing '$1' parameter.",
      #[_11_]# "Extra bare parameter.",
    ]

  func getMessage*(message: CmlMessageId, problemParam: string = ""): string =
    ## Return a message from a message id and problem parameter.
    result = cmlMessages[message] % [problemParam]

when isMainModule:

  type
    Args = object
      ## Args holds all the command line arguments.
      help: bool
      log: bool
      logFilename: string
      user: seq[string]
      source: string
      destination: string

  func `$`*(a: Args): string =
    ## Return a string representation of an Args object.
    var lines = newSeq[string]()
    lines.add("arg.help = $1" % $a.help)
    lines.add("arg.log = $1" % $a.log)
    lines.add("arg.logFilename = '$1'" % a.logFilename)
    lines.add("arg.user = $1" % $a.user)
    lines.add("arg.source = '$1'" % a.source)
    lines.add("arg.destination = '$1'" % a.destination)
    result = lines.join("\n")

  func newArgs(cmlArgs: CmlArgs): Args =
    result.help = "help" in cmlArgs
    if "log" in cmlArgs:
      result.log = true
      let list = cmlArgs["log"]
      if list.len == 1:
        result.logFilename = list[0]
    if "user" in cmlArgs:
      result.user = cmlArgs["user"]
    if "source" in cmlArgs:
      let list = cmlArgs["source"]
      result.source = list[0]
    if "destination" in cmlArgs:
      let list = cmlArgs["destination"]
      result.destination = list[0]


  echo """
This is a parsing example for a fictional command that takes 5 parameters.

cmdline [-h] [-u name] [-l [filename]] source destination
* -h, --help
* -u, --user name (you can specify multiple users).
* -l, --log [filename]
* source
* destination
"""
  # Display the command line.
  commandLineEcho()

  # Parse the command line.
  var options = newSeq[CmlOption]()
  options.add(newCmlOption("help", 'h', cmlNoParameter))
  options.add(newCmlOption("log", 'l', cmlOptionalParameter))
  options.add(newCmlOption("user", 'u', cmlParameter))
  options.add(newCmlOption("source", '_', cmlBareParameter))
  options.add(newCmlOption("destination", '_', cmlBareParameter))
  let argsOrMessage = cmdline(options, collectParams())
  echo "Resulting argsOrMessage object:"
  echo ""
  echo $argsOrMessage
  echo ""

  if argsOrMessage.kind == cmlMessageKind:
    # Display the message.
    echo getMessage(argsOrMessage.messageId, argsOrMessage.problemParam)
  else:
    # Post process the resulting arguments.
    let args = newArgs(argsOrMessage.args)
    echo "Final args object:"
    echo ""
    echo $args
