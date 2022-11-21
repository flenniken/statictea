## Environment holding the input and output streams.

import std/streams
import std/os
import std/times
import std/options
import std/strutils
import tempFile
import messages
import args
import linebuffer

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

type
  Env* = object
    ## Env holds the input and output streams.
    ## @:
    ## @:* errStream -- standard error stream; normally stderr but
    ## @:might be a normal file for testing.
    ## @:* outStream -- standard output stream; normally stdout but
    ## @:might be a normal file for testing.
    ## @:* logFile -- the open log file
    ## @:* logFilename -- the log filename
    ## @:* closeErrStream -- whether to close err stream. You don't
    ## @:close stderr.
    ## @:* closeOutStream -- whether to close out stream. You don't
    ## @:close stdout.
    ## @:* closeTemplateStream -- whether to close the template stream
    ## @:* closeResultStream -- whether to close the result stream
    ## @:* templateFilename -- name of the template file
    ## @:* templateStream -- template stream, may be stdin
    ## @:* resultFilename -- name of the result file
    ## @:* resultStream -- result stream, may be stdout
    ## @:* warningsWritten -- the total number of warnings

    # These get set at the start.
    errStream*: Stream
    outStream*: Stream
    logFile*: File
    logFilename*: string

    # You don't close the stderr or stdout.
    closeErrStream*: bool
    closeOutStream*: bool
    closeTemplateStream*: bool
    closeResultStream*: bool

    # The following streams get set after parsing the command line
    # options.  The result stream may be stdout.
    templateFilename*: string
    templateStream*: Stream
    resultFilename*: string
    resultStream*: Stream

    warningsWritten*: Natural

proc close*(env: var Env) =
  ## Close the environment streams.
  if env.closeErrStream:
    env.errStream.close()
    env.errStream = nil
  if env.closeOutStream:
    env.outStream.close()
    env.outStream = nil
  if env.closeTemplateStream:
    if env.templateStream != nil:
      env.templateStream.close()
      env.templateStream = nil
  if env.closeResultStream:
    if env.resultStream != nil:
      env.resultStream.close()
      env.resultStream = nil
  if env.logFile != nil:
    env.logFile.close()
    env.logFile = nil

proc outputWarning*(env: var Env, lineNum: Natural, message: string) =
  ## Write a message to the error stream and increment the warning
  ## count.
  if env.warningsWritten >= maxWarningsWritten:
    return

  env.errStream.writeLine(message)
  inc(env.warningsWritten)

  if env.warningsWritten == maxWarningsWritten:
    var filename = env.templateFilename
    if filename == "":
      filename = "unnamed"

    # You reached the maximum number of warnings, suppressing the rest.
    let message = getWarningLine(filename, lineNum, wMaxWarnings)
    env.errStream.writeLine(message)
    inc(env.warningsWritten)

proc warn*(env: var Env, filename: string, lineNum: Natural,
    warning: MessageId, p1: string = "") =
  ## Write a formatted warning message to the error stream.

  # Use warnNoFile
  assert filename != ""

  let message = getWarningLine(filename, lineNum, warning, p1)
  outputWarning(env, lineNum, message)

proc warn*(env: var Env, filename: string, lineNum: Natural,
    warningData: WarningData) =
  ## Write a formatted warning message to the error stream.
  warn(env, filename, lineNum, warningData.messageId, warningData.p1)

proc warnNoFile*(env: var Env, messageId: MessageId, p1: string = "") =
  ## Write a formatted warning message to the error stream.
  warn(env, "nofile", 0, messageId, p1)

proc warnNoFile*(env: var Env, warningData: WarningData) =
  ## Write a formatted warning message to the error stream.
  warn(env, "nofile", 0, warningData.messageId, warningData.p1)

proc warnLb*(env: var Env, lb: LineBuffer, messageId: MessageId, p1: string = "") =
  ## Write a formatted warning message to the error stream.
  warn(env, lb.getFilename(), lb.getLineNum(), messageId, p1)

func formatLogDateTime*(dt: DateTime): string =
  ## Return a formatted time stamp for the log.
  result = dt.format(dtFormat)

func formatLogLine*(filename: string, lineNum: int, message: string, dt = now()):
     string =
  ## Return a formatted log line.
  let dtString = formatLogDateTime(dt)
  result = "$1; $2($3); $4" % [dtString, filename, $lineNum, message]

proc logLine*(env: var Env, filename: string, lineNum: int, message: string) =
  ## Append a message to the log file. If there is an error writing,
  ## close the log. Do nothing when the log is closed. A newline is
  ## not added to the line.
  if env.logFile == nil:
    return
  let line = formatLogLine(filename, lineNum, message)
  try:
    # raise newException(IOError, "test io error")
    env.logFile.write(line)
  except:
    # Unable to write to the log file: '$1'.
    env.warnNoFile(wUnableToWriteLogFile, filename)
    # Exception: '$1'.
    env.warnNoFile(wExceptionMsg, getCurrentExceptionMsg())
    # The stack trace is only available in the debug builds.
    when not defined(release):
      # Stack trace: '$1'.
      env.warnNoFile(wStackTrace, getCurrentException().getStackTrace())
    # Close the log file.  Only one warning goes out about it not working.
    env.logFile.close()
    env.logFile = nil

