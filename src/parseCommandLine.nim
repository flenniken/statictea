## Parse the command line and return the arguments.

import parseopt
import streams
import strutils
import tpub

type
  Args* = object
    ## Command line arguments.
    help*: bool
    version*: bool
    serverList*: seq[string]
    sharedList*: seq[string]
    templateList*: seq[string]
    resultList*: seq[string]

const
  fileLists = ["server", "shared", "template", "result"]
  switches = [
    ('h', "help"),
    ('v', "version"),
    ('s', "server"),
    ('j', "shared"),
    ('t', "template"),
    ('r', "result"),
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


proc `$`*(args: Args): string =
  ## A string representation of Args.
  result = """
Args:
  help=$1
  version=$2
  serverList=$3
  sharedList=$4
  templateList=$5
  resultList=$6
""" % [$args.help, $args.version, $args.serverList, $args.sharedList,
       $args.templateList, $args.resultList]


proc handleWord(switch: string, word: string, value: string,
    warnings: Stream, help: var bool, version: var bool,
    filenames: var array[4, seq[string]]) =
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
  else:
    warnings.writeLine("warning 2: Unknown switch: $1" % $switch)


proc parseCommandLine*(warnings: Stream, cmdLine: string=""): Args =
  ## Return the command line parameters and write warnings to the stream.

  var help: bool = false
  var version: bool = false
  var filenames: array[4, seq[string]]
  var optParser = initOptParser(cmdLine)

  # Iterate over all arguments passed to the cmdline.
  for kind, key, value in getopt(optParser):
    # echo "kind: $1, key: $2, value: $3" % [$kind, $key, $value]
    case kind
      of CmdLineKind.cmdShortOption:
        for ix in 0..key.len-1:
          let letter = key[ix]
          let word = letterToWord(letter)
          if word == "":
            warnings.writeLine("warning 2: Unknown switch: $1" % $letter)
          else:
            handleWord($letter, word, value, warnings, help, version, filenames)

      of CmdLineKind.cmdLongOption:
        handleWord(key, key, value, warnings, help, version, filenames)

      of CmdLineKind.cmdArgument:
        warnings.writeLine("warning 3: Unknown argument: $1" % key)

      of CmdLineKind.cmdEnd:
        discard

  result.help = help
  result.version = version
  result.serverList = filenames[0]
  result.sharedList = filenames[1]
  result.templateList = filenames[2]
  result.resultList = filenames[3]
