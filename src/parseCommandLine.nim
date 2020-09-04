## Parse the command line and return the arguments.

import parseopt
import streams
import strutils
import sets

type
  Args* = tuple
    ## Command line arguments.
    help: bool
    version: bool
    serverList: seq[string]
    sharedList: seq[string]
    templateList: seq[string]
    resultList: seq[string]

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
""" % [$args.help, $args.version, $args.serverList, $args.sharedList, $args.templateList, $args.resultList]


proc addFilename(word: string, filename: string, args: var Args) =
  ## Add a filename to the args list specified by the word.
  case word
  of "server":
    args.serverList.add(filename)
  of "shared":
    args.sharedList.add(filename)
  of "template":
    args.templateList.add(filename)
  of "result":
    args.resultList.add(filename)
  else:
    discard


proc letterToWord(letter: char): string =
  case letter
  of 's':
    result = "server"
  of 'j':
    result = "shared"
  of 't':
    result = "template"
  of 'r':
    result = "result"
  of 'h':
    result = "help"
  of 'v':
    result = "version"
  else:
    result = ""


proc handleWord(switch: string, word: string, value: string,
                warnings: Stream, args: var Args) =
  ## switch is either a word or a letter, the value from the command line.
  ## word is the name in the args object.

  let filenameList = toHashSet(["server", "shared", "template", "result"])
  if word in filenameList:
    if value == "":
      warnings.writeLine("warning 4: No $1 filename. Use $2=filename." % [word, $switch])
    else:
      addFilename(word, value, args)
  elif word == "help":
    args.help = true
  elif word == "version":
    args.version = true
  else:
    warnings.writeLine("warning 3: Unknown switch: $1" % $switch)



proc parseCommandLine*(warnings: Stream, cmdLine: string=""): Args =
  ## Return the command line parameters and write warnings to the stream.

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
            warnings.writeLine("warning 3: Unknown switch: $1" % $letter)
          else:
            handleWord($letter, word, value, warnings, result)

      of CmdLineKind.cmdLongOption:
        handleWord(key, key, value, warnings, result)

      of CmdLineKind.cmdArgument:
        warnings.writeLine("warning 1: Unknown argument: $1" % key)

      of CmdLineKind.cmdEnd:
        discard