template log*(env: var Env, message: string) =
  ## Append the message to the log file. The current file and line
  ## becomes part of the message.
  let info = instantiationInfo()
  logLine(env, info.filename, info.line, message)

proc writeOut*(env: var Env, message: string) =
  ## Write a message to the output stream.
  env.outStream.writeLine(message)

proc checkLogSize*(env: var Env) =
  ## Check the log file size and write a warning message when the file
  ## is big.
  if env.logFile != nil:
    let logSize = env.logFile.getFileSize()
    if logSize > logWarnSize:
      # The log file is over 1 GB.
      env.warnNoFile(wBigLogFile)

proc openLogFile*(env: var Env, logFilename: string) =
  ## Open the log file and update the environment. If the log file
  ## cannot be opened, a warning is output and the environment is
  ## unchanged.
  var file: File
  if open(file, logFilename, fmAppend):
    env.logFile = file
    env.logFilename = logFilename
  else:
    # Unable to open log file: '$1'.
    env.warnNoFile(wUnableToOpenLogFile, logFilename)

proc openEnv*(logFilename: string = "",
                  warnSize: int64 = logWarnSize): Env =
  ## Open and return the environment containing standard error and
  ## standard out as streams.

  result = Env(
    errStream: newFileStream(stderr),
    outStream: newFileStream(stdout),
  )

proc setupLogging*(env: var Env, logFilename: string = "",
                  warnSize: int64 = logWarnSize) =
  ## Turn on logging for the environment using the specified log file.

  # When no log filename, use the default.
  var filename: string
  if logFilename == "":
    filename = staticteaLog
  else:
    filename = logFilename

  openLogFile(env, filename)
  checkLogSize(env)

proc addExtraStreams*(env: var Env, templateFilename: string,
    resultFilename: string): Option[WarningData] =
  ## Add the template and result streams to the environment.

  # You can only add them once.
  assert env.templateStream == nil
  assert env.resultStream == nil

  # Open the template stream.
  var tStream: Stream
  var closeTStream: bool
  if templateFilename == "stdin":
    tStream = newFileStream(stdin)
    if tStream == nil:
      # Unable to open standard input: $1.
      return some(newWarningData(wCannotOpenStd, "stdin"))
  else:
    if not fileExists(templateFilename):
      return some(newWarningData(wFileNotFound, templateFilename))
    tStream = newFileStream(templateFilename, fmRead)
    if tStream == nil:
      return some(newWarningData(wUnableToOpenFile, templateFilename))
    closeTStream = true

  env.templateFilename = templateFilename
  env.templateStream = tStream
  env.closeTemplateStream = closeTStream

  # Open the result stream.
  var rStream: Stream
  var closeRStream: bool
  if resultFilename == "":
    # No result filename means use the out stream. The out stream might
    # be a string stream or standard out.
    rStream = env.outStream
  else:
    rStream = newFileStream(resultFilename, fmReadWrite)
    if rStream == nil:
      return some(newWarningData(wUnableToOpenFile, resultFilename))
    closeRStream = true

  env.resultFilename = resultFilename
  env.resultStream = rStream
  env.closeResultStream = closeRStream

proc addExtraStreams*(env: var Env, args: Args): Option[WarningData] =
  ## Add the template and result streams to the environment. Return
  ## true on success.

  # Get the template filename.
  assert args.templateFilename != ""
  let templateFilename = args.templateFilename

  # Get the result filename.
  let resultFilename = args.resultFilename

  result = addExtraStreams(env, templateFilename, resultFilename)

proc addExtraStreamsForUpdate*(env: var Env, args: Args):
    Option[WarningData] =
  ## For the update case, add the template and result streams to the
  ## environment. Return true on success.

  # Warn and exit when a resultFilename is specified.
  if args.resultFilename != "":
    # The update option overwrites the template, no result file allowed.
    return some(newWarningData(wResultFileNotAllowed))

  # Get the template filename.
  assert args.templateFilename != ""
  let templateFilename = args.templateFilename

  # If you specify "stdin" for the template, the template comes from
  # stdin and the output goes to standard out.
  var resultFilename: string
  if templateFilename != "stdin":
    # Create a temp file for the result.  Rename it to the template
    # filename at the end.
    var tempFileO = openTempFile()
    if not tempFileO.isSome():
      # Unable to open temporary file.
      return some(newWarningData(wUnableToOpenTempFile))
    var tempFile = tempFileO.get()
    tempFile.file.close()
    resultFilename = tempFile.filename

  result = addExtraStreams(env, templateFilename, resultFilename)

iterator yieldContentLine*(content: string): string =
  ## Yield one line at a time and keep the line endings.
  var start = 0
  for pos in 0 ..< content.len:
    let ch = content[pos]
    if ch == '\n':
      yield(content[start .. pos])
      start = pos+1
  if start < content.len:
    yield(content[start ..< content.len])

