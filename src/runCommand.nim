## Run a command and fill in the variables dictionaries.

import std/options
import std/strutils
import std/tables
import std/os
import std/streams
import linebuffer
import matches
import regexes
import env
import vartypes
import messages
import variables
import functions
import readjson
import opresult
import unicodes
import utf8decoder
import parseCmdLine
import signatures

const
  # Turn on showPos for testing to graphically show the start and end
  # positions when running a statement.
  showPos = false

  tripleQuotes* = "\"\"\""
    ## Triple quotes for building strings.

# Test code can set the max name length.
when defined(test):
  var maxNameLength* = 64
else:
  const
    maxNameLength* = 64
      ## The maximum length of a variable or dotname.

type
  PosOr* = OpResultWarn[Natural]
    ## A position in a string or a message.

  SpecialFunction* {.pure.} = enum
    ## The special functions.
    ## @:
    ## @:* spNotSpecial -- not a special function
    ## @:* spIf -- if function
    ## @:* spIf0 -- if0 function
    ## @:* spWarn -- warn function
    ## @:* spLog -- log function
    ## @:* spReturn -- return function
    ## @:* spAnd -- and function
    ## @:* spOr -- or function
    ## @:* spFunc -- func function
    ## @:* spListLoop -- list with callback function
    spNotSpecial = "not-special",
    spIf = "if",
    spIf0 = "if0",
    spWarn = "warn",
    spLog = "log",
    spReturn = "return",
    spAnd = "and",
    spOr = "or",
    spFunc = "func",
    spListLoop = "listLoop",

  SpecialFunctionOr* = OpResultWarn[SpecialFunction]
    ## A SpecialFunction or a warning message.

  Found* = enum
    ## The line endings found.
    ## @:
    ## @:* nothing = no special ending
    ## @:* plus = +
    ## @:* triple = """
    ## @:* newline = \\n
    ## @:* plus_n = +\\n
    ## @:* triple_n = """\\n
    ## @:* crlf = \\r\\n
    ## @:* plus_crlf = +\\r\\n
    ## @:* triple_crlf = """\\r\\n
    nothing,
    plus,       # +
    triple,     # """
    newline,    # n
    plus_n,     # +n
    triple_n,   # """n
    crlf,       # rn
    plus_crlf,  # +rn
    triple_crlf # """rn

  LinesOr* = OpResultWarn[seq[string]]
    ## A list of lines or a warning.

  LoopControl* = enum
    ## Controls whether to output the current replacement block
    ## iteration and whether to stop or not.
    ## @:
    ## @:* lcStop -- do not output this replacement block and stop iterating
    ## @:* lcSkip -- do not output this replacement block and continue with the next iteration
    ## @:* lcAdd -- output the replacment block and continue with the next iteration
    lcStop = "stop",
    lcSkip = "skip",
    lcAdd = "add",

func newLinesOr*(warning: MessageId, p1: string = "", pos = 0):
     LinesOr =
  ## Return a new LinesOr object containing a warning.
  let warningData = newWarningData(warning, p1, pos)
  result = opMessageW[seq[string]](warningData)

func newLinesOr*(warningData: WarningData): LinesOr =
  ## Return a new LinesOr object containing a warning.
  result = opMessageW[seq[string]](warningData)

func newLinesOr*(lines: seq[string]): LinesOr =
  ## Return a new LinesOr object containing a list of lines.
  result = opValueW[seq[string]](lines)

func newPosOr*(warning: MessageId, p1 = "", pos = 0): PosOr =
  ## Create a PosOr warning.
  let warningData = newWarningData(warning, p1, pos)
  result = opMessageW[Natural](warningData)

func newPosOr*(pos: Natural): PosOr =
  ## Create a PosOr value.
  result = opValueW[Natural](pos)

func newSpecialFunctionOr*(warning: MessageId, p1 = "", pos = 0): SpecialFunctionOr =
  ## Create a PosOr warning.
  let warningData = newWarningData(warning, p1, pos)
  result = opMessageW[SpecialFunction](warningData)

func newSpecialFunctionOr*(specialFunction: SpecialFunction): SpecialFunctionOr =
  ## Create a SpecialFunctionOr value.
  result = opValueW[SpecialFunction](specialFunction)

func `$`*(s: Statement): string =
  ## Return a string representation of a Statement.
  result = """$1, "$2"""" % [$s.lineNum, s.text]

func `==`*(s1: Statement, s2: Statement): bool =
  ## Return true when the two statements are equal.
  if s1.lineNum == s2.lineNum and s1.text == s2.text:
    result = true

func `==`*(a: PosOr, b: PosOr): bool =
  ## Return true when a equals b.
  if a.kind == b.kind:
    if a.isMessage:
      result = a.message == b.message
    else:
      result = a.value == b.value

func `!=`*(a: PosOr, b: PosOr): bool =
  ## Compare whether two PosOr are not equal.
  result = not (a == b)

type
  VariableNameKind* = enum
    ## The variable name type.
    ## @:
    ## @:vtNormal -- a variable with whitespace following it
    ## @:vtFunction -- a variable with ( following it
    ## @:vtGet -- a variable with [ following it
    vnkNormal,
    vnkFunction,
    vnkGet

  VariableName* = object
    ## A variable name in a statement.
    ## @:
    ## @:* dotName -- the dot name string
    ## @:* kind -- the kind of name defined by the character following the name
    ## @:* pos -- the position after the trailing whitespace
    dotName*: string
    kind*: VariableNameKind
    pos*: Natural

  VariableNameOr* = OpResultWarn[VariableName]

  RightType* = enum
    ## The type of the right hand side of a statement.
    ## @:
    ## @:rtNothing -- not a valid right hand side
    ## @:rtString -- a literal string starting with a quote
    ## @:rtNumber -- a literal number starting with a digit or minus sign
    ## @:rtVariable -- a variable starting with a-zA-Z
    ## @:rtFunction -- a function variable calling a function: len(b)
    ## @:rtList -- a literal list: [1, 2, 3, len(b), 5]
    ## @:rtCondition -- a condition: (a < b)
    ## @:rtGet -- a index into a list or dictionary: teas[2], teas["green"]
    rtNothing,
    rtString,
    rtNumber,
    rtVariable,
    rtList,
    rtCondition,

func newVariableName*(dotName: string, kind: VariableNameKind,
    pos: Natural): VariableName =
  ## Create a new VariableName object.
  result = VariableName(dotName: dotName, kind: kind, pos: pos)

func newVariableNameOr*(warning: MessageId, p1 = "", pos = 0): VariableNameOr =
  ## Create a PosOr warning.
  let warningData = newWarningData(warning, p1, pos)
  result = opMessageW[VariableName](warningData)

func newVariableNameOr*(dotName: string, kind: VariableNameKind,
    pos: Natural): VariableNameOr =
  ## Create a new VariableNameOr object.
  let vn = newVariableName(dotName, kind, pos)
  result = opValueW[VariableName](vn)

func getRightType*(statement: Statement, start: Natural): RightType =
  ## Return the type of the right hand side of the statement at the
  ## start position.

  # The first character determines the type.
  # * quote -- string
  # * digit or minus sign -- number
  # * a-zA-Z -- variable
  # * [ -- a list
  # * ( -- a condition expression

  # Make sure start is pointing to something.
  if start >= statement.text.len:
    return rtNothing

  let char = statement.text[start]
  if char == '"':
    result = rtString
  elif char in {'0' .. '9', '-'}:
    result = rtNumber
  elif char == '[':
    result = rtList
  elif char == '(':
    result = rtCondition
  elif isLowerAscii(char) or isUpperAscii(char):
    result = rtVariable
  else:
    result = rtNothing

proc getVariableNameOr*(text: string, startPos: Natural): VariableNameOr =
  ## Get a variable name from the statement. Start points at a name.
  ## @:
  ## @:~~~
  ## @:a = var-name( 1 )
  ## @:    ^         ^
  ## @:a = abc # comment
  ## @:    ^   ^
  ## @:a = o.def.bbb # comment
  ## @:    ^         ^
  ## @:~~~~
  assert(startPos >= 0, "startPos is less than 0")

  if startPos >= text.len:
    # A variable starts with an ascii letter.
    return newVariableNameOr(wVarStartsWithLetter, "", startPos)

  type
    State = enum
      ## Parsing states.
      start, middle, atHyphenUnderscore, dotState, endWhitespace

  var state = start
  var names = newSeq[string]()
  var currentName = ""
  var variableNameKind: VariableNameKind
  var currentPos: int
  var stopOnChar = false

  # Loop through the text one byte at a time.
  currentPos = startPos - 1
  while true:
    inc(currentPos)
    if currentPos > text.len - 1:
      break

    let ch = text[currentPos]
    case state
    of start:
      case ch
      of 'a'..'z', 'A'..'Z':
        currentName.add(ch)
        state = middle
      else:
        # A variable starts with an ascii letter.
        return newVariableNameOr(wVarStartsWithLetter, "", currentPos)

    of middle:
      case ch
      of 'a'..'z', 'A'..'Z', '0'..'9':
        currentName.add(ch)
      of '-', '_':
        currentName.add(ch)
        state = atHyphenUnderscore
      of '.':
        state = dotState
      of '(':
        variableNameKind = vnkFunction
        state = endWhitespace
      of '[':
        variableNameKind = vnkGet
        state = endWhitespace
      of ' ', '\t':
        variableNameKind = vnkNormal
        state = endWhitespace
      else:
        # done
        stopOnChar = true
        break

      # Add the current name to the names list.
      case state
      of endWhitespace, start, dotState:
        names.add(currentName)
        currentName = ""
      of atHyphenUnderscore, middle:
        discard

    of atHyphenUnderscore:
      case ch
      of 'a'..'z', 'A'..'Z', '0'..'9':
        state = middle
      of '-', '_':
        discard
      else:
        # A variable name ends with an ascii letter or digit.
        return newVariableNameOr(wVarEndsWith, "", currentPos)
      currentName.add(ch)

    of dotState:
      case ch
      of 'a'..'z', 'A'..'Z':
        state = middle
        currentName.add(ch)
      else:
        # A variable starts with an ascii letter.
        return newVariableNameOr(wVarStartsWithLetter, "", currentPos)

    of endWhitespace:
      case ch
      of ' ', '\t':
        discard
      else:
        # done
        stopOnChar = true
        break

  case state:
  of start, middle:
    names.add(currentName)
  of endWhitespace:
    discard
  of dotState, atHyphenUnderscore:
    # A variable name ends with an ascii letter or digit.
    return newVariableNameOr(wVarEndsWith, "", currentPos)

  let dotName = names.join(".")
  if dotName.len > maxNameLength:
    # A variable and dot name are limited to 64 characters.
    return newVariableNameOr(wVarMaximumLength, "", startPos+maxNameLength)

  result = newVariableNameOr(dotName, variableNameKind, currentPos)

