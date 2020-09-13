## Write log messages to a file.
##
## Example Usage:
##
## .. code-block::
##   import loggers
##   import options
##   let option = openLogger("my.log")
##   doAssert option.isSome
##   var logger = option.get()
##   logger.log("first log message")
##   logger.log("second log message")
##   logger.close()
##   for line in lines("my.log"):
##     echo line
##
## Results::
##
##   2020-09-13 11:20:39.407: first log message
##   2020-09-13 11:20:39.407: second log message
##
## A closed or non-opened logger does nothing.
##
## .. code-block::
##   import loggers
##   var doNothingLogger = Logger()
##   doNothingLogger.log("mesage")
##   doNothingLogger.close()

import times
import strutils
import posix
import options

type
  Logger* = object
    file: File

const
  dtFormat* = "yyyy-MM-dd HH:mm:ss'.'fff" ## \
  ## The date time format in local time.


proc openLogger*(filename: string, truncateFile: bool=false): Option[Logger] =
  ## Open the given file for logging. The file is truncated when
  ## specified. Call close when you are done logging.

  if truncateFile:
    discard truncate(filename, 0)

  var logger: Logger
  var file: File
  if open(file, filename, fmAppend):
    logger.file = file
    result = some(logger)


proc log*(logger: Logger, message: string) =
  ## Append a message to the log file. Do nothing when not open.

  if logger.file == nil:
    return

  let dt = now()
  let dtString = dt.format(dtFormat)

  # Split messages with newlines into separate lines in the log.
  for line in splitLines(message):
    let line = "$1: $2" % [dtString, line]
    logger.file.writeLine(line)


proc close*(logger: var Logger) =
  ## Close the log file, if it's open.

  if logger.file != nil:
    logger.file.close()
    logger.file = nil
