## Environment holding the input and output streams.

import streams
import warnings
import os
import strutils
import args
import times
import sets
import tempfile
import options
when defined(test):
  import readlines

# todo: os.sameFile(path1, path2: string) returns whether the to paths refer to the same file.

const
  logWarnSize: BiggestInt = 1024 * 1024 * 1024
    ## Warn the user when the log file gets over 1 GB.

  dtFormat* = "yyyy-MM-dd HH:mm:ss'.'fff"
    ## The date time format in local time written to the log.

when hostOS == "macosx":
  let staticteaLog* = expandTilde("~/Library/Logs/statictea.log")
    ## Name of the default statictea log file when logging.
else:
  let staticteaLog* = expandTilde("~/statictea.log")
    ## Name of the default statictea log file when logging.

type
  Env* = object
    ## Object holding the input and output streams.
    # These get set at the start.
    errStream*: Stream ## stderr
    outStream*: Stream ## stdout
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
      ## The result stream may be stdout.

    warningWritten*: Natural
      ## Count of warnings written.
    oneWarnTable*: HashSet[string]
      ## All unique messages written.

proc close*(env: var Env) =
  ## Close the environment streams.
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
  ## Write a message to the error stream. Duplicates are suppressed and
  ## the environment's warning count is incremented.
  if not env.oneWarnTable.containsOrIncl(message):
    env.errStream.writeLine(message)
  # else:
  #   env.errStream.writeLine("dup: " & message)
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

proc warn*(env: var Env, lineNum: Natural, warningData: WarningData) =
  ## Write a formatted warning message to the error stream.
  warn(env, lineNum, warningData.warning, warningData.p1, warningData.p2)

func formatDateTime*(dt: DateTime): string =
  ## Return a formatted time stamp for the log.
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
  ## Open the log file and update the environment. If the log file
  ## cannot be opened, a warning is output and the environment is
  ## unchanged.
  var file: File
  if open(file, logFilename, fmAppend):
    env.logFile = file
    env.logFilename = logFilename
  else:
    env.warn(0, wUnableToOpenLogFile, logFilename)

proc openEnv*(logFilename: string = "",
                  warnSize: BiggestInt = logWarnSize): Env =
  ## Open and return the environment containing standard error and
  ## standard out as streams.

  result = Env(
    errStream: newFileStream(stderr),
    outStream: newFileStream(stdout),
  )

proc setupLogging*(env: var Env, logFilename: string = "",
                  warnSize: BiggestInt = logWarnSize) =
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

# todo: test the case where the template file is the same as the result file.
# todo: test where a resultFilename is specified with update.
# todo: test update with two template filenames.
# todo: test with template of "stdin" when update is specified.
# todo: test update when the template is readonly.j

proc addExtraStreamsForUpdate*(env: var Env, args: Args): bool =
  ## For the update case, add the template and result streams to the
  ## environment. Return true on success.

  # Warn and exit when a resultFilename is specified.
  if args.resultFilename != "":
    env.warn(0, wResultFileNotAllowed)
    return false

  # Get the template filename.
  assert args.templateList.len > 0
  if args.templateList.len > 1:
    let skipping = join(args.templateList[1..^1], ", ")
    env.warn(0, wOneTemplateAllowed, skipping)
  let templateFilename = args.templateList[0]

  # If you specify "stdin" for the template, the template comes from
  # stdin and the output goes to standard out.
  var resultFilename: string
  if templateFilename != "stdin":
    # Create a temp file for the result.  Rename it to the template
    # filename at the end.
    var tempFileO = openTempFile()
    if not tempFileO.isSome():
      env.warn(0, wUnableToOpenTempFile)
      return false
    var tempFile = tempFileO.get()
    tempFile.file.close()
    resultFilename = tempFile.filename

  result = addExtraStreams(env, templateFilename, resultFilename)

