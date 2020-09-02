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


proc addFilename(args: var Args, switch: string, value: string) =
  ## Add a filename to the args list specified by the switch.
  case switch
    of "server", "s":
      args.serverList.add(value)
    of "shared", "j":
      args.sharedList.add(value)
    of "template", "t":
      args.templateList.add(value)
    of "result", "r":
      args.resultList.add(value)
    else:
      discard


proc parseCommandLine*(warnings: Stream, cmdLine: string=""): Args =
  ## Return the command line parameters and write warnings to the stream.

  var optParser = initOptParser(cmdLine)
  let letterNameList = toHashSet("sjtr")
  let wordNameList = toHashSet(["server", "shared", "template", "result"])

  # Iterate over all arguments passed to the cmdline.
  for kind, key, value in getopt(optParser):
    # echo "kind: $1, key: $2, value: $3" % [$kind, $key, $value]
    case kind
      of CmdLineKind.cmdShortOption:
        for ix in 0..key.len-1:
          var letter = key[ix]
          if letter in letterNameList:
            if value == "":
              warnings.writeLine("warning 4: No $1 filename. Use -$1=filename." % $letter)
            else:
              addFilename(result, $letter, value)
          elif letter == 'h':
            result.help = true
          elif letter == 'v':
            result.version = true
          else:
            warnings.writeLine("warning 3: Unknown switch: %1" % $letter)

      of CmdLineKind.cmdLongOption:
        if key in wordNameList:
          if value == "":
            warnings.writeLine("warning 4: No $1 filename. Use --$1=filename." % key)
          else:
            addFilename(result, key, value)
        elif key == "help":
          result.help = true
        elif key == "version":
          result.version = true
        else:
          warnings.writeLine("warning 3: Unknown switch: %1" % key)

      of CmdLineKind.cmdArgument:
        warnings.writeLine("warning 1: Unknown argument: $1" % key)
      of CmdLineKind.cmdEnd:
        discard
