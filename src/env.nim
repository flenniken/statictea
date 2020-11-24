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
    logEnv*: LogEnv
    errStream*: Stream
    outStream*: Stream
    warningWritten*: Natural
    closeStreams: bool
    templateFilename*: string
    templateStream*: Stream
    resultFilename*: string
    resultStream*: Stream

proc closeExtraStreams*(env: var Env) =
  ## Close the template and result streams.
  # A resultFilename of "" means stdout, don't close it.
  if env.resultFilename != "" and env.resultStream != nil:
    env.resultStream.close()
    env.resultStream = nil
  if env.templateFilename != "stdin" and env.templateStream != nil:
    env.templateStream.close()
    env.templateStream = nil

proc close*(env: var Env) =
  env.logEnv.close()
  if env.closeStreams:
    env.errStream.close()
    env.outStream.close()
  env.closeExtraStreams()

template log*(env: var Env, message: string) =
  ## Append the message to the log file. The current file and line
  ## becomes part of the message.
  let info = instantiationInfo()
  env.logEnv.logLine(info.filename, info.line, message)

proc warn(env: var Env, message: string) =
  env.errStream.writeLine(message)
  inc(env.warningWritten)

proc warn*(env: var Env, filename: string, lineNum: int, warning: Warning,
           p1: string = "", p2: string = "") =
  let message = getWarning(filename, lineNum, warning, p1, p2)
  warn(env, message)

proc writeOut*(env: var Env, message: string) =
  env.outStream.writeLine(message)

proc checkLogSize(env: var Env) =
  let logSize = getFileSize(env.logEnv)
  if logSize > logWarnSize:
    let numStr = insertSep($logSize, ',')
    let line = get_warning("startup", 0, wBigLogFile, staticteaLog, numStr)
    env.log(line)
    env.warn(line)

proc openEnv*(logFilename: string="", warnSize: BiggestInt=logWarnSize): Env =

  var logName: string
  var closeStreams: bool
  var errStream: Stream
  var outStream: Stream
  if logFilename == "":
    logName = staticteaLog
    errStream = newFileStream(stderr)
    outStream = newFileStream(stdout)
    closeStreams = false
  else:
    logName = logFilename
    errStream = newStringStream()
    outStream = newStringStream()
    closeStreams = true

  var log = openLogFile(logName)
  result = Env(logEnv: log, errStream: errStream, outStream: outStream,
               closeStreams: closeStreams)
  checkLogSize(result)

proc addExtraStreams*(env: var Env, args: Args): bool =
  ## Add the template and result streams to the environment. Return
  ## true on success.

  assert env.templateFilename == ""
  assert env.templateStream == nil
  assert env.resultFilename == ""
  assert env.resultStream == nil

  # Get the template filename.
  assert args.templateList.len > 0
  if args.templateList.len > 1:
    let skipping = join(args.templateList[1..^1], ", ")
    env.warn("starting", 0, wOneTemplateAllowed, skipping)
  env.templateFilename = args.templateList[0]

  # Open the template stream.
  if env.templateFilename == "stdin":
    env.templateStream = newFileStream(stdin)
    if env.templateStream == nil:
      env.warn("startup", 0, wCannotOpenStd, "stdin")
      return
  else:
    if not fileExists(env.templateFilename):
      env.warn("startup", 0, wFileNotFound, env.templateFilename)
      return
    env.templateStream = newFileStream(env.templateFilename, fmRead)
    if env.templateStream == nil:
      env.warn("startup", 0, wUnableToOpenFile, env.templateFilename)
      return

  # Open the result stream.
  if args.resultFilename == "":
    env.resultStream = env.outStream
  else:
    env.resultStream = newFileStream(args.resultFilename, fmWrite)
    if env.resultStream == nil:
      env.warn("startup", 0, wUnableToOpenFile, args.resultFilename)
      return
    env.resultFilename = args.resultFilename
  result = true

when defined(test):
  proc readAndClose(stream: Stream): seq[string] =
    stream.setPosition(0)
    for line in stream.lines():
      result.add line
    stream.close()

  proc readCloseDelete*(env: var Env): tuple[logLine: seq[string],
      errLines: seq[string], outLines: seq[string]] =
    if not env.closeStreams:
      return
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
            echo "$1: same" % [$ix]
          else:
            echo "$1:      got: $2" % [$ix, $items[ix]]
            echo "$1: expected: $2" % [$ix, $expectedItems[ix]]
      result = false

  proc testSome*[T](valueO: Option[T], eValueO: Option[T],
      text: string, start: Natural): bool =

    if valueO == eValueO:
      return true

    echo "Did not get the expected value."
    echo "     got: $1" % $valueO
    echo "expected: $1" % $eValueO
    echo " text: $1" % text
    echo "start: $1" % startPointer(start)
