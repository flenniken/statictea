## Parse the command line and return the arguments.

import parseopt
import tpub
import re
import args
import warnings
import env
when defined(test):
  import strutils

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


# func `$`(sequence: seq[string]): string =
#   result = sequence.join(", ")

when defined(test):
  func `$`(prepostList: seq[Prepost]): string {.tpub.} =
    var parts: seq[string]
    for pp in prepostList:
      parts.add("($1, $2)" % [pp.pre, pp.post])
    result = parts.join(", ")


# \x21-\x7F is ascii without spaces or control characters.
let prepostRegex = re"^\s*([\x21-\x7F]+)\s*([\x21-\x7F]*)\s*(.*)$"

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


proc handleWord(env: var Env, switch: string, word: string, value: string,
    help: var bool, version: var bool, update: var bool, log: var bool,
    resultFilename: var string, logFilename: var string,
    filenames: var array[4, seq[string]], prepostList: var seq[Prepost]) =
  ## Handle one switch and return its value.  Switch is the key from
  ## the command line, either a word or a letter.  Word is the long
  ## form of the switch.

  let listIndex = fileListIndex(word)
  if listIndex != -1:
    if value == "":
      env.warn(0, wNoFilename, word, $switch)
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
      env.warn(0, wNoFilename, word, $switch)
    elif resultFilename != "":
      env.warn(0, wOneResultAllowed, value)
    else:
      resultFilename = value
  elif word == "log":
    log = true
    logFilename = value
  elif word == "prepost":
    # prepost is a string with a space dividing the prefix from the
    # postfix. The postfix is optional. -p="<--$ -->" or -p="#$"
    if value == "":
      env.warn(0, wNoPrepostValue, $switch)
    else:
      let (prepost, extra) = parsePrepost(value)
      if extra != "":
        env.warn(0, wSkippingExtraPrepost, extra)
      if prepost.pre == "":
        env.warn(0, wInvalidPrepost, value)
      else:
        prepostList.add(prepost)
  else:
    env.warn(0, wUnknownSwitch, switch)


proc parseCommandLine*(env: var Env, argv: seq[string]): Args =
  ## Return the command line parameters.

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
            env.warn(0, wUnknownSwitch, $letter)
          else:
            handleWord(env, $letter, word, value, help, version, update, log,
              resultFilename, logFilename, filenames, prepostList)

      of CmdLineKind.cmdLongOption:
        handleWord(env, key, key, value, help, version, update, log,
                   resultFilename, logFilename, filenames, prepostList)

      of CmdLineKind.cmdArgument:
        env.warn(0, wUnknownArg, key)

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
  result.logFilename = logFilename
  result.prepostList = prepostList


# todo: what to do about filenames in multiple places?  result = template = log, etc?

when defined(test):
  proc parseCommandLine*(env: var Env, cmdLine: string = ""): Args =
    let argv = cmdLine.splitWhitespace()
    result = parseCommandLine(env, argv)
