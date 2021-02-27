## StaticTea
## A template processor and language.
## See https://github.com/flenniken/statictea

import parseCommandLine
import strutils
import processTemplate
import args
import warnings
import showhelp
import version
import tpub
import env
when not defined(Test):
  import os

# todo: put the log in the standard log location, ie /var/log.

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
    env.writeOut("No template name. Use -h for help.")

proc main(env: var Env, argv: seq[string]): int {.tpub.} =
  ## Run statictea. Return 0 when no warning messages were written.

  env.log("----- starting -----")
  env.log("argv: $1" % $argv)
  env.log("version: " & staticteaVersion)

  # Setup control-c monitoring so ctrl-c stops the program.
  proc controlCHandler() {.noconv.} =
    quit 0
  setControlCHook(controlCHandler)

  # Process the command line args.
  let args = parseCommandLine(env, argv)

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
  var rc: int
  try:
    var env = openEnv()
    rc = main(env, commandLineParams())
    env.close()
  except:
    echo getCurrentExceptionMsg()
    rc = 1

  quit(if rc == 0: QuitSuccess else: QuitFailure)
