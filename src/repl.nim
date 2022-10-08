## Run commands at a prompt.
## Run evaluate print loop (REPL).

import std/rdstdin
import std/options
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

proc echoReplHelp() =
  echo """
You enter statements or commands at the prompt.

Available commands:
* h — this help text
* p dotname — print the value of a variable
* pd dotname — print a dictionary as dot names
* pj dotname — print a variable as json 
* v — show the number of variables in the top level dictionaries
* q — quit"""

proc runEvaluatePrintLoop*(env: var Env, args: Args) =
  ## Run commands at a prompt.
  var variables = getStartingVariables(env, args)

  var runningPos: Natural = 0
  var line: string
  while true:
    try:
      line = readLineFromStdin("tea> ")
    except IOError:
      break
    let replCmdO = matchReplCmd(line, runningPos)
    if not replCmdO.isSome:
      echo "not repl command"
      continue
    let replCmd = replCmdO.getGroup()
    runningPos += replCmdO.get().length

    if replCmd == "q":
      break
    if replCmd == "h":
      echoReplHelp()
      continue
    if replCmd == "v":
      echo "show variables"
      continue

    let matchesO = matchDotNames(line, runningPos)
    if not matchesO.isSome:
      # Expected a variable or a dot name.
      echo getWarning(wExpectedDotname)
      echo startColumn(line, runningPos)
      continue
    let (_, dotNameStr, leftParen, dotNameLen) = matchesO.get3GroupsLen()
    if leftParen == "(":
      # Invalid variable or dot name.
      echo getWarning(wInvalidDotname)
      echo startColumn(line, runningPos + dotNameStr.len)
      continue
    runningPos += dotNameLen
    if runningPos != line.len:
      echo "extra junk at the end"
      echo startColumn(line, runningPos)
      continue

    # Read the dotname's value.
    let valueOr = getVariable(variables, dotNameStr)
    if valueOr.isMessage:
      echo "The variable doesn't exist: " & dotNameStr
      continue
    let value = valueOr.value    

    case replCmd:
    of "p ":
      echo valueToStringRB(value)
    of "pd ":
      if value.kind == vkDict:
        echo dotNameRep(value.dictv)
      else:
        echo valueToString(value)
    of "pj ":
      echo valueToString(value)
    else:
      echo "unknown command"
