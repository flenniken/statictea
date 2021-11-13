## StaticTea; A template processor and language.

import std/strutils
import parseCommandLine
import processTemplate
import args
import messages
import gethelp
import version
import env
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
  elif args.templateList.len > 0:
    result = processTemplateTop(env, args)
  else:
    env.warn(0, wNoTemplateName)

proc main*(env: var Env, argv: seq[string]): int =
  ## Run statictea. Return 0 when no warning messages were written.

  # Parse the command line options.
  let argsOrWarning = parseCommandLine(argv)
  if argsOrWarning.kind == awWarning:
    env.warn(0, argsOrWarning.warningData)
    return 1
  let args = argsOrWarning.args

  # Add the log file to the environment when it is turned on.
  if args.log:
    env.setupLogging(args.logFilename)

  env.log("Starting: argv: $1" % $argv)
  env.log("Version: " & staticteaVersion)

  # Setup control-c monitoring so ctrl-c stops the program.
  proc controlCHandler() {.noconv.} =
    quit 0
  setControlCHook(controlCHandler)

  try:
    result = processArgs(env, args)
  except:
    result = 1
    let msg = getCurrentExceptionMsg()
    env.log(msg)
    env.warn(0, wUnexpectedException)
    env.warn(0, wExceptionMsg, msg)
    # The stack trace is only available in the debug builds.
    when not defined(release):
      env.warn(0, wStackTrace, getCurrentException().getStackTrace())

when isMainModule:
  proc run(): int =
    var env = openEnv()
    result = main(env, commandLineParams())
    env.log("Warnings: $1" % [$env.warningWritten])
    if result == 0 and env.warningWritten > 0:
      result = 1
    env.log("Return code: $1" % [$result])
    env.log("Done")
    env.close()

  quit(if run() == 0: QuitSuccess else: QuitFailure)
