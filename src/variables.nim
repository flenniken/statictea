
import env
import args
import vartypes
import readjson

type
  Variables* = object
    server*: VarsDict
    shared*: VarsDict
    local*: VarsDict
    global*: VarsDict
    tea*: VarsDict

proc readJsonVariables*(env: var Env, args: Args): Variables =
  ## Read the server and shared json files and return their variables.

  # Read the server json.
  result.server = getEmptyVars()
  for filename in args.serverList:
    readJson(env, filename, result.server)

  # Read the shared json.
  result.shared = getEmptyVars()
  for filename in args.sharedList:
    readJson(env, filename, result.shared)
