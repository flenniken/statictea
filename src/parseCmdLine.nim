## Parse a StaticTea language command line.

import std/options
import std/tables
import env
import regexes
import messages
import matches

type
  LineParts* = object
    ## LineParts holds parsed components of a line.
    ## @:
    ## @:~~~
    ## @:prefix command  [code]   [comment] [continuation]
    ## @:|      |        |        |         |[postfix]
    ## @:|      |        |        |         ||  [ending]
    ## @:|      |        |        |         ||  |
    ## @:<!--$  nextline var = 5  # comment +-->\n
    ## @:     |
    ## @:     optional spaces
    ## @:~~~~
    ## @:
    ## @:Whitespace must follow a command except on the last line of the file.
    prefix*: string
    command*: string
    codeStart*: Natural
      ## where the code starts or 0 when codeLen is 0.
    codeLen*: Natural
    commentLen*: Natural
    continuation*: bool
    postfix*: string
    ending*: string
    lineNum*: Natural

func getCodeLength*(line: string, codeStart: Natural, length: Natural): Natural =
  ## Return the length of the code in the line.  The code starts at
  ## codeStart and cannot exceed the given length. The code ends when
  ## there is a comment (a pound sign), or the end is reached.
  ## The input length is returned on errors.
  type
    State = enum
      ## Finite state machine states.
      start,
      slash,
      quoteSlash,
      quote,

  if length < 1:
    return length

  var state: State
  for ix in countUp(codeStart, codeStart+length):
    if ix >= line.len:
      return length
    let ch = line[ix]
    case state:
    of start:
      if ch == '#':
        return ix - codeStart
      elif ch == '\\':
        state = slash
      elif ch == '"':
        state = quote
    of quote:
      if ch == '"':
        state = start
      elif ch == '\\':
        state = quoteSlash
    of slash:
      state = start
    of quoteSlash:
      state = quote
  return length

proc parseCmdLine*(env: var Env, prepostTable: PrepostTable,
    line: string, lineNum: Natural): Option[LineParts] =
  ## Parse the line and return its parts. Return quickly when not a
  ## command line.

  var lineParts: LineParts

  # Get the prefix plus the optional following whitespace.
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

  # We have a prefix, command and optional postfix.

  let middleStart: int = prefixMatch.length + lineParts.command.len
  let middleLength: int = line.len - middleStart - lastPart.length

  assert prefixMatch.length + lineParts.command.len + middleLength + lastPart.length == line.len

  if middleLength > 0:
    # Make sure there is a space after the command.
    let spaceMatchO = matchTabSpace(line, middleStart)
    if not isSome(spaceMatchO):
      # No space after the command.
      env.warn(lineNum, wSpaceAfterCommand)
      return

    let midStart = middleStart + 1
    let midLen = middleLength - 1

    lineParts.codeLen = getCodeLength(line, midStart, midLen)
    lineParts.commentLen = midLen - lineParts.codeLen
    if lineParts.codeLen > 0:
      lineParts.codeStart = midStart

  # Line ending is required except for the last line of the file.
  lineParts.ending = ending
  lineParts.lineNum = lineNum
  result = some(lineParts)

when defined(Test):
  # Used in multiple test files.
  proc newLineParts*(
      prefix: string = "<!--$",
      command: string = "nextline",
      codeStart: Natural = 0,
      codeLen: Natural = 0,
      commentLen: Natural = 0,
      continuation: bool = false,
      postfix: string = "-->",
      ending: string = "\n",
      lineNum: Natural = 1): LineParts =
    ## Return a new LineParts object. The default is: <!--$ nextline -->\n.
    result = LineParts(prefix: prefix, command: command,
      codeStart: codeStart, codeLen: codeLen, commentLen: commentLen,
      continuation: continuation, postfix: postfix,
      ending: ending, lineNum: lineNum)
