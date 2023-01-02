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

proc getVariableName*(text: string, start: Natural): Option[VariableName] =
  ## Get a variable name from the statement. Start points at a name.
  let dotNamesO = matchDotNames(text, start)
  if not dotNamesO.isSome:
    return
  let (_, dotName, leftParenBracket, length) = dotNamesO.get3GroupsLen()
  var kind: VariableNameKind
  case leftParenBracket
  of "(":
    kind = vnkFunction
  of "[":
    kind = vnkGet
  else:
    kind = vnkNormal
  result = some(newVariableName(dotName, kind, start+length))

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
      if not emptyOrSpaces(text):
        yield newStatement(strip(text), lineNum)
      # Setup variables for the next line, if there is one.
      text.setLen(0)
      if cmdLines.lines.len > ix+1:
        lineNum = lp.lineNum + 1
        start = cmdLines.lineParts[ix+1].codeStart

  if not emptyOrSpaces(text):
    yield newStatement(strip(text), lineNum)

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
  ## Return true when the ValueAndPosOr is a messsage, a return or a
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

func getSpecialFunction(funcVar: Value): SpecialFunction =
  ## Return the function type given a function variable.

  var value: Value
  if funcVar.kind == vkList:
    let list = funcVar.listv
    if list.len != 1:
      # This is not a special function because there is more than one
      # item in the list and all special functions are a list of one.
      return spNotSpecial
    value = list[0]
  else:
    value = funcVar

  if value.kind != vkFunc:
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
  else:
    result = spNotSpecial

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
  ## @:
  ## @:The three parameter if requires an assignment.  The two parameter
  ## @:version cannot have an assignment. The if function cond is a
  ## @:boolean, for if0 it is anything.
  ## @:
  ## @:cases:
  ## @:
  ## @:~~~
  ## @:a = if(cond, then, else)
  ## @:       ^                ^
  ## @:if(cond, then)
  ## @:   ^          ^
  ## @:~~~~

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
      if quickExit(vl3Or):
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

proc callUserFunction*(funcVar: Value, variables: Variables, arguments: seq[Value]): FunResult

proc getFunctionValueAndPos*(
    functionName: string,
    statement: Statement,
    start: Natural,
    variables: Variables,
    list = false): ValueAndPosOr =
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

  var arguments: seq[Value] = @[]
  var argumentStarts: seq[Natural] = @[]
  var runningPos = start

  let symbol = if list: gRightBracket else: gRightParentheses
  let startSymbolO = matchSymbol(statement.text, symbol, runningPos)
  if startSymbolO.isSome:
    # There are no arguments.
    runningPos = start + startSymbolO.get().length
  else:
    # Get the arguments to the function.
    while true:
      let vlOr = getValueAndPos(statement, runningPos, variables)
      if quickExit(vlOr):
        return vlOr
      arguments.add(vlOr.value.value)
      argumentStarts.add(runningPos)

      runningPos = vlOr.value.pos

      # Get the , or ) or ] and white space following the value.
      let commaSymbolO = matchCommaOrSymbol(statement.text, symbol, runningPos)
      if not commaSymbolO.isSome:
        if symbol == gRightParentheses:
          # Expected comma or right parentheses.
          return newValueAndPosOr(wMissingCommaParen, "", runningPos)
        else:
          # Missing comma or right bracket.
          return newValueAndPosOr(wMissingCommaBracket, "", runningPos)
      let commaSymbol = commaSymbolO.get()
      runningPos = runningPos + commaSymbol.length
      let foundSymbol = commaSymbol.getGroup()
      if (foundSymbol == ")" and symbol == gRightParentheses) or
         (foundSymbol == "]" and symbol == gRightBracket):
        break

  # Lookup the variable's value.
  let valueOr = getVariable(variables, functionName, npBuiltIn)
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
  assert funcVar.kind == vkFunc
  var funResult: FunResult
  if funcVar.funcv.builtIn:
    funResult = funcVar.funcv.functionPtr(variables, arguments)
  else:
    funResult = callUserFunction(funcVar, variables, arguments)

  if funResult.kind == frWarning:
    var warningPos: int
    if funResult.parameter < argumentStarts.len:
      warningPos = argumentStarts[funResult.parameter]
    else:
      warningPos = start
    return newValueAndPosOr(funResult.warningData.messageId,
      funResult.warningData.p1, warningPos)

  var sideEffect: SideEffect
  # todo: use the signature function name instead?
  if functionName == "return":
    sideEffect = seReturn
  elif functionName == "log":
    sideEffect = seLogMessage
  else:
    sideEffect = seNone

  result = newValueAndPosOr(funResult.value, runningPos, sideEffect)

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

    # Get the boolean operator.
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
    if quickExit(vlRightOr):
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

