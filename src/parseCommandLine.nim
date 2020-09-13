## Parse the command line and return the arguments.

import parseopt
import streams
import strutils
import tpub
import re
import args
import warnings


const
  fileLists = ["server", "shared", "template"]
  switches = [
    ('h', "help"),
    ('v', "version"),
    ('s', "server"),
    ('j', "shared"),
    ('t', "template"),
    ('r', "result"),
    ('u', "update"),
    ('p', "prepost"),
    ('l', "log"),
  ]


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


func `$`(sequence: seq[string]): string =
  result = sequence.join(", ")


func `$`(prepostList: seq[Prepost]): string {.tpub.} =
  var parts: seq[string]
  for pp in prepostList:
    parts.add("($1, $2)" % [pp.pre, pp.post])
  result = parts.join(", ")


func `$`*(args: Args): string =
  ## A string representation of Args.
  result = """
Args:
  help=$1
  version=$2
  update=$3
  log=$4
  serverList=$5
  sharedList=$6
  templateList=$7
  resultFilename=$8
  prepostList=$9
  logFilename=$10
""" % [$args.help, $args.version, $args.update, $args.log,
       $args.serverList, $args.sharedList,
       $args.templateList, $args.resultFilename,
       $args.prepostList, $args.logFilename]

let prepostRegex = re"^\s*(\S+)\s*(\S*)\s*(.*)$"

proc parsePrepost(str: string): (Prepost, string) {.tpub.} =
  ## Parse a prepost string. Return the Prepost object and another
  ## string with any extra unmatched characters.

  ## ""             => ("", ""), ""
  ## "<--$"         => ("<--$", ""), ""
  ## "<--$ -->"     => ("<--$", "-->"), ""
  ## "<--$ --> abc" => ("<--$", "-->"), "abc"

  var matches: array[3, string]
  if match(str, prepostRegex, matches):
    let prefix = matches[0]
    let postfix = matches[1]
    let extra = matches[2]
    result = ((prefix, postfix), extra)
  else:
    result = (("", ""), "")


proc handleWord(switch: string, word: string, value: string,
    stream: Stream, help: var bool, version: var bool, update: var bool,
    log: var bool, resultFilename: var string,
    filenames: var array[4, seq[string]], prepostList: var seq[Prepost],
    logFilename: var string) =
  ## Handle one switch and return its value.  Switch is the key from
  ## the command line, either a word or a letter.  Word is the long
  ## form of the switch.

  let listIndex = fileListIndex(word)
  if listIndex != -1:
    if value == "":
      warning(stream, "cmdline", 0, wNoFilename, word, $switch)
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
      warning(stream, "cmdline", 0, wNoFilename, word, $switch)
    elif resultFilename != "":
      warning(stream, "cmdline", 0, wOneResultAllowed, value)
    else:
      resultFilename = value
  elif word == "prepost":
    # prepost is a string with a space dividing the prefix from the
    # postfix. The postfix is optional. -p="<--$ -->" or -p="#$"
    if value == "":
      warning(stream, "cmdline", 0, wNoPrepostValue, $switch)
    else:
      let (prepost, extra) = parsePrepost(value)
      if extra != "":
        warning(stream, "cmdline", 0, wSkippingExtraPrepost, extra)
      prepostList.add(prepost)
  elif word == "log":
    log = true
    if value != "":
      if logFilename == "":
        logFilename = value
      else:
        warning(stream, "cmdline", 0, wOneLogAllowed, value)
  else:
    warning(stream, "cmdline", 0, wUnknownSwitch, $switch)


proc parseCommandLine*(stream: Stream, cmdLine: string=""): Args =
  ## Return the command line parameters and write warnings to the stream.

  var help: bool = false
  var version: bool = false
  var update: bool = false
  var log: bool = false
  var filenames: array[4, seq[string]]
  var optParser = initOptParser(cmdLine)
  var resultFilename: string
  var prepostList: seq[Prepost]
  var logFilename: string

  # Iterate over all arguments passed to the cmdline.
  for kind, key, value in getopt(optParser):
    case kind
      of CmdLineKind.cmdShortOption:
        for ix in 0..key.len-1:
          let letter = key[ix]
          let word = letterToWord(letter)
          if word == "":
            warning(stream, "cmdline", 0, wUnknownSwitch, $letter)
          else:
            handleWord($letter, word, value, stream, help, version, update,
                 log, resultFilename, filenames, prepostList, logFilename)

      of CmdLineKind.cmdLongOption:
        handleWord(key, key, value, stream, help, version, update, log,
                   resultFilename, filenames, prepostList, logFilename)

      of CmdLineKind.cmdArgument:
        warning(stream, "cmdline", 0, wUnknownArg, key)

      of CmdLineKind.cmdEnd:
        discard

  result.help = help
  result.version = version
  result.update = update
  result.log = log
  result.serverList = filenames[0]
  result.sharedList = filenames[1]
  result.templateList = filenames[2]
  result.resultFilename = resultFilename
  result.prepostList = prepostList
  result.logFilename = logFilename
