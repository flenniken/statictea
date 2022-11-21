## Parse a StaticTea language command line.

import std/options
import std/tables
import regexes
import messages
import matches
import opresult
import args

type
  LineParts* = object
    ## LineParts holds parsed components of a line.
    ## @:
    ## @:~~~
    ## @:prefix command  [code]   [comment] [continuation]
    ## @:|      |        |        |         @![postfix]
    ## @:|      |        |        |         ||  [ending]
    ## @:|      |        |        |         ||  |
    ## @:<!--$  nextline var = 5  # comment +-->\n
    ## @:     |
    ## @:     optional spaces
    ## @:~~~~
    ## @:
    ## @:Whitespace must follow a command except on the last line of the file.
    ## @:codeStart is 0 when codeLen is 0.
    prefix*: string
    command*: string
    codeStart*: Natural
    codeLen*: Natural
    commentLen*: Natural
    continuation*: bool
    postfix*: string
    ending*: string
    lineNum*: Natural

  LinePartsOr* = OpResultWarn[LineParts]
    ## The line parts or a warning.

  CmdLines* = object
    ## The collected command lines and their parts.
    lines*: seq[string]
    lineParts*: seq[LineParts]

  ExtraLineKind* = enum
    ## The ExtraLine type.
    ## @:* elkNoLine -- there is no line here
    ## @:* elkOutOfLines -- no more lines in the template
    ## @:* elkNormalLine -- we have a line of some type
    elkNoLine,
    elkOutOfLines,
    elkNormalLine

  ExtraLine* = object
    ## The extra line and its type. The line is empty except for the
    ## elkNormalLine type.
    kind*: ExtraLineKind
    line*: string

func newNormalLine*(line: string): ExtraLine =
  ## Create a normal ExtraLine.
  result = ExtraLine(kind: elkNormalLine, line: line)

func newNoLine*(): ExtraLine =
  ## Create a no line ExtraLine.
  result = ExtraLine(kind: elkNoLine, line: "")

func newOutOfLines*(): ExtraLine =
  ## Create an out of lines ExtraLine.
  result = ExtraLine(kind: elkOutOfLines, line: "")

func newLinePartsOr*(warning: MessageId, p1: string = "", pos = 0):
     LinePartsOr =
  ## Return a new LinePartsOr object containing a warning.
  let warningData = newWarningData(warning, p1, pos)
  result = opMessageW[LineParts](warningData)

func newLinePartsOr*(lineParts: LineParts): LinePartsOr =
  ## Return a new LinePartsOr object containing a LineParts object.
  result = opValueW[LineParts](lineParts)

func getCodeLength*(line: string, codeStart: Natural,
    length: Natural): Natural =
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

proc parseCmdLine*(prepostTable: PrepostTable,
    line: string, lineNum: Natural): LinePartsOr =
  ## Parse the line and return its parts. Return quickly when not a
  ## command line.

  var lineParts: LineParts

  # Get the prefix plus the optional following whitespace.
  var prefixes = newSeq[string]()
  for key in prepostTable.keys():
    prefixes.add(key)
  let prefixMatchO = matchPrefix(line, prefixes)
  if not prefixMatchO.isSome():
    # No prefix so not a command line. No error.
    return
  let prefixMatch = prefixMatchO.get()
  lineParts.prefix = prefixMatch.getGroup()

  # Get the command.
  let commandMatchO = matchCommand(line, prefixMatch.length)
  if not isSome(commandMatchO):
    # No command found at column $1, treating it as a non-command line.
    return newLinePartsOr(wNoCommand, "", prefixMatch.length+1)

  var commandMatch = commandMatchO.get()
  lineParts.command = commandMatch.getGroup()

  # Get the expected postfix. Not all prefixes have a postfix.
  assert prepostTable.hasKey(lineParts.prefix)
  lineParts.postfix = prepostTable[lineParts.prefix]

  # Match the expected postfix at the end and return the optional
  # continuation and its position when it matches.
  let lastPartO = getLastPart(line, lineParts.postfix)
  if not isSome(lastPartO):
    # The matching closing comment postfix was not found, expected: "$1".
    return newLinePartsOr(wNoPostfix, lineParts.postfix, 0)
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
      return newLinePartsOr(wSpaceAfterCommand, "", 0)

    let midStart = middleStart + 1
    let midLen = middleLength - 1

    lineParts.codeLen = getCodeLength(line, midStart, midLen)
    lineParts.commentLen = midLen - lineParts.codeLen
    if lineParts.codeLen > 0:
      lineParts.codeStart = midStart

  # Line ending is required except for the last line of the file.
  lineParts.ending = ending
  lineParts.lineNum = lineNum
  result = newLinePartsOr(lineParts)
