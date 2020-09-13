## Global logger for statictea.

import loggers
import streams
import args
import options
import warnings

var logger: Logger
var loggerSet = false

const
  staticteaLog* = "statictea.log"


proc log*(message: string) =
  logger.log(message)


proc openStaticTeaLogger*(args: Args, warnings: Stream) =
  ## Open the statictea logger dependent on the command line arguments
  ## and set the logger variable.  Set a do nothing logger when
  ## logging is not specified or when there is an error opening the
  ## log file.

  if loggerSet:
    logger.log("Only call openStaticTeaLogger once.")
    return
  loggerSet = true

  if not args.log:
    return # No logging.

  var logName: string
  var truncateFile: bool
  if args.logFilename == "":
    logName = staticteaLog
    truncateFile = true
  else:
    logName = args.logFilename
    truncateFile = false

  let option = openLogger(logName, truncateFile)
  if not option.isSome:
    warning(warnings, "logger", 0, wUnableToOpenLogFile, logName)
    return

  logger = option.get()
