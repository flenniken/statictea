## Run commands at a prompt.
## Run evaluate print loop (REPL).

import std/rdstdin
import warnings
import env
import vartypes
import args
import opresultwarn

type
  ReplLineKind = enum
    rlHelp,
    rlQuit,
    rlPrintRbVar,
    rlPrintDotnames,
    rlPrintJson,
    rlPringVariables,
    rlRunStatement

  ReplLine = object
    line: string
    kind: ReplLineKind
    value: Value
  
  ReplLineOr = OpResultWarn[ReplLine]

func newReplLine(line: string): ReplLine =
  result = ReplLine(line: line, kind: rlHelp, value: newValue(5))

func newReplLineOr(warningData: WarningData): ReplLineOr =
  result = opMessageW[ReplLine](warningData)

func newReplLineOr(replLine: ReplLine): ReplLineOr =
  result = opValueW[ReplLine](replLine)

proc echoReplHelp() =
  echo """
Available commands:
* h — this help
* p <var> — print the value of a variable
* pd <var> — print a dictionary as dot names
* pj <var> — print a variable as json 
* v — show the number of variables in the top level dictionaries
* q — quit"""

func parseReplLine(line: string): ReplLineOr =
  let replLine = newReplLine(line)
  result = newReplLineOr(replLine)

proc runEvaluatePrintLoop*(env: var Env, args: Args) =
  ## Run commands at a prompt.
  # var variables = getStartingVariables(env, args)

  var line: string
  let value = newValue(5)
  while true:
    try:
      line = readLineFromStdin("tea> ")
    except IOError:
      break
    let replLineOr = parseReplLine(line)
    if replLineOr.isMessage:
      echo replLineOr.message
      continue
    let replLine = replLineOr.value
    case replLine.kind:
    of rlHelp:
      echoReplHelp()
    of rlQuit:
      break
    of rlPrintRbVar:
      echo valueToStringRB(replLine.value)
    of rlPrintDotnames:
      if replLine.value.kind == vkDict:
        echo dotNameRep(replLine.value.dictv)
      else:
        echo valueToString(replLine.value)
    of rlPrintJson:
      echo valueToString(replLine.value)
    of rlPringVariables:
      echo "show variables"
    of rlRunStatement:
      echo "run statement"
