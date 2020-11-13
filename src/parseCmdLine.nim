import options
import tables
import env
import regexes
import warnings
import matches

type
  LineParts* = object
    prefix*: string
    command*: string
    middleStart*: Natural
    middleLen*: Natural
    continuation*: bool
    postfix*: string
    ending*: string

proc parseCmdLine*(env: var Env, prepostTable: PrepostTable,
    prefixMatcher: Matcher, commandMatcher: Matcher, line: string,
    templateFilename: string, lineNum: Natural):
    Option[LineParts] =
  ## Parse the line and return its parts when it is a command. Return
  ## quickly when not a command line.

  # prefix   command     middle    \postfix ending
  # <--!$    nextline    a = 5     \-->\n
  #                   ^middleStart

  var lineParts: LineParts

  # Get the prefix.
  let prefixMatchO = getMatches(prefixMatcher, line)
  if not prefixMatchO.isSome():
    # No prefix so not a command line. No error.
    return
  let prefixMatch = prefixMatchO.get()
  lineParts.prefix = prefixMatch.getGroup()

  # Get the command.
  let commandMatchO = getMatches(commandMatcher, line, prefixMatch.length)
  if not isSome(commandMatchO):
    env.warn(templateFilename, lineNum, wNoCommand, $(prefixMatch.length+1))
    return
  var commandMatch = commandMatchO.get()
  lineParts.command = commandMatch.getGroup()

  lineParts.middleStart = prefixMatch.length + commandMatch.length

  # Get the expected postfix.
  assert prepostTable.hasKey(lineParts.prefix)
  lineParts.postfix = prepostTable[lineParts.prefix]

  # Match the expected postfix at the end and return the optional
  # continuation and its position when it matches.
  var lastPartMatcher = getLastPartMatcher(lineParts.postfix)
  let lastPartO = getLastPart(lastPartMatcher, line)
  if not isSome(lastPartO):
    env.warn(templateFilename, lineNum, wNoPostfix, lineParts.postfix)
    return
  var lastPart = lastPartO.get()
  let (continuation, ending) = lastPart.get2Groups()
  lineParts.continuation = if continuation == "": false else: true
  lineParts.middleLen = line.len - lastPart.length - lineParts.middleStart

  # Line ending is required except for the last line of the file.
  lineParts.ending = ending
  result = some(lineParts)

when defined(test):
  func getEndingString*(ending: string): string =
    if ending == "\n":
      result = r"\n"
    elif ending == "\r\n":
      result = r"\r\n"
    else:
      result = ending

  # func `$`*(lp: LineParts): string =
  #   ## A string representation of LineParts.
  #   var ending: string
  #   if lp.ending == "\n":
  #     ending = r"\n"
  #   elif lp.ending == "\r\n":
  #     ending = r"\r\n"
  #   else:
  #     ending = lp.ending
  #   result = """
  # LineParts:
  # prefix: '$1'
  # command: '$2'
  # middle: '$3'
  # continuation: $4
  # ending: '$5'""" % [$lp.prefix, $lp.command, $lp.middle, $lp.continuation,
  #                    getEndingString(lp.ending)]

  proc newLineParts*(
      prefix: string = "<--!$",
      command: string = "nextline",
      middleStart: Natural = 15,
      middleLen: Natural = 0,
      continuation: bool = false,
      postfix: string = "-->",
      ending: string = "\n"): LineParts =
    ## Return a new LineParts object. The default is: <--!$ nextline -->\n.
    result = LineParts(prefix: prefix, command: command,
      middleStart: middleStart, middleLen: middleLen,
      continuation: continuation, postfix: postfix, ending: ending)
