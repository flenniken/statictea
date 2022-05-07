## Parse the command line.
## @:
## @: Example:
## @: ~~~
## @: import cmdline
## @:
## @: # Define the supported options.
## @: var options = newSeq@{CmlOption]()
## @: options.add(newCmlOption("help", 'h', cmlStopParameter))
## @: options.add(newCmlOption("log", 'l', cmlOptionalParameter))
## @: ...
## @:
## @: # Parse the command line.
## @: let argsOrMessage = cmdline(options, collectParams())
## @: if argsOrMessage.kind == cmlMessageKind:
## @:   # Display the message.
## @:   echo getMessage(argsOrMessage.messageId,
## @:     argsOrMessage.problemParam)
## @: else:
## @:   # Optionally post process the resulting arguments.
## @:   let args = newArgs(argsOrMessage.args)
## @: ~~~~
## @:
## @: For a complete example see the bottom of the file in the isMainModule
## @: section.

import std/os
import std/tables
import std/strutils

type
  CmlArgs* = OrderedTable[string, seq[string]]
    ## CmlArgs holds the parsed command line arguments in an ordered
    ## @:dictionary. The keys are the supported options found on the
    ## @:command line and each value is a list of associated parameters.
    ## @:An option without parameters will have an empty list.

  CmlMessageId* = enum
    ## Possible message IDs returned by cmdline. The number in the
    ## @:name is the same as its ord value.  Since the message handling
    ## @:is left to the caller, it is important for these values to be
    ## @:stable. New values are added to the end and this is a minor
    ## @:version change. It is ok to leave unused values in the list and
    ## @:this is backward compatible. If items are removed or reordered,
    ## @:that is a major version change.
    cml_00_BareTwoDashes,
    cml_01_InvalidOption,
    cml_02_OptionRequiresParam,
    cml_03_BareOneDash,
    cml_04_InvalidShortOption,
    cml_05_ShortParamInList,
    cml_06_DupShortOption,
    cml_07_DupLongOption,
    cml_08_BareShortName,
    cml_09_AlphaNumericShort,
    cml_10_MissingParameter,
    cml_11_TooManyBareParameters,
    cml_12_AlreadyHaveOneParameter,

  ArgsOrMessageKind* = enum
    ## The kind of an ArgsOrMessage object, either args or a message.
    cmlArgsKind,
    cmlMessageKind

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
    ## @:* cmlParameter0or1 -- option with a parameter, 0 or 1 times.
    ## @:* cmlNoParameter -- option without a parameter, 0 or 1 times.
    ## @:* cmlOptionalParameter -- option with an optional parameter, 0
    ## @:    or 1 times.
    ## @:* cmlBareParameter -- a parameter without an option, 1 time.
    ## @:* cmlParameterOnce -- option with a parameter, 1 time.
    ## @:* cmlParameterMany -- option with a parameter, unlimited
    ## @:    number of times.
    ## @:* cmlStopParameter -- option without a parameter, 0 or 1
    ## @:    times. Stop and return this option by itself.
    cmlParameter0or1
    cmlNoParameter
    cmlOptionalParameter
    cmlBareParameter
    cmlParameterOnce
    cmlParameterMany
    cmlStopParameter

  CmlOption* = object
    # An option holds its type, long name and short name.
    optionType: CmlOptionType
    long: string
    short: char

func newCmlOption*(long: string, short: char,
    optionType: CmlOptionType): CmlOption =
  ## Create a new CmlOption object. For no short option use a dash.
  result = CmlOption(long: long, short: short, optionType: optionType)

func newArgsOrMessage(args: CmlArgs): ArgsOrMessage =
  ## Create a new ArgsOrMessage object containing arguments.
  result = ArgsOrMessage(kind: cmlArgsKind, args: args)

func newArgsOrMessage(messageId: CmlMessageId,
    problemParam = ""): ArgsOrMessage =
  ## Create a new ArgsOrMessage object containing a message id and
  ## optionally the problem parameter.
  result = ArgsOrMessage(kind: cmlMessageKind, messageId: messageId,
    problemParam: problemParam)

func `$`*(a: CmlOption): string =
  ## Return a string representation of an CmlOption object.
  return "option: long=$1, short=$2, optionType=$3" % [
    a.long, $a.short, $a.optionType]

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

proc optionCount(args: var CmlArgs, optionName: string): Natural =
  ## Return the number of values the given option name has.
  if not (optionName in args):
    result = 0
  else:
    result = args[optionName].len

