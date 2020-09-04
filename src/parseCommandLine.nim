## Parse the command line and return the arguments.

import parseopt
import streams
import strutils
import tables


type
  # ListType = enum serverList, sharedList, templateList, resultList
  Args* = object
    ## Command line arguments.
    help*: bool
    version*: bool
    filenames*: array[4, seq[string]]


let wordToListIndex = {
  "server": 0,
  "shared": 1,
  "template": 2,
  "result": 3,
}.toTable


let letterToWord = {
  's': "server",
  'j': "shared",
  't': "template",
  'r': "result",
  'h': "help",
  'v': "version",
}.toTable


proc `$`*(args: Args): string =
  ## Return a string representation of Args.
  result = """
Args:
  help=$1
  version=$2
  serverList=$3
  sharedList=$4
  templateList=$5
  resultList=$6
""" % [$args.help, $args.version, $args.filenames[0], $args.filenames[1],
       $args.filenames[2], $args.filenames[3]]




proc handleWord(switch: string, word: string, value: string,
                warnings: Stream, args: var Args) =
  ## switch is either a word or a letter, the value from the command line.
  ## word is the name in the args object.

  let listIndex = wordToListIndex.getOrDefault(word, -1)
  if listIndex != -1:
    if value == "":
      warnings.writeLine("warning 4: No $1 filename. Use $2=filename." % [word, $switch])
    else:
      args.filenames[listIndex].add(value)
  elif word == "help":
    args.help = true
  elif word == "version":
    args.version = true
  else:
    warnings.writeLine("warning 3: Unknown switch: $1" % $switch)


proc parseCommandLine*(warnings: Stream, cmdLine: string=""): Args =
  ## Return the command line parameters and write warnings to the stream.

  # result = Args(help: false, version: false, filenames: [seq[], seq[], seq[], seq[]])

  var optParser = initOptParser(cmdLine)

  # Iterate over all arguments passed to the cmdline.
  for kind, key, value in getopt(optParser):
    # echo "kind: $1, key: $2, value: $3" % [$kind, $key, $value]
    case kind
      of CmdLineKind.cmdShortOption:
        for ix in 0..key.len-1:
          let letter = key[ix]
          let word = letterToWord.getOrDefault(letter, "")
          if word == "":
            warnings.writeLine("warning 3: Unknown switch: $1" % $letter)
          else:
            handleWord($letter, word, value, warnings, result)

      of CmdLineKind.cmdLongOption:
        handleWord(key, key, value, warnings, result)

      of CmdLineKind.cmdArgument:
        warnings.writeLine("warning 1: Unknown argument: $1" % key)

      of CmdLineKind.cmdEnd:
        discard
