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

const
  # Turn on showPos for testing to graphically show the start and end
  # positions when running a statement.
  showPos = false

  tripleQuotes* = "\"\"\""
    ## Triple quotes for building strings.

type
  PosOr* = OpResultWarn[Natural]
    ## A position in a string or a message.

  SpecialFunction* {.pure.} = enum
    ## The special functions.
    ## @:
    ## @:* spNotSpecial -- not a special function
    ## @:* spIf -- if function.
    ## @:* spIf0 -- if0 function.
    ## @:* spWarn -- warn function.
    ## @:* spLog -- log function.
    ## @:* spReturn -- return function.
    ## @:* spAnd -- and function.
    ## @:* spOr -- or function.
    ## @:* spFunc -- func function.
    spNotSpecial = "not-special",
    spIf = "if",
    spIf0 = "if0",
    spWarn = "warn",
    spLog = "log",
    spReturn = "return",
    spAnd = "and",
    spOr = "or",
    spFunc = "func",

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
    ## @:* lcContinue -- output the replacment block and continue with the next iteration
    lcStop = "stop",
    lcSkip = "skip",
    lcContinue = "continue",

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
  result = """$1, $2: "$3"""" % [$s.lineNum, $s.start, s.text]

func `==`*(s1: Statement, s2: Statement): bool =
  ## Return true when the two statements are equal.
  if s1.lineNum == s2.lineNum and s1.start == s2.start and
      s1.text == s2.text:
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
    message = "$1($2): $3" % [filename,
      $statement.lineNum, warningData.p1]
  else:
    message = getWarnStatement(filename, statement, warningData)
  env.outputWarning(statement.lineNum, message)

proc warnStatement*(env: var Env, statement: Statement,
    messageId: MessageId, p1: string, pos:Natural, sourceFilename = "") =
  let warningData = newWarningData(messageId, p1, pos)
  env.warnStatement(statement, warningData, sourceFilename)

iterator yieldStatements*(cmdLines: CmdLines): Statement =
  ## Iterate through the command's statements. Skip blank statements.

  type
    State {.pure.} = enum
      ## Finite state machine states for finding statements.
      start, double

  # Find the statements in the list of command lines.  Statements may
  # continue between them. A statement continues when there is a plus
  # sign at the end of the line.

  var text = newStringOfCap(defaultMaxLineLen)
  var lineNum: Natural
  var start: Natural
  if cmdLines.lines.len > 0:
    lineNum = cmdLines.lineParts[0].lineNum
    start = cmdLines.lineParts[0].codeStart
  var state = State.start
  for ix in 0 ..< cmdLines.lines.len:
    let line = cmdLines.lines[ix]
    let lp = cmdLines.lineParts[ix]
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
      if notEmptyOrSpaces(text):
        yield newStatement(strip(text), lineNum, start)
      # Setup variables for the next line, if there is one.
      text.setLen(0)
      if cmdLines.lines.len > ix+1:
        lineNum = lp.lineNum + 1
        start = cmdLines.lineParts[ix+1].codeStart

  if notEmptyOrSpaces(text):
    yield newStatement(strip(text), lineNum, start)

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

func getMultilineStr*(text: string, start: Natural): ValueAndPosOr =
  ## Return the triple quoted string literal. The startPos points one
  ## @:past the leading triple quote.  Return the parsed
  ## @:string value and the ending position one past the trailing
  ## @:whitespace.

  # a = """\ntest string"""\n
  #         ^                ^

  if start >= text.len or text[start] != '\n':
    # Triple quotes must always end the line.
    return newValueAndPosOr(wTripleAtEnd, "", start)
  if start + 5 > text.len or text[text.len - 4 .. text.len - 1] != "\"\"\"\n":
    # Missing the ending triple quotes.
    return newValueAndPosOr(wMissingEndingTriple, "", text.len)

  let newStr = text[start + 1 .. text.len - 5]
  result = newValueAndPosOr(newStr, text.len)

func getString*(statement: Statement, start: Natural): ValueAndPosOr =
  ## Return a literal string value and position after it. The start
  ## parameter is the index of the first quote in the statement and
  ## the return position is after the optional trailing white space
  ## following the last quote.

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

func getNumber*(statement: Statement, start: Natural): ValueAndPosOr =
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
      # true, false, variable, number
      of 'a' .. 'z', 'A' .. 'Z', '0' .. '9', '-':
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
      of 'a' .. 'z', 'A' .. 'Z', '0' .. '9', '_', '.':
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

func quickExit(valueAndPosOr: ValueAndPosOr): bool =
  ## Return true when the ValueAndPosOr is a messsage or a return or a
  ## log.
  result = valueAndPosOr.isMessage or valueAndPosOr.value.sideEffect != seNone

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

