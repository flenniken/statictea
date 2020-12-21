import logenv
import streams
import warnings
import os
import strutils
import args
when defined(test):
  import options
  import regexes

const
  staticteaLog* = "statictea.log" ## \
  ## Name of the default statictea log file.

  logWarnSize: BiggestInt = 1024 * 1024 * 1024 ##/
   ## Warn the user when the log file gets big.

type
  Env* = object
    # These streams get set at the start.
    logEnv*: LogEnv
    errStream*: Stream
    outStream*: Stream

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
  env.logEnv.close()
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

template log*(env: var Env, message: string) =
  ## Append the message to the log file. The current file and line
  ## becomes part of the message.
  let info = instantiationInfo()
  env.logEnv.logLine(info.filename, info.line, message)

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
  let message = getWarning(filename, lineNum, warning, p1, p2)
  warn(env, message)

proc writeOut*(env: var Env, message: string) =
  ## Write a message to the output stream.
  env.outStream.writeLine(message)

proc checkLogSize(env: var Env) =
  ## Check the log file size and write a warning message when the file
  ## is big.
  let logSize = getFileSize(env.logEnv)
  if logSize > logWarnSize:
    let numStr = insertSep($logSize, ',')
    let line = get_warning("startup", 0, wBigLogFile, staticteaLog, numStr)
    env.log(line)
    env.warn(line)

proc openEnvTest*(logFilename: string): Env =
  ## Open the log, error, and out streams. The given log file is used.
  ## The error and out streams get created as a string type streams.

  var logEnv = openLogFile(logFilename)
  result = Env(
    logEnv: logEnv,
    errStream: newStringStream(), closeErrStream: true,
    outStream: newStringStream(), closeOutStream: true,
  )
  checkLogSize(result)

proc openEnv*(logFilename: string = staticteaLog, warnSize: BiggestInt
                 = logWarnSize): Env =
  ## Open the log, error, and out streams. The statictea.log file is
  ## used by default. Stderr and stdout are used for err and out
  ## streams.

  var logEnv = openLogFile(logFilename)
  result = Env(
    logEnv: logEnv,
    errStream: newFileStream(stderr),
    outStream: newFileStream(stdout),
  )
  checkLogSize(result)

proc addExtraStreams*(env: var Env, args: Args): bool =
  ## Add the template and result streams to the environment. Return
  ## true on success.

  # Get the template filename.
  assert args.templateList.len > 0
  if args.templateList.len > 1:
    let skipping = join(args.templateList[1..^1], ", ")
    env.warn(0, wOneTemplateAllowed, skipping)
  let templateFilename = args.templateList[0]

  # You can only call it once.
  assert env.templateFilename == ""
  assert env.templateStream == nil
  assert env.resultFilename == ""
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

  # Get the result filename.
  let resultFilename = args.resultFilename

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

when defined(test):
  # You treat string streams different than file streams. Once you
  # close a string stream the data is gone, so you need to read it
  # before and you need to set the position at the start.

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

  proc readAndClose(stream: Stream): seq[string] =
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
      result = (env.logEnv.closeReadDelete(20),
        env.errStream.readAndClose(), env.outStream.readAndClose())
      discard tryRemoveFile(env.logEnv.filename)

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

  template notReturn*(boolProc: untyped) =
    if not boolProc:
      return false

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

  proc expectedItems*[T](name: string, items: seq[T], expectedItems: seq[T]): bool =
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
