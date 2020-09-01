## StaticTea
## A template processor and language.
## See https://github.com/flenniken/statictea

import parseopt
import streams
import strutils

type
  Args* = tuple
    ## Command line arguments.
    help: bool
    version: bool
    server: seq[string]
    shared: seq[string]
    templates: seq[string]


proc `$`*(args: Args): string =
  ## Return a string representation of Args.
  result = """
Args:
  help=$1
  version=$2
  server=$3
  shared=$4
  templates=$5
""" % [$args.help, $args.version, $args.server, $args.shared, $args.templates]


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
              result.server.add(value)
          elif letter == 's':
            if value == "":
              warnings.writeLine("warning 4: No shared json filename. Use -s=filename.")
            else:
              result.shared.add(value)
          elif letter == 't':
            if value == "":
              warnings.writeLine("warning 4: No template filename. Use -t=filename.")
            else:
              result.templates.add(value)
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
            result.server.add(value)
        elif key == "shared":
          if value == "":
            warnings.writeLine("warning 4: No shared json filename. Use --shared=filename.")
          else:
            result.shared.add(value)
        elif key == "template":
          if value == "":
            warnings.writeLine("warning 4: No template filename. Use --template=filename.")
          else:
            result.templates.add(value)
        else:
          warnings.writeLine("warning 3: Unknown switch: %1" % key)
      of CmdLineKind.cmdArgument:
        warnings.writeLine("warning 1: Unknown argument: $1" % key)
      of CmdLineKind.cmdEnd:
        discard


when isMainModule:
  # Detect control-c and stop.
  proc controlCHandler() {.noconv.} =
    quit 0
  setControlCHook(controlCHandler)

  # Process the command line args and run.
  var optParser = initOptParser(shortNoVal={'h', 'v'})
  var stream = newFileStream(stderr)
  let args = parseCommandLine(stream)
  echo $args
