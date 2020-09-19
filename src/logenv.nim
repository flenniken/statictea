## Logging environment.

import loggers
import streams
import options
import warnings

var logger: Logger
var loggerSet = false


proc log*(message: string) =
  logger.log(message)


proc openStaticTeaLogger*(filename: string, warnings: Stream) =
  ## Open the statictea logger dependent on the command line arguments
  ## and set the logger variable.  Set a do nothing logger when
  ## logging is not specified or when there is an error opening the
  ## log file.

  if loggerSet:
    logger.log("Calling open for statictea log when it's already open.")
    return
  loggerSet = true

  let option = openLogger(filename, false)
  if not option.isSome:
    warning(warnings, "logger", 0, wUnableToOpenLogFile, filename)
    return

  logger = option.get()


proc closeStaticTeaLogger*() =
  if not loggerSet:
    # Calling close for statictea log when it's not open.
    return
  logger.close()
  loggerSet = false
