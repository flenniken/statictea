## StaticTea
## A template processor and language.
## See https://github.com/flenniken/statictea

import streams
import parseCommandLine
import strutils
import processTemplate

when isMainModule:
  # Detect control-c and stop.
  proc controlCHandler() {.noconv.} =
    quit 0
  setControlCHook(controlCHandler)

  # Process the command line args.
  var warnings = newFileStream(stderr)
  let args = parseCommandLine(warnings)

  if args.help:
    echo "showHelp()"
  elif args.version:
    echo "showVersion()"
  elif args.update:
    echo "updateTemplate(warnings, args)"
  elif args.templateList.len > 0:
    processTemplate(warnings, args)
  else:
    echo "showHelp()"
