## Command line arguments.
import strutils
import sets

type
  Prepost* = tuple[pre: string, post: string]

  Args* = object
    help*: bool
    version*: bool
    update*: bool
    log*: bool
    serverList*: seq[string]
    sharedList*: seq[string]
    templateList*: seq[string]
    resultFilename*: string
    prepostList*: seq[Prepost]

proc addBool(name: string, value: bool, trueElements: var seq[string],
             falseElements: var seq[string]) =
  if value:
    trueElements.add(name)
  else:
    falseElements.add(name)

proc addEmpty(name: string, value: seq[string] | seq[Prepost], emptyElements: var seq[string]) =
  if value.len == 0:
    emptyElements.add(name)

proc addEmptyString(name: string, value: string, emptyElements: var seq[string]) =
  if value == "":
    emptyElements.add(name)

proc addLine(name: string, elements: seq[string], lines: var seq[string]) =
  if elements.len != 0:
    lines.add("$1 = $2" % [name, elements.join(", ")])

proc addLine(name: string, elements: seq[Prepost], lines: var seq[string]) =
  if elements.len != 0:
    lines.add("$1 = $2" % [name, elements.join(", ")])

proc addLine(name: string, value: string, lines: var seq[string]) =
  if value != "":
    lines.add("$1 = $2" % [name, value])

func `$`*(args: Args): string =
  ## A string representation of Args.
  var trueElements: seq[string]
  var falseElements: seq[string]
  var emptyElements: seq[string]

  for name, value in args.fieldPairs:
    when value is bool:
      addBool(name, value, trueElements, falseElements)
    elif value is seq:
      addEmpty(name, value, emptyElements)
    elif value is string:
      addEmptyString(name, value, emptyElements)

  var lines: seq[string]
  lines.add("args:")
  lines.add("true: $1" % [join(trueElements, ", ")])
  lines.add("false: $1" % [join(falseElements, ", ")])
  lines.add("empty: $1" % [join(emptyElements, ", ")])

  for name, value in args.fieldPairs:
    when value is seq[string]:
      addLine(name, value, lines)
    elif value is seq[Prepost]:
      addLine(name, value, lines)
    elif value is string:
      addLine(name, value, lines)

  result = join(lines, "\n")
