## Parse a template command line.
## @:
## @:We have two types of command lines.  We distingush them using
## different names CmdLine and CommandLine.
## @:
## @:* CmdLine -- is a line in a StaticTea template commands.
## @:* CommandLine -- is a line at a terminal for system commands.

import options
import tables
import env
import regexes
import warnings
import matches

type
  LineParts* = object
    ## The parsed components of a line.
    prefix*: string
    command*: string
    middleStart*: Natural
    middleLen*: Natural
    continuation*: bool
    postfix*: string
    ending*: string
    lineNum*: Natural

proc parseCmdLine*(env: var Env, prepostTable: PrepostTable,
    line: string, lineNum: Natural): Option[LineParts] =
  ## Parse the line and return its parts when it is a command. Return
  ## quickly when not a command line.

  # ix0 prefix   command     middleStart  continuation
  # ix0 |        |           |            |postfix
  # ix0 |        |           |            ||  ending
  # ix0 |        |           |            ||  |
  # ix0 <!--$    nextline    a = 5        +-->\n

  var lineParts: LineParts

  # Get the prefix.
  let prefixMatchO = matchPrefix(line, prepostTable)
  if not prefixMatchO.isSome():
    # No prefix so not a command line. No error.
    return
  let prefixMatch = prefixMatchO.get()
  lineParts.prefix = prefixMatch.getGroup()

  # Get the command.
  let commandMatchO = matchCommand(line, prefixMatch.length)
  if not isSome(commandMatchO):
    env.warn(lineNum, wNoCommand, $(prefixMatch.length+1))
    return
  var commandMatch = commandMatchO.get()
  lineParts.command = commandMatch.getGroup()

  # Get the optional spaces.
  let spaceMatchO = matchTabSpace(line, prefixMatch.length + commandMatch.length)

  # Get the expected postfix. Not all prefixes have a postfix.
  assert prepostTable.hasKey(lineParts.prefix)
  lineParts.postfix = prepostTable[lineParts.prefix]

  # Match the expected postfix at the end and return the optional
  # continuation and its position when it matches.
  let lastPartO = getLastPart(line, lineParts.postfix)
  if not isSome(lastPartO):
    env.warn(lineNum, wNoPostfix, lineParts.postfix)
    return
  var lastPart = lastPartO.get()
  let (continuation, ending) = lastPart.get2Groups()
  lineParts.continuation = if continuation == "": false else: true

  # We have a prefix, command and optional postfix.  Determine whether
  # there is a middle part.  There must be a space after the command
  # before the middle part starts.
  var spaceLength: int
  if isSome(spaceMatchO):
    spaceLength = spaceMatchO.get().length
  else:
    spaceLength = 0

  lineParts.middleStart = prefixMatch.length + commandMatch.length + spaceLength
  let middleLength: int = line.len - lineParts.middleStart - lastPart.length

  if spaceLength == 0 and middleLength > 0:
    env.warn(lineNum, wSpaceAfterCommand)
    return
  if middleLength > 0:
    lineParts.middleLen = middleLength

  # Line ending is required except for the last line of the file.
  lineParts.ending = ending
  lineParts.lineNum = lineNum
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
      prefix: string = "<!--$",
      command: string = "nextline",
      middleStart: Natural = 15,
      middleLen: Natural = 0,
      continuation: bool = false,
      postfix: string = "-->",
      ending: string = "\n",
      lineNum: Natural = 1): LineParts =
    ## Return a new LineParts object. The default is: <!--$ nextline -->\n.
    result = LineParts(prefix: prefix, command: command,
      middleStart: middleStart, middleLen: middleLen,
      continuation: continuation, postfix: postfix,
      ending: ending, lineNum: lineNum)