# Forward reference to getValueAndPos since we call it recursively.
proc getValueAndPos*(statement: Statement, start: Natural, variables:
  Variables): ValueAndPosOr

func getSpecialFunction(dotNameStr: string, variables: Variables): SpecialFunctionOr =
  ## Return the function type given a function name.

  # Get the function or list of functions.
  let dotNameValueOr = getVariable(variables, dotNameStr, "f")
  if dotNameValueOr.isMessage:
    return newSpecialFunctionOr(dotNameValueOr.message.messageId, dotNameValueOr.message.p1)
  let dotNameValue = dotNameValueOr.value

  var value: Value
  if dotNameValue.kind == vkList:
    let list = dotNameValue.listv
    if list.len != 1:
      # This is not a special function because there is more than one
      # item in the list and all special functions are a list of one.
      return newSpecialFunctionOr(spNotSpecial)
    value = list[0]
  else:
    value = dotNameValue

  if value.kind != vkFunc:
    return newSpecialFunctionOr(spNotSpecial)

  var spFun: SpecialFunction
  case value.funcv.signature.name
  of "if":
    spFun = spIf
  of "if0":
    spFun = spIf0
  of "and":
    spFun = spAnd
  of "or":
    spFun = spOr
  of "warn":
    spFun = spWarn
  of "return":
    spFun = spReturn
  of "log":
    spFun = spLog
  of "func":
    spFun = spFunc
  else:
    spFun = spNotSpecial

  result = newSpecialFunctionOr(spFun)

proc ifFunctions*(
    specialFunction: SpecialFunction,
    statement: Statement,
    start: Natural,
    variables: Variables,
    list=false, bare=false): ValueAndPosOr =
  ## Return the if/if0 function's value and position after. It
  ## conditionally runs one of its arguments and skips the
  ## other. Start points at the first argument of the function. The
  ## position includes the trailing whitespace after the ending ).

  # The three parameter if requires an assignment.  The two parameter
  # version cannot have an assignment.

  # cases:
  #   a = if(cond, then, else)
  #          ^                ^
  #   if(cond, then)
  #      ^          ^
  # The if function cond is a boolean, for if0 it is anything.

  # Get the condition's value.
  let vlcOr = getValueAndPos(statement, start, variables)
  if quickExit(vlcOr):
    return vlcOr
  let cond = vlcOr.value.value
  var runningPos = vlcOr.value.pos

  var condition = false
  if specialFunction == spIf:
    if cond.kind != vkBool:
      # The if condition must be a bool value, got a $1.
      return newValueAndPosOr(wExpectedBool, $cond.kind, start)
    condition = cond.boolv
  else: # if0
    condition = if0Condition(cond) == false

  # Match the comma and whitespace.
  let commaO = matchSymbol(statement.text, gComma, runningPos)
  if not commaO.isSome:
    if bare:
      # "An if without an assignment takes two arguments.
      return newValueAndPosOr(wBareIfTwoArguments, "", start)
    else:
      # An if with an assignment takes three arguments.
      return newValueAndPosOr(wAssignmentIf, "", start)
  runningPos += commaO.get().length

  # Handle the second parameter.
  var vl2Or: ValueAndPosOr
  var skip = (condition == false)

  if skip:
    let posOr = skipArg(statement, runningPos)
    if posOr.isMessage:
      return newValueAndPosOr(posOr.message)
    runningPos = posOr.value
  else:
    vl2Or = getValueAndPos(statement, runningPos, variables)
    if quickExit(vl2Or):
      return vl2Or
    runningPos = vl2Or.value.pos

  var vl3Or: ValueAndPosOr
  # Match the comma and whitespace.
  let cO = matchSymbol(statement.text, gComma, runningPos)
  if cO.isSome:
    if bare:
      # A bare if statement takes to arguments.
      return newValueAndPosOr(wBareIfTwoArguments, "", runningPos)

    # We got a comma so we expect a third parameter.
    runningPos += cO.get().length

    # Handle the third parameter.
    skip = (condition == true)
    if skip:
      let posOr = skipArg(statement, runningPos)
      if posOr.isMessage:
        return newValueAndPosOr(posOr.message)
      runningPos = posOr.value
    else:
      vl3Or = getValueAndPos(statement, runningPos, variables)
      if vl3Or.isMessage or vl3Or.value.sideEffect != seNone:
        return vl3Or
      runningPos = vl3Or.value.pos
  else:
    if not bare:
      # An if with an assignment takes three arguments.
      return newValueAndPosOr(wAssignmentIf, "", runningPos)

  # Match ) and trailing whitespace.
  let parenO = matchSymbol(statement.text, gRightParentheses, runningPos)
  if not parenO.isSome:
    # No matching end right parentheses.
    return newValueAndPosOr(wNoMatchingParen, "", runningPos)

  runningPos += parenO.get().length

  if bare:
    result = newValueAndPosOr(newValue(0), runningPos)
  else:
    var value: Value
    if condition:
      value = vl2Or.value.value
    else:
      value = vl3Or.value.value
    result = newValueAndPosOr(value, runningPos)

