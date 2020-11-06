import strutils
import env
import matches
import options
import regexes
import tables

type
  LineParts* = object
    prefix*: string
    middle*: string
    command*: string
    continuation*: bool
    postfix*: string
    ending*: string

proc parseCmdLine*(env: Env, prepostTable: PrepostTable,
    prefixMatcher: Matcher, commandMatcher: Matcher, line: string):
    Option[LineParts] =
  ## Parse the line and return its parts. Return quickly when not a
  ## command line.
  # prefix   command    middle    \postfix end
  # <--!$    nextline   a = 5     \-->\n
  var lineParts: LineParts

  # Get the prefix.
  let prefixMatchO = getMatches(prefixMatcher, line)
  if not prefixMatchO.isSome():
    return
  let prefixMatch = prefixMatchO.get()
  lineParts.prefix = prefixMatch.getGroup()

  # Get the command.
  let commandMatchO = getMatches(commandMatcher, line, prefixMatch.length)
  if not isSome(commandMatchO):
    env.warn("Invalid command")
    return
  var commandMatch = commandMatchO.get()
  lineParts.command = commandMatch.getGroup()

  # Get the postfix.
  assert prepostTable.hasKey(lineParts.prefix)
  lineParts.postfix = prepostTable[lineParts.prefix]

  let middleStart = prefixMatch.length + commandMatch.length

  # Get the optional continuation and its position.
  var lastPartMatcher = getLastPartMatcher(lineParts.postfix)
  let lastPartO = getLastPart(lastPartMatcher, line)
  if not isSome(lastPartO):
    env.warn("Missing postfix")
    return
  var lastPart = lastPartO.get()
  let (continuation, ending) = lastPart.get2Groups()
  lineParts.continuation = if continuation == "": false else: true
  let endPos = line.len - lastPart.length

  # Line ending is required except for the last line of the file.
  lineParts.ending = ending

  # Get the middle string.
  if endPos - middleStart > 0:
    lineParts.middle = line[middleStart..<endPos]
  result = some(lineParts)

when defined(test):
  func getEndingString*(ending: string): string =
    if ending == "\n":
      result = r"\n"
    elif ending == "\r\n":
      result = r"\r\n"
    else:
      result = ending

  func `$`*(lp: LineParts): string =
    ## A string representation of LineParts.
    var ending: string
    if lp.ending == "\n":
      ending = r"\n"
    elif lp.ending == "\r\n":
      ending = r"\r\n"
    else:
      ending = lp.ending
    result = """
  LineParts:
  prefix: '$1'
  command: '$2'
  middle: '$3'
  continuation: $4
  ending: '$5'""" % [$lp.prefix, $lp.command, $lp.middle, $lp.continuation,
                     getEndingString(lp.ending)]

  proc newLineParts*(prefix: string = "<--!$",
      command: string = "nextline",
      middle: string = "",
      continuation: bool = false,
      postfix: string = "-->",
      ending: string = "\n"): LineParts =
    result = LineParts(prefix: prefix, command: command,
      middle: middle, continuation: continuation, postfix: postfix, ending: ending)
