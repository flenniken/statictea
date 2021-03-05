## StaticTea
## A template processor and language.
## See httpss://github.com/flenniken/statictea

import parseCommandLine
import strutils
import processTemplate
import args
import warnings
import showhelp
import version
import tpub
import env
when isMainModule:
  import os

# todo: log the return code
# todo: log how many warnings were output.
# todo: invalid statement skipping it -- remove this line
# todo: create new dictionary with a function.
# todo: create new list with a function.
# todo: add a third option for the find function which is the value to return when not found.

proc processArgs(env: var Env, args: Args): int =
  if args.help:
    result = showHelp(env)
  elif args.version:
    env.writeOut(staticteaVersion)
    result = 0
  elif args.update:
    result = updateTemplateTop(env, args)
  elif args.templateList.len > 0:
    result = processTemplateTop(env, args)
  else:
    env.warn(0, wNoTemplateName)

proc main(env: var Env, argv: seq[string]): int {.tpub.} =
  ## Run statictea. Return 0 when no warning messages were written.

  # Parse the command line options.
  let args = parseCommandLine(env, argv)

  # Add the log file to the environment when it is turned on.
  if args.log:
    env.setupLogging(args.logFilename)

  env.log("Starting: argv: $1" % $argv)
  env.log("version: " & staticteaVersion)

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
  env.log("Done")

when isMainModule:
  proc run(): int =
    var env = openEnv()
    result = main(env, commandLineParams())
    env.close()

  quit(if run() == 0: QuitSuccess else: QuitFailure)