proc andOrFunctions*(
    specialFunction: SpecialFunction,
    statement: Statement,
    start: Natural,
    variables: Variables,
    list=false): ValueAndPosOr =
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
  let vlcOr = getValueAndPos(statement, start, variables)
  if quickExit(vlcOr):
    return vlcOr
  let firstValue = vlcOr.value.value
  var runningPos = vlcOr.value.pos

  if firstValue.kind != vkBool:
    # Expected bool argument got $1.
    return newValueAndPosOr(wExpectedBool, $firstValue.kind, start)

  let a = firstValue.boolv
  var skip = if specialFunction == spAnd: a == false else: a == true

  # Match the comma and whitespace.
  let commaO = matchSymbol(statement.text, gComma, runningPos)
  if not commaO.isSome:
    # Expected two arguments.
    return newValueAndPosOr(wTwoArguments, "", runningPos)
  runningPos += commaO.get().length

  # Handle the second parameter.
  var secondValue: Value
  var afterSecond: Natural
  if skip:
    let posOr = skipArg(statement, runningPos)
    if posOr.isMessage:
      return newValueAndPosOr(posOr.message)
    afterSecond = posOr.value
    secondValue = newValue(0)
  else:
    let vl2Or = getValueAndPos(statement, runningPos, variables)
    if quickExit(vl2Or):
      return vl2Or
    afterSecond = vl2Or.value.pos
    secondValue = vl2Or.value.value

  var b: bool
  if skip:
    b = true
  else:
    if secondValue.kind != vkBool:
      # Expected bool argument got $1.
      return newValueAndPosOr(wExpectedBool, $secondValue.kind, runningPos)
    b = secondValue.boolv
  runningPos = afterSecond

  # Match ) and trailing whitespace.
  let parenO = matchSymbol(statement.text, gRightParentheses, runningPos)
  if not parenO.isSome:
    # Expected two arguments.
    return newValueAndPosOr(wTwoArguments, "", runningPos)
  runningPos += parenO.get().length

  var value: bool
  if specialFunction == spAnd:
    value = a and b
  else:
    value = a or b
  result = newValueAndPosOr(newValue(value), runningPos)

proc callUserFunction*(funcVar: Value, variables: Variables, arguments: seq[Value]): FunResult =
  ## Run the given user function.
  assert funcVar.kind == vkFunc
  assert funcVar.funcv.builtIn == false

  return newFunResultWarn(wInvalidStringType, 1)

  # var userVariables = emptyVariables()

  # # Populate the m dictionary with the parameters and arguments.
  # let funResult = mapParameters(funcVar.funcv.signature, arguments)
  # if funResult.kind == frWarning:
  #   return funResult
  # userVariables["m"] = funResult.value

  # # Run the function statements.
  # for statement in funcVar.funcv.statements:

  #   let variableDataOr = runStatement(statement, variables)
  #   if variableDataOr.isMessage:
  #     return newFuncResult(variableDataOr.message)
  #   let variableData = variableDataOr.value

  #   # Handle a return function exit.
  #   if variableData.operator == opReturn:
  #       return newFuncResult(variableData.value)

  #   # Write log lines.
  #   if variableData.operator == opLog:
  #     env.logLine(sourceFilename, statement.lineNum, variableData.value.stringv & "\n")

  #   # if variableData.operator == opIgnore:

  #   # Assign the variable if possible.
  #   let warningDataO = assignVariable(userVariables,
  #     variableData.dotNameStr, variableData.value,
  #     variableData.operator, location = lcFunction)
  #   if isSome(warningDataO):
  #     return newFuncResult(warningDataO.message)

proc callFunction*(funcVar: Value, variables: Variables, arguments: seq[Value]): FunResult =
  ## Call the function variable.
  assert funcVar.kind == vkFunc
  if funcVar.funcv.builtIn:
    result = funcVar.funcv.functionPtr(variables, arguments)
  else:
    result = callUserFunction(funcVar, variables, arguments)

