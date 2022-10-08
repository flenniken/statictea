## Types for handling command line arguments.

import std/strutils
import messages
import warnings
import opresultwarn

type
  Prepost* = object
    ## Prepost holds one prefix and its associated postfix.
    prefix*: string
    postfix*: string

  Args* = object
    ## Args holds all the command line arguments.
    help*: bool
    version*: bool
    update*: bool
    log*: bool
    repl*: bool
    serverList*: seq[string]
    codeList*: seq[string]
    prepostList*: seq[Prepost]
    templateFilename*: string
    resultFilename*: string
    logFilename*: string

  ArgsOr* = OpResultWarn[Args]
    ## The args or a warning.

# func newArgs*(help=false, version=false, update=false, log=false, repl=false,
#     logFilename="", serverList = newSeq[string](), codeList = newSeq[string](),
#     templateFilename="", prepostList = newSeq[Prepost]()): Args =
#   result = Args(help: help, version: version, update: update, log: log, repl: repl,
#              logFilename: logFilename, serverList: serverList, codeList: codeList,
#              templateFilename: templateFilename, prepostList: prepostList)

func newArgsOr*(warningData: WarningData):
     ArgsOr =
  ## Return a new ArgsOr object containing a warning.
  result = opMessageW[Args](warningData)

func newArgsOr*(warning: MessageId, p1: string = "", pos = 0):
     ArgsOr =
  ## Return a new ArgsOr object containing a warning.
  let warningData = newWarningData(warning, p1, pos)
  result = opMessageW[Args](warningData)

func newArgsOr*(args: Args): ArgsOr =
  ## Return a new ArgsOr object containing args.
  result = opValueW[Args](args)

func newPrepost*(prefix: string, postfix: string): Prepost =
  ## Create a new prepost object from the prefix and postfix.
  result = Prepost(prefix: prefix, postfix: postfix)

func toString(list: openArray[string]): string =
  ## Return the string representation of an array of strings.
  result = "["
  for i, item in list:
    if i > 0:
      result.add(", ")
    result.add("\"")
    result.add(item)
    result.add("\"")
  result.add("]")

func `$`*(p: Prepost): string =
  ## Return the Prepost string representation.
  result = "\"" & p.prefix &  "," & p.postfix & "\""

func toString(list: openArray[Prepost]): string =
  ## Return the Prepost list string representation.
  result = "["
  for i, prepost in list:
    if i > 0:
      result.add(", ")
    result.add($prepost)
  result.add("]")

func `$`*(args: Args): string =
  ## Return the Args string representation.
  result.add("args.help = $1\n" % $args.help)
  result.add("args.version = $1\n" % $args.version)
  result.add("args.update = $1\n" % $args.update)
  result.add("args.log = $1\n" % $args.log)
  result.add("args.repl = $1\n" % $args.repl)
  result.add("args.logFilename = \"$1\"\n" % args.logFilename)
  result.add("args.resultFilename = \"$1\"\n" % args.resultFilename)
  result.add("args.serverList = $1\n" % toString(args.serverList))
  result.add("args.codeList = $1\n" % toString(args.codeList))
  result.add("args.templateFilename = \"$1\"\n" % args.templateFilename)
  result.add("args.prepostList = $1" % toString(args.prepostList))
