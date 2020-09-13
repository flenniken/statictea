## StaticTea
## A template processor and language.
## See https://github.com/flenniken/statictea

import streams
import parseCommandLine
import strutils
import processTemplate

const
  staticteaLog* = "statictea.log"

proc getStaticTeaLogger(args: Args): Logger =
  ## Get the statictea logger dependent on the command line arguments.
  ## Return a do nothing logger when logging is not specified or when
  ## there is an error opening the log file.

  if not args.log:
    return
  var logName: string
  var truncateFile: bool
  if args.logFilename:
    logName = args.logFilename
    truncateFile = false
  else:
    logName = staticteaLog
    truncateFile = true
  let option = openLogger(logName, truncateFile)
  if option.isSome:
    result = option.get()
  else:
    warning(warnings, "logger", 0, wUnableToOpenLogFile, logName)


when isMainModule:
  # Detect control-c and stop.
  proc controlCHandler() {.noconv.} =
    quit 0
  setControlCHook(controlCHandler)

  # Process the command line args.
  var warnings = newFileStream(stderr)
  let args = parseCommandLine(warnings)

  # Open a log file when specified.
  var logName: string
  var truncateFile: bool
  var logger: Logger
  if args.log:
    if args.logFilename:
      logName = args.logFilename
      truncateFile = false
    else:
      logName = staticteaLog
      truncateFile = true
    let newLogger = openLogger(logName, truncateFile)
    if newLogger == nil:
      warning(warnings, "logger", 0, wUnableToOpenLogFile, logName)
    else:
      logger = newLogger


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