proc getFunctionValueAndPos*(
    functionName: string,
    statement: Statement,
    start: Natural,
    variables: Variables,
    list = false): ValueAndPosOr =
  ## Return the function's value and the position after it. Start points at the
  ## first argument of the function. The position includes the trailing
  ## whitespace after the ending ).

  var arguments: seq[Value] = @[]
  var argumentStarts: seq[Natural] = @[]
  var pos: Natural

  let symbol = if list: gRightBracket else: gRightParentheses
  let startSymbolO = matchSymbol(statement.text, symbol, start)
  if startSymbolO.isSome:
    # There are no arguments.
    pos = start + startSymbolO.get().length
  else:
    # Get the arguments to the function.
    pos = start
    while true:
      let vlOr = getValueAndPos(statement, pos, variables)
      if quickExit(vlOr):
        return vlOr
      arguments.add(vlOr.value.value)
      argumentStarts.add(pos)

      pos = vlOr.value.pos

      # Get the , or ) or ] and white space following the value.
      let commaSymbolO = matchCommaOrSymbol(statement.text, symbol, pos)
      if not commaSymbolO.isSome:
        if symbol == gRightParentheses:
          # Expected comma or right parentheses.
          return newValueAndPosOr(wMissingCommaParen, "", pos)
        else:
          # Missing comma or right bracket.
          return newValueAndPosOr(wMissingCommaBracket, "", pos)
      let commaSymbol = commaSymbolO.get()
      pos = pos + commaSymbol.length
      let foundSymbol = commaSymbol.getGroup()
      if (foundSymbol == ")" and symbol == gRightParentheses) or
         (foundSymbol == "]" and symbol == gRightBracket):
        break

  # Lookup the variable's value.
  let valueOr = getVariable(variables, functionName, "f")
  if valueOr.isMessage:
    let warningData = newWarningData(valueOr.message.messageId,
      valueOr.message.p1, start)
    return newValueAndPosOr(warningData)
  let value = valueOr.value

  # Find the best matching function by looking at the arguments.
  let funcValueOr = getBestFunction(value, arguments)
  if funcValueOr.isMessage:
    let warningData = newWarningData(funcValueOr.message.messageId,
      funcValueOr.message.p1, start)
    return newValueAndPosOr(warningData)
  let funcVar = funcValueOr.value

  # Call the function.
  let funResult = callFunction(funcVar, variables, arguments)

  if funResult.kind == frWarning:
    var warningPos: int
    if funResult.parameter < argumentStarts.len:
      warningPos = argumentStarts[funResult.parameter]
    else:
      warningPos = start
    return newValueAndPosOr(funResult.warningData.messageId,
      funResult.warningData.p1, warningPos)

  var sideEffect: SideEffect
  if functionName == "return":
    sideEffect = seReturn
  elif functionName == "log":
    sideEffect = seLogMessage
  else:
    sideEffect = seNone

  result = newValueAndPosOr(funResult.value, pos, sideEffect)

proc getList(statement: Statement, start: Natural,
    variables: Variables): ValueAndPosOr =
  ## Return the literal list value and position afte it.
  ## The start index points at [. The position includes the
  ## trailing whitespace after the ending ].

  # Match the left bracket and whitespace.
  let startSymbolO = matchSymbol(statement.text, gLeftBracket, start)
  assert startSymbolO.isSome
  let startSymbol = startSymbolO.get()

  # Get the list. The literal list [...] and list(...) are similar.
  return getFunctionValueAndPos("list", statement,
    start+startSymbol.length, variables, list=true)

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
proc getCondition*(statement: Statement, start: Natural,
    variables: Variables): ValueAndPosOr

proc getValueOrNestedCond(statement: Statement, start: Natural,
    variables: Variables): ValueAndPosOr =
  ## Return a value and position after it. If start points at a nested
  ## condition, handle it.

  var runningPos = start
  let parenO = matchSymbol(statement.text, gLeftParentheses, runningPos)
  if parenO.isSome:
    # Found a left parenetheses, get the nested condition.
    result = getCondition(statement, start, variables)
  else:
    result = getValueAndPos(statement, start, variables)

