## Support logging to a file.

import warnenv
import times
import strutils
import warnings
import options
import regex
when defined(test):
  import os

type
  LogEnv* = object ##/
    ## Log environment holding the log File and filename.
    file: File
    filename: string

const
  dtFormat = "yyyy-MM-dd HH:mm:ss'.'fff" ## \
  ## The date time format in local time written to the log.

func formatDateTime*(dt: DateTime): string =
  result = dt.format(dtFormat)

func formatLine*(filename: string, lineNum: int, message: string, dt=now()):
     string =
  ## Return a formatted log line.
  let dtString = formatDateTime(dt)
  result = "$1; $2($3); $4" % [dtString, filename, $lineNum, message]

func isOpen*(logEnv: LogEnv): bool =
  ## Return true when the log file is open.
  result = logEnv.file != nil

func isClosed*(logEnv: LogEnv): bool =
  ## Return true when the log file is closed.
  result = logEnv.file == nil

func filename*(logEnv: LogEnv): string =
  ## Return the log filename.
  result = logEnv.filename

func getFileSize*(logEnv: LogEnv): int64 =
  result = logEnv.file.getFileSize()

proc close*(logEnv: var LogEnv) =
  ## Close the log file and set the filename to "". Do nothing when
  ## it's already closed.
  if logEnv.file != nil:
    logEnv.file.close()
  logEnv.file = nil
  logEnv.filename = ""

proc logLine*(logEnv: var LogEnv, filename: string, lineNum: int, message: string) =
  ## Append a message to the log file. If there is an error writing,
  ## close the log. Do nothing when the log is closed.
  if isClosed(logEnv):
    return
  let line = formatLine(filename, lineNum, message)
  try:
    # raise newException(IOError, "test io error")
    logEnv.file.writeLine(line)
  except:
    warn("logger", 0, wUnableToWriteLogFile, filename)
    warn("logger", 0, wExceptionMsg, getCurrentExceptionMsg())
    # The stack trace is only available in the debug builds.
    when not defined(release):
      warn("logger", 0, wStackTrace, getCurrentException().getStackTrace())
    logEnv.close()

template log*(logEnv: var LogEnv, message: string) =
  ## Append the message to the log file. The current file and line
  ## becomes part of the message.
  if logEnv.isOpen:
    let info = instantiationInfo()
    logLine(logEnv, info.filename, info.line, message)

proc openLogFile*(filename: string): LogEnv =
  ## Open the log file for appending and return the LogEnv. If the
  ## file cannot be opened, a closed LogEnv is returned.
  var file: File
  if open(file, filename, fmAppend):
    result.file = file
    result.filename = filename
  else:
    warn("logger", 0, wUnableToOpenLogFile, filename)

when defined(test):
  type
    FileLine* = object
      filename*: string
      lineNum*: Natural

    LogLine* = object
      dt*: DateTime
      filename*: string
      lineNum*: Natural
      message*: string

  proc parseTimeStamp*(str: string): Option[DateTime] =
    try:
      result = some(parse(str, dtFormat))
    except TimeParseError:
      result = none(DateTime)

  proc parseFileLine*(str: string): Option[FileLine] =
    let pattern = getPattern(r"^(.*)\(([0-9]+)\)$")
    var groups: array[2, string]
    if matches(str, pattern, groups):
      let lineNum =  parseUInt(groups[1])
      result = some(FileLine(filename: groups[0], lineNum: lineNum))

  proc parseLine*(line: string): Option[LogLine] =
    var parts = split(line, "; ", 3)
    if parts.len != 3:
      return none(LogLine)
    let dtO = parseTimeStamp(parts[0])
    if not dtO.isSome:
      return none(LogLine)
    let fileLineO = parseFileLine(parts[1])
    if not fileLineO.isSome:
      return none(LogLine)
    let fileLine = fileLineO.get()
    result = some(LogLine(dt: dtO.get(), filename: fileLine.filename,
      lineNum: fileLine.lineNum, message: parts[2]))

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

when defined(test):
  proc closeReadDelete*(logEnv: var LogEnv, maximum: int = -1): seq[string] =
      # Close the log file, read its lines, then delete the file.
      let name = logEnv.filename
      if logEnv.isOpen:
        logEnv.close()
        result = readLines(name, maximum)
        discard tryRemoveFile(name)
