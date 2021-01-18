import streams
import warnings
import os
import strutils
import args
import times
when defined(test):
  import options
  import regexes
  import readlines

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
    filename = "unnamed"
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

when defined(test):
  proc splitNewLines*(content: string): seq[string] =
    ## Split lines and keep the line endings.
    if content.len == 0:
      return
    var start = 0
    var pos: int
    for pos in 0 ..< content.len:
      let ch = content[pos]
      if ch == '\n':
        result.add(content[start .. pos])
        start = pos+1
    if start < content.len:
      result.add(content[start ..< content.len])

  proc splitNewLinesNoEndings*(content: string): seq[string] =
    ## Split lines without the line endings.
    if content.len == 0:
      return
    var start = 0
    var pos: int
    for pos in 0 ..< content.len:
      let ch = content[pos]
      if ch == '\n':
        result.add(content[start ..< pos])
        start = pos+1
    if start < content.len:
      result.add(content[start ..< content.len])

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

  # proc readLines*(filename: string, maximum: int = -1): seq[string] =
  #   ## Read up to maximum lines from the given file. When maximum is
  #   ## negative, read all lines.
  #   var count = 0
  #   if maximum == 0:
  #     return
  #   var max: int
  #   if maximum < 0:
  #     max = high(int)
  #   else:
  #     max = maximum
  #   for line in lines(filename):
  #     result.add(line)
  #     inc(count)
  #     if count > max:
  #       break

  proc closeReadDeleteLog*(env: var Env, maximum: int = -1): seq[string] =
    # Close the log file, read its lines, then delete the file.
    if env.logFile != nil:
      env.logFile.close()
      env.logFile = nil
      result = readAllLines(env.logFilename)
      discard tryRemoveFile(env.logFilename)

  proc readStream*(stream: Stream): seq[string] =
    let pos = stream.getPosition()
    stream.setPosition(0)
    for line in stream.lines():
      result.add line
    stream.setPosition(pos)

  proc echoStream*(stream: Stream) =
    assert stream != nil
    let pos = stream.getPosition()
    stream.setPosition(0)
    for line in stream.lines():
      echo line
    stream.setPosition(pos)

  # todo: this does not care about line endings.
  proc readAndClose*(stream: Stream): seq[string] =
    stream.setPosition(0)
    for line in stream.lines():
      result.add line
    stream.close()

  # todo: replace readCloseDelete with readCloseDelete2
  proc readCloseDelete*(env: var Env): tuple[logLine: seq[string],
      errLines: seq[string], outLines: seq[string]] =
    if env.closeErrStream and env.closeOutStream:
      result = (env.closeReadDeleteLog(100),
        env.errStream.readAndClose(), env.outStream.readAndClose())

  proc readCloseDelete2*(env: var Env): tuple[
      logLines: seq[string],
      errLines: seq[string],
      outLines: seq[string],
      templateLines: seq[string],
      resultLines: seq[string]] =

    result.logLines = env.closeReadDeleteLog(100)
    if env.closeErrStream:
      result.errLines = env.errStream.readAndClose()
    if env.closeOutStream:
      result.outLines = env.outStream.readAndClose()
    if env.closeTemplateStream:
      result.templateLines = env.templateStream.readAndClose()
    if env.closeResultStream:
      result.resultLines = env.resultStream.readAndClose()

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
        echo "~~~~~~~~~~ $1 ($2)~~~~~~~~~~~:" % [name, $items.len]
        for item in items:
          echo $item
        echo "~~~~~~ expected $1 ($2)~~~~~~:" % [name, $expectedItems.len]
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

  proc showLines*(logLine: string, eLogLine: string, ix: int, eix: int) =
    echo "     got: " & logLine
    echo "          " & startPointer(ix)
    echo "expected: " & eLogLine
    echo "          " & startPointer(eix)

  proc compareLogLine*(logLine: string, eLogLine: string): Option[tuple[ix: int, eix: int]] =
    ## Compare the two log lines, skipping variable parts. If
    ## the expected line has a X in it, that character is skipped. If
    ## it has a *, zero or more characters are skipped.
    ## This simple regex is used instead of full regex so you don't
    ## have to escape all the special regex characters.

    #      got: 2020-10-01 08:21:28.618; statictea.nim(2652); version: 0.1.0"
    #                                                            ^
    # expected: XXXX-XX-XX XX:XX:XX.XXX; statictea.nim(X*); verzion: X*.X*.X*"
    #                                                          ^
    var eix = 0
    var ix = 0
    let logLineLen = logLine.len
    let eLogLineLen = eLogLine.len
    while true:
      if ix == logLineLen or eix == eLogLineLen:
        if ix != logLineLen or eix != eLogLineLen:
          return some((ix, eix))
        return
      var ch = logLine[ix]
      var eCh = eLogLine[eix]
      case eCh
      of 'X':
        discard
      of '*':
        # Get the next expected character and search for it in the
        # current position in the log line. If there is no next
        # expected character, we match everything to the end of the
        # line. When the expected character is found, go back to
        # normal matching.
        inc(eix)
        if eix == eLogLineLen:
          return # Match to the end of the line.
        eCh = eLogLine[eix]
        var pos = find(logLine, eCh, ix)
        if pos == -1:
          return some((ix, eix))
        ix = pos
      else:
        if ch != eCh:
          return some((ix, eix))
      inc(ix)
      inc(eix)

  proc compareLogLinesMatches*(logLines: seq[string], eLogLines: seq[string]): seq[int] =
    ## Compare the two sets of log lines, skipping variable parts. If
    ## the expected line has a X in it, that character is skipped. If
    ## it has a *, zero or more characters are skipped.  More actual
    ## lines may exist then expected lines. The expected lines must
    ## appear in order but there may be other lines around them.
    ## Return the indexes of the expected log lines that match.

    var start = 0
    for eix, eLogLine in eLogLines:
      if start == logLines.len:
        break
      for ix, logLine in logLines[start .. ^1]:
        let diffsO = compareLogLine(logLine, eLogLine)
        if not diffsO.isSome:
          result.add(eix)
          start = start + ix + 1
          break

  proc showLogLinesAndExpected*(logLines: seq[string], eLogLines: seq[string], matches: seq[int]) =
    echo "-------- logLines ---------"
    for logLine in logLines:
      echo "   line: " & logLine
    echo "-------- eLogLines ---------"
    for eix, eLogLine in eLogLines:
      if matches.contains(eix):
        echo "  found: " & eLogLine
      else:
        echo "missing: " & eLogLine

  proc compareLogLines*(logLines: seq[string], eLogLines: seq[string]): bool =
    var matches = compareLogLinesMatches(logLines, eLogLines)
    if matches.len == eLogLines.len:
      return true
    showLogLinesAndExpected(logLines, eLogLines, matches)

  proc openEnvTest*(logFilename: string, templateContent: string = ""): Env =
    ## Open the log, error, out, template and result streams. The
    ## given log file is used for the log stream.  The error, out,
    ## template and result streams get created as string type
    ## streams. The templateContent string is written to the
    ## templateStream. The env templateFilename is set to
    ## "template.html" and is only used for error messages.

    result = Env(
      errStream: newStringStream(), closeErrStream: true,
      outStream: newStringStream(), closeOutStream: true,
      templateFilename: "template.html",
    )
    openLogFile(result, logFilename)
    checkLogSize(result)

    result.templateStream = newStringStream(templateContent)
    result.closeTemplateStream = true

    result.resultStream = newStringStream()
    result.closeResultStream = true

  proc readCloseDeleteCompare*(env: var Env,
      eLogLines: seq[string] = @[],
      eErrLines: seq[string] = @[],
      eOutLines: seq[string] = @[],
      eTemplateLines: seq[string] = @[],
      eResultLines: seq[string] = @[]
    ): bool =
    ## Read the env streams and close and delete them. Compare the
    ## streams with the expected content. Return true when they are
    ## the same.
    result = true
    let (logLines, errLines, outLines, templateLines, resultLines) = env.readCloseDelete2()

    if not compareLogLines(logLines, eLogLines):
      result = false
    if not expectedItems("errLines", errLines, eErrLines):
      result = false
    if not expectedItems("outLines", outLines, eOutLines):
      result = false
    if not expectedItems("templateLines", templateLines, eTemplateLines):
      result = false
    if not expectedItems("resultLines", resultLines, eResultLines):
      result = false

  proc createFile*(filename: string, content: string) =
    var file = open(filename, fmWrite)
    file.write(content)
    file.close()