proc getVariableName*(text: string, start: Natural): VariableNameOr =
  ## Get a variable name from the statement. Skip leading whitespace.

  # Skip whitespace, if any.
  var runningPos = start
  let spaceMatchO = matchTabSpace(text, runningPos)
  if isSome(spaceMatchO):
    runningPos += spaceMatchO.get().length

  result = getVariableNameOr(text, runningPos)

func isTriple(line: string, ch: char, ix: Natural): bool =
  if ch == '"' and line.len >= ix-2 and
      line[ix-1] == '"' and line[ix-2] == '"':
    result = true

func matchTripleOrPlusSign*(line: string): Found =
  ## Match the optional """ or + at the end of the line. This tells
  ## whether the statement continues on the next line for code files.

  type
    Have = enum
      have_nothing, have_lf, have_cr

  var state = have_nothing
  var ix = line.len - 1
  while true:
    if ix < 0 or ix >= line.len:
      case state:
      of have_nothing:
        return nothing
      of have_lf:
        return newline
      of have_cr:
        return crlf
    var ch = line[ix]
    case state:
    of have_nothing:
      if ch == '\n':
        state = have_lf
        dec(ix)
        continue
      if ch == '+':
        return plus
      elif isTriple(line, ch, ix):
        return triple
      return nothing
    of have_lf:
      if ch == '\r':
        state = have_cr
        dec(ix)
        continue
      if ch == '+':
        return plus_n
      elif isTriple(line, ch, ix):
        return triple_n
      return newline
    of have_cr:
      if ch == '+':
        return plus_crlf
      elif isTriple(line, ch, ix):
        return triple_crlf
      return crlf

func addText*(line: string, found: Found, text: var string) =
  ## Add the line up to the line-ending to the text string.
  var skipNum: Natural
  var addNewline = false
  case found:
  of nothing:
    skipNum = 0
  of plus:
    skipNum = 1
  of triple:
    # Include the quotes.
    skipNum = 0
    addNewline = true
  of newline:
    skipNum = 1
  of plus_n:
    skipNum = 2
  of triple_n:
    # Include the quotes and newline
    skipNum = 0
  of crlf:
    skipNum = 2
  of plus_crlf:
    skipNum = 3
  of triple_crlf:
    # Include the quotes.
    skipNum = 2
    addNewline = true

  var endPos = line.len - 1 - skipNum
  if endPos < -1:
    endPos = -1
  text.add(line[0 .. endPos])
  if addNewline:
    text.add('\n')

func getFragmentAndPos*(statement: Statement, start: Natural):
     (string, Natural) =
  ## Split up a long statement around the given position.  Return the
  ## statement fragment, and the position where the fragment starts in
  ## the statement.

  # Change the newlines and control characters to something readable
  # and so the fragment fits on one line.
  let text = visibleControl(statement.text)

  var fragment: string
  var extraStart = ""
  var extraEnd = ""
  let fragmentMax = 60
  let halfFragment = fragmentMax div 2
  var startPos: int
  var endPos: int
  var pointerPos: int

  if text.len <= fragmentMax:
    fragment = text
    startPos = start
    pointerPos = start
  else:
    startPos = start.int - halfFragment
    if startPos < 0:
      startPos = 0
    else:
      extraStart = "..."

    endPos = startPos + fragmentMax
    if endPos > text.len:
      endPos = text.len
    else:
      extraEnd = "..."
    fragment = extraStart & text[startPos ..< endPos] & extraEnd
    pointerPos = start.int - startPos + extraStart.len

  assert pointerPos >= 0
  result = (fragment, Natural(pointerPos))

when showPos:
  proc showDebugPos*(statement: Statement, start: Natural, symbol: string) =
    let (fragment, pointerPos) = getFragmentAndPos(statement, start)
    echo fragment
    echo startColumn(fragment, pointerPos, symbol)

func getWarnStatement*(filename: string, statement: Statement,
    warningData: WarningData): string =
  ## Return a multiline error message.

  let start = warningData.pos
  assert start >= 0
  let (fragment, pointerPos) = getFragmentAndPos(statement, start)

  let warning = warningData.messageId
  let p1 = warningData.p1

  var message = """
$1
statement: $2
           $3""" % [
    getWarningLine(filename, statement.lineNum, warning, p1),
    fragment,
    startColumn(fragment, pointerPos)
  ]
  result = message

proc warnStatement*(env: var Env, statement: Statement,
                    warningData: WarningData, sourceFilename = "") =
  ## Show an invalid statement with a pointer pointing at the start of
  ## the problem. Long statements are trimmed around the problem area.
  var message: string
  var filename: string
  if sourceFilename == "":
    filename = env.templateFilename
  else:
    filename = sourceFilename

  if warningData.messageId == wUserMessage:
    # Format user messages on one line.
    message = "$1($2): $3" % [filename,
      $statement.lineNum, warningData.p1]
  elif warningData.messageId == wSuccess:
    # Don't output success messages.
    return
  else:
    message = getWarnStatement(filename, statement, warningData)
  env.outputWarning(statement.lineNum, message)

proc warnStatement*(env: var Env, statement: Statement,
    messageId: MessageId, p1: string, pos:Natural, sourceFilename = "") =
  let warningData = newWarningData(messageId, p1, pos)
  env.warnStatement(statement, warningData, sourceFilename)

func removeLineEnd*(s: string): string =
  ## Return a new string with the \n or \r\n removed from the end of
  ## the line.
  var last = s.len - 1
  if s.len > 0 and s[^1] == '\n':
    dec(last)
    if s.len > 1 and s[^2] == '\r':
      dec(last)
  result = system.substr(s, 0, last)

iterator yieldStatements*(cmdLines: CmdLines): Statement =
  ## Iterate through the command's statements. A statement can be
  ## blank or all whitespace.

  type
    State {.pure.} = enum
      ## Finite state machine states for finding statements.
      start, double

  # Find the statements in the list of command lines.  Statements may
  # continue between them. A statement continues when there is a plus
  # sign at the end of the line.

  var text = newStringOfCap(defaultMaxLineLen)
  var ending = ""
  var lineNum: Natural
  var start: Natural
  if cmdLines.lines.len > 0:
    lineNum = cmdLines.lineParts[0].lineNum
    start = cmdLines.lineParts[0].codeStart
  var state = State.start
  for ix in 0 ..< cmdLines.lines.len:
    let line = cmdLines.lines[ix]
    let lp = cmdLines.lineParts[ix]
    ending = lp.ending
    for pos in lp.codeStart ..< lp.codeStart+lp.codeLen:
      let ch = line[pos]
      if state == State.start:
        if ch == '"':
          state = double
      elif state == double:
        if ch == '"':
          state = State.start
      text.add(ch)

    # A statement is terminated by the end of the line without a
    # continuation.
    if not lp.continuation:
      yield newStatement(removeLineEnd(text), lineNum, ending)

      # Setup variables for the next line, if there is one.
      text.setLen(0)
      ending = ""
      if cmdLines.lines.len > ix+1:
        lineNum = lp.lineNum + 1
        start = cmdLines.lineParts[ix+1].codeStart

  if not emptyOrSpaces(text):
    yield newStatement(removeLineEnd(text), lineNum, ending)

proc readStatement*(env: var Env, lb: var LineBuffer): Option[Statement] =
  ## Read the next statement from the code file reading multiple lines
  ## if needed.

  type
    State = enum
      ## Parsing states.
      start, plusSign, multiline

  var text: string
  var state = start
  while true:
    # Read a line.
    var line = lb.readline()

    # Validate the line is UTF-8.
    let invalidPos = validateUtf8String(line)
    if invalidPos != -1:
      let statement = newStatement(line, lb.getLineNum())
      env.warnStatement(statement,
        newWarningData(wInvalidUtf8ByteSeq, $invalidPos, invalidPos), lb.getfilename)
      return

    if line == "":
      var messageId: MessageId
      case state
        of start:
          return # done
        of plusSign:
          # Out of lines looking for the plus sign line.
          messageId = wNoPlusSignLine
        of multiline:
          # Out of lines looking for the multiline string.
          messageId = wIncompleteMultiline
      env.warn(lb.getFilename, lb.getLineNum(), newWarningData(messageId))
      return

    # Match the optional """ or + at the end of the line. This tells
    # whether the statement continues on the next line.
    let found = matchTripleOrPlusSign(line)

    case state:
      of start:
        if found == plus or found == plus_n or found == plus_crlf:
          state = plusSign
        elif found == triple or found == triple_n or found == triple_crlf:
          state = multiline

          # Check for the case where there are starting and ending
          # triple quotes on the same line. This catches the mistake
          # like: a = """xyx""".
          let triplePos = line.find(tripleQuotes)
          if triplePos != -1 and triplePos+4 != line.len:
            # Triple quotes must always end the line.
            let statement = newStatement(line, lb.getLineNum())
            env.warnStatement(statement,
              newWarningData(wTripleAtEnd, "", triplePos+3), lb.getfilename)
            return

        addText(line, found, text)
        if state == start:
          break # done

      of plusSign:
        if not (found == plus or found == plus_n or found == plus_crlf):
          state = start
        addText(line, found, text)
        if state == start:
          break # done

      of multiline:
        if found == triple or found == triple_n or found == triple_crlf:
          state = start
          addText(line, found, text)
        else:
          # Add the whole line.
          addText(line, nothing, text)
        if state == start:
          break # done

  result = some(newStatement(text, lb.getLineNum()))

func getMultilineStr*(text: string, start: Natural): ValuePosSiOr =
  ## Return the triple quoted string literal. The startPos points one
  ## @:past the leading triple quote.  Return the parsed
  ## @:string value and the ending position one past the trailing
  ## @:whitespace.

  # a = """\ntest string"""\n
  #         ^                ^

  if start >= text.len or text[start] != '\n':
    # Triple quotes must always end the line.
    return newValuePosSiOr(wTripleAtEnd, "", start)
  if start + 5 > text.len or text[text.len - 4 .. text.len - 1] != "\"\"\"\n":
    # Missing the ending triple quotes.
    return newValuePosSiOr(wMissingEndingTriple, "", text.len)

  let newStr = text[start + 1 .. text.len - 5]
  result = newValuePosSiOr(newStr, text.len)

