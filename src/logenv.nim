## Logging environment.

import warnenv
import tpub
import times
import strutils
import warnings
when defined(test):
  import os

var logFile: File
var logFilename: string

tpubType:
  const
    dtFormat = "yyyy-MM-dd HH:mm:ss'.'fff" ## \
    ## The date time format in local time.

func formatLine(filename: string, lineNum: int, message: string, dt=now()):
     string {.tpub.} =
  ## Format and return the log line.
  let dtString = dt.format(dtFormat)
  result = "$1; $2($3); $4" % [dtString, filename, $lineNum, message]

proc closeLogFile*() =
  ## Close the log file.
  if logFile == nil:
    return
  logFile.close()
  logFile = nil
  logFilename = ""


proc logLine*(filename: string, lineNum: int, message: string) =
  ## Append a message to the log file.

  if logFile == nil:
    return
  let line = formatLine(filename, lineNum, message)
  try:
    # raise newException(IOError, "test io error")
    logFile.writeLine(line)
  except:
    warn("logger", 0, wUnableToWriteLogFile, filename)
    warn("logger", 0, wExceptionMsg, getCurrentExceptionMsg())
    # The stack trace is only available in the debug builds.
    when not defined(release):
      warn("logger", 0, wStackTrace, getCurrentException().getStackTrace())
    closeLogFile()

template log*(message: string) =
  ## Append the message to the log file.
  let info = instantiationInfo()
  logLine(info.filename, info.line, message)

proc openLogFile*(filename: string) =
  ## Open the log file.
  if logFile != nil:
    return
  var file: File
  if open(file, filename, fmAppend):
    logFile = file
    logFilename = filename
  else:
    warn("logger", 0, wUnableToOpenLogFile, filename)

when defined(test):
  proc readLines*(filename: string, maximum: int = -1): seq[string] =
    ## Read up to maximum lines from the given file. When maximum is
    ## negative, read all lines.
    var count = 0
    if maximum == 0:
      return
    var maxLines: int
    if maximum < 0:
      maxLines = high(int)
    else:
      maxLines = maximum
    for line in lines(filename):
      result.add(line)
      inc(count)
      if count > maxLines:
        break

  proc logReadDelete*(maximum: int = -1): seq[string] =
    # Close the log file, read its lines, then delete the file.
    if logFilename == "":
      return
    let logFilenameSave = logFilename
    closeLogFile()
    result = readLines(logFilenameSave, maximum)
    discard tryRemoveFile(logFilenameSave)
