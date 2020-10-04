## StaticTea
## A template processor and language.
## See https://github.com/flenniken/statictea

import streams
import parseCommandLine
import strutils
import processTemplate
import logenv
import warnenv
import args
import warnings
import showhelp
import version
import tpub

# todo: put the log in the standard log location, ie /var/log.

const
  staticteaLog = "statictea.log" ## \
  ## Name of the default statictea log file.

  logWarnSize: BiggestInt = 1024 * 1024 * 1024 ##/
   ## Warn the user when the log file gets big.

proc processArgs(env: LogEnv, args: Args, stream: Stream): int =
  if args.help:
    result = showHelp(stream)
  elif args.version:
    stream.writeLine(staticteaVersion)
    result = 0
  elif args.update:
    echo "updateTemplate(args)"
  elif args.templateList.len > 0:
    result = processTemplate(args, stream)
  else:
    result = showHelp(stream)

proc main(env: var LogEnv, argv: seq[string], logWarnSize: BiggestInt,
          stream: Stream): int {.tpub.} =
  ## Run statictea.

  # Setup control-c monitoring so ctrl-c stops the program.
  proc controlCHandler() {.noconv.} =
    quit 0
  setControlCHook(controlCHandler)

  # Open the global warn stream.
  openWarnStream()

  # Process the command line args.
  let args = parseCommandLine(argv)

  env.log("----- starting -----")
  env.log("argv: $1" % $argv)
  env.log("version: " & staticteaVersion)
  let logSize = getFileSize(env)
  if logSize > logWarnSize:
    let numStr = insertSep($logSize, ',')
    let line = get_warning("startup", 0, wBigLogFile, staticteaLog, numStr)
    env.log(line)
    warn(line)

  try:
    result = processArgs(env, args, stream)
  except:
    result = 1
    let msg = getCurrentExceptionMsg()
    env.log(msg)
    warn("error exit", 0, wUnexpectedException)
    warn("error exit", 0, wExceptionMsg, msg)
    # The stack trace is only available in the debug builds.
    when not defined(release):
      warn("exiting", 0, wStackTrace, getCurrentException().getStackTrace())
  env.log("Done")

when isMainModule:
  var rc: int
  try:
    var stream = newFileStream(stdout)
    # todo: always log!
    var env = openLogFile(staticteaLog)
    rc = main(env, commandLineParams(), staticteaLog, logWarnSize, stream)
    env.close()
    closeWarnStream()
  except:
    echo getCurrentExceptionMsg()
    rc = 1

  quit(if rc == 0: QuitSuccess else: QuitFailure)