func getString*(statement: Statement, start: Natural): ValuePosSiOr =
  ## Return a literal string value and position after it. The start
  ## parameter is the index of the first quote in the statement and
  ## the return position is after the optional trailing white space
  ## following the last quote.
  ## @:
  ## @:~~~
  ## @:var = "hello" # asdf
  ## @:      ^       ^
  ## @:~~~~

  let str = statement.text

  # Parse the json string and remove escaping.
  result = parseJsonStr(str, start+1)
  if result.isMessage:
    return result

  # A triple quoted string looks like an empty string with a quote
  # following it to the parseJsonStr function.
  let pos = result.value.pos
  if pos < str.len and pos == start+2 and str[start+2] == '"':
    result = getMultilineStr(str, start+3)

func getNumber*(statement: Statement, start: Natural): ValuePosSiOr =
  ## Return the literal number value and position after it.  The start
  ## index points at a digit or minus sign. The position includes the
  ## trailing whitespace.
  result = parseNumber(statement.text, start)

func skipArgument*(statement: Statement, startPos: Natural): PosOr =
  ## Skip past the argument.  startPos points at the first character
  ## of a function argument.  Return the first non-whitespace
  ## character after the argument or a message when there is a
  ## problem.
  ## @:~~~
  ## @:a = fn( 1 )
  ## @:        ^ ^
  ## @:          ^^
  ## @:a = fn( 1 , 2 )
  ## @:        ^ ^
  ## @:~~~~

  let text = statement.text
  assert(startPos < text.len, "startPos is greater than the text len")
  assert(startPos >= 0, "startPos is less than 0")

  type
    State = enum
      ## Parsing states.
      start, middle, inString, slash, inGroup,
      inGroupString, inGroupSlash, endWhitespace

  var state = start
  var pos = text.len

  # The difference between the number of left and right parentheses or
  # left and right brackets.
  var groupCount = 0
  var groupSymbol: char # ( or [

  # Loop through the text one byte at a time.
  for ix in countUp(startPos, text.len-1):
    let ch = text[ix]

    case state
    of start:
      case ch
      of startTFVarNumber:
        state = middle
      # string
      of '"':
        state = inString
      # boolean expression or list
      of '(', '[':
        state = inGroup
        groupSymbol = ch
        inc(groupCount)
      else:
        # Invalid argument.
        return newPosOr(wInvalidFirstArgChar, "", startPos)

    of inString:
      case ch
      of '\\':
        state = slash
      of '"':
        state = endWhitespace
      else:
        discard

    of slash:
      state = inString

    of middle:
      case ch
      of '(', '[':
        state = inGroup
        groupSymbol = ch
        inc(groupCount)
      of ',', ')', ']':
        return newPosOr(ix)
      of ' ', '\t':
        state = endWhitespace
      # true, false, variable, number
      of variableChars:
        discard
      else:
        # Invalid character.
        return newPosOr(wInvalidCharacter, "", ix)

    of inGroup:
      case ch
      of '"':
        state = inGroupString
      of '(', '[':
        if groupSymbol == ch:
          inc(groupCount)
      of ')':
        if groupSymbol == '(':
          dec(groupCount)
          if groupCount == 0:
            state = endWhiteSpace
      of ']':
        if groupSymbol == '[':
          dec(groupCount)
          if groupCount == 0:
            state = endWhiteSpace
      else:
        discard

    of inGroupString:
      case ch
      of '\\':
        state = inGroupSlash
      of '"':
        state = inGroup
      else:
        discard

    of inGroupSlash:
      state = inGroupString

    of endWhitespace:
      case ch
      of ' ', '\t', '\n', '\r':
        discard
      else:
        pos = ix
        break

  if state != endWhitespace:
    case state:
    of inGroup:
      if groupSymbol == '(':
        # No matching end right parentheses.
        result = newPosOr(wNoMatchingParen, "", text.len)
      else:
        # No matching end right bracket.
        result = newPosOr(wNoMatchingBracket, "", text.len)
    else:
      # Ran out of characters before finishing the statement.
      result = newPosOr(wNotEnoughCharacters, "", text.len)
  else:
    result = newPosOr(pos)

func skipArg(statement: Statement, start: Natural): PosOr =
  when showPos:
    showDebugPos(statement, start, "^ s arg")
  result = skipArgument(statement, start)
  when showPos:
    var pos: Natural
    if result.isMessage:
      pos = result.message.pos
    else:
      pos = result.value
    showDebugPos(statement, pos, "^ f arg")

# Forward reference to getValuePosSi since we call it recursively.
proc getValuePosSi*(env: var Env, statement: Statement, start: Natural, variables:
  Variables): ValuePosSiOr

func getSpecialFunction(funcVar: Value): SpecialFunction =
  ## Return the function type given a function variable.

  var value: Value
  if funcVar.kind == vkList:
    let list = funcVar.listv.list
    if list.len < 1:
      return spNotSpecial
    value = list[0]
  else:
    value = funcVar

  # All special functions are built-in functions.
  if not (value.kind == vkFunc and value.funcv.builtIn):
    return spNotSpecial

  case value.funcv.signature.name
  of "if":
    result = spIf
  of "if0":
    result = spIf0
  of "and":
    result = spAnd
  of "or":
    result = spOr
  of "warn":
    result = spWarn
  of "return":
    result = spReturn
  of "log":
    result = spLog
  of "func":
    result = spFunc
  of "listLoop":
    result = spListLoop
  else:
    result = spNotSpecial

proc bareReturn(
    env: var Env,
    statement: Statement,
    start: Natural,
    variables: Variables,
  ): ValuePosSiOr =
  ## Handle the return function.
  ## if(true, return( "stop")  )
  ##                  ^         ^
  ## return( "stop")
  ##         ^      ^
  # Get the value.
  var runningPos = start
  let valueAndPosOr = getValuePosSi(env, statement, runningPos, variables)
  if valueAndPosOr.isMessage:
    return valueAndPosOr
  var value = valueAndPosOr.value.value
  runningPos = valueAndPosOr.value.pos

  # Match ) and trailing whitespace.
  let parenO = matchSymbol(statement.text, gRightParentheses, runningPos)
  if not parenO.isSome:
    # No matching end right parentheses.
    return newValuePosSiOr(wNoMatchingParen, "", runningPos)
  runningPos += parenO.get().length

  return newValuePosSiOr(value, runningPos, seReturn)

proc ifFunctions*(
    env: var Env,
    specialFunction: SpecialFunction,
    statement: Statement,
    start: Natural,
    variables: Variables,
  ): ValuePosSiOr =
  ## Return the if/if0 function's value and position after. It
  ## conditionally runs one of its arguments and skips the
  ## other. Start points at the first argument of the function. The
  ## position includes the trailing whitespace after the ending ).
  ## @:
  ## @:This handles the three parameter form with an assignment.
  ## @:
  ## @:~~~
  ## @:a = if(cond, then, else)
  ## @:       ^                ^
  ## @:~~~~

  # Get the condition's value.
  let vlcOr = getValuePosSi(env, statement, start, variables)
  if vlcOr.isMessage:
    return vlcOr
  let cond = vlcOr.value.value
  var runningPos = vlcOr.value.pos

  # Get the boolean for IF and IF0.
  var condition = false
  if specialFunction == spIf:
    if cond.kind != vkBool:
      # The if condition must be a bool value, got a $1.
      return newValuePosSiOr(wExpectedBool, $cond.kind, start)
    condition = cond.boolv
  else: # if0
    condition = if0Condition(cond) == false

  # Match the comma and whitespace.
  let commaO = matchSymbol(statement.text, gComma, runningPos)
  if not commaO.isSome:
    # An if with an assignment takes three arguments.
    return newValuePosSiOr(wAssignmentIf, "", start)
  runningPos += commaO.get().length

  # Handle the second parameter.
  var vl2Or: ValuePosSiOr
  var skip = (condition == false)

  if skip:
    let posOr = skipArg(statement, runningPos)
    if posOr.isMessage:
      return newValuePosSiOr(posOr.message)
    runningPos = posOr.value
  else:
    # Get the second value.
    vl2Or = getValuePosSi(env, statement, runningPos, variables)
    if vl2Or.isMessage:
      return vl2Or
    runningPos = vl2Or.value.pos

  # Match the comma and whitespace.
  var vl3Or: ValuePosSiOr
  let cO = matchSymbol(statement.text, gComma, runningPos)
  if not cO.isSome:
    # An if with an assignment takes three arguments.
    return newValuePosSiOr(wAssignmentIf, "", runningPos)
  runningPos += cO.get().length

  # Handle the third parameter.
  skip = (condition == true)
  if skip:
    let posOr = skipArg(statement, runningPos)
    if posOr.isMessage:
      return newValuePosSiOr(posOr.message)
    runningPos = posOr.value
  else:
    vl3Or = getValuePosSi(env, statement, runningPos, variables)
    if vl3Or.isMessage:
      return vl3Or
    runningPos = vl3Or.value.pos

  # Match ) and trailing whitespace.
  let parenO = matchSymbol(statement.text, gRightParentheses, runningPos)
  if not parenO.isSome:
    # No matching end right parentheses.
    return newValuePosSiOr(wNoMatchingParen, "", runningPos)
  runningPos += parenO.get().length

  var value: Value
  if condition:
    value = vl2Or.value.value
  else:
    value = vl3Or.value.value
  result = newValuePosSiOr(value, runningPos)

