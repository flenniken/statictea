## Parse the StaticTea terminal command line and return the arguments.

import std/options
import std/tables
import args
import messages
import warnings
import regexes
import cmdline

type
  ArgsOrWarningKind* = enum
    ## The kind of a ArgsOrWarning object, either args or warning.
    awArgs,
    awWarning

  ArgsOrWarning* = object
    ## Holds args or a warning.
    case kind*: ArgsOrWarningKind
      of awArgs:
        args*: Args
      of awWarning:
        warningData*: WarningData

func newArgsOrWarning(args: Args): ArgsOrWarning =
  ## Return a new ArgsOrWarning object containing args.
  result = ArgsOrWarning(kind: awArgs, args: args)

func newArgsOrWarning(warningData: WarningData): ArgsOrWarning =
  ## Return a new ArgsOrWarning object containing a warning.
  result = ArgsOrWarning(kind: awWarning, warningData: warningData)

proc parsePrepost*(str: string): Option[Prepost] =
  ## Match a prefix followed by an optional postfix, prefix[,postfix].
  ## Each part contains 1 to 20 ascii characters including spaces but
  ## without control characters or commas.
  let pattern = "([\x20-\x2b\x2d-\x7F]{1,20})(?:,([\x20-\x2b\x2d-\x7F]{1,20})){0,1}$"
  let matchesO = matchPattern(str, pattern, 0, 2)
  if matchesO.isSome:
    let (prefix, postfix) = matchesO.get2Groups()
    result = some(newPrepost(prefix, postfix))

func `$`*(aw: ArgsOrWarning): string =
  ## Return a string representation of a ArgsOrWarning object.
  if aw.kind == awArgs:
    result = $aw.args
  else:
    result = $aw.warningData

func mapCmlMessages(messageId: CmlMessageId): MessageId =
  when high(CmlMessageId) != cml_12_AlreadyHaveOneParameter:
    debugEcho "Update mapCmlMessages"
    fail
  result = MessageId(ord(messageId) + 157)




proc parseCommandLine*(argv: seq[string]): ArgsOrWarning =

  var options = newSeq[CmlOption]()
  options.add(newCmlOption("help", 'h', cmlStopParameter))
  options.add(newCmlOption("version", 'v', cmlStopParameter))
  options.add(newCmlOption("update", 'u', cmlNoParameter))

  options.add(newCmlOption("log", 'l', cmlOptionalParameter))

  options.add(newCmlOption("server", 's', cmlParameterMany))
  options.add(newCmlOption("shared", 'j', cmlParameterMany))
  options.add(newCmlOption("prepost", 'p', cmlParameterMany))

  # todo: template is a required parameter.
  options.add(newCmlOption("template", 't', cmlParameter0or1))
  options.add(newCmlOption("result", 'r', cmlParameter0or1))
  let ArgsOrMessage = cmdLine(options, argv)

  if ArgsOrMessage.kind == cmlMessageKind:
    let messageId = mapCmlMessages(ArgsOrMessage.messageId)
    let warningData = newWarningData(messageId, ArgsOrMessage.problemParam)
    return newArgsOrWarning(warningData)

  # Convert the cmlArgs to Args
  let cmlArgs = ArgsOrMessage.args
  var args: Args
  args.help = "help" in cmlArgs
  args.version = "version" in cmlArgs
  args.update = "update" in cmlArgs

  if "server" in cmlArgs:
    args.serverList = cmlArgs["server"]
  if "shared" in cmlArgs:
    args.sharedList = cmlArgs["shared"]
  if "prepost" in cmlArgs:
    var prepostList: seq[Prepost]
    for str in cmlArgs["prepost"]:
      let prepostO = parsePrepost(str)
      if not prepostO.isSome:
        return newArgsOrWarning(newWarningData(wInvalidPrepost, str))
      else:
        prepostList.add(prepostO.get())
    args.prepostList = prepostList

  if "template" in cmlArgs:
    let filenames = cmlArgs["template"]
    assert len(filenames) == 1
    args.templateFilename = filenames[0]

  if "result" in cmlArgs:
    let filenames = cmlArgs["result"]
    assert len(filenames) == 1
    args.resultFilename = filenames[0]

  if "log" in cmlArgs:
    let filenames = cmlArgs["log"]
    assert len(filenames) <= 1
    if len(filenames) == 1:
      args.logFilename = filenames[0]
    args.log = true

  # todo: what to do about filenames in multiple places?  result = template = log, etc?

  result = newArgsOrWarning(args)
