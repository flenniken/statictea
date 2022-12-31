## Run commands at a prompt.
## Run evaluate print loop (REPL).

import std/rdstdin
import std/tables
import std/options
import std/strutils
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

func showVariables(variables: Variables): string =
  ## Show repl command.
  var first = true
  for key, d in variables.pairs():
    if not first:
      result.add(" ")
    first = false
    if d.dictv.len == 0:
      result.add("$1={}" % key)
    else:
      result.add("$1={$2}" % [key, $d.dictv.len])

proc replHelp(): string =
  result = """
You enter statements or commands at the prompt.

Available commands:
* h — this help text
* p variable — print a variable as dot names
* pj variable — print a variable as json
* pr variable — print a variable like in a replacement block
* v — show the number of top variables in the top level dictionaries
* q — quit"""

proc errorAndColumn(env: var Env, messageId: MessageId, line: string,
    runningPos: Natural, p1 = "") =
  env.writeErr(line)
  env.writeErr(startColumn(line, runningPos))
  env.writeErr(getWarning(messageId, p1))

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
      "repl.tea", inOther)
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

  # Read the variable for the command.
  let matchesO = matchDotNames(line, runningPos)
  if not matchesO.isSome:
    # Expected a variable or a dot name.
    errorAndColumn(env, wExpectedDotname, line, runningPos)
    return false
  let (_, dotNameStr, leftParen, dotNameLen) = matchesO.get3GroupsLen()
  if leftParen == "(":
    # Expected variable name not function call.
    errorAndColumn(env, wInvalidDotname, line, runningPos+dotNameStr.len)
    return false
  if runningPos + dotNameLen != line.len:
    # Invalid REPL command syntax, unexpected text.
    errorAndColumn(env, wInvalidReplSyntax, line, runningPos + dotNameLen)
    return false

  # Read the dot name's value.
  let valueOr = getVariable(variables, dotNameStr, npLocal)
  if valueOr.isMessage:
    # The variable '$1' does not exist.", ## wVariableMissing
    errorAndColumn(env, wVariableMissing, line, runningPos, dotNameStr)
    return false
  let value = valueOr.value

  # The print options mirror the string function.
  case replCmd:
  of "p": # string dn
    if value.kind == vkDict:
      env.writeOut(dotNameRep(value.dictv))
    else:
      env.writeOut(valueToString(value))
  of "pj": # string json
    env.writeOut(valueToString(value))
  of "pr": # string rb
    env.writeOut(valueToStringRB(value))
  else:
    discard
  result = false

proc runEvaluatePrintLoop*(env: var Env, args: Args) =
  ## Run commands at a prompt.
  var variables = getStartingVariables(env, args)
  var line: string
  while true:
    try:
      line = readLineFromStdin("tea> ")
    except IOError:
      break
    let stop = handleReplLine(env, variables, line)
    if stop:
      break
