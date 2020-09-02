## Parse the command line and return the arguments.

import parseopt
import streams
import strutils

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


proc parseCommandLine*(warnings: Stream, cmdLine: string=""): Args =
  ## Return the command line parameters and write warnings to the stream.

  # var optParser = initOptParser(cmdLine, shortNoVal={'h', 'v'})
  var optParser = initOptParser(cmdLine)

  # Iterate over all arguments passed to the cmdline.
  for kind, key, value in getopt(optParser):
    # echo "kind: $1, key: $2, value: $3" % [$kind, $key, $value]
    case kind
      of CmdLineKind.cmdShortOption:
        var keyEnd = key.len - 1
        for ix in 0..keyEnd:
          var letter = key[ix]
          if letter == 'h':
            result.help = true
          elif letter == 'v':
            result.version = true
          elif letter == 'd':
            if value == "":
              warnings.writeLine("warning 4: No server json filename. Use -d=filename.")
            else:
              result.serverList.add(value)
          elif letter == 's':
            if value == "":
              warnings.writeLine("warning 4: No shared json filename. Use -s=filename.")
            else:
              result.sharedList.add(value)
          elif letter == 't':
            if value == "":
              warnings.writeLine("warning 4: No template filename. Use -t=filename.")
            else:
              result.templateList.add(value)
          elif letter == 'r':
            if value == "":
              warnings.writeLine("warning 4: No result filename. Use -r=filename")
            else:
              result.resultList.add(value)
          else:
            warnings.writeLine("warning 3: Unknown switch: $1" % key)
      of CmdLineKind.cmdLongOption:
        if key == "help":
          result.help = true
        elif key == "version":
          result.version = true
        elif key == "data":
          if value == "":
            warnings.writeLine("warning 4: No server json filename. Use --data=filename.")
          else:
            result.serverList.add(value)
        elif key == "shared":
          if value == "":
            warnings.writeLine("warning 4: No shared json filename. Use --shared=filename.")
          else:
            result.sharedList.add(value)
        elif key == "template":
          if value == "":
            warnings.writeLine("warning 4: No template filename. Use --template=filename.")
          else:
            result.templateList.add(value)
        elif key == "result":
          if value == "":
            warnings.writeLine("warning 4: No result filename. Use -result=filename")
          else:
            result.resultList.add(value)
        else:
          warnings.writeLine("warning 3: Unknown switch: %1" % key)
      of CmdLineKind.cmdArgument:
        warnings.writeLine("warning 1: Unknown argument: $1" % key)
      of CmdLineKind.cmdEnd:
        discard
