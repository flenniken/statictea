## StaticTea
## A template processor and language.
## See https://github.com/flenniken/statictea

import streams
import parseCommandLine
import strutils
import processTemplate
import logenv
import warnenv
import args
import warnings

const
  staticteaLog* = "statictea.log" ## \
  ## Name of the default statictea log file.

proc processArgs(args: Args): int =
  if args.help:
    echo "showHelp()"
  elif args.version:
    echo "showVersion()"
  elif args.update:
    echo "updateTemplate(warnings, args)"
  elif args.templateList.len > 0:
    result = processTemplate(args)
  else:
    echo "showHelp()"

proc main(): int =
  ## Run statictea.

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

  try:
    result = processArgs(args)
  except:
    result = 1
    let msg = getCurrentExceptionMsg()
    log(msg)
    warn("error exit", 0, wUnexpectedException)
    warn("error exit", 0, wExceptionMsg, msg)
    # The stack trace is only available in the debug builds.
    when not defined(release):
      warn("exiting", 0, wStackTrace, getCurrentException().getStackTrace())

  closeLogFile()
  closeWarnStream()

when isMainModule:
  var rc: int
  try:
    rc = main()
  except:
    echo getCurrentExceptionMsg()
    rc = 1

  quit(if rc == 0: QuitSuccess else: QuitFailure)
