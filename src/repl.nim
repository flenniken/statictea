## Run commands at a prompt.
## Run evaluate print loop (REPL).

import std/rdstdin
import std/tables
import std/options
import std/strutils
import std/strformat
import messages
import env
import vartypes
import args
import opresult
import startingvars
import matches
import regexes
import runCommand
import variables
import unicodes
import functions

func showVariables(variables: Variables): string =
  ## Show the number of variables in the one letter dictionaries.
  var first = true
  for key, d in variables.pairs():
    if not first:
      result.add(" ")
    first = false
    if d.dictv.dict.len == 0:
      result.add("$1={}" % key)
    else:
      result.add("$1={$2}" % [key, $d.dictv.dict.len])

proc replHelp(): string =
  result = """
You enter statements or commands at the prompt.

Available commands:
* h — this help text
* p variable — print a variable as dot names
* ph func variable — print function's doc comment
* pj variable — print a variable as json
* pr variable — print a variable like in a replacement block
* v — show the number of top variables in the top level dictionaries
* q — quit"""

proc errorAndColumn(env: var Env, messageId: MessageId, line: string,
    runningPos: Natural, p1 = "") =
  env.writeErr(line)
  env.writeErr(startColumn(line, runningPos))
  env.writeErr(getWarning(messageId, p1))

func getDocComment(funcVar: Value): string =
  ## Get the function's doc comment.
  assert funcVar.kind == vkFunc
  let functionSpec = funcVar.funcv
  result = functionSpec.docComment

proc handleReplLine*(env: var Env, variables: var Variables, line: string): bool =
  ## Handle the REPL line. Return true to end the loop.
  if emptyOrSpaces(line, 0):
    return false

  var runningPos = 0
  let replCmdO = matchReplCmd(line, runningPos)
  if not replCmdO.isSome:

    # Run the statement and add to the variables.
    let statement = newStatement(line[runningPos .. ^1], 1)

    let loopControl = runStatementAssignVar(env, statement, variables,
      "repl.tea")
    if loopControl == lcStop:
      return true
    return false

  # We got a REPL command.

  let replCmd = replCmdO.getGroup()
  runningPos += replCmdO.get().length

  if replCmd in ["q", "h", "v"]:
    if runningPos != line.len:
      # Invalid REPL command syntax, unexpected text.
      errorAndColumn(env, wInvalidReplSyntax, line, runningPos)
      return false
    case replCmd
    of "q":
      return true
    of "h":
      env.writeOut(replHelp())
      return false
    of "v":
      env.writeOut(showVariables(variables))
      return false

  # Skip whitespace, if any.
  let spaceMatchO = matchTabSpace(line, runningPos)
  if isSome(spaceMatchO):
    runningPos += spaceMatchO.get().length

  # Read the variable for the command.
  let varNameOr = getVariableName(line, runningPos)
  if varNameOr.isMessage:
    # Expected a variable or a dot name.
    errorAndColumn(env, wExpectedDotname, line, runningPos)
    return false
  let varName = varNameOr.value

  case varName.kind:
  of vnkFunction, vnkGet:
    # Expected variable name not function call.
    errorAndColumn(env, wInvalidDotname, line, runningPos+varName.dotName.len)
    return false
  of vnkNormal:
    discard
  if varName.pos != line.len:
    # Invalid REPL command syntax, unexpected text.
    errorAndColumn(env, wInvalidReplSyntax, line, varName.pos)
    return false

  # Read the dot name's value.
  let valueOr = getVariable(variables, varName.dotName, npLocal)
  if valueOr.isMessage:
    # The variable '$1' does not exist.", ## wVariableMissing
    errorAndColumn(env, wVariableMissing, line, runningPos, varName.dotName)
    return false
  let value = valueOr.value

  # The print options mirror the string function.
  case replCmd:
  of "p": # string dn
    if value.kind == vkDict:
      env.writeOut(dotNameRep(value.dictv.dict))
    else:
      env.writeOut(valueToString(value))
  of "pj": # string json
    env.writeOut(valueToString(value))
  of "ph": # print doc comment
    if varName.dotName == "f":
      let count = variables["f"].dictv.dict.len
      env.writeOut(fmt"The f dictionary contains {functionsDict.len} functions and {count} names.")
    elif value.kind == vkList:
      for ix, funcVar in value.listv.list:
        env.writeOut(fmt"{varName.dotName}[{ix}] -- {funcVar.funcv.signature}")
    elif value.kind == vkFunc:
      env.writeOut(getDocComment(value))
    else:
      # The variable is not a function variable.
      errorAndColumn(env, wNotFuncVariable, line, runningPos)
  of "pr": # string rb
    env.writeOut(valueToStringRB(value))
  else:
    discard
  result = false

proc runEvaluatePrintLoop*(env: var Env, args: Args) =
  ## Run commands at a prompt.
  var variables = getStartVariables(env, args)
  var line: string
  while true:
    try:
      line = readLineFromStdin("tea> ")
    except IOError:
      break
    let stop = handleReplLine(env, variables, line)
    if stop:
      break
