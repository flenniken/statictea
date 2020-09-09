## Command line arguments.

type
  Prepost* = tuple[pre: string, post: string]

  Args* = object
    help*: bool
    version*: bool
    update*: bool
    serverList*: seq[string]
    sharedList*: seq[string]
    templateList*: seq[string]
    resultFilename*: string
    prepostList*: seq[Prepost]
