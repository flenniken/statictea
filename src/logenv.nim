## Logging environment.

import warnenv
import tpub
import times
import strutils
import warnings

var logFile: File

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
  else:
    warn("logger", 0, wUnableToOpenLogFile, filename)

