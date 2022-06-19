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
  ## Run the option specified.
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
    env.warnNoFile(wNoTemplateName)

proc main*(env: var Env, argv: seq[string]) =
  ## Run statictea.

  # Parse the command line options.
  let argsOr = parseCommandLine(argv)
  if argsOr.isMessage:
    env.warnNoFile(argsOr.message)
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
    env.warnNoFile(wUnexpectedException, msg)
    when not defined(release):
      # The stack trace is only available in the debug builds.
      # Stack trace: '$1'.
      env.warnNoFile(wStackTrace, getCurrentException().getStackTrace())

when isMainModule:
  block:
    var timer = newTimer()
    var env = openEnv()
    main(env, commandLineParams())
    let rc = if env.warningsWritten > 0: QuitFailure else: QuitSuccess
    env.log("Warnings: $1\n" % [$env.warningsWritten])
    env.log("Duration: $1\n" % $timer.seconds())
    env.close()
    quit(rc)
