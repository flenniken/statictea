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
    templateList*: seq[string]
    prepostList*: seq[Prepost]
    resultFilename*: string
    logFilename*: string

func newPrepost*(prefix: string, postfix: string): Prepost =
  ## Create a new prepost object from the prefix and postfix.
  result = Prepost(prefix: prefix, postfix: postfix)

func `$`*(args: Args): string =
  ## Return a string representation of the Args object.
  # todo: print out one line per field.
  # args.help = true
  # args.version = 0.1.0
  # args.serverList = ["one", "two"]
  result = """
Args:
help=$1, version=$2, update=$3, log=$10
serverList: [$4]
sharedList: [$5]
templateList: [$6]
prepostList: [$7]
resultFilename: "$8"
logFilename: "$9"""" % [$args.help, $args.version, $args.update,
  $args.serverList.join(", "), $args.sharedList.join(", "),
  $args.templateList.join(", "), $args.prepostList.join(", "),
  $args.resultFilename, $args.logFilename, $args.log]
