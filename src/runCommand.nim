## Run a command and fill in the variables dictionaries.

import std/options
import std/strutils
import std/tables
import readLines
import matches
import regexes
import env
import vartypes
import messages
import warnings
import parseNumber
import variables
import runFunction
import readjson
import collectCommand
import opresultwarn
import unicodes
import utf8decoder

const
  # Turn on showPos for testing to graphically show the start and end
  # positions when running a statement.
  showPos = false

type
  Statement* = object
    ## A Statement object stores the statement text and where it
    ## @:starts in the template file.
    ## @:
    ## @:* lineNum -- line number, starting at 1, where the statement
    ## @:             starts.
    ## @:* start -- index where the statement starts
    ## @:* text -- the statement text.
    lineNum*: Natural
    start*: Natural
    text*: string

  PosOr* = OpResultWarn[Natural]

func newPosOr*(warning: MessageId, p1 = "", pos = 0): PosOr =
  ## Create a PosOr warning.
  let warningData = newWarningData(warning, p1, pos)
  result = opMessageW[Natural](warningData)

func newPosOr*(pos: Natural): PosOr =
  ## Create a PosOr value.
  result = opValueW[Natural](pos)

proc `==`*(a: PosOr, b: PosOr): bool =
  ## Return true when a equals b.
  if a.kind == b.kind:
    if a.isMessage:
      result = a.message == b.message
    else:
      result = a.value == b.value

proc `!=`*(a: PosOr, b: PosOr): bool =
  result = not (a == b)

proc startColumn*(text: string, start: Natural, message: string = "^"): string =
  ## Return enough spaces to point at the start byte position of the
  ## given text.  This accounts for multibyte UTF-8 sequences that
  ## might be in the text.
  result = newStringOfCap(start + message.len)
  var ixFirst: int
  var ixLast: int
  var codePoint: uint32
  var byteCount = 0
  var charCount = 0
  for valid in yieldUtf8Chars(text, ixFirst, ixLast, codePoint):
    # Byte positions inside multibyte sequences except the first point
    # to the next start.
    if byteCount >= start:
      break
    byteCount += (ixLast - ixFirst + 1)
    inc(charCount)
    result.add(' ')
  result.add(message)

func newStatement*(text: string, lineNum: Natural = 1,
    start: Natural = 0): Statement =
  ## Create a new statement.
  result = Statement(lineNum: lineNum, start: start, text: text)

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

proc getWarnStatement*(filename: string, statement: Statement,
    warningData: WarningData): string =
  ## Return a multiline error message.

  let start = warningData.pos
  assert start >= 0
  let (fragment, pointerPos) = getFragmentAndPos(statement, start)

  let warning = warningData.warning
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

  if warningData.warning == wUserMessage:
    message = "$1($2): $3" % [filename,
      $statement.lineNum, warningData.p1]
  else:
    message = getWarnStatement(filename, statement, warningData)
  env.outputWarning(statement.lineNum, message)

func `==`*(s1: Statement, s2: Statement): bool =
  ## Return true when the two statements are equal.
  if s1.lineNum == s2.lineNum and s1.start == s2.start and
      s1.text == s2.text:
    result = true

func `$`*(s: Statement): string =
  ## Return a string representation of a Statement.
  result = """$1, $2: "$3"""" % [$s.lineNum, $s.start, s.text]

# todo: move this
func get3GroupsLen*(matchesO: Option[Matches]):
    (string, string, string, Natural) =
  let matches = matchesO.get()
  let (one, two, three) = matches.get3Groups()
  result = (one, two, three, matches.length)

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

proc getNumber*(statement: Statement, start: Natural): ValueAndPosOr =
  ## Return the literal number value and position after it.  The start
  ## index points at a digit or minus sign. The position includes the
  ## trailing whitespace.

  # Check that we have a statictea number and get the length including
  # trailing whitespace.
  let matchesO = matchNumber(statement.text, start)
  if not matchesO.isSome:
    # Invalid number.
    return newValueAndPosOr(wNotNumber, "", start)

  # The decimal point determines whether the number is an integer or
  # float.
  let matches = matchesO.get()
  let decimalPoint = matches.getGroup()
  var valueAndPos: ValueAndPos
  if decimalPoint == ".":
    # Parse the float.
    let valueAndPosO = parseFloat(statement.text, start)
    if not valueAndPosO.isSome:
      # The number is too big or too small.
      return newValueAndPosOr(wNumberOverFlow, "", start)
    valueAndPos = valueAndPosO.get()
  else:
    # Parse the int.
    let valueAndPosO = parseInteger(statement.text, start)
    if not valueAndPosO.isSome:
      # The number is too big or too small.
      return newValueAndPosOr(wNumberOverFlow, "", start)
    valueAndPos = valueAndPosO.get()
  # Note that we use the matches length so it includes the trailing whitespace.
  result = newValueAndPosOr(newValueAndPos(valueAndPos.value, start + matches.length))

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

