import streams
import warnings
import os
import strutils
import args
import times
when defined(test):
  import options
  import regexes

const
  staticteaLog* = "statictea.log"                    ## \
  ## Name of the default statictea log file.

  logWarnSize: BiggestInt = 1024 * 1024 * 1024       ## \
  ## Warn the user when the log file gets over 1 GB.

  dtFormat = "yyyy-MM-dd HH:mm:ss'.'fff"             ## \
  ## The date time format in local time written to the log.

type
  Env* = object
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
    # options.
    templateFilename*: string
    templateStream*: Stream
    resultFilename*: string
    resultStream*: Stream

    # Count of warnings written.
    warningWritten*: Natural

proc close*(env: var Env) =
  if env.closeErrStream:
    env.errStream.close()
    env.errStream = nil
  if env.closeOutStream:
    env.outStream.close()
    env.outStream = nil
  if env.closeTemplateStream:
    env.templateStream.close()
    env.templateStream = nil
  if env.closeResultStream:
    env.resultStream.close()
    env.resultStream = nil
  if env.logFile != nil:
    env.logFile.close()
    env.logFile = nil

proc warn*(env: var Env, message: string) =
  ## Write a message to the error stream.
  env.errStream.writeLine(message)
  inc(env.warningWritten)

proc warn*(env: var Env, lineNum: Natural, warning: Warning, p1:
           string = "", p2: string = "") =
  ## Write a formatted warning message to the error stream.
  var filename = env.templateFilename
  if filename == "":
    filename = "initializing"
    assert lineNum == 0
  let message = getWarning(filename, lineNum, warning, p1, p2)
  warn(env, message)

func formatDateTime*(dt: DateTime): string =
  result = dt.format(dtFormat)

func formatLine*(filename: string, lineNum: int, message: string, dt = now()):
     string =
  ## Return a formatted log line.
  let dtString = formatDateTime(dt)
  result = "$1; $2($3); $4" % [dtString, filename, $lineNum, message]

proc logLine*(env: var Env, filename: string, lineNum: int, message: string) =
  ## Append a message to the log file. If there is an error writing,
  ## close the log. Do nothing when the log is closed.
  if env.logFile == nil:
    return
  let line = formatLine(filename, lineNum, message)
  try:
    # raise newException(IOError, "test io error")
    env.logFile.writeLine(line)
  except:
    env.warn(0, wUnableToWriteLogFile, filename)
    env.warn(0, wExceptionMsg, getCurrentExceptionMsg())
    # The stack trace is only available in the debug builds.
    when not defined(release):
      env.warn(0, wStackTrace, getCurrentException().getStackTrace())
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

proc checkLogSize(env: var Env) =
  ## Check the log file size and write a warning message when the file
  ## is big.
  if env.logFile != nil:
    let logSize = env.logFile.getFileSize()
    if logSize > logWarnSize:
      let numStr = insertSep($logSize, ',')
      env.warn(0, wBigLogFile, env.logFilename, numStr)

proc openLogFile(env: var Env, logFilename: string) =
  ## Open the log file and update the environment.
  var file: File
  if open(file, logFilename, fmAppend):
    env.logFile = file
    env.logFilename = logFilename
  else:
    env.warn(0, wUnableToOpenLogFile, logFilename)

proc openEnv*(logFilename: string = staticteaLog,
                  warnSize: BiggestInt = logWarnSize): Env =
  ## Open and return the environment containing the standard error,
  ## standard out and the log file as streams.

  result = Env(
    errStream: newFileStream(stderr),
    outStream: newFileStream(stdout),
  )
  openLogFile(result, logFilename)
  checkLogSize(result)

proc addExtraStreams*(env: var Env, templateFilename: string,
                      resultFilename: string): bool =
  ## Add the template and result streams to the environment. Return
  ## true on success.

  # You can only add them once.
  assert env.templateStream == nil
  assert env.resultStream == nil

  # Open the template stream.
  var tStream: Stream
  var closeTStream: bool
  if templateFilename == "stdin":
    tStream = newFileStream(stdin)
    if tStream == nil:
      env.warn(0, wCannotOpenStd, "stdin")
      return
  else:
    if not fileExists(templateFilename):
      env.warn(0, wFileNotFound, templateFilename)
      return
    tStream = newFileStream(templateFilename, fmRead)
    if tStream == nil:
      env.warn(0, wUnableToOpenFile, templateFilename)
      return
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
      env.warn(0, wUnableToOpenFile, resultFilename)
      return
    closeRStream = true

  env.resultFilename = resultFilename
  env.resultStream = rStream
  env.closeResultStream = closeRStream

  result = true

proc addExtraStreams*(env: var Env, args: Args): bool =
  ## Add the template and result streams to the environment. Return
  ## true on success.

  # Get the template filename.
  assert args.templateList.len > 0
  if args.templateList.len > 1:
    let skipping = join(args.templateList[1..^1], ", ")
    env.warn(0, wOneTemplateAllowed, skipping)
  let templateFilename = args.templateList[0]

  # Get the result filename.
  let resultFilename = args.resultFilename

  result = addExtraStreams(env, templateFilename, resultFilename)

