## StaticTea
## A template processor and language.
## See https://github.com/flenniken/statictea

# import streams
import parseCommandLine
import strutils
import processTemplate
import logenv
import warnenv
import args
import warnings
import showhelp
import os
import version
# import limits
import tpub

var logSizeWarning*: BiggestInt = 1024 * 1024 * 1024 ##/
 ## Warn the user when the log file gets big.

const
  staticteaLog* = "statictea.log" ## \
  ## Name of the default statictea log file.

proc processArgs(args: Args): int =
  if args.help:
    result = showHelp()
  elif args.version:
    echo staticteaVersion
    result = 0
  elif args.update:
    echo "updateTemplate(args)"
  elif args.templateList.len > 0:
    result = processTemplate(args)
  else:
    result = showHelp()

proc main(): int {.tpub.} =
  ## Run statictea.

  # Setup control-c monitoring so ctrl-c stops the program.
  proc controlCHandler() {.noconv.} =
    quit 0
  setControlCHook(controlCHandler)

  # Open the global warn stream.
  openWarnStream()

  # Process the command line args.
  let args = parseCommandLine()

  # Open the global statictea.log file when logging is turned on.
  var logSize: BiggestInt = 0
  if not args.nolog:
    # todo: put the log in the system standard log location.
    logSize = getFileSize(statictealog)
    openLogFile(staticteaLog)

  # We go through the motions of logging even when logging is turned
  # off so the logging code gets exercised.
  log("----- starting -----")
  log("Cmdline: $1" % $commandLineParams())
  log($args)
  log(staticteaVersion)
  if logSize > logSizeWarning:
    let numStr = insertSep($logSize, ',')
    let line = get_warning("startup", 0, wBigLogFile, numStr)
    log(line)
    warn(line)

  try:
    result = processArgs(args)
  except:
    result = 1
    let msg = getCurrentExceptionMsg()
    log(msg)
    warn("error exit", 0, wUnexpectedException)
    warn("error exit", 0, wExceptionMsg, msg)
    # The stack trace is only available in the debug builds.
    when not defined(release):
      warn("exiting", 0, wStackTrace, getCurrentException().getStackTrace())

  log("Done")
  closeLogFile()
  closeWarnStream()

when isMainModule:
  var rc: int
  try:
    rc = main()
  except:
    echo getCurrentExceptionMsg()
    rc = 1

  quit(if rc == 0: QuitSuccess else: QuitFailure)