proc skipArg(statement: Statement, start: Natural): PosOr =
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

# Call stack:
# - runStatement
# - getValueAndPos
# - getFunctionValueAndPos
# - ifFunctions
# - getList
# - getValueAndPos

proc ifFunctions*(
    functionName: string,
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
  if vlcOr.isMessage or vlcOr.value.exit:
    return vlcOr
  let cond = vlcOr.value.value
  var runningPos = vlcOr.value.pos

  var condition = false
  if functionName == "if":
    if cond.kind != vkBool:
      # The if condition must be a bool value, got a $1.
      return newValueAndPosOr(wExpectedBool, $cond.kind, start)
    condition = cond.boolv
  else: # functionName == "if0"
    case cond.kind:
     of vkInt:
       if cond.intv == 0:
         condition = true
     of vkFloat:
       if cond.floatv == 0.0:
         condition = true
     of vkString:
       if cond.stringv.len == 0:
         condition = true
     of vkList:
       if cond.listv.len == 0:
         condition = true
     of vkDict:
       if cond.dictv.len == 0:
         condition = true
     of vkBool:
       condition = cond.boolv
     of vkFunc:
       condition = false

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
    if vl2Or.isMessage or vl2Or.value.exit:
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
      if vl3Or.isMessage or vl3Or.value.exit:
        return vl3Or
      runningPos = vl3Or.value.pos
  else:
    if not bare:
      # An if with an assignment takes three arguments.
      return newValueAndPosOr(wAssignmentIf, "", runningPos)

  # Match ) and trailing whitespace.
  let parenO = matchSymbol(statement.text, gRightParentheses, runningPos)
  if not parenO.isSome:
    # Expected two or three parameters.
    return newValueAndPosOr(wTwoOrThreeParams, "", runningPos)
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
    functionName: string,
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
  if vlcOr.isMessage or vlcOr.value.exit:
    return vlcOr
  let firstValue = vlcOr.value.value
  var runningPos = vlcOr.value.pos

  if firstValue.kind != vkBool:
    # Expected bool argument got $1.
    return newValueAndPosOr(wExpectedBool, $firstValue.kind, start)

  let a = firstValue.boolv
  var skip = if functionName == "and": a == false else: a == true

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
    if vl2Or.isMessage or vl2Or.value.exit:
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
  if functionName == "and":
    value = a and b
  else:
    value = a or b
  result = newValueAndPosOr(newValue(value), runningPos)

proc getFunctionValueAndPos*(
    dotNameStr: string,
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
      if vlOr.isMessage or vlOr.value.exit:
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
  let valueOr = getVariable(variables, dotNameStr)
  if valueOr.isMessage:
    let warningData = newWarningData(valueOr.message.warning,
      valueOr.message.p1, start)
    return newValueAndPosOr(warningData)
  let value = valueOr.value

  # Find the best matching function by looking at the arguments.
  let funcValueOr = getBestFunction(value, arguments)
  if funcValueOr.isMessage:
    let warningData = newWarningData(funcValueOr.message.warning,
      funcValueOr.message.p1, start)
    return newValueAndPosOr(warningData)

  # Call the function.
  let funResult = funcValueOr.value.funcv.functionPtr(variables, arguments)
  if funResult.kind == frWarning:
    var warningPos: int
    if funResult.parameter < argumentStarts.len:
      warningPos = argumentStarts[funResult.parameter]
    else:
      warningPos = start
    return newValueAndPosOr(funResult.warningData.warning,
      funResult.warningData.p1, warningPos)

  var exit = if dotNameStr == "return": true else: false
  result = newValueAndPosOr(funResult.value, pos, exit)

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

proc runBoolOp*(left: Value, op: string, right: Value): Value =
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

proc runCompareOp*(left: Value, op: string, right: Value): Value =
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
  if accumOr.isMessage or accumOr.value.exit:
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
    if vlRightOr.isMessage or vlRightOr.value.exit:
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
      if vlThirdOr.isMessage or vlThirdOr.value.exit:
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
  let containerOr = getVariable(variables, dotName)
  if containerOr.isMessage:
    # The variable doesn't exist, etc.
    let warningData = newWarningData(containerOr.message.warning,
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
  ## Get the value and position from the statement.

  # The first character determines its type.
  # * quote -- string
  # * digit or minus sign -- number
  # * a-zA-Z -- variable or function
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
    # Get the name.
    let matchesO = matchDotNames(statement.text, start)
    if not matchesO.isSome:
      # Expected a string, number, variable, list or condition.
      return newValueAndPosOr(wInvalidRightHandSide, "", start)
    let (_, dotNameStr, leftParenBrack, dotNameLen) = matchesO.get3GroupsLen()

    if leftParenBrack == "(":
      # We have a function, run it and return its value.

      # Handle the special if functions.
      if dotNameStr in ["if", "if0"]:
        return ifFunctions(dotNameStr, statement, start+dotNameLen, variables)

      # Handle the special and/or functions.
      if dotNameStr in ["and", "or"]:
        return andOrFunctions(dotNameStr, statement, start+dotNameLen, variables)

      return getFunctionValueAndPos(dotNameStr, statement,
        start+dotNameLen, variables, false)
    elif leftParenBrack == "[":
      # a = list[2] or a = dict["key"]
      return getBracketedVarValue(statement, dotNameStr, dotNameLen, start, variables)

    # We have a variable.
    let valueOr = getVariable(variables, dotNameStr)
    if valueOr.isMessage:
      let warningData = newWarningData(valueOr.message.warning,
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

# todo: add a start
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
    return newVariableDataOr("", "", newValue(0))

  # Get the variable dot name string and match the surrounding white
  # space.
  let matchesO = matchDotNames(statement.text, pos)
  if not isSome(matchesO):
    # Statement does not start with a variable name.
    return newVariableDataOr(wMissingStatementVar)
  let (_, dotNameStr, leftParenBrack, dotNameLen) = matchesO.get3GroupsLen()
  let leadingLen = dotNameLen + pos

  var vlOr: ValueAndPosOr
  var operator = ""
  var operatorLength = 0
  var varName = ""

  if leftParenBrack == "(" and dotNameStr in ["if0", "if"]:
    # Handle the special bare if functions.
    vlOr = ifFunctions(dotNameStr, statement, leadingLen, variables, bare=true)
  # elif leftParenBrack == "[":
  #   # a[2] = 4
  #   # not implemented
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
    operator = match.getGroup()
    operatorLength = match.length

    # Get the right hand side value and match the following whitespace.
    vlOr = getValueAndPos(statement,
      leadingLen + operatorLength, variables)

  if vlOr.isMessage:
    return newVariableDataOr(vlOr.message)

  # Return function exit.
  if vlOr.value.exit:
    return newVariableDataOr("", "exit", vlOr.value.value)

  # Check that there is not any unprocessed text following the value.
  if vlOr.value.pos != statement.text.len:
    # Check for a trailing comment.
    if statement.text[vlOr.value.pos] != '#':
      # Unused text at the end of the statement.
      return newVariableDataOr(wTextAfterValue, "", vlOr.value.pos)

  # Return the variable dot name and value.
  result = newVariableDataOr(varName, operator, vlOr.value.value)

proc runCommand*(env: var Env, cmdLines: CmdLines,
    variables: var Variables): string =
  ## Run a command and fill in the variables dictionaries. Return "",
  ## @:"skip" or "stop".
  ## @:
  ## @:* "" -- output the replacement block. This is the default.
  ## @:* "skip" -- skip this replacement block but continue with the
  ## @:next.
  ## @:* "stop" -- stop processing the block.

  # Clear the local variables and set the tea vars to their initial
  # state.
  resetVariables(variables)

  # Loop over the statements and run each one.
  for statement in yieldStatements(cmdLines):

    # Run the statement and get the variable, operator and value.
    let variableDataOr = runStatement(statement, variables)
    if variableDataOr.isMessage:
      env.warnStatement(statement, variableDataOr.message)
      continue
    let variableData = variableDataOr.value

    # Return function exit.
    if variableData.operator == "exit":
      if variableData.value.kind != vkString:
        # Expected 'skip', 'stop' or '' for the block command return value.
        env.warnStatement(statement, newWarningData(wSkipStopOrEmpty))
        continue
      return variableData.value.stringv

    # A bare if without taking a return.
    if variableData.operator == "":
      continue

    # Assign the variable if possible.
    let warningDataO = assignVariable(variables,
      variableData.dotNameStr, variableData.value, variableData.operator)
    if isSome(warningDataO):
      env.warnStatement(statement, warningDataO.get())

    # If t.repeat was set to 0, we're done.
    let tea = variables["t"].dictv
    if "repeat" in tea and tea["repeat"].intv == 0:
      break

  result = ""
