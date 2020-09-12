## Logging System

import times
import strutils
import re
import streams
import warnings
import posix


type
  Logger* = object
    filename: string
    fh: File

const
  staticteaLog* = "statictea.log"
  dtFormat = "yyyy-MM-dd HH:mm:ss'.'fff"


# 2020-09-12 11:45:24.369: first message
let logLineRegex = re"^(\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d.\d\d\d): (.*)$"


proc openWithWarning(filename: string, mode: FileMode, warn: Stream = nil): File =
  try:
    result = open(filename, mode)
  except:
    if warn != nil:
      warning(warn, "logger", 0, wUnableToOpenLogFile, filename)


proc openLogger*(filename: string, warn: Stream = nil): Logger =
  ## Open the given file for logging. Call closeLogger when you are
  ## done with logging.

  result.fh = openWithWarning(filename, fmAppend, warn)
  result.filename = filename


proc openLogger*(warn: Stream = nil): Logger =
  ## Truncate the statictea.log then open it for logging. Call
  ## closeLogger when you are done logging.

  discard truncate(staticteaLog, 0)
  result = openLogger(staticteaLog, warn)


proc log*(logger: Logger, message: string) =
  ## Log a message.

  if logger.fh != nil:
    let dt = now()
    let dtString = dt.format(dtFormat)
    for line in splitLines(message):
      let line = "$1: $2" % [dtString, line]
      logger.fh.writeLine(line)


proc close*(logger: var Logger) =
  ## Close the logger.

  if logger.fh != nil:
    logger.fh.close()
    logger.fh = nil


proc parseLogLine*(line: string): (string, string) =
  ## Parse a log line and return the datetime string and message
  ## string.

  var matches: array[2, string]
  if match(line, logLineRegex, matches):
    let dtString = matches[0]
    let message = matches[1]
    result = (dtString, message)


proc parseDateTime*(dtString: string): DateTime =
  result = parse(dtString, dtFormat)


func formatDateTime*(dt: DateTime): string =
  result = dt.format(dtFormat)
