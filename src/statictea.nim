## StaticTea; A template processor and language.

import std/strutils
import parseCommandLine
import processTemplate
import args
import messages
import gethelp
import version
import env
import opresultwarn
when isMainModule:
  import std/os
  import timer

proc processArgs(env: var Env, args: Args) =
  if args.help:
    env.writeOut(getHelp())
  elif args.version:
    env.writeOut(staticteaVersion)
  elif args.update:
    updateTemplateTop(env, args)
  elif args.templateFilename != "":
    processTemplateTop(env, args)
  else:
    # No template name. Use -h for help.
    env.warn(wNoTemplateName)

proc main*(env: var Env, argv: seq[string]) =
  ## Run statictea.

  # Parse the command line options.
  let argsOr = parseCommandLine(argv)
  if argsOr.isMessage:
    env.warn(argsOr.message)
    return
  let args = argsOr.value

  # Add the log file to the environment when it is turned on.
  if args.log:
    env.setupLogging(args.logFilename)

  env.log("Starting: argv: $1\n" % $argv)
  env.log("Version: $1\n" % staticteaVersion)

  # Setup control-c monitoring so ctrl-c stops the program.
  proc controlCHandler() {.noconv.} =
    quit 0
  setControlCHook(controlCHandler)

  try:
    processArgs(env, args)
  except:
    let msg = getCurrentExceptionMsg()
    env.log(msg & "\n")
    # Unexpected exception: '$1'.
    env.warn(wUnexpectedException)
    # Exception: '$1'.
    env.warn(wExceptionMsg, msg)
    # The stack trace is only available in the debug builds.
    when not defined(release):
      # Stack trace: '$1'.
      env.warn(wStackTrace, getCurrentException().getStackTrace())

when isMainModule:
  proc run(): int =
    var timer = newTimer()
    var env = openEnv()
    main(env, commandLineParams())
    env.log("Warnings: $1\n" % [$env.warningsWritten])
    if env.warningsWritten > 0:
      result = 1
    env.log("Duration: $1\n" % $timer.seconds())
    env.close()

  quit(if run() == 0: QuitSuccess else: QuitFailure)
