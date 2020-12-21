
import env
import args
import vartypes
import readjson
import tables

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

when defined(test):
  func newVariables*(): Variables =
    return

  func getTestVariables*(): Variables =
    # s.test = "hello"
    # h.test = "there"
    # five = 5
    # t.five = 5
    # g.aboutfive = 5.11
    result = newVariables()
    result.server["test"] = Value(kind: vkString, stringv: "hello")
    result.shared["test"] = Value(kind: vkString, stringv: "there")
    result.local["five"] = Value(kind: vkInt, intv: 5)
    result.tea["five"] = Value(kind: vkInt, intv: 5)
    result.global["aboutfive"] = Value(kind: vkFloat, floatv: 5.11)

