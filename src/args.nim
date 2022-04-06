## Command line arguments.

import std/strutils

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
    serverList*: seq[string]
    sharedList*: seq[string]
    templateFilename*: string
    prepostList*: seq[Prepost]
    resultFilename*: string
    logFilename*: string

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

func toString(b: bool): string =
  ## Return the string representation of a bool, 0 or 1.
  if b:
    result = "1"
  else:
    result = "0"

func `$`*(p: Prepost): string =
  ## Return a string representation of the Prepost object.
  result = "\"" & p.prefix &  "," & p.postfix & "\""

func toString(list: openArray[Prepost]): string =
  ## Return a string representation of a list of Prepost objects.
  result = "["
  for i, prepost in list:
    if i > 0:
      result.add(", ")
    result.add($prepost)
  result.add("]")

func `$`*(args: Args): string =
  ## Return a string representation of the Args object.
  var lines = newSeq[string]()
  lines.add("args.help = $1" % toString(args.help))
  lines.add("args.version = $1" % toString(args.version))
  lines.add("args.update = $1" % toString(args.update))
  lines.add("args.log = $1" % toString(args.log))
  lines.add("args.logFilename = \"$1\"" % args.logFilename)
  lines.add("args.resultFilename = \"$1\"" % args.resultFilename)
  lines.add("args.serverList = $1" % toString(args.serverList))
  lines.add("args.sharedList = $1" % toString(args.sharedList))
  lines.add("args.templateFilename = \"$1\"" % args.templateFilename)
  lines.add("args.prepostList = $1" % toString(args.prepostList))
  result = join(lines, "\n")