func cmdLine*(options: openArray[CmlOption],
    parameters: openArray[string]): ArgsOrMessage =
  ## Parse the command line parameters.  You pass in the list of
  ## supported options and the parameters to parse. The arguments
  ## found are returned. If there is a problem with the parameters,
  ## args contains a message telling the problem. Use collectParams()
  ## to generate the parameters.

  # shortOptions maps a short option letter to its option.
  var shortOptions: OrderedTable[char, CmlOption]

  # longOptions maps a long name to its option.
  var longOptions: OrderedTable[string, CmlOption]

  # bareParameterNames is a list of each bare name in the order specified.
  var bareParameterNames = newSeq[string]()

  # onceNames is a list of each cmlParameterOnce type option.
  var onceNames = newSeq[string]()

  # Populate shortOptions, longOptions, bareParameterNames and onceNames.
  var bareIx = 0
  for option in options:
    if option.long in longOptions:
      # _07_, Duplicate long option: '--$1'.
      return newArgsOrMessage(cml_07_DupLongOption, $option.long)
    longOptions[option.long] = option
    if option.optionType == cmlParameterOnce:
      onceNames.add(option.long)
    if option.optionType == cmlBareParameter:
      bareParameterNames.add(option.long)
      if option.short != '_':
        # _08_, Use the short name '_' instead of '$1' with a bare parameter.
        return newArgsOrMessage(cml_08_BareShortName, $option.short)
    else:
      if option.short != '_' and not isAlphaNumeric(option.short):
        # _09_, Use an alphanumeric ascii character for a short option name instead of '$1'.
        return newArgsOrMessage(cml_09_AlphaNumericShort, $option.short)
      if option.short in shortOptions:
        # _06_, Duplicate short option: '-$1'.
        return newArgsOrMessage(cml_06_DupShortOption, $option.short)
      shortOptions[option.short] = option

  type
    State = enum
      ## Finite state machine states.
      start,
      longOption,
      shortOption,
      needParameter,
      processOption,
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

    # Skip empty parameters.
    if parameter == "":
      inc(ix)
      continue

    case state:
    of start:
      if parameter.startsWith("--"):
        state = longOption
      elif parameter.startsWith("-"):
        state = shortOption
      else:
        # _11_, Extra bare parameter.
        if bareIx >= bareParameterNames.len:
          return newArgsOrMessage(cml_11_TooManyBareParameters)

        let name = bareParameterNames[bareIx]
        addArg(args, name, parameter)
        inc(ix)
        inc(bareIx)

    of longOption:
      if parameter.len < 3:
        # _00_, Two dashes must be followed by an option name.
        return newArgsOrMessage(cml_00_BareTwoDashes)
      optionName = parameter[2 .. parameter.len - 1]
      if not (optionName in longOptions):
        # _01_, The option '--$1' is not supported.
        return newArgsOrMessage(cml_01_InvalidOption, optionName)

      state = processOption

    of shortOption:
      if parameter.len < 2:
        # _03_, One dash must be followed by a short option name.
        return newArgsOrMessage(cml_03_BareOneDash)
      if parameter.len > 2:
        state = multipleShortOptions
        continue

      let shortOptionName = parameter[1]
      if not (shortOptionName in shortOptions):
        # _04_, The short option '-$1' is not supported.
        return newArgsOrMessage(cml_04_InvalidShortOption, $shortOptionName)

      let option = shortOptions[shortOptionName]
      optionName = option.long
      state = processOption

    of processOption:
      let option = longOptions[optionName]
      case option.optionType:
      of cmlNoParameter:
        state = start
        addArg(args, optionName)
        inc(ix)
      of cmlOptionalParameter, cmlParameter0or1, cmlParameterOnce:
        if args.optionCount(option.long) > 0:
          # _12_, Already have one '$1' parameter.
          return newArgsOrMessage(cml_12_AlreadyHaveOneParameter, $option.long)
        if option.optionType == cmlOptionalParameter:
          state = optionalParameter
        else:
          state = needParameter
        inc(ix)
      of cmlParameterMany:
        state = needParameter
        inc(ix)
      of cmlBareParameter:
        assert(false, "got a bare parameter and option combination somehow")
        inc(ix)
      of cmlStopParameter:
        var stopArgs: CmlArgs
        addArg(stopArgs, optionName)
        return newArgsOrMessage(stopArgs)

    of needParameter:
      if parameter.startsWith("-"):
        # _02_, The option '$1' needs a parameter.
        return newArgsOrMessage(cml_02_OptionRequiresParam, optionName)
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
          # _04_, The short option '-$1' is not supported.
          return newArgsOrMessage(cml_04_InvalidShortOption, $shortOptionName)

        let option = shortOptions[shortOptionName]
        optionName = option.long
        if option.optionType in [cmlParameter0or1,
            cmlParameterOnce, cmlParameterMany]:
          # _05_, The option '-$1' needs a parameter; use it by itself.
          return newArgsOrMessage(cml_05_ShortParamInList, $shortOptionName)
        addArg(args, optionName)

      state = start
      inc(ix)

  if state == needParameter:
    # _02_, The option '$1' needs a parameter.
    return newArgsOrMessage(cml_02_OptionRequiresParam, optionName)

  if bareIx < bareParameterNames.len:
    # _10_, Missing bare parameter: '$1'.
    return newArgsOrMessage(cml_10_MissingParameter,
      bareParameterNames[bareIx])

  if state == optionalParameter:
    addArg(args, optionName)

  # Make sure all the once parameters have one.
  for option in options:
    if option.optionType == cmlParameterOnce:
      if not (option.long in args):
        # _02_, The option '$1' needs a parameter.
        return newArgsOrMessage(cml_02_OptionRequiresParam, option.long)

  result = newArgsOrMessage(args)

