## Parse a template command line. We have two types of command lines,
## @:CmdLine and CommandLine.
## @:
## @:* CmdLine -- is a command line in a StaticTea template.
## @:* CommandLine -- is a line at a terminal for system commands.

import std/options
import std/tables
import env
import regexes
import messages
import matches

# prefix command  middleStart   continuation
# |      |        |             |postfix
# |      |        |             ||  ending
# |      |        |             ||  |
# <!--$  nextline var = 5       +-->\n

# $$ nextline str = "abc+\n
# $$ : def+\n
# $$ : ghi"\n
# statement: 'str = "abcdefghi"\n'

# There is one space after a command.  It is not part of the middle
# part. The rest of the line including spaces up to the continuation
# is part of the middle part. In the example below replace the dashes
# with spaces.

# $$ nextline -str = "abc-+\n
# $$ : -def-+\n
# $$ : -ghi"-\n
# statement: ' str = "abc--def--ghi"-\n'

# Statements are trimmed of leading and trailing spaces later.

# todo: since we don't support semicolons the middle part is not needed anymore.
type
  LineParts* = object
    ## LineParts holds parsed components of a line.
    prefix*: string
    command*: string
    middleStart*: Natural ## One after the command.
    middleLen*: Natural ## Length to the first ending part.
    continuation*: bool
    postfix*: string
    ending*: string
    lineNum*: Natural

proc parseCmdLine*(env: var Env, prepostTable: PrepostTable,
    line: string, lineNum: Natural): Option[LineParts] =
  ## Parse the line and return its parts when it is a command. Return
  ## quickly when not a command line.

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

  lineParts.middleStart = prefixMatch.length + commandMatch.length
  if spaceLength > 0:
     lineParts.middleStart += 1
  let middleLength: int = line.len - lineParts.middleStart - lastPart.length

  if spaceLength == 0 and middleLength > 0:
    # No space after the command.
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
