## Parse the command line and return the arguments.

import parseopt
import streams
import strutils
import tpub
import re
import args


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
  serverList=$4
  sharedList=$5
  templateList=$6
  resultFilename=$7
  prepostList=$8
""" % [$args.help, $args.version, $args.update,
       $args.serverList, $args.sharedList,
       $args.templateList, $args.resultFilename,
       $args.prepostList]

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
                warnings: Stream, help: var bool, version: var bool, update: var bool,
                resultFilename: var string, filenames: var array[4, seq[string]],
                prepostList: var seq[Prepost]) =
  ## Handle one switch and return its value.  Switch is the key from
  ## the command line, either a word or a letter.  Word is the long
  ## form of the switch.

  let listIndex = fileListIndex(word)
  if listIndex != -1:
    if value == "":
      warnings.writeLine("warning 1: No $1 filename. Use $2=filename." % [word, $switch])
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
      warnings.writeLine("warning 1: No $1 filename. Use $2=filename." % [word, $switch])
    elif resultFilename != "":
      warnings.writeLine("warning 4: One result file allowed, skipping: $1" % [value])
    else:
      resultFilename = value
  elif word == "prepost":
    # prepost is a string with a space dividing the prefix from the
    # postfix. The postfix is optional. -p="<--$ -->" or -p="#$"
    if value == "":
      warnings.writeLine("warning 1: No prepost value. Use $2=\"...\"" % [word, $switch])
    else:
      let (prepost, extra) = parsePrepost(value)
      if extra != "":
        warnings.writeLine("warning 5: Skipping extra prepost text: $1" % [extra])
      prepostList.add(prepost)
  else:
    warnings.writeLine("warning 2: Unknown switch: $1" % $switch)


proc parseCommandLine*(warnings: Stream, cmdLine: string=""): Args =
  ## Return the command line parameters and write warnings to the stream.

  var help: bool = false
  var version: bool = false
  var update: bool = false
  var filenames: array[4, seq[string]]
  var optParser = initOptParser(cmdLine)
  var resultFilename: string
  var prepostList: seq[Prepost]

  # Iterate over all arguments passed to the cmdline.
  for kind, key, value in getopt(optParser):
    case kind
      of CmdLineKind.cmdShortOption:
        for ix in 0..key.len-1:
          let letter = key[ix]
          let word = letterToWord(letter)
          if word == "":
            warnings.writeLine("warning 2: Unknown switch: $1" % $letter)
          else:
            handleWord($letter, word, value, warnings, help, version, update,
                       resultFilename, filenames, prepostList)

      of CmdLineKind.cmdLongOption:
        handleWord(key, key, value, warnings, help, version, update,
                   resultFilename, filenames, prepostList)

      of CmdLineKind.cmdArgument:
        warnings.writeLine("warning 3: Unknown argument: $1" % key)

      of CmdLineKind.cmdEnd:
        discard

  result.help = help
  result.version = version
  result.update = update
  result.serverList = filenames[0]
  result.sharedList = filenames[1]
  result.templateList = filenames[2]
  result.resultFilename = resultFilename
  result.prepostList = prepostList