proc bareIfAndIf0*(
    env: var Env,
    specialFunction: SpecialFunction,
    statement: Statement,
    start: Natural,
    variables: Variables,
  ): ValuePosSiOr =
  ## Handle the bare if/if0. Return the resulting value and the
  ## position in the statement after the if.
  ## @:
  ## @:~~~
  ## @:if(cond, return("stop"))
  ## @:   ^                    ^
  ## @:if(c, warn("c is true"))
  ## @:   ^                    ^
  ## @:~~~~
  var runningPos = start

  # Get the condition's value.
  let vlcOr = getValuePosSi(env, statement, runningPos, variables)
  if vlcOr.isMessage:
    return vlcOr
  let cond = vlcOr.value.value
  runningPos = vlcOr.value.pos

  # Get the boolean for IF and IF0.
  var condition = false
  if specialFunction == spIf:
    if cond.kind != vkBool:
      # The if condition must be a bool value, got a $1.
      return newValuePosSiOr(wExpectedBool, $cond.kind, start)
    condition = cond.boolv
  else: # if0
    condition = if0Condition(cond) == false

  # Match the comma and whitespace.
  let commaO = matchSymbol(statement.text, gComma, runningPos)
  if not commaO.isSome:
    # "An IF without an assignment takes two arguments.
    return newValuePosSiOr(wBareIfTwoArguments, "", start)
  runningPos += commaO.get().length

  # Handle the second parameter.
  var skip = (condition == false)
  var value2: Value
  var se2: SideEffect
  if skip:
    let posOr = skipArg(statement, runningPos)
    if posOr.isMessage:
      return newValuePosSiOr(posOr.message)
    runningPos = posOr.value
    value2 = newValue(0)
    se2 = seBareIfIgnore
  else:
    # Get the second value.
    var valueAndPosOr: ValuePosSiOr
    # Handle the return function extra special.
    if statement.text[runningPos .. ^1].startsWith("return("):
      const
        returnParenLen = len("return(")
      runningPos += returnParenLen

      # Skip whitespace, if any.
      let spaceMatchO = matchTabSpace(statement.text, runningPos)
      if isSome(spaceMatchO):
        runningPos += spaceMatchO.get().length

      valueAndPosOr = bareReturn(env, statement, runningPos, variables)
      if valueAndPosOr.isMessage:
        return valueAndPosOr
      se2 = valueAndPosOr.value.sideEffect
    else:
      valueAndPosOr = getValuePosSi(env, statement, runningPos, variables)
      if valueAndPosOr.isMessage:
        return valueAndPosOr
      se2 = valueAndPosOr.value.sideEffect
    let vandp = valueAndPosOr.value
    runningPos = vandp.pos
    value2 = vandp.value

  # Match , or ) and trailing whitespace.
  let commaSymbolO = matchCommaOrSymbol(statement.text, gRightParentheses, runningPos)
  if not commaSymbolO.isSome:
    # No matching end right parentheses.
    return newValuePosSiOr(wNoMatchingParen, "", runningPos)
  let commaSymbol = commaSymbolO.get()
  let foundSymbol = commaSymbol.getGroup()
  if foundSymbol == ",":
    # An IF without an assignment takes two arguments.
    return newValuePosSiOr(wBareIfTwoArguments, "", runningPos)

  runningPos += commaSymbol.length

  result = newValuePosSiOr(value2, runningPos, se2)

proc andOrFunctions*(
    env: var Env,
    specialFunction: SpecialFunction,
    statement: Statement,
    start: Natural,
    variables: Variables,
    listCase = false
  ): ValuePosSiOr =
  ## Return the and/or function's value and the position after. The and
  ## function stops on the first false. The or function stops on the
  ## first true. The rest of the arguments are skipped.
  ## Start points at the first parameter of the function. The position
  ## includes the trailing whitespace after the ending ).
  # cases:
  #   c1 = and(a, b)  # test
  #            ^      ^
  #   c2 = or(a, b)  # test
  #           ^      ^

  # Get the first argument value.
  let vlcOr = getValuePosSi(env, statement, start, variables)
  if vlcOr.isMessage:
    return vlcOr
  let firstValue = vlcOr.value.value
  var runningPos = vlcOr.value.pos

  if firstValue.kind != vkBool:
    # Expected bool argument got $1.
    return newValuePosSiOr(wExpectedBool, $firstValue.kind, start)

  let a = firstValue.boolv
  var skip = if specialFunction == spAnd: a == false else: a == true

  # Match the comma and whitespace.
  let commaO = matchSymbol(statement.text, gComma, runningPos)
  if not commaO.isSome:
    # Expected two arguments.
    return newValuePosSiOr(wTwoArguments, "", runningPos)
  runningPos += commaO.get().length

  # Handle the second parameter.
  var secondValue: Value
  var afterSecond: Natural
  if skip:
    let posOr = skipArg(statement, runningPos)
    if posOr.isMessage:
      return newValuePosSiOr(posOr.message)
    afterSecond = posOr.value
    secondValue = newValue(0)
  else:
    let vl2Or = getValuePosSi(env, statement, runningPos, variables)
    if vl2Or.isMessage:
      return vl2Or
    afterSecond = vl2Or.value.pos
    secondValue = vl2Or.value.value

  var b: bool
  if skip:
    b = true
  else:
    if secondValue.kind != vkBool:
      # Expected bool argument got $1.
      return newValuePosSiOr(wExpectedBool, $secondValue.kind, runningPos)
    b = secondValue.boolv
  runningPos = afterSecond

  # Match ) and trailing whitespace.
  let parenO = matchSymbol(statement.text, gRightParentheses, runningPos)
  if not parenO.isSome:
    # Expected two arguments.
    return newValuePosSiOr(wTwoArguments, "", runningPos)
  runningPos += parenO.get().length

  var value: bool
  if specialFunction == spAnd:
    value = a and b
  else:
    value = a or b
  result = newValuePosSiOr(newValue(value), runningPos)

proc callUserFunction*(env: var Env, funcVar: Value, variables: Variables, arguments: seq[Value]): FunResult

proc getArguments*(
    env: var Env,
    statement: Statement,
    start: Natural,
    variables: Variables,
    listCase=false,
    arguments: var seq[Value],
    argumentStarts: var seq[Natural],
  ): ValuePosSiOr =
  ## Get the function arguments and the position of each. If an
  ## argument has a side effect, the return value and pos and side
  ## effect is returned, else a 0 value and seNone is returned.
  ## @:~~~
  ## @:newList = listLoop(list, callback, state)  # comment
  ## @:                   ^                       ^
  ## @:newList = listLoop(return(3), callback, state)  # comment
  ## @:                          ^ ^
  ## @:~~~~

  var runningPos = start

  # Look for the no argument case.
  let symbol = if listCase: gRightBracket else: gRightParentheses
  let startSymbolO = matchSymbol(statement.text, symbol, runningPos)
  if startSymbolO.isSome:
    # There are no arguments.
    runningPos = start + startSymbolO.get().length
  else:
    # Get the arguments to the function.
    while true:
      let vlOr = getValuePosSi(env, statement, runningPos, variables)
      if vlOr.isMessage:
        return vlOr
      arguments.add(vlOr.value.value)
      argumentStarts.add(runningPos)
      runningPos = vlOr.value.pos

      # Get the , or ) or ] and white space following the value.
      let commaSymbolO = matchCommaOrSymbol(statement.text, symbol, runningPos)
      if not commaSymbolO.isSome:
        if symbol == gRightParentheses:
          # Expected comma or right parentheses.
          return newValuePosSiOr(wMissingCommaParen, "", runningPos)
        else:
          # Missing comma or right bracket.
          return newValuePosSiOr(wMissingCommaBracket, "", runningPos)
      let commaSymbol = commaSymbolO.get()
      runningPos = runningPos + commaSymbol.length
      let foundSymbol = commaSymbol.getGroup()
      if (foundSymbol == ")" and symbol == gRightParentheses) or
         (foundSymbol == "]" and symbol == gRightBracket):
        break

  result = newValuePosSiOr(newValue(0), runningPos, seNone)

func warningParameterPos(
    parameter: int,
    argumentStarts: seq[Natural],
    start: Natural,
    functionStart: Natural
  ): Natural =
  ## Translate the warning parameter to a warning position.
  if parameter == -1:
    result = functionStart
  elif parameter < argumentStarts.len:
    result = argumentStarts[parameter]
  else:
    result = start

proc getFunctionValuePosSi*(
    env: var Env,
    functionName: string,
    functionPos: Natural,
    statement: Statement,
    start: Natural,
    variables: Variables,
    listCase = false): ValuePosSiOr =
  ## Return the function's value and the position after it. Start points at the
  ## first argument of the function. The position includes the trailing
  ## whitespace after the ending ).
  ## @:
  ## @:~~~
  ## @:a = get(b, 2, c) # condition
  ## @:        ^        ^
  ## @:a = get(b, len("hi"), c)
  ## @:               ^    ^
  ## @:~~~~

  # Get all the function arguments.
  var runningPos = start
  var arguments: seq[Value]
  var argumentStarts: seq[Natural]
  let vpOr = getArguments(env, statement, runningPos, variables, listCase,
    arguments, argumentStarts)
  if vpOr.isMessage:
    return vpOr
  runningPos = vpOr.value.pos

  # Lookup the variable's value.
  let valueOr = getVariable(variables, functionName, npBuiltIn)
  if valueOr.isMessage:
    let warningData = newWarningData(valueOr.message.messageId,
      valueOr.message.p1, start)
    return newValuePosSiOr(warningData)
  let value = valueOr.value

  # Find the best matching function by looking at the arguments.
  let funcValueOr = getBestFunction(value, arguments)
  if funcValueOr.isMessage:
    let warningData = newWarningData(funcValueOr.message.messageId,
      funcValueOr.message.p1, start)
    return newValuePosSiOr(warningData)
  let funcVar = funcValueOr.value

  # Call the function.
  assert funcVar.kind == vkFunc
  var funResult: FunResult
  if funcVar.funcv.builtIn:
    funResult = funcVar.funcv.functionPtr(variables, arguments)
  else:
    funResult = callUserFunction(env, funcVar, variables, arguments)

  if funResult.kind == frWarning:
    let warningPos = warningParameterPos(funResult.parameter, argumentStarts, start, functionPos)
    return newValuePosSiOr(funResult.warningData.messageId,
      funResult.warningData.p1, warningPos)

  var sideEffect: SideEffect
  # todo: use the signature function name instead?
  assert functionName != "return"

  if functionName == "log":
    sideEffect = seLogMessage
  else:
    sideEffect = seNone

  result = newValuePosSiOr(funResult.value, runningPos, sideEffect)

func runBoolOp*(left: Value, op: string, right: Value): Value =
  ## Evaluate the bool expression and return a bool value.
  assert left.kind == vkBool and right.kind == vkBool

  var b: bool
  if op == "and":
    b = left.boolv and right.boolv
  elif op == "or":
    b = left.boolv or right.boolv
  else:
    assert(false, "Expected the boolean operator 'and' or 'or'.")
  result = newValue(b)

func runCompareOp*(left: Value, op: string, right: Value): Value =
  ## Evaluate the comparison and return a bool value.
  assert left.kind == right.kind
  assert left.kind == vkInt or left.kind == vkFloat or left.kind == vkString

  let cmpValue = cmpBaseValues(left, right)
  var b: bool
  case op
  of "==":
    b = cmpValue == 0
  of "!=":
    b = cmpValue != 0
  of "<":
    b = cmpValue < 0
  of ">":
    b = cmpValue > 0
  of "<=":
    b = cmpValue <= 0
  of ">=":
    b = cmpValue >= 0
  else:
    assert(false, "Expected a boolean expression operator.")
  result = newValue(b)

