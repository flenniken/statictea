
import env
import args
import vartypes
import readjson
import tables
import options
import version

type
  Variables* = VarsDict

proc getNamespaceDict*(variables: Variables, nameSpace: string): Option[VarsDict] =
  ## Get the dictionary for the given namespace.
  case nameSpace:
    of "":
      result = some(variables["local"].dictv)
    of "s.":
      result = some(variables["server"].dictv)
    of "h.":
      result = some(variables["shared"].dictv)
    of "g.":
      result = some(variables["global"].dictv)
    of "t.":
      result = some(variables)
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
  let value = variables[varName]
  assert value.kind == vkInt
  result = value.intv

proc getTeaVarString*(variables: Variables, varName: string): string =
  ## Return the string value of one of the tea dictionary string items.
  assert varName in ["output"]
  let value = variables[varName]
  assert value.kind == vkString
  result = value.stringv

proc readServerVariables*(env: var Env, args: Args): VarsDict =
  ## Read the server json.
  result = getEmptyVars()
  for filename in args.serverList:
    readJson(env, filename, result)

proc readSharedVariables*(env: var Env, args: Args): VarsDict =
  ## Read the shared json.
  result = getEmptyVars()
  for filename in args.sharedList:
    readJson(env, filename, result)

proc resetVariables*(variables: var Variables) =
  ## Clear the local variables and reset the tea variables for running
  ## a command.
  var varsDict: VarsDict
  variables["output"] = newValue("result")
  variables["repeat"] = newValue(1)
  variables["maxLines"] = newValue(10)
  variables["maxRepeat"] = newValue(100)
  variables.del("content")
  variables["local"] = newValue(varsDict)

proc newVariables*(server: VarsDict = newVarsDict(), shared: VarsDict = newVarsDict()): Variables =
  ## Create the "tea" variables in their initial state.
  var varsDict: VarsDict
  # todo: can we move the dictionary instead of copy it? Does it
  # matter here?
  result["server"] = newValue(server)
  result["shared"] = newValue(shared)
  result["global"] = newValue(varsDict)
  result["row"] = newValue(0)
  result["version"] = newValue(staticteaVersion)
  resetVariables(result)

when defined(test):
  func getTestVariables*(): Variables =
    # s.test = "hello"
    # h.test = "there"
    # five = 5
    # t.five = 5
    # g.aboutfive = 5.11
    result = newVariables()
    result["server"].dictv["test"] = Value(kind: vkString, stringv: "hello")
    result["shared"].dictv["test"] = Value(kind: vkString, stringv: "there")
    result["local"].dictv["five"] = Value(kind: vkInt, intv: 5)
    result["five"] = Value(kind: vkInt, intv: 5)
    result["global"].dictv["aboutfive"] = Value(kind: vkFloat, floatv: 5.11)

  proc echoVariables*(variables: Variables) =
    echo "---tea variables:"
    for k, v in variables.pairs():
      echo k, ": ", $v
    echo "---server variables:"
    for k, v in variables["server"].dictv.pairs():
      echo k, ": ", $v
    echo "---shared variables:"
    for k, v in variables["shared"].dictv.pairs():
      echo k, ": ", $v
    echo "---local variables:"
    for k, v in variables["local"].dictv.pairs():
      echo k, ": ", $v
    echo "---global variables:"
    for k, v in variables["global"].dictv.pairs():
      echo k, ": ", $v
