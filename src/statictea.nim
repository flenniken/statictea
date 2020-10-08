## StaticTea
## A template processor and language.
## See https://github.com/flenniken/statictea

import parseCommandLine
import strutils
import processTemplate
import logenv
import args
import warnings
import showhelp
import version
import tpub
import env
import os

# todo: put the log in the standard log location, ie /var/log.

proc processArgs(env: Env, args: Args): int =
  if args.help:
    result = showHelp(env)
  elif args.version:
    env.writeOut(staticteaVersion)
    result = 0
  elif args.update:
    echo "updateTemplate(args)"
  elif args.templateList.len > 0:
    result = processTemplate(env, args)
  else:
    env.writeOut("No template name. Use -h for help.")

proc main(env: var Env, argv: seq[string]): int {.tpub.} =
  ## Run statictea.

  env.log("----- starting -----")
  env.log("argv: $1" % $argv)
  env.log("version: " & staticteaVersion)

  # Setup control-c monitoring so ctrl-c stops the program.
  proc controlCHandler() {.noconv.} =
    quit 0
  setControlCHook(controlCHandler)

  # Process the command line args.
  let args = parseCommandLine(argv)

  try:
    result = processArgs(env, args)
  except:
    result = 1
    let msg = getCurrentExceptionMsg()
    env.log(msg)
    env.warn("error exit", 0, wUnexpectedException)
    env.warn("error exit", 0, wExceptionMsg, msg)
    # The stack trace is only available in the debug builds.
    when not defined(release):
      env.warn("exiting", 0, wStackTrace, getCurrentException().getStackTrace())
  env.log("Done")

when isMainModule:
  var rc: int
  try:
    var env = openEnv()
    rc = main(env, commandLineParams())
    env.close()
  except:
    echo getCurrentExceptionMsg()
    rc = 1

  quit(if rc == 0: QuitSuccess else: QuitFailure)
