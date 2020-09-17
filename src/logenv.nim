## Logger environment.

import loggers
import streams
import args
import options
import warnings

var logger: Logger
var loggerSet = false

const
  staticteaLog* = "statictea.log" ## \
  ## Name of the default statictea log file.


proc log*(message: string) =
  logger.log(message)


proc openStaticTeaLogger*(args: Args, warnings: Stream) =
  ## Open the statictea logger dependent on the command line arguments
  ## and set the logger variable.  Set a do nothing logger when
  ## logging is not specified or when there is an error opening the
  ## log file.

  if loggerSet:
    logger.log("Calling open for statictea log when it's already open.")
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


proc closeStaticTeaLogger*() =
  if not loggerSet:
    # Calling close for statictea log when it's not open.
    return
  logger.close()
  loggerSet = false