# Forward reference since we call getCondition recursively.
proc getCondition*(env: var Env, statement: Statement, start: Natural,
    variables: Variables): ValuePosSiOr

proc getValueOrNestedCond(env: var Env, statement: Statement, start: Natural,
    variables: Variables): ValuePosSiOr =
  ## Return a value and position after it. If start points at a nested
  ## condition, handle it.

  var runningPos = start
  let parenO = matchSymbol(statement.text, gLeftParentheses, runningPos)
  if parenO.isSome:
    # Found a left parenetheses, get the nested condition.
    result = getCondition(env, statement, start, variables)
  else:
    result = getValuePosSi(env, statement, start, variables)

proc getCondition*(env: var Env, statement: Statement, start: Natural,
    variables: Variables): ValuePosSiOr =
  ## Return the bool value of the condition expression and the
  ## position after it.  The start index points at the ( left
  ## parentheses. The position includes the trailing whitespace after
  ## the ending ).
  ## @:
  ## @:~~~
  ## @:a = (5 < 3) # condition
  ## @:    ^       ^
  ## @:~~~~
  when showPos:
    showDebugPos(statement, start, "^ s condition")

  var runningPos = start
  var lastBoolOp: string

  # Match the left parentheses and following whitespace to get the
  # first argument.
  let parenO = matchSymbol(statement.text, gLeftParentheses, runningPos)
  assert parenO.isSome
  runningPos += parenO.get().length

  # Return a value and position after handling any nested condition.
  var accumOr = getValueOrNestedCond(env, statement, runningPos, variables)
  if accumOr.isMessage:
    return accumOr
  var accum = accumOr.value.value
  runningPos = accumOr.value.pos

  while true:
    # Check for ending right parentheses and trailing whitespace.
    let rightParenO = matchSymbol(statement.text, gRightParentheses, runningPos)
    if rightParenO.isSome:
      let finish = runningPos + rightParenO.get().length
      let vAndL = newValuePosSi(accum, finish)
      when showPos:
        showDebugPos(statement, finish, "^ f condition")
      return newValuePosSiOr(vAndL)

    # Get the boolean operator.
    let opO = matchBoolExprOperator(statement.text, runningPos)
    if not opO.isSome:
      # Expected a boolean expression operator, and, or, ==, !=, <, >, <=, >=.
      return newValuePosSiOr(wNotBoolOperator, "", runningPos)
    let op = opO.getGroup()
    if (op == "and" or op == "or") and accum.kind != vkBool:
      # A boolean operator’s left value must be a bool.
      return newValuePosSiOr(wBoolOperatorLeft, "", runningPos)

    # Look for short ciruit conditions.
    var sortCiruitTaken: bool
    var shortCiruitResult: bool
    if op == "or":
      if lastBoolOp == "":
        lastBoolOp = "or"
      elif lastBoolOp != "or":
        # When mixing 'and's and 'or's you need to specify the precedence with parentheses.
        return newValuePosSiOr(wNeedPrecedence, "", runningPos)
      if accum.boolv == true:
        sortCiruitTaken = true
        shortCiruitResult = true
    elif op == "and":
      if lastBoolOp == "":
        lastBoolOp = "and"
      elif lastBoolOp != "and":
        # When mixing 'and's and 'or's you need to specify the precedence with parentheses.
        return newValuePosSiOr(wNeedPrecedence, "", runningPos)
      if accum.boolv == false:
        sortCiruitTaken = true
        shortCiruitResult = false
    else:
      # We have a compare operator.
      if accum.kind != vkInt and accum.kind != vkFloat and accum.kind != vkString:
        # The comparison operator’s left value must be a number or string.
        return newValuePosSiOr(wCompareOperator, "", runningPos)

    runningPos += opO.get().length

    if sortCiruitTaken:
      # Sort ciruit the condition and skip past the closing right parentheses.
      let posOr = skipArg(statement, start)
      if posOr.isMessage:
        return newValuePosSiOr(posOr.message)
      runningPos = posOr.value
      when showPos:
        showDebugPos(statement, runningPos, "^ f condition")
      return newValuePosSiOr(newValue(shortCiruitResult), runningPos)

    # Return a value and position after handling any nestedcondition.
    let vlRightOr = getValueOrNestedCond(env, statement, runningPos, variables)
    if vlRightOr.isMessage:
      return vlRightOr
    let xyz = runningPos
    let right = vlRightOr.value.value
    runningPos = vlRightOr.value.pos

    # We have a left and right value with an operator but the right value
    # might be part of a following comparision.

    var bValue: Value
    if op != "and" and op != "or":
      # Compare two values.
      if right.kind != accum.kind:
        # The comparison operator’s right value must be the same type as the left value.
        let messageData = newWarningData(wCompareOperatorSame, "", xyz)
        return newValuePosSiOr(messageData)
      bValue = runCompareOp(accum, op, right)
    elif right.kind == vkBool:
      bValue = runBoolOp(accum, op, right)
    else:
      # Get the next operator.
      let op2O = matchCompareOperator(statement.text, runningPos)
      if not op2O.isSome:
        # Expected a compare operator, ==, !=, <, >, <=, >=.
        return newValuePosSiOr(wNotCompareOperator, "", runningPos)
      let op2 = op2O.getGroup()
      runningPos += op2O.get().length

      # Return a value and position after handling any nested condition.
      let vlThirdOr = getValueOrNestedCond(env, statement, runningPos, variables)
      if vlThirdOr.isMessage:
        return vlThirdOr

      if vlThirdOr.value.value.kind != right.kind:
        # The comparison operator’s right value must be the same type as the left value.
        return newValuePosSiOr(wCompareOperatorSame, "", runningPos)

      let bValue2 = runCompareOp(right, op2, vlThirdOr.value.value)
      bValue = runBoolOp(accum, op, bValue2)
      runningPos = vlThirdOr.value.pos

    accum = newValue(bValue)

proc getBracketedVarValue*(env: var Env, statement: Statement, start: Natural,
    container: Value, variables: Variables): ValuePosSiOr =
  ## Return the value of the bracketed variable and the position after
  ## the trailing whitespace.. Start points at the the first argument.
  ## @:
  ## @:~~~
  ## @:a = list[ 4 ]
  ## @:          ^  ^
  ## @:a = dict[ "abc" ]
  ## @:          ^      ^
  ## @:~~~~
  when showPos:
    showDebugPos(statement, start, "^ s bracketed")
  var runningPos = start

  assert(container.kind == vkList or container.kind == vkDict, "expected list or dict")

  # Get the index/key value.
  let vAndPosOr = getValuePosSi(env, statement, runningPos, variables)
  if vAndPosOr.isMessage:
    return vAndPosOr
  let indexValue = vAndPosOr.value.value

  # Get the value from the container using the index/key.
  var value: Value
  if container.kind == vkList:
    # list container
    if indexValue.kind != vkInt:
      # The index variable must be an integer.
      return newValuePosSiOr(wIndexNotInt, "", runningPos)
    let index = indexValue.intv
    let list = container.listv.list
    if index < 0 or index >= list.len:
      # The index value $1 is out of range.
      return newValuePosSiOr(wInvalidIndexRange, $index, runningPos)
    value = container.listv.list[index]
  else:
    # dictionary container
    if indexValue.kind != vkString:
      # The key variable must be an string.
      return newValuePosSiOr(wKeyNotString, "", runningPos)
    let key = indexValue.stringv
    let dict = container.dictv.dict
    if not (key in dict):
      # The key doesn't exist in the dictionary.
      return newValuePosSiOr(wMissingKey, "", runningPos)
    value = dict[key]

  # Get the ending right bracket.
  runningPos = vAndPosOr.value.pos
  let rightBracketO = matchSymbol(statement.text, gRightBracket, runningPos)
  if not rightBracketO.isSome:
    # Missing right bracket.
    return newValuePosSiOr(wMissingRightBracket, "", runningPos)
  runningPos += rightBracketO.get().length

  when showPos:
    showDebugPos(statement, runningPos, "^ f bracketed")

  return newValuePosSiOr(value, runningPos)

proc funListLoop(env: var Env, variables: Variables,
    arguments: seq[Value]
  ): FunResult =
  ## Build and return a new item by calling the callback for each item
  ## in the given list.

  # listLoop(a: list, container: any, callback: func, state: optional any) bool
  let signatureO = newSignatureO("listLoop", "lapoab")
  let funResult = mapParameters(signatureO.get(), arguments)
  if funResult.kind == frWarning:
    return funResult
  let map = funResult.value.dictv.dict

  let list = map["a"]
  let container = map["b"]
  let callbackVar = map["c"]

  # Validate the callback signature.
  # callback(ix: int, item: any, container: any, state: optional any) list
  let signature = callbackVar.funcv.signature

  if signature.params.len != 3 and signature.params.len != 4:
    # Expected the func variable has 3 or 4 parameters but it has 1.
    return newFunResultWarn(wCallbackNumParams, 2, $signature.params.len)
  if signature.params[0].paramType != ptInt:
    # Expected the func variable's first parameter to be an int, got $1.
    return newFunResultWarn(wCallbackIntParam, 2, $signature.params[0].paramType)
  if "d" in map and signature.params.len == 3:
    # The listLoop state argument exists but the callback doesn't have a state parameter.
    return newFunResultWarn(wMissingStateVar, 3, "")
  if not signature.optional and signature.params.len == 4 and not ("d" in map):
    # The func variable has a required state parameter but it is being not passed to it.
    return newFunResultWarn(wStateRequired, 2, "")
  if signature.returnType != ptBool:
    # Expected the function variable's return type to be a bool, got: $1.
    return newFunResultWarn(wCallbackReturnType, 2, $signature.returnType)

  # Call the callback for each item in the list.
  var stopped = false
  for ix, value in list.listv.list:

    # Call the callback.
    # callback(ix: int, item: any, container: any, state: optional any) bool
    var callbackArgs = newSeq[Value]()
    callbackArgs.add(newValue(ix))
    callbackArgs.add(value)
    callbackArgs.add(container)
    if "d" in map:
      callbackArgs.add(map["d"])
    let callResult = callUserFunction(env, callbackVar, variables, callbackArgs)
    if callResult.kind == frWarning:
      # Note: if the warning is a signature type issue, add another
      # signature check above.
      return callResult

    # Stop the loop when the callback returns true.
    if callResult.value.boolv:
      stopped = true
      break

  result = newFunResult(newValue(stopped))