proc getCondition*(statement: Statement, start: Natural,
    variables: Variables): ValueAndPosOr =
  ## Return the bool value of the condition expression and the
  ## position after it.  The start index points at the ( left
  ## parentheses. The position includes the trailing whitespace after
  ## the ending ).
  when showPos:
    showDebugPos(statement, start, "^ s condition")

  var runningPos = start
  var lastBoolOp: string

  # Match the left parentheses and following whitespace.
  let parenO = matchSymbol(statement.text, gLeftParentheses, runningPos)
  assert parenO.isSome
  runningPos += parenO.get().length

  # Return a value and position after handling any nested condition.
  var accumOr = getValueOrNestedCond(statement, runningPos, variables)
  if quickExit(accumOr):
    return accumOr
  var accum = accumOr.value.value
  runningPos = accumOr.value.pos

  while true:
    # Check for ending right parentheses and trailing whitespace.
    let rightParenO = matchSymbol(statement.text, gRightParentheses, runningPos)
    if rightParenO.isSome:
      let finish = runningPos + rightParenO.get().length
      let vAndL = newValueAndPos(accum, finish)
      when showPos:
        showDebugPos(statement, finish, "^ f condition")
      return newValueAndPosOr(vAndL)

    # Get the operator.
    let opO = matchBoolExprOperator(statement.text, runningPos)
    if not opO.isSome:
      # Expected a boolean expression operator, and, or, ==, !=, <, >, <=, >=.
      return newValueAndPosOr(wNotBoolOperator, "", runningPos)
    let op = opO.getGroup()
    if (op == "and" or op == "or") and accum.kind != vkBool:
      # A boolean operator’s left value must be a bool.
      return newValueAndPosOr(wBoolOperatorLeft, "", runningPos)

    # Look for short ciruit conditions.
    var sortCiruitTaken: bool
    var shortCiruitResult: bool
    if op == "or":
      if lastBoolOp == "":
        lastBoolOp = "or"
      elif lastBoolOp != "or":
        # When mixing 'and's and 'or's you need to specify the precedence with parentheses.
        return newValueAndPosOr(wNeedPrecedence, "", runningPos)
      if accum.boolv == true:
        sortCiruitTaken = true
        shortCiruitResult = true
    elif op == "and":
      if lastBoolOp == "":
        lastBoolOp = "and"
      elif lastBoolOp != "and":
        # When mixing 'and's and 'or's you need to specify the precedence with parentheses.
        return newValueAndPosOr(wNeedPrecedence, "", runningPos)
      if accum.boolv == false:
        sortCiruitTaken = true
        shortCiruitResult = false
    else:
      # We have a compare operator.
      if accum.kind != vkInt and accum.kind != vkFloat and accum.kind != vkString:
        # The comparison operator’s left value must be a number or string.
        return newValueAndPosOr(wCompareOperator, "", runningPos)

    runningPos += opO.get().length

    if sortCiruitTaken:
      # Sort ciruit the condition and skip past the closing right parentheses.
      let posOr = skipArg(statement, start)
      if posOr.isMessage:
        return newValueAndPosOr(posOr.message)
      runningPos = posOr.value
      when showPos:
        showDebugPos(statement, runningPos, "^ f condition")
      return newValueAndPosOr(newValue(shortCiruitResult), runningPos)

    # Return a value and position after handling any nestedcondition.
    let vlRightOr = getValueOrNestedCond(statement, runningPos, variables)
    let xyz = runningPos
    if quickExit(vlRightOr):
      return vlRightOr
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
        return newValueAndPosOr(messageData)
      bValue = runCompareOp(accum, op, right)
    elif right.kind == vkBool:
      bValue = runBoolOp(accum, op, right)
    else:
      # Get the next operator.
      let op2O = matchCompareOperator(statement.text, runningPos)
      if not op2O.isSome:
        # Expected a compare operator, ==, !=, <, >, <=, >=.
        return newValueAndPosOr(wNotCompareOperator, "", runningPos)
      let op2 = op2O.getGroup()
      runningPos += op2O.get().length

      # Return a value and position after handling any nested condition.
      let vlThirdOr = getValueOrNestedCond(statement, runningPos, variables)
      if quickExit(vlThirdOr):
        return vlThirdOr

      if vlThirdOr.value.value.kind != right.kind:
        # The comparison operator’s right value must be the same type as the left value.
        return newValueAndPosOr(wCompareOperatorSame, "", runningPos)

      let bValue2 = runCompareOp(right, op2, vlThirdOr.value.value)
      bValue = runBoolOp(accum, op, bValue2)
      runningPos = vlThirdOr.value.pos

    accum = newValue(bValue)

proc getBracketedVarValue*(statement: Statement, dotName: string, dotNameLen: Natural, start: Natural,
    variables: Variables): ValueAndPosOr =
  ## Return the value of the bracketed variable. Start points a the
  ## container variable name.
  ## a = list[ 4 ]
  ##     ^ sbv    ^ fbv
  ## a = dict[ "abc" ]
  ##     ^ sbv        ^ fbv
  when showPos:
    showDebugPos(statement, start, "^ s bracketed")
  var runningPos = start

  # Get the container variable.
  let containerOr = getVariable(variables, dotName, "l")
  if containerOr.isMessage:
    # The variable doesn't exist, etc.
    let warningData = newWarningData(containerOr.message.messageId,
      containerOr.message.p1, runningPos)
    return newValueAndPosOr(warningData)
  let containerValue = containerOr.value
  if containerValue.kind != vkList and containerValue.kind != vkDict:
    # The container variable must be a list or dictionary got $1.
    return newValueAndPosOr(wIndexNotListOrDict, $containerValue.kind, runningPos)
  runningPos += dotNameLen

  # Get the index/key value.
  let vAndPosOr = getValueAndPos(statement, runningPos, variables)
  if vAndPosOr.isMessage:
    return vAndPosOr
  let indexValue = vAndPosOr.value.value

  # Get the value from the container using the index/key.
  var value: Value
  if containerValue.kind == vkList:
    # list container
    if indexValue.kind != vkInt:
      # The index variable must be an integer.
      return newValueAndPosOr(wIndexNotInt, "", runningPos)
    let index = indexValue.intv
    let list = containerValue.listv
    if index < 0 or index >= list.len:
      # The index value $1 is out of range.
      return newValueAndPosOr(wInvalidIndexRange, $index, runningPos)
    value = containerValue.listv[index]
  else:
    # dictionary container
    if indexValue.kind != vkString:
      # The key variable must be an string.
      return newValueAndPosOr(wKeyNotString, "", runningPos)
    let key = indexValue.stringv
    let dict = containerValue.dictv
    if not (key in dict):
      # The key doesn't exist in the dictionary.
      return newValueAndPosOr(wMissingKey, "", runningPos)
    value = dict[key]

  # Get the ending right bracket.
  runningPos = vAndPosOr.value.pos
  let rightBracketO = matchSymbol(statement.text, gRightBracket, runningPos)
  if not rightBracketO.isSome:
    # Missing right bracket.
    return newValueAndPosOr(wMissingRightBracket, "", runningPos)
  runningPos += rightBracketO.get().length

  when showPos:
    showDebugPos(statement, runningPos, "^ f bracketed")

  return newValueAndPosOr(value, runningPos)

