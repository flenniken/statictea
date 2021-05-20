## Args object for holding command line arguments.

import strutils

type
  Prepost* = object
    ## One prefix and its associated postfix.
    prefix*: string
    postfix*: string

  Args* = object
    ## Object to hold all the command line arguments.
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
  result = Prepost(prefix: prefix, postfix: postfix)

func `$`*(args: Args): string =
  ## Return a string representation of the Args object.
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
