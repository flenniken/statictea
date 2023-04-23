## Log to a file.

import std/streams
import std/os
import std/times
import std/options
import std/strutils
import tempFile
import messages

const
  logWarnSize*: int64 = 1024 * 1024 * 1024
    ## Warn the user when the log file gets over 1 GB.

  dtFormat* = "yyyy-MM-dd HH:mm:ss'.'fff"
    ## The date time format in local time written to the log.

  maxWarningsWritten* = 32
    ## The maximum number of warning messages to show.

when hostOS == "macosx":
  const
    staticteaLog* = expandTilde("~/Library/Logs/statictea.log")
      ## Name of the default statictea log file.  The path on the Mac is
      ## different than the other platforms.
else:
  const
    staticteaLog* = expandTilde("~/statictea.log")
      ## Name of the default statictea log file.  The path on the Mac is
      ## different than the other platforms.

func formatLogDateTime*(dt: DateTime): string =
  ## Return a formatted time stamp for the log.
  result = dt.format(dtFormat)

func formatLogLine*(filename: string, lineNum: int, message: string, dt = now()):
     string =
  ## Return a formatted log line.
  let dtString = formatLogDateTime(dt)
  result = "$1; $2($3); $4" % [dtString, filename, $lineNum, message]

proc logLine*(logFile: File, filename: string, lineNum: int, message: string) =
  ## Append a message to the log file. If there is an error writing,
  ## close the log. Do nothing when the log is closed. A newline is
  ## not added to the line.
  if logFile == nil:
    return
  let line = formatLogLine(filename, lineNum, message)
  try:
    # raise newException(IOError, "test io error")
    logFile.write(line)
  except:
    # Unable to write to the log file: '$1'.
    # env.warnNoFile(wUnableToWriteLogFile, filename)
    # Exception: '$1'.
    # env.warnNoFile(wExceptionMsg, getCurrentExceptionMsg())
    # The stack trace is only available in the debug builds.
    # when not defined(release):
    #   # Stack trace: '$1'.
    #   env.warnNoFile(wStackTrace, getCurrentException().getStackTrace())
    # Close the log file.  Only one warning goes out about it not working.
    logFile.close()
    # logFile = nil

template log*(logFile: File, message: string) =
  ## Append the message to the log file. The current file and line
  ## becomes part of the message.
  let info = instantiationInfo()
  logLine(logFile, info.filename, info.line, message)
