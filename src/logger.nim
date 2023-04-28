## Log to a file.

import std/times
import std/strutils

var logFile: FILE

const
  dtFormat* = "yyyy-MM-dd HH:mm:ss'.'fff"
    ## The date time format in local time written to the log.

func formatLogDateTime*(dt: DateTime): string =
  ## Return a formatted time stamp for the log.
  result = dt.format(dtFormat)

func formatLogLine*(filename: string, lineNum: int, message: string, dt = now()):
     string =
  ## Return a formatted log line.
  let dtString = formatLogDateTime(dt)
  result = "$1; $2($3); $4\n" % [dtString, filename, $lineNum, message]

proc openLogFile*(logFilename: string): bool =
  ## Open the log file. Return true when it opened sucessfully.
  if logFile == nil:
    if open(logFile, logFilename, fmAppend):
      assert(logFile != nil)
      result = true
  
proc closeLogFile*() =
  ## Close the log file.
  if logFile != nil:
    logFile.close()
    logFile = nil

proc logLine*(filename: string, lineNum: int, message: string) =
  ## Append a message to the log file. If there is an error writing,
  ## close the log. Do nothing when the log is closed. A newline is
  ## added to the message.
  if logFile == nil:
    return
  let line = formatLogLine(filename, lineNum, message)
  try:
    # raise newException(IOError, "test io error")
    logFile.write(line)
    logFile.flushFile()
  except:
    # Close the log file.
    closeLogFile()

template log*(message: string) =
  ## Append the message to the log file including the current file and
  ## line number.
  let info = instantiationInfo()
  logLine(info.filename, info.line, message)
