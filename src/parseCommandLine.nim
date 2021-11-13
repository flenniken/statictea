## Parse the StaticTea terminal command line and return the arguments.

import std/parseopt
import std/options
import tpub
import args
import messages
import warnings
import regexes

const
  fileLists = ["server", "shared", "template"]
  switches = [
    ('h', "help"),
    ('v', "version"),
    ('s', "server"),
    ('j', "shared"),
    ('t', "template"),
    ('r', "result"),
    ('l', "log"),
    ('u', "update"),
    ('p', "prepost"),
  ]

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

func newArgsOrWarning(warning: Warning, p1: string = "",
    p2: string = ""): ArgsOrWarning =
  ## Return a new ArgsOrWarning object containing a warning.
  let warningData = newWarningData(warning, p1, p2)
  result = ArgsOrWarning(kind: awWarning, warningData: warningData)

func newArgsOrWarning(warningData: WarningData): ArgsOrWarning =
  ## Return a new ArgsOrWarning object containing a warning.
  result = ArgsOrWarning(kind: awWarning, warningData: warningData)

func fileListIndex(word: string): int {.tpub.} =
  for ix, w in fileLists:
    if w == word:
      return ix
  return -1

func letterToWord(letter: char): string {.tpub.} =
  for tup in switches:
    if tup[0] == letter:
      return tup[1]
  return ""

proc parsePrepost(str: string): Option[Prepost] {.tpub.} =
  ## Match a prefix followed by an optional postfix, prefix[,postfix].
  ## Each part contains 1 to 20 ascii characters including spaces but
  ## without control characters or commas.
  let pattern = "([\x20-\x2b\x2d-\x7F]{1,20})(?:,([\x20-\x2b\x2d-\x7F]{1,20})){0,1}$"
  let matchesO = matchPattern(str, pattern)
  if matchesO.isSome:
    let matches = matchesO.get()
    let (prefix, postfix) = matches.get2Groups()
    result = some(newPrepost(prefix, postfix))

proc handleWord(switch: string, word: string, value: string,
    help: var bool, version: var bool, update: var bool, log: var bool,
    resultFilename: var string, logFilename: var string,
    filenames: var array[4, seq[string]], prepostList: var seq[Prepost]):
    Option[WarningData] =
  ## Handle one switch and return its value.  Switch is the key from
  ## the command line, either a word or a letter.  Word is the long
  ## form of the switch.

  let listIndex = fileListIndex(word)
  if listIndex != -1:
    if value == "":
      return some(newWarningData(wNoFilename, word, $switch))
    else:
      filenames[listIndex].add(value)
  elif word == "help":
    help = true
  elif word == "version":
    version = true
  elif word == "update":
    update = true
  elif word == "result":
    if value == "":
      return some(newWarningData(wNoFilename, word, $switch))
    elif resultFilename != "":
      return some(newWarningData(wOneResultAllowed, value))
    else:
      resultFilename = value
  elif word == "log":
    log = true
    logFilename = value
  elif word == "prepost":
    # prepost is a string with a space dividing the prefix from the
    # postfix. The postfix is optional. -p="<--$ -->" or -p="#$"
    if value == "":
      return some(newWarningData(wNoPrepostValue, $switch))
    else:
      let prepostO = parsePrepost(value)
      if not prepostO.isSome:
        return some(newWarningData(wInvalidPrepost, value))
      else:
        prepostList.add(prepostO.get())
  else:
    return some(newWarningData(wUnknownSwitch, switch))

proc parseCommandLine*(argv: seq[string]): ArgsOrWarning =
  ## Return the command line arguments or a warning. Processing stops
  ## on the first warning.

  var args: Args
  var help: bool = false
  var version: bool = false
  var update: bool = false
  var log: bool = false
  var filenames: array[4, seq[string]]
  var optParser = initOptParser(argv)
  var resultFilename: string
  var logFilename: string
  var prepostList: seq[Prepost]

  # Iterate over all arguments passed to the command line.
  for kind, key, value in getopt(optParser):
    case kind
      of CmdLineKind.cmdShortOption:
        for ix in 0..key.len-1:
          let letter = key[ix]
          let word = letterToWord(letter)
          if word == "":
            return newArgsOrWarning(wUnknownSwitch, $letter)
          else:
            let warningDataO = handleWord($letter, word, value,
              help, version, update, log, resultFilename, logFilename,
              filenames, prepostList)
            if warningDataO.isSome():
              return newArgsOrWarning(warningDataO.get())

      of CmdLineKind.cmdLongOption:
        let warningDataO = handleWord(key, key, value, help, version, update, log,
                   resultFilename, logFilename, filenames, prepostList)
        if warningDataO.isSome():
          return newArgsOrWarning(warningDataO.get())

      of CmdLineKind.cmdArgument:
        return newArgsOrWarning(wUnknownArg, key)

      of CmdLineKind.cmdEnd:
        discard

  args.help = help
  args.version = version
  args.update = update
  args.log = log
  args.serverList = filenames[0]
  args.sharedList = filenames[1]
  args.templateList = filenames[2]
  args.resultFilename = resultFilename
  args.logFilename = logFilename
  args.prepostList = prepostList

  result = newArgsOrWarning(args)

func `$`*(aw: ArgsOrWarning): string =
  ## Return a string representation of a ArgsOrWarning object.
  if aw.kind == awArgs:
    result = $aw.args
  else:
    result = $aw.warningData

# todo: what to do about filenames in multiple places?  result = template = log, etc?