proc getBracketedVarValue*(statement: Statement, start: Natural,
    container: Value, variables: Variables): ValueAndPosOr =
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
  let vAndPosOr = getValueAndPos(statement, runningPos, variables)
  if quickExit(vAndPosOr):
    return vAndPosOr
  let indexValue = vAndPosOr.value.value

  # Get the value from the container using the index/key.
  var value: Value
  if container.kind == vkList:
    # list container
    if indexValue.kind != vkInt:
      # The index variable must be an integer.
      return newValueAndPosOr(wIndexNotInt, "", runningPos)
    let index = indexValue.intv
    let list = container.listv
    if index < 0 or index >= list.len:
      # The index value $1 is out of range.
      return newValueAndPosOr(wInvalidIndexRange, $index, runningPos)
    value = container.listv[index]
  else:
    # dictionary container
    if indexValue.kind != vkString:
      # The key variable must be an string.
      return newValueAndPosOr(wKeyNotString, "", runningPos)
    let key = indexValue.stringv
    let dict = container.dictv
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
    return newValueAndPosOr(wInvalidRightHandSide, "", start)
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
    result = getFunctionValueAndPos("list", statement,
      start+startSymbol.length, variables, list=true)

  of rtCondition:
    result = getCondition(statement, start, variables)

  of rtVariable:
    # Get the variable name.
    let rightNameO = getVariableName(statement.text, start)
    if not rightNameO.isSome:
      # Expected a string, number, variable, list or condition.
      return newValueAndPosOr(wInvalidRightHandSide, "", start)
    let rightName = rightNameO.get()

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
      return newValueAndPosOr(warningData)

    case rightName.kind
    of vnkNormal:
      return newValueAndPosOr(valueOr.value, rightName.pos)

    of vnkFunction:
      # We have a function, run it and return its value.
      let specialFunction = getSpecialFunction(valueOr.value)
      case specialFunction:
      of spIf, spIf0:
        # Handle the special IF functions.
        return ifFunctions(specialFunction, statement, rightName.pos, variables)
      of spAnd, spOr:
        # Handle the special AND/OR functions.
        return andOrFunctions(specialFunction, statement, rightName.pos, variables)
      of spFunc:
        # Define a function in a code file and not nested.
        return newValueAndPosOr(wDefineFunction, "", start)
      of spNotSpecial, spReturn, spWarn, spLog:
        # Handle normal functions and warn, return and log.
        return getFunctionValueAndPos(rightName.dotName, statement,
          rightName.pos, variables, list=false)

    of vnkGet:
      # a = list[2] or a = dict["key"]
      let container = valueOr.value
      if container.kind != vkList and container.kind != vkDict:
        # The container variable must be a list or dictionary got $1.
        return newValueAndPosOr(wIndexNotListOrDict, $container.kind, start)

      return getBracketedVarValue(statement, rightName.pos, valueOr.value, variables)

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

proc runBareFunction*(statement: Statement, start: Natural,
    variables: Variables, leftName: VariableName): ValueAndPosOr =
  ## Handle bare function: if, if0, return, warn and log. A bare
  ## function does not assign a variable.
  ## @:
  ## @:~~~
  ## @:if( true, warn("tea time")) # test
  ## @:^                           ^
  ## @:~~~~
  let runningPos = leftName.pos

  # Get the function variable.
  let funcVarOr = getVariable(variables, leftName.dotName, npBuiltIn)
  if funcVarOr.isMessage:
    return newValueAndPosOr(funcVarOr.message)
  let funcVar = funcVarOr.value

  # Look up the special function type.
  let specialFunction = getSpecialFunction(funcVar)

  # Handle all the special function types.
  case specialFunction:
  of spIf, spIf0:
    # Handle the special bare if functions.
    result = ifFunctions(specialFunction, statement, runningPos, variables, bare=true)
  of spNotSpecial, spAnd, spOr, spFunc:
    # Missing left hand side and operator, e.g. a = len(b) not len(b).
    result = newValueAndPosOr(wMissingLeftAndOpr, "", start)
  of spReturn, spWarn, spLog:
    # Handle a bare warn, log or return function.
    result = getFunctionValueAndPos($specialFunction, statement, runningPos, variables, list=false)