proc getValueAndPosWorker(statement: Statement, start: Natural, variables:
    Variables): ValueAndPosOr =
  ## Get the value, position and side effect from the statement. Start
  ## points at the right hand side of the statement. For "a = 5" start
  ## points at the 5.

  # The first character determines its type.
  # * quote -- string
  # * digit or minus sign -- number
  # * a-zA-Z -- variable
  # * [ -- a list
  # * ( -- a condition expression

  # Make sure start is pointing to something.
  if start >= statement.text.len:
    # Expected a string, number, variable, list or condition.
    return newValueAndPosOr(wInvalidRightHandSide, "", start)

  ## Branch based on the first character.
  let char = statement.text[start]
  if char == '"':
    result = getString(statement, start)
  elif char in {'0' .. '9', '-'}:
    result = getNumber(statement, start)
  elif char == '[':
    result = getList(statement, start, variables)
  elif char == '(':
    result = getCondition(statement, start, variables)
  elif isLowerAscii(char) or isUpperAscii(char):
    # Get the variable name.
    let matchesO = matchDotNames(statement.text, start)
    if not matchesO.isSome:
      # Expected a string, number, variable, list or condition.
      return newValueAndPosOr(wInvalidRightHandSide, "", start)
    let (_, dotNameStr, leftParenBrack, dotNameLen) = matchesO.get3GroupsLen()

    # Handle top level function call or nested call.
    # top level: a = cmp(4, 4)
    # len nested: a = cmd(len(b), len(c))

    if leftParenBrack == "(":
      # We have a function, run it and return its value.

      let specialFunctionOr = getSpecialFunction(dotNameStr, variables)
      if specialFunctionOr.isMessage:
        let warningData = newWarningData(specialFunctionOr.message.messageId,
          specialFunctionOr.message.p1, start)
        return newValueAndPosOr(warningData)
      let specialFunction = specialFunctionOr.value

      case specialFunction:
      of spIf, spIf0:
        # Handle the special IF functions.
        return ifFunctions(specialFunction, statement, start+dotNameLen, variables)
      of spAnd, spOr:
        # Handle the special AND/OR functions.
        return andOrFunctions(specialFunction, statement, start+dotNameLen, variables)
      of spFunc:
        # Define a function in a code file and not nested.
        return newValueAndPosOr(wDefineFunction, "", start)
      of spNotSpecial, spReturn, spWarn, spLog:
        # Handle normal functions and warn, return and log.
        return getFunctionValueAndPos(dotNameStr, statement,
          start+dotNameLen, variables, list=false)

    elif leftParenBrack == "[":
      # a = list[2] or a = dict["key"]
      return getBracketedVarValue(statement, dotNameStr, dotNameLen, start, variables)

    # We have a variable.
    let valueOr = getVariable(variables, dotNameStr, "l")
    if valueOr.isMessage:
      let warningData = newWarningData(valueOr.message.messageId,
        valueOr.message.p1, start)
      return newValueAndPosOr(warningData)
    return newValueAndPosOr(valueOr.value, start+dotNameLen)
  else:
    # Expected a string, number, variable, list or condition.
    return newValueAndPosOr(wInvalidRightHandSide, "", start)

proc getValueAndPos*(statement: Statement, start: Natural, variables:
    Variables): ValueAndPosOr =
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

  result = getValueAndPosWorker(statement, start, variables)

  when showPos:
    var pos: Natural
    if result.isMessage:
      pos = result.message.pos
    else:
      pos = result.value.pos
    showDebugPos(statement, pos, "^ f")

