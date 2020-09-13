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


proc openLogger*(filename: string, truncateFile: bool=false, warn: Stream = nil): Logger =
  ## Open the given file for logging. The file is first truncate when
  ## specified. Warnings are written to the warn stream if specified.
  ## Call closeLogger when you are done logging.

  if truncateFile:
    discard truncate(filename, 0)
  try:
    result.fh = open(filename, fmAppend)
    result.filename = filename
  except:
    if warn != nil:
      warning(warn, "logger", 0, wUnableToOpenLogFile, filename)


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
