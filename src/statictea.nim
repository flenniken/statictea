## StaticTea
## A template processor and language.
## See https://github.com/flenniken/statictea

import streams
import parseCommandLine
import strutils
import processTemplate
import logenv
import warnenv

const
  staticteaLog* = "statictea.log" ## \
  ## Name of the default statictea log file.

proc main() =
  # Setup control-c monitoring so ctrl-c stops the program.
  proc controlCHandler() {.noconv.} =
    quit 0
  setControlCHook(controlCHandler)

  # Open the global warn stream.
  openWarnStream()

  # Process the command line args.
  let args = parseCommandLine()

  # Open the global statictea.log file when logging is turned on.
  if args.log:
    openLogFile(staticteaLog)

  # We go through the motions of logging even when logging is turned
  # off so the logging code gets exercised.
  log($args)

  if args.help:
    echo "showHelp()"
  elif args.version:
    echo "showVersion()"
  elif args.update:
    echo "updateTemplate(warnings, args)"
  elif args.templateList.len > 0:
    processTemplate(args)
  else:
    echo "showHelp()"

  closeLogFile()
  closeWarnStream()

when isMainModule:
  main()
