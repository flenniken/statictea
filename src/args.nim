## Command line arguments.
import strutils

type
  Prepost* = tuple[pre: string, post: string]

  Args* = object
    help*: bool
    version*: bool
    update*: bool
    nolog*: bool
    serverList*: seq[string]
    sharedList*: seq[string]
    templateList*: seq[string]
    prepostList*: seq[Prepost]
    resultFilename*: string

func `$`*(args: Args): string =
  ## A string representation of Args.
  result = """
Args:
help=$1, version=$2, update=$3, nolog=$4
serverList: [$5]
sharedList: [$6]
templateList: [$7]
prepostList: [$8]
resultFilename: "$9"""" % [$args.help, $args.version, $args.update, $args.nolog,
  $args.serverList.join(", "), $args.sharedList.join(", "),
  $args.templateList.join(", "), $args.prepostList.join(", "),
  $args.resultFilename]
