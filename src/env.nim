## Environment holding the input and output streams.

import std/streams
import std/os
import std/options
import tempFile
import messages
import logger

const
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
    ##
    ## * errStream — standard error stream; normally stderr but
    ##   might be a normal file for testing.
    ## * outStream — standard output stream; normally stdout but
    ##   might be a normal file for testing.
    ## * logFilename — the log filename
    ## * closeErrStream — whether to close err stream. You don't
    ##   close stderr.
    ## * closeOutStream — whether to close out stream. You don't
    ##   close stdout.
    ## * closeTemplateStream — whether to close the template stream
    ## * closeResultStream — whether to close the result stream
    ## * templateFilename — name of the template file
    ## * templateStream — template stream, may be stdin
    ## * resultFilename — name of the result file
    ## * resultStream — result stream, may be stdout
    ## * warningsWritten — the total number of warnings

    # These get set at the start.
    errStream*: Stream
    outStream*: Stream
    logFilename*: string

    # You don't close the stderr or stdout.
    closeErrStream*: bool
    closeOutStream*: bool
    closeTemplateStream*: bool
    closeResultStream*: bool

    # The following streams get set after parsing the command line
    # options.  The result stream may be stdout and the templateStream
    # may be stdin.
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
  closeLogFile()

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

proc writeOut*(env: var Env, message: string) =
  ## Write a message to the output stream.
  env.outStream.writeLine(message)

proc writeErr*(env: var Env, message: string) =
  ## Write a message to the error stream.
  env.errStream.writeLine(message)

proc openEnvLogFile*(env: var Env, logFilename: string) =
  ## Open the log file and update the environment. If the log file
  ## cannot be opened, a warning is output and the environment is
  ## unchanged.
  if openLogFile(logFilename) == false:
    # Unable to open log file: '$1'.
    env.warnNoFile(wUnableToOpenLogFile, logFilename)
  else:
    env.logFilename = logFilename

proc openEnv*(logFilename: string = ""): Env =
  ## Open and return the environment containing standard error and
  ## standard out as streams.

  result = Env(
    errStream: newFileStream(stderr),
    outStream: newFileStream(stdout),
  )

proc setupLogging*(env: var Env, logFilename: string = "") =
  ## Turn on logging for the environment using the specified log file.

  # When no log filename, use the default.
  var filename: string
  if logFilename == "":
    filename = staticteaLog
  else:
    filename = logFilename
  openEnvLogFile(env, filename)

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

proc addExtraStreamsForUpdate*(env: var Env, resultFilename: string, templateFilename: string):
    Option[WarningData] =
  ## For the update case, add the template and result streams to the
  ## environment. Return true on success.

  # Warn and exit when a resultFilename is specified.
  if resultFilename != "":
    # The update option overwrites the template, no result file allowed.
    return some(newWarningData(wResultFileNotAllowed))

  # Get the template filename.
  assert templateFilename != ""

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