proc listLoop*(
    env: var Env,
    specialFunction: SpecialFunction,
    statement: Statement,
    start: Natural,
    variables: Variables,
    listCase=false): ValuePosSiOr =
  ## Make a new list from an existing list. The callback function is
  ## called for each item in the list and determines what goes in the
  ## new list.  See funList_lpoal in functions.nim for more
  ## information.
  ## @:
  ## @:Return the listLoop value and the ending position.  Start
  ## @:points at the first parameter of the function. The position
  ## @:includes the trailing whitespace after the ending right
  ## @:parentheses.
  ## @:
  ## @:~~~
  ## @:stopped = listLoop(list, new, callback, state)
  ## @:                   ^                          ^
  ## @:~~~~
  # Get all the function arguments.
  var runningPos = start
  var arguments: seq[Value]
  var argumentStarts: seq[Natural]
  let vpOr = getArguments(env, statement, runningPos, variables, false,
    arguments, argumentStarts)
  if vpOr.isMessage:
    return vpOr
  runningPos = vpOr.value.pos

  let funResult = funListLoop(env, variables, arguments)
  if funResult.kind == frWarning:
    # todo: pass in functionPos
    let functionPos = 0
    let warningPos = warningParameterPos(funResult.parameter, argumentStarts, start, functionPos)
    return newValuePosSiOr(funResult.warningData.messageId,
      funResult.warningData.p1, warningPos)

  return newValuePosSiOr(funResult.value, runningPos)

proc getValuePosSiWorker(env: var Env, statement: Statement, start: Natural, variables:
    Variables): ValuePosSiOr =
  ## Get the value, position and side effect from the statement. Start
  ## points at the right hand side of the statement. The return pos is
  ## the first character after trailing whitespace.
  ## @:
  ## @:~~~
  ## @:a = 5  # statement
  ## @:    ^  ^
  ## @:
  ## @:a = cmp(len(c), 4)
  ## @:        ^         ^
  ## @:a = [1, 2, 3]
  ## @:    ^        ^
  ## @:~~~~

  let rightType = getRightType(statement, start)
  case rightType:
  of rtNothing:
    # Expected a string, number, variable, list or condition.
    return newValuePosSiOr(wInvalidRightHandSide, "", start)
  of rtString:
    result = getString(statement, start)
  of rtNumber:
    result = getNumber(statement, start)
  of rtList:
    # Return the literal list value and position after it.
    # The start index points at [. The return position includes the
    # trailing whitespace after the ending ].

    # Match the left bracket and whitespace to get the position of the
    # first argument.
    let startSymbolO = matchSymbol(statement.text, gLeftBracket, start)
    assert startSymbolO.isSome
    let startSymbol = startSymbolO.get()

    # Get the list. The literal list [...] and list(...) are similar.
    result = getFunctionValuePosSi(env, "list", start, statement,
      start+startSymbol.length, variables, listCase=true)

  of rtCondition:
    result = getCondition(env, statement, start, variables)

  of rtVariable:
    # Get the variable name.
    let rightNameOr = getVariableName(statement.text, start)
    if rightNameOr.isMessage:
      return newValuePosSiOr(rightNameOr.message)
    let rightName = rightNameOr.value

    # Use f for functions, else use the local dictionary of no prefix
    # vars.
    var noPrefixDict: NoPrefixDict
    case rightName.kind
    of vnkNormal, vnkGet:
      noPrefixDict = npLocal
    of vnkFunction:
      noPrefixDict = npBuiltIn

    # Get the variable's value.
    let valueOr = getVariable(variables, rightName.dotName, noPrefixDict)
    if valueOr.isMessage:
      let warningData = newWarningData(valueOr.message.messageId,
        valueOr.message.p1, start)
      return newValuePosSiOr(warningData)

    case rightName.kind
    of vnkNormal:
      return newValuePosSiOr(valueOr.value, rightName.pos)

    of vnkFunction:
      # We have a function, run it and return its value.
      let specialFunction = getSpecialFunction(valueOr.value)
      case specialFunction:
      of spIf, spIf0:
        # Handle the special IF functions.
        return ifFunctions(env, specialFunction, statement, rightName.pos, variables)
      of spAnd, spOr:
        # Handle the special AND/OR functions.
        return andOrFunctions(env, specialFunction, statement, rightName.pos, variables)
      of spListLoop:
        # Handle the special listLoop function.
        return listLoop(env, specialFunction, statement, rightName.pos, variables)
      of spFunc:
        # Define a function in a code file and not nested.
        return newValuePosSiOr(wDefineFunction, "", start)
      of spNotSpecial, spReturn, spWarn, spLog:
        # Handle normal functions and warn, return and log.
        return getFunctionValuePosSi(env, rightName.dotName, start, statement,
          rightName.pos, variables, listCase=false)

    of vnkGet:
      # a = list[2] or a = dict["key"]
      let container = valueOr.value
      if container.kind != vkList and container.kind != vkDict:
        # The container variable must be a list or dictionary got $1.
        return newValuePosSiOr(wIndexNotListOrDict, $container.kind, start)

      return getBracketedVarValue(env, statement, rightName.pos, valueOr.value, variables)

proc getValuePosSi*(env: var Env, statement: Statement, start: Natural, variables:
    Variables): ValuePosSiOr =
  ## Return the value and position of the item that the start parameter
  ## points at which is a string, number, variable, list, or condition.
  ## The position returned includes the trailing whitespace after the
  ## item. So the ending position is pointing at the end of the
  ## statement, or at the first non-whitespace character after the
  ## item.
  ## @:
  ## @:~~~
  ## @:a = "tea" # string
  ## @:    ^     ^
  ## @:a = 123.5 # number
  ## @:    ^     ^
  ## @:a = t.row # variable
  ## @:    ^     ^
  ## @:a = [1, 2, 3] # list
  ## @:    ^         ^
  ## @:a = (c < 10) # condition
  ## @:    ^        ^
  ## @:a = cmp(b, c) # calling variable
  ## @:    ^         ^
  ## @:a = if( (b < c), d, e) # if
  ## @:    ^                  ^
  ## @:a = if( bool(len(b)), d, e) # if
  ## @:    ^                       ^
  ## @:        ^             ^
  ## @:             ^     ^
  ## @:                 ^^
  ## @:                      ^  ^
  ## @:                         ^  ^
  ## @:~~~~

  when showPos:
    showDebugPos(statement, start, "^ s")

  result = getValuePosSiWorker(env, statement, start, variables)

  when showPos:
    var pos: Natural
    if result.isMessage:
      pos = result.message.pos
    else:
      pos = result.value.pos
    showDebugPos(statement, pos, "^ f")

proc runBareFunction*(env: var Env, statement: Statement, start: Natural,
    variables: Variables, leftName: VariableName): ValuePosSiOr =
  ## Handle bare function: if, if0, return, warn and log. A bare
  ## function does not assign a variable.
  ## @:
  ## @:~~~
  ## @:if( true, warn("tea time")) # test
  ## @:^                           ^
  ## @:return(5)
  ## @:^        ^
  ## @:~~~~
  let runningPos = leftName.pos

  # Get the function variable.
  let funcVarOr = getVariable(variables, leftName.dotName, npBuiltIn)
  if funcVarOr.isMessage:
    return newValuePosSiOr(funcVarOr.message)
  let funcVar = funcVarOr.value

  # Look up the special function type.
  let specialFunction = getSpecialFunction(funcVar)

  # Handle all the special function types.
  case specialFunction:
  of spIf, spIf0:
    # Handle the special bare if functions.
    result = bareIfAndIf0(env, specialFunction, statement, runningPos, variables)
  of spReturn:
    result = bareReturn(env, statement, runningPos, variables)
  of spNotSpecial, spAnd, spOr, spFunc, spListLoop:
    # Missing left hand side and operator, e.g. a = len(b) not len(b).
    result = newValuePosSiOr(wMissingLeftAndOpr, "", start)
  of spWarn, spLog:
    # Handle a bare warn, or log function.
    result = getFunctionValuePosSi(env, $specialFunction, start,
      statement, runningPos, variables, listCase=false)

proc getBracketDotName*(env: var Env, statement: Statement, start: Natural,
    variables: Variables, leftName: VariableName): ValuePosSiOr =
  ## Convert var[key] to a dot name.
  ## @:
  ## @:~~~
  ## @:key = "hello"
  ## @:name[key] = 20
  ## @:^         ^
  ## @:=> name.hello, pos
  ## @:
  ## @:name["hello"] = 20
  ## @:^             ^
  ## @:~~~~

  # Get the index name.
  var runningPos = leftName.pos
  var indexName: string
  let indexVarNameOr = getVariableName(statement.text, runningPos)
  if indexVarNameOr.isMessage:
    # Not a variable name, Look for a string literal.
    let valuePosSiOr = getString(statement, runningPos)
    if valuePosSiOr.isMessage:
      # The index value must be a variable name or literal string.
      return newValuePosSiOr(wInvalidIndexValue, "", runningPos)
    runningPos = valuePosSiOr.value.pos
    indexName = valuePosSiOr.value.value.stringv
  else:
    # Variable name.
    let indexVarName = indexVarNameOr.value
    if indexVarName.kind != vnkNormal:
      # The index value must be a variable name or literal string.
      return newValuePosSiOr(wInvalidIndexValue, "", runningPos)

    # Look up the variable's value.
    let valueOr = getVariable(variables, indexVarName.dotName, npLocal)
    if valueOr.isMessage:
      # The variable '$1' does not exist.
      return newValuePosSiOr(wVariableMissing, indexVarName.dotName, runningPos)
    let value = valueOr.value

    # Make sure the value is a string.
    if value.kind != vkString:
      # The index value is not a string.
      return newValuePosSiOr(wNotIndexString, "", runningPos)

    # Make sure the string is a valid variable name.
    let indexVarNameOr = getVariableName(value.stringv, 0)
    if indexVarNameOr.isMessage:
      # The index variable value is not a valid variable name.
      return newValuePosSiOr(wNotVariableName, "", runningPos)
    if indexVarNameOr.value.pos != value.stringv.len:
      # The index variable value is not a valid variable name.
      return newValuePosSiOr(wNotVariableName, "", runningPos)

    runningPos = indexVarName.pos
    indexName = value.stringv

  # Concatenate the left name and the index name to make the dot name.
  let dotName = "$1.$2" % [leftName.dotName, indexName]
  if dotName.len > maxNameLength:
    # A variable and dot name are limited to 64 characters.
    return newValuePosSiOr(wVarMaximumLength, "", runningPos)

  # Match ] and trailing whitespace.
  let rightBracketO = matchSymbol(statement.text, gRightBracket, runningPos)
  if not rightBracketO.isSome:
    # Missing right bracket.
    return newValuePosSiOr(wMissingRightBracket, "", runningPos)
  runningPos += rightBracketO.get().length

  result = newValuePosSiOr(newValue(dotName), runningPos)

