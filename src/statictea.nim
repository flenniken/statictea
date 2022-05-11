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

proc processArgs(env: var Env, args: Args): int =
  if args.help:
    env.writeOut(getHelp())
    result = 0
  elif args.version:
    env.writeOut(staticteaVersion)
    result = 0
  elif args.update:
    result = updateTemplateTop(env, args)
  elif args.templateFilename != "":
    result = processTemplateTop(env, args)
  else:
    # todo: is this possible to hit?
    env.warn(0, wNoTemplateName)

proc main*(env: var Env, argv: seq[string]): int =
  ## Run statictea. Return 0 when no warning messages were written.

  # Parse the command line options.
  let argsOr = parseCommandLine(argv)
  if argsOr.isMessage:
    env.warn(0, argsOr.message)
    return 1
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
    result = processArgs(env, args)
  except:
    result = 1
    let msg = getCurrentExceptionMsg()
    env.log(msg & "\n")
    env.warn(0, wUnexpectedException)
    env.warn(0, wExceptionMsg, msg)
    # The stack trace is only available in the debug builds.
    when not defined(release):
      env.warn(0, wStackTrace, getCurrentException().getStackTrace())

when isMainModule:
  proc run(): int =
    var env = openEnv()
    result = main(env, commandLineParams())
    env.log("Warnings: $1\n" % [$env.warningsWritten])
    if result == 0 and env.warningsWritten > 0:
      result = 1
    env.log("Return code: $1\n" % [$result])
    env.log("Done\n")
    env.close()

  quit(if run() == 0: QuitSuccess else: QuitFailure)