proc runStatement*(statement: Statement, variables: Variables): VariableDataOr =
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
  let leftNameO = getVariableName(statement.text, runningPos)
  if not isSome(leftNameO):
    # Statement does not start with a variable name.
    return newVariableDataOr(wMissingStatementVar)
  let leftName = leftNameO.get()

  var vlOr: ValueAndPosOr
  var operator = opIgnore
  var operatorLength = 0

  case leftName.kind
  of vnkFunction:
    # Handle bare function: if, if0, return, warn and log. A bare
    # function does not assign a variable.
    vlOr = runBareFunction(statement, runningPos, variables, leftName)
    if vlOr.isMessage:
      return newVariableDataOr(vlOr.message)
  of vnkGet:
    # You cannot use bracket notation to change a variable.
    return newVariableDataOr(wLeftHandBracket)
  of vnkNormal:
    # Handle normal "varName operator right" statements.

    # Get the equal sign or &= and the following whitespace.
    let operatorO = matchEqualSign(statement.text, leftName.pos)
    if not operatorO.isSome:
      # Missing operator, = or &=.
      return newVariableDataOr(wInvalidVariable, "", leftName.pos)
    let match = operatorO.get()
    let op = match.getGroup()
    if op == "=":
      operator = opEqual
    else:
      operator = opAppendList

    operatorLength = match.length

    # Get the right hand side value and match the following whitespace.
    vlOr = getValueAndPos(statement,
      leftName.pos + operatorLength, variables)

  if vlOr.isMessage:
    return newVariableDataOr(vlOr.message)

  case vlOr.value.sideEffect
  of seReturn:
    # Return function exit.
    return newVariableDataOr("", opReturn, vlOr.value.value)
  of seLogMessage:
    # Log statement exit.
    return newVariableDataOr("", opLog, vlOr.value.value)
  of seNone:
    discard

  # Check that there is not any unprocessed text following the value.
  if vlOr.value.pos != statement.text.len:
    # Check for a trailing comment.
    if statement.text[vlOr.value.pos] != '#':
      # Unused text at the end of the statement.
      return newVariableDataOr(wTextAfterValue, "", vlOr.value.pos)

  # Return the variable dot name and value.
  result = newVariableDataOr(leftName.dotName, operator, vlOr.value.value)

proc callUserFunction*(funcVar: Value, variables: Variables, arguments: seq[Value]): FunResult =
  ## Run the given user function.
  assert funcVar.kind == vkFunc
  assert funcVar.funcv.builtIn == false

  let funcsVarDict = createFuncDictionary().dictv
  var userVariables = startVariables(funcs=funcsVarDict)

  # Populate the l dictionary with the parameters and arguments.
  let funResult = mapParameters(funcVar.funcv.signature, arguments)
  if funResult.kind == frWarning:
    return funResult
  userVariables["l"] = funResult.value

  # Run the function statements.
  for statement in funcVar.funcv.statements:

    # Run the statement.
    let variableDataOr = runStatement(statement, userVariables)
    if variableDataOr.isMessage:
      return newFunResultWarn(variableDataOr.message)
    let variableData = variableDataOr.value

    # Handle the result of the statement.
    case variableData.operator
    of opEqual, opAppendList:
      # Assign the variable if possible.
      let wdO = assignVariable(userVariables, variableData, inOther)
      if isSome(wdO):
        return newFunResultWarn(wdO.get())
    of opIgnore:
      continue
    of opReturn:
      # Return the value of the function.
      return newFunResult(variableData.value)
    of opLog:
      # todo: support logging in user functions.
      discard

  assert(false, "the function doesn't have a return statement")
  # Out of lines; missing the function's return statement.
  result = newFunResultWarn(wNoReturnStatement)

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

  case variableData.operator
  of opEqual, opAppendList:
    # Assign the variable if possible.
    let warningDataO = assignVariable(variables,
      variableData.dotNameStr, variableData.value, variableData.operator, codeLocation)
    if isSome(warningDataO):
      env.warnStatement(statement, warningDataO.get(), sourceFilename)
    result = lcContinue
  of opIgnore:
    result = lcContinue
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

    # Expected 'skip' or 'stop' for the return function value.
    let wd = newWarningData(wSkipOrStop)
    env.warnStatement(statement, wd, sourceFilename = sourceFilename)
    result = lcSkip

  of opLog:
    env.logLine(sourceFilename, statement.lineNum, variableData.value.stringv & "\n")
    result = lcContinue

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
  let functionNameO = getVariableName(signature, runningPos)
  if not isSome(functionNameO):
    if not emptyOrSpaces(signature):
      # Excected a function name.
      return newSignatureOr(wFunctionName, "", runningPos)
    else:
      # Missing the function signature string.
      return newSignatureOr(wMissingSignature, "", runningPos)
  let functionName = functionNameO.get()

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
      let paramNameO = getVariableName(signature, runningPos)
      if not isSome(paramNameO):
        # Excected a parameter name.
        return newSignatureOr(wParameterName, "", runningPos)
      let paramName = paramNameO.get()

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
  let leftNameO = getVariableName(statement.text, runningPos)
  if not isSome(leftNameO):
    return false
  let leftName = leftNameO.get()

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
  let funcNameO = getVariableName(statement.text, runningPos)
  if not isSome(funcNameO):
    return false
  let funcName = funcNameO.get()
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
    let leftNameO = getVariableName(statement.text, 0)
    if isSome(leftNameO):
      let leftName = leftNameO.get()
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
