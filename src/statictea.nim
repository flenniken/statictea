## StaticTea
## A template processor and language.
## See https://github.com/flenniken/statictea

import streams
import parseCommandLine

when isMainModule:
  # Detect control-c and stop.
  proc controlCHandler() {.noconv.} =
    quit 0
  setControlCHook(controlCHandler)

  # Process the command line args.
  var stream = newFileStream(stderr)
  let args = parseCommandLine(stream)
  echo $args
