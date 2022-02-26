## Parse the StaticTea terminal command line and return the arguments.

import std/options
import std/tables
import args
import messages
import warnings
import regexes
import cmdline

# todo: what to do about filenames in multiple places?  result = template = log, etc?

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
  let matchesO = matchPattern(str, pattern)
  if matchesO.isSome:
    let matches = matchesO.get()
    let (prefix, postfix) = matches.get2Groups()
    result = some(newPrepost(prefix, postfix))

func `$`*(aw: ArgsOrWarning): string =
  ## Return a string representation of a ArgsOrWarning object.
  if aw.kind == awArgs:
    result = $aw.args
  else:
    result = $aw.warningData

func mapClMessages(messageId: ClMessageId): MessageId =
  result = MessageId(ord(messageId) + 157)




proc parseCommandLine*(argv: seq[string]): ArgsOrWarning =

  var options = newSeq[ClOption]()
  options.add(newClOption("help", 'h', clNoParameter))
  options.add(newClOption("version", 'v', clNoParameter))
  options.add(newClOption("update", 'u', clNoParameter))

  options.add(newClOption("log", 'l', clOptionalParameter))

  options.add(newClOption("server", 's', clParameter))
  options.add(newClOption("shared", 'j', clParameter))
  options.add(newClOption("prepost", 'p', clParameter))

  options.add(newClOption("template", 't', clParameter))
  options.add(newClOption("result", 'r', clParameter))
  let ArgsOrMessage = cmdLine(options, argv)

  if ArgsOrMessage.kind == clMessage:
    let messageId = mapClMessages(ArgsOrMessage.messageId)
    let warningData = newWarningData(messageId, ArgsOrMessage.problemParam, "")
    return newArgsOrWarning(warningData)

  # Convert the clArgs to Args
  let clArgs = ArgsOrMessage.args
  var args: Args
  if "help" in clArgs:
    args.help = true
  if "version" in clArgs:
    args.version = true
  if "update" in clArgs:
    args.update = true

  if "server" in clArgs:
    args.serverList = clArgs["server"]
  if "shared" in clArgs:
    args.sharedList = clArgs["shared"]
  if "prepost" in clArgs:
    var prepostList: seq[Prepost]
    for str in clArgs["prepost"]:
      let prepostO = parsePrepost(str)
      if not prepostO.isSome:
        return newArgsOrWarning(newWarningData(wInvalidPrepost, str))
      else:
        prepostList.add(prepostO.get())
    args.prepostList = prepostList

  if "template" in clArgs:
    let filenames = clArgs["template"]
    if len(filenames) != 1:
      return newArgsOrWarning(newWarningData(wOneTemplateAllowed))
    args.templateList = filenames
  # todo: handle no template filename? or is that done some where else?
  # else:
  #   return newArgsOrWarning(newWarningData(wNoTemplateFilename))

  if "result" in clArgs:
    let filenames = clArgs["result"]
    if len(filenames) != 1:
      return newArgsOrWarning(newWarningData(wOneResultAllowed))
    args.resultFilename = filenames[0]

  if "log" in clArgs:
    let filenames = clArgs["log"]
    if len(filenames) > 1:
      return newArgsOrWarning(newWarningData(wOneLogAllowed))
    if len(filenames) == 1:
      args.logFilename = filenames[0]
    args.log = true

  result = newArgsOrWarning(args)
    
