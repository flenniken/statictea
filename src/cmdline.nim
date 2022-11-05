## Parse the command line.
## @:
## @: Example:
## @: ~~~
## @: import cmdline
## @:
## @: # Define the supported options.
## @: var options = newSeq@{CmlOption]()
## @: options.add(newCmlOption("help", 'h', cmlStopArgument))
## @: options.add(newCmlOption("log", 'l', cmlOptionalArgument))
## @: ...
## @:
## @: # Parse the command line.
## @: let argsOrMessage = cmdline(options, collectArgs())
## @: if argsOrMessage.kind == cmlMessageKind:
## @:   # Display the message.
## @:   echo getMessage(argsOrMessage.messageId,
## @:     argsOrMessage.problemArg)
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
    ## @:command line and each value is a list of associated arguments.
    ## @:An option without arguments will have an empty list.

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
    cml_02_OptionRequiresArg,
    cml_03_BareOneDash,
    cml_04_InvalidShortOption,
    cml_05_ShortArgInList,
    cml_06_DupShortOption,
    cml_07_DupLongOption,
    cml_08_BareShortName,
    cml_09_AlphaNumericShort,
    cml_10_MissingArgument,
    cml_11_TooManyBareArgs,
    cml_12_AlreadyHaveOneArg,

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
      problemArg*: string

  CmlOptionType* = enum
    ## The option type.
    ## @:* cmlArgument0or1 -- option with a argument, 0 or 1 times.
    ## @:* cmlNoArgument -- option without a argument, 0 or 1 times.
    ## @:* cmlOptionalArgument -- option with an optional argument, 0
    ## @:    or 1 times.
    ## @:* cmlBareArgument -- a argument without an option, 1 time.
    ## @:* cmlArgumentOnce -- option with a argument, 1 time.
    ## @:* cmlArgumentMany -- option with a argument, unlimited
    ## @:    number of times.
    ## @:* cmlStopArgument -- option without a argument, 0 or 1
    ## @:    times. Stop and return this option by itself.
    cmlArgument0or1
    cmlNoArgument
    cmlOptionalArgument
    cmlBareArgument
    cmlArgumentOnce
    cmlArgumentMany
    cmlStopArgument

  CmlOption* = object
    ## An CmlOption holds its type, long name and short name.
    optionType: CmlOptionType
    long: string
    short: char

func newCmlOption*(long: string, short: char,
    optionType: CmlOptionType): CmlOption =
  ## Create a new CmlOption object. For no short option use a dash.
  result = CmlOption(long: long, short: short, optionType: optionType)

func newArgsOrMessage*(args: CmlArgs): ArgsOrMessage =
  ## Create a new ArgsOrMessage object containing arguments.
  result = ArgsOrMessage(kind: cmlArgsKind, args: args)

func newArgsOrMessage*(messageId: CmlMessageId,
    problemArg = ""): ArgsOrMessage =
  ## Create a new ArgsOrMessage object containing a message id and
  ## optionally the problem argument.
  result = ArgsOrMessage(kind: cmlMessageKind, messageId: messageId,
    problemArg: problemArg)

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
      var first = true
      for k, v in pairs(a.args):
        if first:
          first = false
        else:
          result.add("\n")
        result.add("argsOrMessage.args[$1] = $2" % [k, ($v)[1..^1]])
  else:
    result.add("argsOrMessage.messageId = $1\n" % $a.messageId)
    result.add("argsOrMessage.problemArg = '$1'" % $a.problemArg)

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

proc collectArgs*(): seq[string] =
  ## Get the command line arguments from the system and return a
  ## list. Don't return the first one which is the app name. This is
  ## the list that cmdLine expects.
  let count = paramCount() + 1
  for ix in 1 .. count - 1:
    result.add(paramStr(ix))

proc addArg(args: var CmlArgs, optionName: string) =
  ## Add the given option name that doesn't have an associated
  ## argument to args.
  if not (optionName in args):
    args[optionName] = newSeq[string]()

proc addArg(args: var CmlArgs, optionName: string, argument: string) =
  ## Add the given option name and its argument value to the args.
  if optionName in args:
    var arguments = args[optionName]
    arguments.add(argument)
    args[optionName] = arguments
  else:
    args[optionName] = @[argument]

proc optionCount(args: var CmlArgs, optionName: string): Natural =
  ## Return the number of values the given option name has.
  if not (optionName in args):
    result = 0
  else:
    result = args[optionName].len