proc runStatement*(env: var Env, statement: Statement, variables: Variables): VariableDataOr =
  ## Run one statement and return the variable dot name string,
  ## operator and value.

  # Skip comments and blank lines.
  var runningPos = 0
  let spacesO = matchTabSpace(statement.text, 0)
  if isSome(spacesO):
    runningPos = spacesO.get().length
  if runningPos >= statement.text.len or statement.text[runningPos] == '#':
    return newVariableDataOr("", opIgnore, newValue(0))

  # Get the variable dot name string and match the trailing white
  # space.
  let leftNameOr = getVariableName(statement.text, runningPos)
  if leftNameOr.isMessage:
    return newVariableDataOr(leftNameOr.message)
  let leftName = leftNameOr.value

  var vlOr: ValuePosSiOr
  var operator = opIgnore
  var finalLeftName = leftName.dotName

  case leftName.kind
  of vnkFunction:
    # Handle bare function: if, if0, return, warn and log. A bare
    # function does not assign a variable.
    vlOr = runBareFunction(env, statement, runningPos, variables, leftName)
    if vlOr.isMessage:
      return newVariableDataOr(vlOr.message)
    finalLeftName = ""
  of vnkGet, vnkNormal:
    if leftName.kind == vnkGet:
      # Get the dotname of name[index] => name.index
      let dotNameOr = getBracketDotName(env, statement, runningPos, variables, leftName)
      if dotNameOr.isMessage:
        return newVariableDataOr(dotNameOr.message)
      finalLeftName = dotNameOr.value.value.stringv
      runningPos = dotNameOr.value.pos
    else:
      runningPos = leftName.pos

    # Handle normal "varName operator right" statements.

    # Get the equal sign or &= and the following whitespace.
    let operatorO = matchEqualSign(statement.text, runningPos)
    if not operatorO.isSome:
      # Missing operator, = or &=.
      return newVariableDataOr(wInvalidVariable, "", runningPos)
    let match = operatorO.get()
    let op = match.getGroup()
    if op == "=":
      operator = opEqual
    else:
      operator = opAppendList
    runningPos = runningPos + match.length

    # Get the right hand side value and match the following whitespace.
    vlOr = getValuePosSi(env, statement, runningPos, variables)

  if vlOr.isMessage:
    return newVariableDataOr(vlOr.message)

  # Check that there is not any unprocessed text following the value.
  if vlOr.value.pos != statement.text.len:
    # Check for a trailing comment.
    if statement.text[vlOr.value.pos] != '#':
      # Unused text at the end of the statement.
      return newVariableDataOr(wTextAfterValue, "", vlOr.value.pos)

  case vlOr.value.sideEffect
  of seReturn:
    # Return function exit.
    return newVariableDataOr("", opReturn, vlOr.value.value)
  of seLogMessage:
    # Log statement exit.
    return newVariableDataOr("", opLog, vlOr.value.value)
  of seBareIfIgnore:
    # Bare if with a false condition.
    return newVariableDataOr("", opIgnore, vlOr.value.value)
  of seNone:
    discard

  # Return the variable dot name and value.
  result = newVariableDataOr(finalLeftName, operator, vlOr.value.value)

proc skipSpaces*(text: string): Natural =
  let spacesO = matchTabSpace(text, 0)
  if isSome(spacesO):
    result = spacesO.get().length

proc callUserFunction*(env: var Env, funcVar: Value, variables: Variables,
    arguments: seq[Value]): FunResult =
  ## Run the given user function.
  assert funcVar.kind == vkFunc
  assert funcVar.funcv.builtIn == false

  var userVariables = startVariables(funcs = funcsVarDict)

  # Populate the l dictionary with the parameters and arguments.
  let funResult = mapParameters(funcVar.funcv.signature, arguments)
  if funResult.kind == frWarning:
    return funResult
  userVariables["l"] = newValue(funResult.value.dictv.dict, mutable = Mutable.append)

  # Run the function statements.
  for statement in funcVar.funcv.statements:

    # Run the statement.
    let variableDataOr = runStatement(env, statement, userVariables)
    if variableDataOr.isMessage:
      env.warnStatement(statement, variableDataOr.message, funcVar.funcv.filename)
      # Return success so another message is not shown.
      return newFunResultWarn(wSuccess)
    let variableData = variableDataOr.value

    # Handle the result of the statement.
    case variableData.operator
    of opEqual, opAppendList:
      # Assign the variable if possible.
      let wdO = assignVariable(userVariables, variableData)
      if isSome(wdO):
        let wd = wdO.get()
        let pos = skipSpaces(statement.text)
        let wd2 = newWarningData(wd.messageId, wd.p1, pos)
        env.warnStatement(statement, wd2, funcVar.funcv.filename)
        # Return success so another message is not shown.
        return newFunResultWarn(wSuccess)
    of opIgnore:
      continue
    of opLog:
      env.logLine(funcVar.funcv.filename, statement.lineNum, variableData.value.stringv & "\n")
    of opReturn:
      # Validate return type.
      if not sameType(funcVar.funcv.signature.returnType, variableData.value.kind):
        # Wrong return type, got $1.
        env.warnStatement(statement, wWrongReturnType, $variableData.value.kind, 0, funcVar.funcv.filename)
        # Return success so another message is not shown.
        return newFunResultWarn(wSuccess)
      # Return the value of the function.
      return newFunResult(variableData.value)

  assert(false, "the function doesn't have a return statement")
  # Out of lines; missing the function's return statement.
  result = newFunResultWarn(wNoReturnStatement)

proc runStatementAssignVar*(env: var Env, statement: Statement, variables: var Variables,
    sourceFilename: string): LoopControl =
  ## Run a statement and assign the variable if appropriate. Return
  ## skip, stop or continue to control the loop.

  # Run the statement and get the variable, operator and value.
  let variableDataOr = runStatement(env, statement, variables)
  if variableDataOr.isMessage:
    env.warnStatement(statement, variableDataOr.message, sourceFilename = sourceFilename)
    return lcAdd
  let variableData = variableDataOr.value

  case variableData.operator
  of opEqual, opAppendList:
    # Assign the variable if possible.
    let warningDataO = assignVariable(variables,
      variableData.dotNameStr, variableData.value, variableData.operator)
    if isSome(warningDataO):
      env.warnStatement(statement, warningDataO.get(), sourceFilename)
    result = lcAdd
  of opIgnore:
    result = lcAdd
  of opLog:
    env.logLine(sourceFilename, statement.lineNum, variableData.value.stringv & "\n")
    result = lcAdd
  of opReturn:
    # Handle a return function exit.
    if variableData.value.kind == vkString:
      case variableData.value.stringv:
      of "stop":
        return lcStop
      of "skip":
        return lcSkip
      else:
        discard
    # todo: handle return differently.  We don't know the position of
    # the return argument in the statement for the warning message.

    # Expected 'skip' or 'stop' for the return function value.
    let wd = newWarningData(wSkipOrStop)
    env.warnStatement(statement, wd, sourceFilename = sourceFilename)
    result = lcStop


proc parseSignature*(signature: string): SignatureOr =
  ## Parse the signature and return the list of parameters or a
  ## message.
  ## @:
  ## @:Example signatures:
  ## @:~~~
  ## @:cmp(numStr1: string, numStr2: string) int
  ## @:get(group: list, ix: int, optional any) any
  ## @:~~~~
  var runningPos = 0
  let functionNameOr = getVariableName(signature, runningPos)
  if functionNameOr.isMessage:
    if not emptyOrSpaces(signature):
      # Excected a function name.
      return newSignatureOr(wFunctionName, "", runningPos)
    else:
      # Missing the function signature string.
      return newSignatureOr(wMissingSignature, "", runningPos)
  let functionName = functionNameOr.value

  case functionName.kind
  of vnkNormal, vnkGet:
    # Excected a left parentheses for the signature.
    return newSignatureOr(wMissingLeftParen, "", runningPos + functionName.dotName.len)
  of vnkFunction:
    discard
  runningPos = functionName.pos

  var optional = false
  var params = newSeq[Param]()

  # Look for ) and following white space.
  let rightParen = matchSymbol(signature, gRightParentheses, runningPos)
  if rightParen.isSome:
    # No parameters case.
    runningPos += rightParen.get().length
  else:
    # One or more parameters.

    while true:
      if optional:
        # Only the last parameter can be optional.
        return newSignatureOr(wNotLastOptional, "", runningPos)

      # Get the parameter name and following white space.
      let paramNameOr = getVariableName(signature, runningPos)
      if paramNameOr.isMessage:
        # Excected a parameter name.
        return newSignatureOr(wParameterName, "", runningPos)
      let paramName = paramNameOr.value

      case paramName.kind
      of vnkFunction, vnkGet:
        # Expected a colon.
        return newSignatureOr(wMissingColon, "", runningPos + paramName.dotName.len)
      of vnkNormal:
        discard
      runningPos = paramName.pos

      # Look for : and the following white space.
      let colonO = matchSymbol(signature, gColon, runningPos)
      if not colonO.isSome:
        # Expected a colon.
        return newSignatureOr(wMissingColon, "", runningPos)
      runningPos += colonO.get().length

      # Look for the parameter type and following white space.
      let paramTypeO = matchParameterType(signature, runningPos)
      if not paramTypeO.isSome:
        # Expected a parameter type: bool, int, float, string, dict, list, func or any.
        return newSignatureOr(wExpectedParamType, "", runningPos)
      let (optionalText, paramTypeStr, paramTypeLen) = paramTypeO.get2GroupsLen()
      if optionalText.len > 0:
        optional = true
      runningPos += paramTypeLen

      let paramType = strToParamType(paramTypeStr)
      params.add(newParam(paramName.dotName, paramType))

      # Look for a comma or right parentheses.
      let corpO = matchCommaOrSymbol(signature, gRightParentheses, runningPos)
      if not corpO.isSome:
        # Expected comma or right parentheses.
        return newSignatureOr(wMissingCommaParen, "", runningPos)
      let (corp, corpLen) = corpO.getGroupLen()
      runningPos += corpLen

      if corp == ")":
        break

  # Look for the return type and following white space.
  let returnTypeO = matchParameterType(signature, runningPos)
  if not returnTypeO.isSome:
    # Expected the return type.
    return newSignatureOr(wExpectedReturnType, "", runningPos)
  let (optionalText, returnTypeStr, matchLen) = returnTypeO.get2GroupsLen()
  if optionalText.len > 0:
    # The return type is required.
    return newSignatureOr(wReturnTypeRequired, "", runningPos)
  runningPos += matchLen
  let returnType = strToParamType(returnTypeStr)

  # Look for trailing junk.
  if runningPos < signature.len:
    # Unused extra text at the end of the signature.
    return newSignatureOr(wUnusedSignatureText, "", runningPos)

  let signature = newSignature(optional, functionName.dotName, params, returnType)
  result = newSignatureOr(signature)