proc runStatement*(statement: Statement, variables: Variables):
    VariableDataOr =
  ## Run one statement and return the variable dot name string,
  ## operator and value.

  # Skip blank lines and comments.
  var pos: Natural
  let spacesO = matchTabSpace(statement.text, 0)
  if not isSome(spacesO):
    pos = 0
  else:
    pos = spacesO.get().length
  if pos >= statement.text.len or statement.text[pos] == '#':
    return newVariableDataOr("", opIgnore, newValue(0))

  # Get the variable dot name string and match the surrounding white
  # space.
  let matchesO = matchDotNames(statement.text, pos)
  if not isSome(matchesO):
    # Statement does not start with a variable name.
    return newVariableDataOr(wMissingStatementVar)
  let (_, dotNameStr, leftParenBrack, dotNameLen) = matchesO.get3GroupsLen()
  let leadingLen = dotNameLen + pos

  var vlOr: ValueAndPosOr
  var operator = opIgnore
  var operatorLength = 0
  var varName = ""

  if leftParenBrack == "(":
    # Handle bare function: if, if0, return, warn and log. A bare
    # function does not assign a variable.

    let specialFunctionOr = getSpecialFunction(dotNameStr, variables)
    if specialFunctionOr.isMessage:
      let warningData = newWarningData(specialFunctionOr.message.messageId,
        specialFunctionOr.message.p1, pos)
      return newVariableDataOr(warningData)
    let specialFunction = specialFunctionOr.value

    case specialFunction:
    of spIf, spIf0:
      # Handle the special bare if functions.
      vlOr = ifFunctions(specialFunction, statement, leadingLen, variables, bare=true)
    of spNotSpecial, spAnd, spOr, spFunc:
      # Missing left hand side and operator, e.g. a = len(b) not len(b).
      return newVariableDataOr(wMissingLeftAndOpr, "", pos)
    of spReturn, spWarn, spLog:
      # Handle a bare warn, log or return function.
      vlOr = getFunctionValueAndPos($specialFunction, statement, leadingLen, variables, list=false)

  else:
    # Handle normal "varName operator right" statements.
    varName = dotNameStr

    if leftParenBrack != "":
      # Statement does not start with a variable name.
      return newVariableDataOr(wMissingStatementVar)

    # Get the equal sign or &= and the following whitespace.
    let operatorO = matchEqualSign(statement.text, leadingLen)
    if not operatorO.isSome:
      # Missing operator, = or &=.
      return newVariableDataOr(wInvalidVariable, "", leadingLen)
    let match = operatorO.get()
    let op = match.getGroup()
    if op == "=":
      operator = opEqual
    else:
      operator = opAppendList

    operatorLength = match.length

    # Get the right hand side value and match the following whitespace.
    vlOr = getValueAndPos(statement,
      leadingLen + operatorLength, variables)

  if vlOr.isMessage:
    return newVariableDataOr(vlOr.message)

  # Return function exit.
  if vlOr.value.sideEffect == seReturn:
    return newVariableDataOr("", opReturn, vlOr.value.value)

  if vlOr.value.sideEffect == seLogMessage:
    return newVariableDataOr("", opLog, vlOr.value.value)

  # Check that there is not any unprocessed text following the value.
  if vlOr.value.pos != statement.text.len:
    # Check for a trailing comment.
    if statement.text[vlOr.value.pos] != '#':
      # Unused text at the end of the statement.
      return newVariableDataOr(wTextAfterValue, "", vlOr.value.pos)

  # Return the variable dot name and value.
  result = newVariableDataOr(varName, operator, vlOr.value.value)