func cmdLine*(options: openArray[CmlOption],
    arguments: openArray[string]): ArgsOrMessage =
  ## Parse the command line arguments.  You pass in the list of
  ## supported options and the arguments to parse. The arguments found
  ## are returned. If there is a problem with the arguments, args
  ## contains a message telling the problem. Use collectArgs() to
  ## generate the arguments. Parse uses "arg value" not "arg=value".

  # todo: is it easy to post process to support arg=value on an option?

  # shortOptions maps a short option letter to its option.
  var shortOptions: OrderedTable[char, CmlOption]

  # longOptions maps a long name to its option.
  var longOptions: OrderedTable[string, CmlOption]

  # bareArgumentNames is a list of each bare name in the order specified.
  var bareArgumentNames = newSeq[string]()

  # onceNames is a list of each cmlArgumentOnce type option.
  var onceNames = newSeq[string]()

  # Populate shortOptions, longOptions, bareArgumentNames and onceNames.
  var bareIx = 0
  for option in options:
    if option.long in longOptions:
      # _07_, Duplicate long option: '--$1'.
      return newArgsOrMessage(cml_07_DupLongOption, $option.long)
    longOptions[option.long] = option
    if option.optionType == cmlArgumentOnce:
      onceNames.add(option.long)
    if option.optionType == cmlBareArgument:
      bareArgumentNames.add(option.long)
      if option.short != '_':
        # _08_, Use the short name '_' instead of '$1' with a bare argument.
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
      needArgument,
      processOption,
      optionalArgument,
      multipleShortOptions,

  # Loop over the arguments and populate args.
  var args: CmlArgs
  var ix = 0
  var state: State
  var argument: string
  var optionName: string
  while true:
    if ix >= arguments.len:
      break
    argument = arguments[ix]

    # Skip empty arguments.
    if argument == "":
      inc(ix)
      continue

    case state:
    of start:
      if argument.startsWith("--"):
        state = longOption
      elif argument.startsWith("-"):
        state = shortOption
      else:
        # _11_, Extra bare argument.
        if bareIx >= bareArgumentNames.len:
          return newArgsOrMessage(cml_11_TooManyBareArgs)

        let name = bareArgumentNames[bareIx]
        addArg(args, name, argument)
        inc(ix)
        inc(bareIx)

    of longOption:
      if argument.len < 3:
        # _00_, Two dashes must be followed by an option name.
        return newArgsOrMessage(cml_00_BareTwoDashes)
      optionName = argument[2 .. argument.len - 1]
      if not (optionName in longOptions):
        # _01_, The option '--$1' is not supported.
        return newArgsOrMessage(cml_01_InvalidOption, optionName)

      state = processOption

    of shortOption:
      if argument.len < 2:
        # _03_, One dash must be followed by a short option name.
        return newArgsOrMessage(cml_03_BareOneDash)
      if argument.len > 2:
        state = multipleShortOptions
        continue

      let shortOptionName = argument[1]
      if not (shortOptionName in shortOptions):
        # _04_, The short option '-$1' is not supported.
        return newArgsOrMessage(cml_04_InvalidShortOption, $shortOptionName)

      let option = shortOptions[shortOptionName]
      optionName = option.long
      state = processOption

    of processOption:
      let option = longOptions[optionName]
      case option.optionType:
      of cmlNoArgument:
        state = start
        addArg(args, optionName)
        inc(ix)
      of cmlOptionalArgument, cmlArgument0or1, cmlArgumentOnce:
        if args.optionCount(option.long) > 0:
          # _12_, One '$1' argument is allowed.
          return newArgsOrMessage(cml_12_AlreadyHaveOneArg, $option.long)
        if option.optionType == cmlOptionalArgument:
          state = optionalArgument
        else:
          state = needArgument
        inc(ix)
      of cmlArgumentMany:
        state = needArgument
        inc(ix)
      of cmlBareArgument:
        assert(false, "got a bare argument and option combination somehow")
        inc(ix)
      of cmlStopArgument:
        var stopArgs: CmlArgs
        addArg(stopArgs, optionName)
        return newArgsOrMessage(stopArgs)

    of needArgument:
      if argument.startsWith("-"):
        # _02_, The option '$1' needs a argument.
        return newArgsOrMessage(cml_02_OptionRequiresArg, optionName)
      addArg(args, optionName, argument)
      state = start
      inc(ix)

    of optionalArgument:
      if argument.startsWith("-"):
        addArg(args, optionName)
      else:
        addArg(args, optionName, argument)
        inc(ix)
      state = start

    of multipleShortOptions:

      for shortOptionName in argument[1 .. argument.len - 1]:
        if not (shortOptionName in shortOptions):
          # _04_, The short option '-$1' is not supported.
          return newArgsOrMessage(cml_04_InvalidShortOption, $shortOptionName)

        let option = shortOptions[shortOptionName]
        optionName = option.long
        if option.optionType in [cmlArgument0or1,
            cmlArgumentOnce, cmlArgumentMany]:
          # _05_, The option '-$1' needs an argument; use it by itself.
          return newArgsOrMessage(cml_05_ShortArgInList, $shortOptionName)
        addArg(args, optionName)

      state = start
      inc(ix)

  if state == needArgument:
    # _02_, The option '$1' needs an argument.
    return newArgsOrMessage(cml_02_OptionRequiresArg, optionName)

  if bareIx < bareArgumentNames.len:
    # _10_, Missing bare argument: '$1'.
    return newArgsOrMessage(cml_10_MissingArgument,
      bareArgumentNames[bareIx])

  if state == optionalArgument:
    addArg(args, optionName)

  # Make sure all the once arguments have one.
  for option in options:
    if option.optionType == cmlArgumentOnce:
      if not (option.long in args):
        # _02_, The option '$1' needs an argument.
        return newArgsOrMessage(cml_02_OptionRequiresArg, option.long)

  result = newArgsOrMessage(args)