when defined(test):
  # You treat string streams different than file streams. Once you
  # close a string stream the data is gone, so you need to read it
  # before and you need to set the position at the start.


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

  proc parseFileLine*(line: string): Option[FileLine] =
    var matcher = newMatcher(r"^(.*)\(([0-9]+)\)$", 2)
    let matchesO = getMatches(matcher, line, 0)
    if matchesO.isSome:
      let matches = matchesO.get()
      let (filename, lineNumString) = matches.get2Groups()
      let lineNum = parseUInt(lineNumString)
      result = some(FileLine(filename: filename, lineNum: lineNum))

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

  proc closeReadDeleteLog*(env: var Env, maximum: int = -1): seq[string] =
    # Close the log file, read its lines, then delete the file.
    if env.logFile != nil:
      env.logFile.close()
      env.logFile = nil
      result = readLines(env.logFilename, maximum)
      discard tryRemoveFile(env.logFilename)

  proc readStream*(stream: Stream): seq[string] =
    let pos = stream.getPosition()
    stream.setPosition(0)
    for line in stream.lines():
      result.add line
    stream.setPosition(pos)

  proc echoStream*(stream: Stream) =
    if stream == nil:
      echo "nil stream"
    else:
      try:
        echo readStream(stream)
      except:
        echo "Unable to read the stream."
        echo "Is it open for reading?"
        echo "Is it stdout or stderr?"

  proc readAndClose*(stream: Stream): seq[string] =
    stream.setPosition(0)
    for line in stream.lines():
      result.add line
    stream.close()

  proc readCloseDeleteResult*(env: var Env): seq[string] =
    # If the result is going to stdout, read it to get the result.
    if env.closeResultStream:
      result = env.resultStream.readAndClose()
      discard tryRemoveFile(env.resultFilename)

  proc readCloseDelete*(env: var Env): tuple[logLine: seq[string],
      errLines: seq[string], outLines: seq[string]] =
    if env.closeErrStream and env.closeOutStream:
      result = (env.closeReadDeleteLog(100),
        env.errStream.readAndClose(), env.outStream.readAndClose())

  proc echoLines*(logLines, errLines, outLines: seq[string]) =
    echo "=== log ==="
    for line in logLines:
      echo line
    echo "=== err ==="
    for line in errLines:
      echo line
    echo "=== out ==="
    for line in outLines:
      echo line
    echo "==="

  proc expectedItem*[T](name: string, item: T, expectedItem: T): bool =
    ## Compare the item with the expected item and show them when
    ## different. Return true when they are the same.

    if item == expectedItem:
      result = true
    else:
      echo "$1" % name
      echo "     got: $1" % $item
      echo "expected: $1" % $expectedItem
      result = false

  proc expectedItems*[T](name: string, items: seq[T], expectedItems:
                         seq[T]): bool =
    ## Compare the items with the expected items and show them when
    ## different. Return true when they are the same.

    if items == expectedItems:
      result = true
    else:
      if items.len != expectedItems.len:
        echo "~~~~~~~~~~ $1 ~~~~~~~~~~~:" % name
        for item in items:
          echo $item
        echo "~~~~~~ expected $1 ~~~~~~:" % name
        for item in expectedItems:
          echo $item
      else:
        echo "~~~~~~~~~~ $1 ~~~~~~~~~~~:" % name
        for ix in 0 ..< items.len:
          if items[ix] == expectedItems[ix]:
            echo "$1 (same):      got: $2" % [$ix, $items[ix]]
            echo "$1 (same): expected: $2" % [$ix, $expectedItems[ix]]
          else:
            echo "$1       :      got: $2" % [$ix, $items[ix]]
            echo "$1       : expected: $2" % [$ix, $expectedItems[ix]]
      result = false

  proc testSome*[T](valueAndLengthO: Option[T], eValueAndLengthO: Option[T],
      text: string, start: Natural): bool =

    if valueAndLengthO == eValueAndLengthO:
      return true

    if not isSome(eValueAndLengthO):
      echo "Expected nothing be got something."
      echo $valueAndLengthO
      return false

    let value = valueAndLengthO.get().value
    let length = valueAndLengthO.get().length
    let eValue = eValueAndLengthO.get().value
    let eLength = eValueAndLengthO.get().length

    echo "Did not get the expected value."
    echo " text: $1" % text
    echo "start: $1" % startPointer(start)
    echo "got value: $1" % $value
    echo " expected: $1" % $evalue
    echo "got length: $1" % $length
    echo "  expected: $1" % $eLength

  proc openEnvTest*(logFilename: string, templateFilename: string = ""): Env =
    ## Open the log, error, and out streams. The given log file is used
    ## for the log stream.  The error and out streams get created as a
    ## string type streams. The templateFilename is used for warning messages.

    result = Env(
      errStream: newStringStream(), closeErrStream: true,
      outStream: newStringStream(), closeOutStream: true,
      templateFilename: templateFilename,
    )
    openLogFile(result, logFilename)
    checkLogSize(result)

  proc readCloseDeleteCompare*(env: var Env, eLogLines: seq[string] = @[],
                               eErrLines: seq[string] = @[], eOutLines: seq[string] = @[]): bool =
    ## Read the env streams and close and delete them. Compare the
    ## streams with the expected content. Return true when they are
    ## the same.

    result = true
    let (logLines, errLines, outLines) = env.readCloseDelete()

    if not expectedItems("logLines", logLines, eLogLines):
      result = false
    if not expectedItems("errLines", errLines, eErrLines):
      result = false
    if not expectedItems("outLines", outLines, eOutLines):
      result = false

  proc readCloseDeleteCompareResult*(env: var Env, eResultLines: seq[string] = @[]): bool =
    result = true
    let resultLines = env.readCloseDeleteResult()
    if not expectedItems("resultLines", resultLines, eResultLines):
      result = false

  proc createFile*(filename: string, content: string) =
    var file = open(filename, fmWrite)
    file.write(content)
    file.close()