proc runStatementAssignVar*(env: var Env, statement: Statement, variables: var Variables,
    sourceFilename: string, codeLocation: CodeLocation): LoopControl =
  ## Run a statement and assign the variable if appropriate. Return
  ## skip, stop or continue to control the loop.

  # Run the statement and get the variable, operator and value.
  let variableDataOr = runStatement(statement, variables)
  if variableDataOr.isMessage:
    env.warnStatement(statement, variableDataOr.message, sourceFilename = sourceFilename)
    return lcContinue
  let variableData = variableDataOr.value

  # Handle a return function exit.
  if variableData.operator == opReturn:
    if variableData.value.stringv == "stop":
      return lcStop
    # "skip"
    return lcSkip

  if variableData.operator == opLog:
    env.logLine(sourceFilename, statement.lineNum, variableData.value.stringv & "\n")
    return lcContinue

  if variableData.operator == opIgnore:
    return lcContinue

  # Assign the variable if possible.
  let warningDataO = assignVariable(variables,
    variableData.dotNameStr, variableData.value, variableData.operator, codeLocation)
  if isSome(warningDataO):
    env.warnStatement(statement, warningDataO.get(), sourceFilename)
  return lcContinue

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
  let matchesO = matchDotNames(signature, runningPos)
  if not isSome(matchesO):
    if notEmptyOrSpaces(signature):
      # Excected a function name.
      return newSignatureOr(wFunctionName, "", runningPos)
    else:
      # Missing the function signature string.
      return newSignatureOr(wMissingSignature, "", runningPos)
  let (_, dotNameStr, leftParenBrack, dotNameLen) = matchesO.get3GroupsLen()
  if leftParenBrack != "(":
    # Excected a left parentheses for the signature.
    return newSignatureOr(wMissingLeftParen, "", runningPos + dotNameStr.len)
  runningPos += dotNameLen
  let functionName = dotNameStr

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
      let paramNameO = matchDotNames(signature, runningPos)
      if not isSome(paramNameO):
        # Excected a parameter name.
        return newSignatureOr(wParameterName, "", runningPos)
      let (_, paramName, leftP, paramNameLen) = paramNameO.get3GroupsLen()
      if leftP == "(":
        # Expected a colon.
        return newSignatureOr(wMissingColon, "", runningPos + paramName.len)
      runningPos += paramNameLen

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
      params.add(newParam(paramName, paramType))

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

  let signature = newSignature(optional, functionName, params, returnType)
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
  let leftNameO = matchDotNames(statement.text, runningPos)
  if not isSome(leftNameO):
    return false
  let (_, leftName, leftParenBrack, leftNameLen) = leftNameO.get3GroupsLen()
  if leftParenBrack == "(":
    return false
  runningPos += leftNameLen

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
  let mO = matchDotNames(statement.text, runningPos)
  if not isSome(mO):
    return false
  let (_, funcStr, leftParen, funcStrLen) = mO.get3GroupsLen()
  if funcStr != "func":
    return false
  if leftParen != "(":
    return false
  runningPos += funcStrLen

  retLeftName = leftName
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

# func leftOpRightFunc*(statement: Statement,
#     retLeftName: string,
#     retOperator: string,
#     retRightName: string,
#     retRightNameParen: string,
#     retPos: Natural
#   ): bool =
#   ## Parse the statement and fill in the left name, operator, the
#   ## right hand side dot name and right hand paren. Return true when
#   ## it matches.
#   var runningPos = 0

#   var leftName: string
#   var operator: Operator
#   var rightName: string
#   var pos: Natural
#   if not leftAndOperator(statement, leftName, operator, runningPos):
#     return false

#   let mO = matchDotNames(statement.text, runningPos)
#   if not isSome(mO):
#     return false
#   let (_, rightName, rightNameParen, rightLen) = mO.get3GroupsLen()
#   runningPos += funcStrLen

#   retLeftName = leftName
#   retOperator = operator
#   retRightName = rightName
#   retRightNameParen = rightNameParen
#   retPos = runningPos
#   return true

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
  var docComments = newSeq[string]()
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
  docComments.add(firstStatement.text)
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
    docComments.add(statement.text)

  # Collect the function's statements.
  var userStatements = newSeq[Statement]()
  userStatements.add(statement)
  while true:
    # Look for a return statement.
    let mO = matchDotNames(statement.text, 0)
    if isSome(mO):
      let (_, leftName, leftNameParen, _) = mO.get3GroupsLen()
      if leftName == "return" and leftNameParen == "(":
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

  let userFunc = newFunc(builtIn=false, signature, docComments, sourceFilename, lineNum,
    numLines, userStatements, dummy)
  let funcVar = newValue(userFunc)

  # Assign the variable if possible.
  let warningDataO = assignVariable(variables, leftName, funcVar,
    operator, inCodeFile)
  if isSome(warningDataO):
    env.warnStatement(statement, warningDataO.get(), sourceFilename)
  return true

proc runCommand*(env: var Env, cmdLines: CmdLines,
    variables: var Variables, codeLocation: CodeLocation): LoopControl =
  ## Run a command and fill in the variables dictionaries.

  # Clear the local variables and set the tea vars to their initial
  # state.
  resetVariables(variables)

  # Loop over the statements and run each one.
  for statement in yieldStatements(cmdLines):

    # Run the statement.
    let loopControl = runStatementAssignVar(env, statement, variables,
      env.templateFilename, codeLocation)

    # Stop looping when we get a return.
    if loopControl == lcStop or loopControl == lcSkip:
      return loopControl

    # If t.repeat was set to 0, we're done.
    let tea = variables["t"].dictv
    if "repeat" in tea and tea["repeat"].intv == 0:
      break

  result = lcContinue

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

    # todo: merge in the code for defining user functions better

    # If the statement starts a function definition, define it and
    # assign the variable. A true return value means the statement(s)
    # were processed and maybe errors output. A false means the
    # statement should be processed as a regular statement.
    if defineUserFunctionAssignVar(env, lb, statement, variables, filename, codeFile=true):
      continue

    # Process a regular statement.
    let loopControl = runStatementAssignVar(env, statement, variables, filename, inCodeFile)
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
