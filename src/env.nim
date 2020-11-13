import logenv
import streams
import warnings
import os
import strutils

# todo: count the number of warnings written to errStream.

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
    warningWritten*: bool
    closeStreams: bool

proc close*(env: var Env) =
  env.logEnv.close()
  if env.closeStreams:
    env.errStream.close()
    env.outStream.close()

template log*(env: var Env, message: string) =
  ## Append the message to the log file. The current file and line
  ## becomes part of the message.
  let info = instantiationInfo()
  env.logEnv.logLine(info.filename, info.line, message)

proc warn*(env: var Env, filename: string, lineNum: int, warning: Warning,
           p1: string = "", p2: string = "") =
  warn(env.errStream, filename, lineNum, warning, p1, p2)

proc warn*(env: var Env, message: string) =
  env.errStream.writeLine(message)
  env.warningWritten = true

proc writeOut*(env: var Env, message: string) =
  env.outStream.writeLine(message)

proc checkLogSize(env: var Env) =
  let logSize = getFileSize(env.logEnv)
  if logSize > logWarnSize:
    let numStr = insertSep($logSize, ',')
    let line = get_warning("startup", 0, wBigLogFile, staticteaLog, numStr)
    env.log(line)
    env.warn(line)

proc openEnv*(filename: string="", warnSize: BiggestInt=logWarnSize): Env =

  var name: string
  var closeStreams: bool
  var err: Stream
  var output: Stream
  if filename == "":
    name = staticteaLog
    err = newFileStream(stderr)
    output = newFileStream(stdout)
    closeStreams = false
  else:
    name = filename
    err = newStringStream()
    output = newStringStream()
    closeStreams = true

  var log = openLogFile(name)
  result = Env(logEnv: log, errStream: err, outStream: output,
               closeStreams: closeStreams)
  checkLogSize(result)

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