when defined(Test) or isMainModule:

  const
    cmlMessages*: array[low(CmlMessageId)..high(CmlMessageId), string] = [
      #[_00_]# "Two dashes must be followed by an option name.",
      #[_01_]# "The option '--$1' is not supported.",
      #[_02_]# "The option '$1' requires a parameter.",
      #[_03_]# "One dash must be followed by a short option name.",
      #[_04_]# "The short option '-$1' is not supported.",
      #[_05_]# "The option '-$1' needs a parameter; use it by itself.",
      #[_06_]# "Duplicate short option: '-$1'.",
      #[_07_]# "Duplicate long option: '--$1'.",
      #[_08_]# "Use the short name '_' instead of '$1' with a bare parameter.",
      #[_09_]# "Use an alphanumeric ascii character for a short option name instead of '$1'.",
      #[_10_]# "Missing '$1' parameter.",
      #[_11_]# "Extra bare parameter.",
      #[_12_]# "Already have one '$1' parameter.",
    ]

  func getMessage*(message: CmlMessageId, problemParam: string = ""): string =
    ## Return a message from a message id and problem parameter.
    result = cmlMessages[message] % [problemParam]

when isMainModule:

  echo """
This is a parsing example for a fictional command that takes several
types of parameters.

cmdline [-h] [-u name] [-l [filename]] -r leader [-s state] source destination
* -h, --help
* -l, --log [filename]
* -u, --user name (you can specify multiple users).
* -r, --leader (required)
* -s, --state
* source
* destination
"""
  # Display the command line.
  commandLineEcho()

  type
    Args = object
      ## Args holds all the command line arguments for the example
      ## cmdline.
      help: bool
      log: bool
      logFilename: string
      user: seq[string]
      leader: string
      source: string
      destination: string

  func `$`*(a: Args): string =
    ## Return a string representation of an Args object.
    var lines = newSeq[string]()
    lines.add("arg.help = $1" % $a.help)
    lines.add("arg.log = $1" % $a.log)
    lines.add("arg.logFilename = '$1'" % a.logFilename)
    lines.add("arg.user = '$1'" % $a.user)
    lines.add("arg.leader = '$1'" % $a.leader)
    lines.add("arg.source = '$1'" % a.source)
    lines.add("arg.destination = '$1'" % a.destination)
    result = lines.join("\n")

  func newArgs(cmlArgs: CmlArgs): Args =
    ## Create an Args object from a CmlArgs.
    result.help = "help" in cmlArgs
    if "log" in cmlArgs:
      result.log = true
      let list = cmlArgs["log"]
      if list.len == 1:
        result.logFilename = list[0]
    if "user" in cmlArgs:
      result.user = cmlArgs["user"]
    if "leader" in cmlArgs:
      result.leader = cmlArgs["leader"][0]
    if "source" in cmlArgs:
      result.source = cmlArgs["source"][0]
    if "destination" in cmlArgs:
      result.destination = cmlArgs["destination"][0]

  # Parse the command line.
  var options = newSeq[CmlOption]()
  options.add(newCmlOption("help", 'h', cmlStopParameter))
  options.add(newCmlOption("log", 'l', cmlOptionalParameter))
  options.add(newCmlOption("user", 'u', cmlParameterMany))
  options.add(newCmlOption("leader", 'r', cmlParameterOnce))
  options.add(newCmlOption("state", 's', cmlParameter0or1))
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
