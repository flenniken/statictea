## Parse the StaticTea terminal command line and return the arguments.

import std/options
import std/tables
import std/os
import args
import messages
import warnings
import regexes
import cmdline

proc parsePrepost*(str: string): Option[Prepost] =
  ## Parse the prepost item on the terminal command line.  A prefix is
  ## followed by an optional postfix, prefix[,postfix].  Each part
  ## contains 1 to 20 ascii characters including spaces but without
  ## control characters or commas.
  let pattern = "([\x20-\x2b\x2d-\x7F]{1,20})(?:,([\x20-\x2b\x2d-\x7F]{1,20})){0,1}$"
  let matchesO = matchPattern(str, pattern, 0, 2)
  if matchesO.isSome:
    let (prefix, postfix) = matchesO.get2Groups()
    result = some(newPrepost(prefix, postfix))

func mapCmlMessages(messageId: CmlMessageId): MessageId =
  when high(CmlMessageId) != cml_12_AlreadyHaveOneParameter:
    debugEcho "Update mapCmlMessages"
    fail
  result = MessageId(ord(messageId) + 157)

proc mySameFile(filename1: string, filename2: string): bool =
  ## Return true when the two files are the same file.
  if not fileExists(filename1):
    return false
  if not fileExists(filename2):
    return false
  result = sameFile(filename1, filename2)

proc parseCommandLine*(argv: seq[string]): ArgsOr =
  ## Parse the terminal command line.

  var options = newSeq[CmlOption]()
  options.add(newCmlOption("help", 'h', cmlStopParameter))
  options.add(newCmlOption("version", 'v', cmlStopParameter))
  options.add(newCmlOption("update", 'u', cmlNoParameter))

  options.add(newCmlOption("log", 'l', cmlOptionalParameter))

  options.add(newCmlOption("server", 's', cmlParameterMany))
  options.add(newCmlOption("shared", 'j', cmlParameterMany))
  options.add(newCmlOption("prepost", 'p', cmlParameterMany))

  options.add(newCmlOption("template", 't', cmlParameter0or1))
  options.add(newCmlOption("result", 'r', cmlParameter0or1))
  let ArgsOrMessage = cmdLine(options, argv)

  if ArgsOrMessage.kind == cmlMessageKind:
    let messageId = mapCmlMessages(ArgsOrMessage.messageId)
    let warningData = newWarningData(messageId, ArgsOrMessage.problemParam)
    return newArgsOr(warningData)

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
        return newArgsOr(newWarningData(wInvalidPrepost, str))
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
    if "update" in cmlArgs:
      ## The result file is used with the update option.
      return newArgsOr(newWarningData(wResultWithUpdate))

  if "log" in cmlArgs:
    let filenames = cmlArgs["log"]
    assert len(filenames) <= 1
    if len(filenames) == 1:
      args.logFilename = filenames[0]
    args.log = true

  # We don't need to check whether some of the command line files are
  # unique. We read the json files first and the code handles
  # duplicates.

  # Check that the template, result and log files are different.
  if mySameFile(args.templateFilename, args.resultFilename):
    # The template and result files are the same.
    return newArgsOr(newWarningData(wSameAsTemplate, "result"))
  elif mySameFile(args.templateFilename, args.logFilename):
    # The template and log files are the same.
    return newArgsOr(newWarningData(wSameAsTemplate, "log"))
  elif mySameFile(args.resultFilename, args.logFilename):
    # The result and log files are the same.
    return newArgsOr(newWarningData(wSameAsResult, "log"))
  result = newArgsOr(args)
