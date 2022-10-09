## Run commands at a prompt.
## Run evaluate print loop (REPL).

import std/rdstdin
import std/tables
import std/options
import std/strutils
import warnings
import env
import vartypes
import args
import opresultwarn
import startingvars
import matches
import regexes
import messages
import runcommand
import variables

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
* p dotname — print the value of a variable
* pd dotname — print a dictionary as dot names
* pj dotname — print a variable as json
* v — show the number of variables in the top level dictionaries
* q — quit"""

func errorAndColumn(messageId: MessageId, line: string, runningPos: Natural, p1 = ""): string =
  result.add(startColumn(line, runningPos))
  result.add("\n")
  result.add(getWarning(messageId, p1))

proc runReplStatement(statement: Statement, variables: var Variables): Option[WarningData] =
  ## Run the statement and add to the variables.
  let variableDataOr = runStatement(statement, variables)
  if variableDataOr.isMessage:
    return some(variableDataOr.message)
  let variableData = variableDataOr.value
  # echo "variableData = $1" % $variableData

  if variableData.operator == "exit" or variableData.operator == "":
    return

  # Assign the variable if possible.
  result = assignVariable(variables, variableData.dotNameStr, variableData.value)

proc handleReplLine*(line: string, start: Natural, variables: var Variables, stop: var bool): string =
  ## Handle the REPL line. Set the stop variable to end the loop. The
  ## return string is the result of the line.
  if emptyOrSpaces(line, start):
    return

  var runningPos = start
  let replCmdO = matchReplCmd(line, runningPos)
  if not replCmdO.isSome:

    # Run the statement and add to the variables.
    let statement = newStatement(line[runningPos ..< line.len], 1)
    let warningDataO = runReplStatement(statement, variables)
    if isSome(warningDataO):
      let wd = warningDataO.get()
      return errorAndColumn(wd.warning, line, wd.pos+runningPos, wd.p1)
    return

  let replCmd = replCmdO.getGroup()
  runningPos += replCmdO.get().length

  if replCmd in ["q", "h", "v"]:
    if runningPos != line.len:
      # Invalid REPL command syntax.
      return errorAndColumn(wInvalidReplSyntax, line, runningPos)
    case replCmd
    of "q":
      stop = true
      return
    of "h":
      return replHelp()
    of "v":
      return showVariables(variables)

  let matchesO = matchDotNames(line, runningPos)
  if not matchesO.isSome:
    # Expected a variable or a dot name.
    return errorAndColumn(wExpectedDotname, line, runningPos)
  let (_, dotNameStr, leftParen, dotNameLen) = matchesO.get3GroupsLen()
  runningPos += dotNameLen
  if leftParen == "(":
    # Invalid variable or dot name.
    return errorAndColumn(wInvalidDotname, line, runningPos-1)
  if runningPos != line.len:
    # Invalid REPL command syntax.
    return errorAndColumn(wInvalidReplSyntax, line, runningPos)

  # Read the dotname's value.
  let valueOr = getVariable(variables, dotNameStr)
  if valueOr.isMessage:
    # The variable '$1' does not exist.", ## wVariableMissing
    return errorAndColumn(wVariableMissing, line, runningPos, dotNameStr)
  let value = valueOr.value

  case replCmd:
  of "p":
    result.add(valueToStringRB(value))
  of "pd":
    if value.kind == vkDict:
      result.add(dotNameRep(value.dictv))
    else:
      result.add(valueToString(value))
  of "pj":
    result.add(valueToString(value))
  else:
    discard
  stop = false

proc runEvaluatePrintLoop*(env: var Env, args: Args) =
  ## Run commands at a prompt.
  var variables = getStartingVariables(env, args)
  var line: string
  var stop: bool
  while true:
    try:
      line = readLineFromStdin("tea> ")
    except IOError:
      break
    let str = handleReplLine("tea> " & line, 5, variables, stop)
    if stop:
      break
    if str != "":
      echo str