proc isFunctionDefinition*(statement: Statement, retLeftName: var string,
    retOperator: var Operator, retPos: var Natural): bool =
  ## If the statement is the first line of a function definition,
  ## return true and fill in the return parameters.  Return quickly
  ## when not a function definition. The retPos points at the first
  ## non-whitespace after the "func(".

  # Quick exit when we know it's not a function definition.
  if not ("func(" in statement.text):
    return false

  # Skip comment only line with func() in it.
  var runningPos: Natural
  let spacesO = matchTabSpace(statement.text, 0)
  if not isSome(spacesO):
    runningPos = 0
  else:
    runningPos = spacesO.get().length
  if runningPos >= statement.text.len or statement.text[runningPos] == '#':
    # We handled it.
    return false

  # Get the left hand variable dot name string and match the
  # surrounding white space.
  let leftNameOr = getVariableName(statement.text, runningPos)
  if leftNameOr.isMessage:
    return false
  let leftName = leftNameOr.value

  case leftName.kind
  of vnkFunction, vnkGet:
    return false
  of vnkNormal:
    discard
  runningPos = leftName.pos

  # Get the equal sign or &= and the following whitespace.
  let operatorO = matchEqualSign(statement.text, runningPos)
  if not operatorO.isSome:
    return false
  let (op, matchLen) = operatorO.getGroupLen()
  var operator: Operator
  if op == "=":
    operator = opEqual
  else:
    operator = opAppendList
  runningPos += matchLen

  # Look for "func(".
  let funcNameOr = getVariableName(statement.text, runningPos)
  if funcNameOr.isMessage:
    return false
  let funcName = funcNameOr.value
  if funcName.dotName != "func":
    return false
  case funcName.kind
  of vnkNormal, vnkGet:
    return false
  of vnkFunction:
    discard
  runningPos = funcName.pos

  retLeftName = leftName.dotName
  retOperator = operator
  retPos = runningPos
  return true

proc processFunctionSignature*(statement: Statement, start: Natural): SignatureOr =
  ## Process the function definition line starting at the signature
  ## string. The start parameter points at the first non-whitespace
  ## character after "func(".
  ## @:
  ## @:Example:
  ## @:mycmp = func("numStrCmp(numStr1: string, numStr2: string) int")
  ## @:             ^ start

  var runningPos = start
  if runningPos >= statement.text.len or statement.text[runningPos] != '"':
    return newSignatureOr(wExpectedSignature, "", runningPos)

  let signatureStrStart = runningPos+1
  runningPos = signatureStrStart

  # Get the signature string argument and following white space.
  let vlOr = parseJsonStr(statement.text, runningPos)
  if vlOr.isMessage:
    return newSignatureOr(vlOr.message)
  assert vlOr.value.value.kind == vkString
  let signatureStr = vlOr.value.value.stringv
  runningPos = vlOr.value.pos

  # Check for ending right parentheses and trailing whitespace.
  let rightParenO = matchSymbol(statement.text, gRightParentheses, runningPos)
  if not rightParenO.isSome:
    # No matching end right parentheses.
    return newSignatureOr(wNoMatchingParen, "", runningPos)
  runningPos += rightParenO.get().length

  # Check that there is not any unprocessed text following the function.
  if runningPos < statement.text.len:
    # Check for a trailing comment.
    if statement.text[runningPos] != '#':
      # Unused text at the end of the statement.
      return newSignatureOr(wTextAfterValue, "", runningPos)

  # Parse the signature string and return a signature object.
  let signatureOr = parseSignature(signatureStr)
  if signatureOr.isMessage:
    let md = signatureOr.message
    return newSignatureOr(md.messageId, md.p1, signatureStrStart + md.pos)

  result = signatureOr

proc isDocComment(statement: Statement): bool =
  ## Return true when the statement is a doc comment.
  let mO = matchDocComment(statement.text, 0)
  result = mO.isSome

proc defineUserFunctionAssignVar*(env: var Env, lb: var LineBuffer, statement: Statement,
    variables: var Variables, sourceFilename: string,
    codeFile: bool): bool =
  ## If the statement starts a function definition, define it and
  ## assign the variable. A true return value means the statement(s)
  ## were processed and maybe errors output. A false means the
  ## statement should be processed as a regular statement.

  var leftName: string
  var operator: Operator
  var pos: Natural
  if not isFunctionDefinition(statement, leftName, operator, pos):
    return false # run as regular statement

  let lineNum = lb.getLineNum()

  let signatureOr = processFunctionSignature(statement, pos)
  if signatureOr.isMessage:
    let md = signatureOr.message
    env.warnStatement(statement, md.messageId, md.p1,  md.pos, sourceFilename)
    return true # handled
  let signature = signatureOr.value

  # Read the doc comments.
  var docComment = ""
  let firstStatementO = readStatement(env, lb)
  if not firstStatementO.isSome:
    # Out of lines; Missing required doc comment.
    env.warn(sourceFilename, lb.getLineNum, wMissingDocComment, "")
    return true # handled
  let firstStatement = firstStatementO.get()
  if not isDocComment(firstStatement):
    # Missing required doc comment.
    env.warnStatement(statement, wMissingDocComment, "",  0, sourceFilename)
    # Process it as a regular statement.
    return true # handled
  docComment.add(firstStatement.text & firstStatement.ending)
  var statement: Statement
  while true:
    let statementO = readStatement(env, lb)
    if not statementO.isSome:
      # Out of lines; No statements for the function.
      env.warn(sourceFilename, lb.getLineNum, wMissingStatements, "")
      return true # handled
    statement = statementO.get()
    if not isDocComment(statement):
      break
    docComment.add(statement.text & firstStatement.ending)

  # Collect the function's statements.
  var userStatements = newSeq[Statement]()
  userStatements.add(statement)
  while true:
    # Look for a return statement.
    let leftNameOr = getVariableName(statement.text, 0)
    if leftNameOr.isValue:
      let leftName = leftNameOr.value
      if leftName.dotName == "return" and leftName.kind == vnkFunction:
        break

    let statementO = readStatement(env, lb)
    if not statementO.isSome:
      # Out of lines; missing the function's return statement.
      env.warn(sourceFilename, lb.getLineNum, wNoReturnStatement, "")
      return true # handled
    statement = statementO.get()
    userStatements.add(statement)

  let numLines = lb.getLineNum() - lineNum

  func dummy(variables: Variables, parameters: seq[Value]): FunResult =
    result = newFunResult(newValue(0))

  let userFunc = newFunc(builtIn=false, signature, docComment, sourceFilename, lineNum,
    numLines, userStatements, dummy)
  let funcVar = newValue(userFunc)

  # Assign the variable if possible.
  let warningDataO = assignVariable(variables, leftName, funcVar,
    operator)
  if isSome(warningDataO):
    env.warnStatement(statement, warningDataO.get(), sourceFilename)
  return true

proc runCommand*(env: var Env, cmdLines: CmdLines,
    variables: var Variables): LoopControl =
  ## Run a command and fill in the variables dictionaries.

  # Clear the local variables and set the tea vars to their initial
  # state.
  resetVariables(variables)

  # Loop over the statements and run each one.
  for statement in yieldStatements(cmdLines):

    # Run the statement.
    let loopControl = runStatementAssignVar(env, statement, variables,
      env.templateFilename)

    # Stop looping when we get a return.
    if loopControl == lcStop or loopControl == lcSkip:
      return loopControl

    # If t.repeat was set to 0, we're done.
    let tea = variables["t"].dictv.dict
    if "repeat" in tea and tea["repeat"].intv == 0:
      break

  result = lcAdd

proc runCodeFile*(env: var Env, variables: var Variables, filename: string) =
  ## Run the code file and fill in the variables.

  if not fileExists(filename):
    # File not found: $1.
    env.warnNoFile(wFileNotFound, filename)
    return

  # Create a stream out of the file.
  var stream: Stream
  stream = newFileStream(filename)
  if stream == nil:
    # Unable to open file: $1.
    env.warnNoFile(wUnableToOpenFile, filename)
    return
  defer:
    # Close the stream and file.
    stream.close()

  # Allocate a buffer for reading lines. Return when not enough memory.
  let lineBufferO = newLineBuffer(stream, filename = filename)
  if not lineBufferO.isSome():
    # Not enough memory for the line buffer.
    env.warnNoFile(wNotEnoughMemoryForLB)
    return
  var lb = lineBufferO.get()

  # Read and process code lines.
  while true:
    let statementO = readStatement(env, lb)
    if not statementO.isSome:
      break # done
    let statement = statementO.get()

    # If the statement starts a function definition, define it and
    # assign the variable. A true return value means the statement(s)
    # were processed and maybe errors output. A false means the
    # statement should be processed as a regular statement.
    if defineUserFunctionAssignVar(env, lb, statement, variables, filename, codeFile=true):
      continue

    # Process a regular statement.
    let loopControl = runStatementAssignVar(env, statement, variables, filename)
    if loopControl == lcStop:
      break
    elif loopControl == lcSkip:
      # Use '...return(\"stop\")...' in a code file.
      let warningData = newWarningData(wUseStop)
      env.warnStatement(statement, warningData, sourceFilename = filename)

proc runCodeFiles*(env: var Env, variables: var Variables, codeList: seq[string]) =
  ## Run each code file and populate the variables.
  for filename in codeList:
    runCodeFile(env, variables, filename)
    resetVariables(variables)