when defined(Test) or isMainModule:

  const
    cmlMessages*: array[low(CmlMessageId)..high(CmlMessageId), string] = [
      #[_00_]# "Two dashes must be followed by an option name.",
      #[_01_]# "The option '--$1' is not supported.",
      #[_02_]# "The option '$1' requires an argument.",
      #[_03_]# "One dash must be followed by a short option name.",
      #[_04_]# "The short option '-$1' is not supported.",
      #[_05_]# "The option '-$1' needs an argument; use it by itself.",
      #[_06_]# "Duplicate short option: '-$1'.",
      #[_07_]# "Duplicate long option: '--$1'.",
      #[_08_]# "Use the short name '_' instead of '$1' with a bare argument.",
      #[_09_]# "Use an alphanumeric ascii character for a short option name instead of '$1'.",
      #[_10_]# "Missing '$1' argument.",
      #[_11_]# "Extra bare argument.",
      #[_12_]# "One '$1' argument is allowed.",
    ]
      ## Messages used by this module.

  func getMessage*(message: CmlMessageId, problemArg: string = ""): string =
    ## Return a message from a message id and problem argument.
    result = cmlMessages[message] % [problemArg]

when isMainModule:

  echo """
This is a parsing example for a fictional command that takes several
types of arguments.

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
    result.add("arg.help = $1\n" % $a.help)
    result.add("arg.log = $1\n" % $a.log)
    result.add("arg.logFilename = '$1'\n" % a.logFilename)
    result.add("arg.user = '$1'\n" % $a.user)
    result.add("arg.leader = '$1'\n" % $a.leader)
    result.add("arg.source = '$1'\n" % a.source)
    result.add("arg.destination = '$1'" % a.destination)

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
  options.add(newCmlOption("help", 'h', cmlStopArgument))
  options.add(newCmlOption("log", 'l', cmlOptionalArgument))
  options.add(newCmlOption("user", 'u', cmlArgumentMany))
  options.add(newCmlOption("leader", 'r', cmlArgumentOnce))
  options.add(newCmlOption("state", 's', cmlArgument0or1))
  options.add(newCmlOption("source", '_', cmlBareArgument))
  options.add(newCmlOption("destination", '_', cmlBareArgument))
  let argsOrMessage = cmdline(options, collectArgs())
  echo "Resulting argsOrMessage object:"
  echo ""
  echo $argsOrMessage
  echo ""

  if argsOrMessage.kind == cmlMessageKind:
    # Display the message.
    echo getMessage(argsOrMessage.messageId, argsOrMessage.problemArg)
  else:
    # Post process the resulting arguments.
    let args = newArgs(argsOrMessage.args)
    echo "Final args object:"
    echo ""
    echo $args