when defined(test):
  proc createFile*(filename: string, content: string) =
    ## Create a file with the given content.
    var file = open(filename, fmWrite)
    file.write(content)
    file.close()

  proc splitNewLines*(content: string): seq[string] =
    ## Split lines and keep the line endings. Works with \n and \r\n
    ## type endings.
    if content.len == 0:
      return
    var start = 0
    for pos in 0 ..< content.len:
      let ch = content[pos]
      if ch == '\n':
        result.add(content[start .. pos])
        start = pos+1
    if start < content.len:
      result.add(content[start ..< content.len])

  proc echoNewline*(str: string) =
    ## Print a line to the screen and display the line endings as \n
    ## or \r\n.
    var newstr = str.replace("\r\n", r"\r\n")
    echo newstr.replace("\n", r"\n")

  proc closeReadDeleteLog*(env: var Env, maximum: Natural = high(Natural)): seq[string] =
    ## Close the log file, read its lines, then delete the
    ## file. Return the lines read but don't read more than maximum
    ## lines. Lines contain the line endings.
    if env.logFile != nil:
      env.logFile.close()
      env.logFile = nil
      result = readXLines(env.logFilename, maximum)
      discard tryRemoveFile(env.logFilename)

  # A string stream content disappears when you close it where as a
  # file's content still exists on disk. To work with both types of
  # streams you need to read the content before closing and you need
  # to set the stream position to the start to read all the content.

  proc readAndClose*(stream: Stream): seq[string] =
    ## Read and return all the lines including line endings from the
    ## stream then close it.
    result = readXLines(stream)
    stream.close()

  proc readCloseDeleteEnv*(env: var Env): tuple[
      logLines: seq[string],
      errLines: seq[string],
      outLines: seq[string],
      resultLines: seq[string],
      templateLines: seq[string]] =
    ## Read the env's streams, then close and delete them. Return the
    ## streams content.

    result.logLines = env.closeReadDeleteLog(100)
    if env.closeErrStream:
      result.errLines = env.errStream.readAndClose()
    if env.closeOutStream:
      result.outLines = env.outStream.readAndClose()
    if env.closeResultStream:
      result.resultLines = env.resultStream.readAndClose()
    if env.closeTemplateStream:
      result.templateLines = env.templateStream.readAndClose()
      discard tryRemoveFile(env.templateFilename)


  proc expectedItem*[T](name: string, item: T, expectedItem: T): bool =
    ## Compare the item with the expected item and show them when
    ## different. Return true when they are the same.

    if item == expectedItem:
      result = true
    else:
      echo "$1" % name
      echoNewline "     got: $1" % $item
      echoNewline "expected: $1" % $expectedItem
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
          echoNewline $item
        echo "~~~~~~ expected $1 ($2)~~~~~~:" % [name, $expectedItems.len]
        for item in expectedItems:
          echoNewline $item
      else:
        echo "~~~~~~~~~~ $1 ~~~~~~~~~~~:" % name
        for ix in 0 ..< items.len:
          if items[ix] == expectedItems[ix]:
            echoNewline "$1 (same):      got: $2" % [$ix, $items[ix]]
            echoNewline "$1 (same): expected: $2" % [$ix, $expectedItems[ix]]
          else:
            echoNewline "$1       :      got: $2" % [$ix, $items[ix]]
            echoNewline "$1       : expected: $2" % [$ix, $expectedItems[ix]]
      result = false

  proc compareLogLine*(logLine: string, eLogLine: string): Option[tuple[ix: int, eix: int]] =
    ## Compare the two log lines, skipping variable parts. If they
    ## differ, return the position in each line where they differ. If
    ## the expected line has a X in it, that character is skipped. If
    ## it has a *, zero or more characters are skipped.  This simple
    ## regex is used instead of full regex so you don't have to escape
    ## all the special regex characters.

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
    ## Show the log lines and expected log lines. The matches list
    ## contains the indexes of the expected log lines that match.
    echo "-------- logLines ---------"
    for logLine in logLines:
      echoNewLine "   line: " & logLine
    echo "-------- eLogLines ---------"
    for eix, eLogLine in eLogLines:
      if matches.contains(eix):
        echoNewLine "  found: " & eLogLine
      else:
        echoNewLine "missing: " & eLogLine

  proc compareLogLines*(logLines: seq[string], eLogLines: seq[string]): bool =
    ## Compare the log lines with the expected log lines and when
    ## different show the differences. Each expected line must match
    ## the log lines and in the correct order, but other log lines are
    ## ignored. Expected log lines can use X and * to skip variable
    ## content.
    var matches = compareLogLinesMatches(logLines, eLogLines)
    if matches.len == eLogLines.len:
      return true
    showLogLinesAndExpected(logLines, eLogLines, matches)

  proc openEnvTest*(logFilename: string, templateContent: string = ""): Env =
    ## Return an Env object with open log, error, out, template and
    ## result streams. The given log file is used for the log
    ## stream. A template file is created from the template content.
    ## The error, out, and result streams get created as string type
    ## streams.

    var templateFilename = "template.html"
    createFile(templateFilename, templateContent)
    let templateStream = newFileStream(templateFilename, fmRead)
    assert templateStream != nil

    result = Env(
      errStream: newStringStream(), closeErrStream: true,
      outStream: newStringStream(), closeOutStream: true,
      templateFilename: templateFilename,
      templateStream: templateStream,
      closeTemplateStream: true,
    )
    openLogFile(result, logFilename)
    checkLogSize(result)

    result.resultStream = newStringStream()
    result.closeResultStream = true

  proc readCloseDeleteCompare*(env: var Env,
      eLogLines: seq[string] = @[],
      eErrLines: seq[string] = @[],
      eOutLines: seq[string] = @[],
      eResultLines: seq[string] = @[],
      eTemplateLines: seq[string] = @[],
      showLog: bool = false
    ): bool =
    ## Read the env streams then close and delete them. Compare the
    ## streams with the expected content. Return true when they are
    ## the same. For the log lines compare verifies that all the
    ## expected lines compare and ignores the other lines that may
    ## exist. The template lines are ignored when eTemplateLines is
    ## not set.
    result = true
    let (logLines, errLines, outLines, resultLines, templateLines) = env.readCloseDeleteEnv()

    if showLog:
      echo "------- log lines:"
      echo logLines
      echo "-------"

    if not compareLogLines(logLines, eLogLines):
      result = false
    if not expectedItems("errLines", errLines, eErrLines):
      result = false
    if not expectedItems("outLines", outLines, eOutLines):
      result = false
    if not expectedItems("resultLines", resultLines, eResultLines):
      result = false

    if eTemplateLines.len > 0:
      if not expectedItems("templateLines", templateLines, eTemplateLines):
        result = false
