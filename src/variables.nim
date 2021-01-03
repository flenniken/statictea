
import env
import args
import vartypes
import readjson
import tables
import options

type
  Variables* = object
    server*: VarsDict
    shared*: VarsDict
    local*: VarsDict
    global*: VarsDict
    tea*: VarsDict

proc getNamespaceDict*(variables: Variables, nameSpace: string): Option[VarsDict] =
  case nameSpace:
    of "":
      result = some(variables.local)
    of "s.":
      result = some(variables.server)
    of "h.":
      result = some(variables.shared)
    of "g.":
      result = some(variables.global)
    of "t.":
      result = some(variables.tea)
    else:
      discard

proc getVariable*(variables: Variables, namespace: string, varName:
                  string): Option[Value] =
  ## Look up the variable and return its value.

  let dictO = getNamespaceDict(variables, namespace)
  if isSome(dictO):
    let dict = dictO.get()
    if varName in dict:
      result = some(dict[varName])

proc getTeaVarInt*(variables: Variables, varName: string): int64 =
  ## Return the int value of one of the tea dictionary integer items.
  assert varName in ["row", "repeat", "maxRepeat", "maxLines"]
  let value = variables.tea[varName]
  assert value.kind == vkInt
  result = value.intv

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

proc setInitialVariables*(variables: var Variables) =
  ## Set the variable dictionaries to their initial state before
  ## running a command.
  variables.tea["output"] = Value(kind: vkString, stringv: "result")
  variables.tea["repeat"] = Value(kind: vkInt, intv: 1)
  variables.tea["maxLines"] = Value(kind: vkInt, intv: 10)
  variables.tea["maxRepeat"] = Value(kind: vkInt, intv: 100)
  # The row variable is handled at a higher scope.
  # variables.tea["row"] = Value(kind: vkInt, intv: 0)
  variables.tea.del("content")
  variables.local.clear()

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

    setInitialVariables(result)

    result.server["test"] = Value(kind: vkString, stringv: "hello")
    result.shared["test"] = Value(kind: vkString, stringv: "there")
    result.local["five"] = Value(kind: vkInt, intv: 5)
    result.tea["five"] = Value(kind: vkInt, intv: 5)
    result.global["aboutfive"] = Value(kind: vkFloat, floatv: 5.11)

