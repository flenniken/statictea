## Run a command and fill in the variables dictionaries.

import std/options
import std/strUtils
import readLines
import matches
import regexes
import env
import vartypes
import messages
import warnings
import parseNumber
import variables
import funtypes
import runFunction
import readjson
import collectCommand
import opresultwarn

const
  # Turn on showPos for testing to graphically show the start and end
  # positions when running a statement.
  showPos = false

type
  # todo: Inforce a maximum statement length?
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

  ValueAndLength* = object
    ## A value and the length of the matching text in the statement.
    ## For the example statement: "var = 567 ". The value 567 starts
    ## at index 6 and the matching length is 4 because it includes the
    ## trailing space. For example "id = row(3 )" the value is 3 and
    ## the length is 2.
    value*: Value
    length*: Natural

proc newValueAndLength*(value: Value, length: Natural): ValueAndLength =
  ## Create a newValueAndLength object.
  result = ValueAndLength(value: value, length: length)

func newValueAndLengthOr*(warning: Warning, p1 = "", pos = 0):
    OpResultWarn[ValueAndLength] =
  ## Create a OpResultWarn[ValueAndLength] warning.
  let warningData = newWarningData(warning, p1, pos)
  result = opMessageW[ValueAndLength](warningData)

func newValueAndLengthOr*(warningData: WarningData):
    OpResultWarn[ValueAndLength] =
  ## Create a OpResultWarn[ValueAndLength] warning.
  result = opMessageW[ValueAndLength](warningData)

func newValueAndLengthOr*(value: Value, length: Natural):
    OpResultWarn[ValueAndLength] =
  ## Create a OpResultWarn[ValueAndLength] value.
  let val = ValueAndLength(value: value, length: length)
  result = opValueW[ValueAndLength](val)

proc newValueAndLengthOr*(number: int | int64 | float64 | string,
    length: Natural): OpResultWarn[ValueAndLength] =
  result = newValueAndLengthOr(newValue(number), length)

func newValueAndLengthOr*(val: ValueAndLength):
    OpResultWarn[ValueAndLength] =
  ## Create a OpResultWarn[ValueAndLength].
  result = opValueW[ValueAndLength](val)

func newLengthOr*(warning: Warning, p1 = "", pos = 0):
    OpResultWarn[Natural] =
  ## Create a OpResultWarn[Natural] warning.
  let warningData = newWarningData(warning, p1, pos)
  result = opMessageW[Natural](warningData)

func newLengthOr*(pos: Natural): OpResultWarn[Natural] =
  ## Create a OpResultWarn[Natural] value.
  result = opValueW[Natural](pos)

func newStatement*(text: string, lineNum: Natural = 1,
    start: Natural = 0): Statement =
  ## Create a new statement.
  result = Statement(lineNum: lineNum, start: start, text: text)

proc startColumn*(start: Natural, symbol: string = "^"): string =
  ## Return enough spaces to point at the warning column.  Used under
  ## the statement line.
  for ix in 0..<start:
    result.add(' ')
  result.add(symbol)

func getFragmentAndPos*(statement: Statement, start: Natural):
     (string, Natural) =
  ## Return a statement fragment, and new position to show the given
  ## position.

  var fragment: string
  var extraStart = ""
  var extraEnd = ""
  let fragmentMax = 60
  let halfFragment = fragmentMax div 2
  var startPos: int
  var endPos: int
  var pointerPos: int

  if statement.text.len <= fragmentMax:
    fragment = statement.text
    startPos = start
    pointerPos = start
  else:
    startPos = start.int - halfFragment
    if startPos < 0:
      startPos = 0
    else:
      extraStart = "..."

    endPos = startPos + fragmentMax
    if endPos > statement.text.len:
      endPos = statement.text.len
    else:
      extraEnd = "..."
    fragment = extraStart & statement.text[startPos ..< endPos] & extraEnd
    pointerPos = start.int - startPos + extraStart.len

  assert pointerPos >= 0
  result = (fragment, Natural(pointerPos))

when showPos:
  proc showDebugPos*(statement: Statement, start: Natural, symbol: string) =
    let (fragment, pointerPos) = getFragmentAndPos(statement, start)
    echo fragment
    echo startColumn(pointerPos, symbol)

proc getWarnStatement*(statement: Statement,
    warningData: WarningData,
    templateFilename: string): string =
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
    getWarningLine(templateFilename, statement.lineNum, warning, p1),
    fragment,
    startColumn(pointerPos)
  ]
  result = message

proc warnStatement*(env: var Env, statement: Statement,
    warningData: WarningData) =
  ## Show an invalid statement with a pointer pointing at the start of
  ## the problem. Long statements are trimmed around the problem area.
  let message = getWarnStatement(statement, warningData, env.templateFilename)
  env.outputWarning(statement.lineNum, message)

func `==`*(s1: Statement, s2: Statement): bool =
  ## Return true when the two statements are equal.
  if s1.lineNum == s2.lineNum and s1.start == s2.start and
      s1.text == s2.text:
    result = true

func `$`*(s: Statement): string =
  ## Return a string representation of a Statement.
  result = """$1, $2: "$3"""" % [$s.lineNum, $s.start, s.text]

func get3GroupsLen(matchesO: Option[Matches]): (string,
    string, string, Natural) =
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

func getString*(statement: Statement, start: Natural):
    OpResultWarn[ValueAndLength] =
  ## Return a literal string value and match length from a statement. The
  ## start parameter is the index of the first quote in the statement
  ## and the return length includes optional trailing white space
  ## after the last quote.

  let str = statement.text

  # Parse the json string and remove escaping.
  let parsedString = parseJsonStr(str, start+1)
  if parsedString.messageId != MessageId(0):
    return newValueAndLengthOr(parsedString.messageId, "", parsedString.pos)

  result = newValueAndLengthOr(newValue(parsedString.str),
    parsedString.pos - start)

proc getNumber*(statement: Statement, start: Natural):
    OpResultWarn[ValueAndLength] =
  ## Return the literal number value and match length from the
  ## statement. The start index points at a digit or minus sign. The
  ## length includes the trailing whitespace.

  # Check that we have a statictea number.
  let matchesO = matchNumber(statement.text, start)
  if not matchesO.isSome:
    return newValueAndLengthOr(wNotNumber, "", start)

  # The decimal point determines whether the number is an integer or
  # float.
  let matches = matchesO.get()
  let decimalPoint = matches.getGroup()
  let length = matches.length
  var value: Value
  if decimalPoint == ".":
    # Parse the float.
    let floatPosO = parseFloat64(statement.text, start)
    if not floatPosO.isSome:
      return newValueAndLengthOr(wNumberOverFlow, "", start)
    let floatPos = floatPosO.get()
    value = newValue(floatPos.number)
    assert floatPos.length <= length
  else:
    # Parse the int.
    let intPosO = parseInteger(statement.text, start)
    if not intPosO.isSome:
      return newValueAndLengthOr(wNumberOverFlow, "", start)
    let intPos = intPosO.get()
    value = newValue(intPos.integer)
    assert intPos.length <= length
  result = newValueAndLengthOr(value, length)

# Forward reference to getValueAndLength since we call it recursively.
proc getValueAndLength*(statement: Statement, start: Natural, variables:
  Variables, skip: bool): OpResultWarn[ValueAndLength]

# Call stack:
# - runStatement
# - getValueAndLength
# - getFunctionValueAndLength
# - getValueAndLength

proc ifFunction*(
    functionName: string,
    statement: Statement,
    start: Natural,
    variables: Variables,
    list=false): OpResultWarn[ValueAndLength] =
  ## Return the if0 and if1 function's value and the length. These
  ## functions conditionally run one of their parameters. Start points
  ## at the first parameter of the function. The length includes the
  ## trailing whitespace after the ending ).

  # if0(cond, then, else)
  # if1(cond, then, else)

  # Get the condition's integer value.
  let vlcOr = getValueAndLength(statement, start, variables, skip=false)
  if vlcOr.isMessage:
    return vlcOr
  let condition = vlcOr.value.value
  var runningLen = vlcOr.value.length

  # Make sure the condition is an integer.
  if condition.kind != vkInt:
    # The parameter must be an integer.
    return newValueAndLengthOr(wExpectedInteger, "", start)

  # Match the comma and whitespace.
  let commaO = matchSymbol(statement.text, gComma, start + runningLen)
  if not commaO.isSome:
    # Expected three parameters.
    return newValueAndLengthOr(wThreeParameters, "", start)
  runningLen += commaO.get().length

  # Determine whether we execute the second or third parameter.
  var getSecond: bool
  if (condition.intv == 0 and functionName == "if0") or
     (condition.intv == 1 and functionName == "if1"):
    # Return the second parameter.
    getSecond = true
  else:
    # Return the third parameter.
    getSecond = false

  # Handle the second parameter.
  var skip = (getSecond == false)
  let vl2Or = getValueAndLength(statement, start + runningLen, variables, skip)
  if vl2Or.isMessage:
    return vl2Or
  runningLen += vl2Or.value.length

  # Match the comma and whitespace.
  let cO = matchSymbol(statement.text, gComma, start + runningLen)
  if not cO.isSome:
    # Expected three parameters.
    return newValueAndLengthOr(wThreeParameters, "", start + runningLen)
  runningLen += cO.get().length

  # Handle the third parameter.
  skip = (getSecond == true)
  let vl3Or = getValueAndLength(statement, start + runningLen, variables, skip)
  if vl3Or.isMessage:
    return vl3Or
  runningLen += vl3Or.value.length

  # Match ) and trailing whitespace.
  let parenO = matchSymbol(statement.text, gRightParentheses,
    start + runningLen)
  if not parenO.isSome:
    # Expected three parameters.
    return newValueAndLengthOr(wThreeParameters, "", start + runningLen)
  runningLen += parenO.get().length

  var value: Value
  if getSecond:
    value = vl2Or.value.value
  else:
    value = vl3Or.value.value
  result = newValueAndLengthOr(value, runningLen)

proc getFunctionValueAndLength*(
    functionName: string,
    statement: Statement,
    start: Natural,
    variables: Variables,
    list = false, skip: bool): OpResultWarn[ValueAndLength] =
  ## Return the function's value and the length. Start points at the
  ## first parameter of the function. The length includes the trailing
  ## whitespace after the ending ).

  var parameters: seq[Value] = @[]
  var parameterStarts: seq[Natural] = @[]
  var pos: Natural

  # If we get a right parentheses or right bracket, there are no
  # parameters.
  let symbol = if list: gRightBracket else: gRightParentheses
  let startSymbolO = matchSymbol(statement.text, symbol, start)
  if startSymbolO.isSome:
    pos = start + startSymbolO.get().length
  else:
    pos = start
    while true:
      # Get the parameter's value.
      let vlOr = getValueAndLength(statement, pos, variables, skip)
      if vlOr.isMessage:
        return vlOr
      parameters.add(vlOr.value.value)
      parameterStarts.add(pos)

      pos = pos + vlOr.value.length

      # Get the , or ) or ] and white space following the value.
      let commaSymbolO = matchCommaOrSymbol(statement.text, symbol, pos)
      if not commaSymbolO.isSome:
        if symbol == gRightParentheses:
          # Expected comma or right parentheses.
          return newValueAndLengthOr(wMissingCommaParen, "", pos)
        else:
          # Missing comma or right bracket.
          return newValueAndLengthOr(wMissingCommaBracket, "", pos)
      let commaSymbol = commaSymbolO.get()
      pos = pos + commaSymbol.length
      let foundSymbol = commaSymbol.getGroup()
      if (foundSymbol == ")" and symbol == gRightParentheses) or
         (foundSymbol == "]" and symbol == gRightBracket):
        break

  if skip:
    # pos-start is the length including trailing whitespace.
    return newValueAndLengthOr(newValue(0), pos-start)

  # Lookup the function.
  let functionSpecO = getFunction(functionName, parameters)
  if not isSome(functionSpecO):
    # The function does not exist: $1.
    return newValueAndLengthOr(wInvalidFunction, functionName, start)
  let functionSpec = functionSpecO.get()

  # Call the function.
  let funResult = functionSpec.functionPtr(parameters)
  if funResult.kind == frWarning:
    var warningPos: int
    if funResult.parameter < parameterStarts.len:
      warningPos = parameterStarts[funResult.parameter]
    else:
      warningPos = start
    return newValueAndLengthOr(funResult.warningData.warning,
      funResult.warningData.p1, warningPos)

  # pos-start is the length including trailing whitespace.
  result = newValueAndLengthOr(funResult.value, pos-start)

proc getList(statement: Statement, start: Natural,
    variables: Variables, skip: bool): OpResultWarn[ValueAndLength] =
  ## Return the literal list value and match length from the
  ## statement. The start index points at [. The length includes the
  ## trailing whitespace after the ending ].

  # Match the left bracket and whitespace.
  let startSymbolO = matchSymbol(statement.text, gLeftBracket, start)
  assert startSymbolO.isSome
  let startSymbol = startSymbolO.get()

  # Get the list.
  let funValueLengthOr = getFunctionValueAndLength("list", statement,
    start+startSymbol.length, variables, list=true, skip)
  if funValueLengthOr.isMessage:
    return funValueLengthOr
  let funValueLength = funValueLengthOr.value

  # Return the value and length.
  let valueAndLength = newValueAndLength(funValueLength.value,
    funValueLength.length+startSymbol.length)
  result = newValueAndLengthOr(valueAndLength)

proc getValueAndLengthWorker(statement: Statement, start: Natural, variables:
    Variables, skip: bool): OpResultWarn[ValueAndLength] =
  ## Get the value and length from the statement.

  # The first character determines its type.
  # * quote -- string
  # * digit or minus sign -- number
  # * a-zA-Z -- variable or function
  # * [ -- a list

  # Make sure start is pointing to something.
  if start >= statement.text.len:
    # Expected a string, number, variable, list or function.
    return newValueAndLengthOr(wInvalidRightHandSide, "", start)

  ## Branch based on the first character.
  let char = statement.text[start]
  if char == '"':
    result = getString(statement, start)
  elif char in {'0' .. '9', '-'}:
    result = getNumber(statement, start)
  elif char == '[':
    result = getList(statement, start, variables, skip)
  elif isLowerAscii(char) or isUpperAscii(char):
    # Get the name.
    let matchesO = matchDotNames(statement.text, start)
    if not matchesO.isSome:
      # Expected a string, number, variable, list or function.
      return newValueAndLengthOr(wInvalidRightHandSide, "", start)
    let (_, dotNameStr, leftParen, dotNameLen) = matchesO.get3GroupsLen()

    if leftParen == "(":
      # We have a function, run it and return its value.

      # Handle the special if functions.
      if dotNameStr in ["if0", "if1"]:
        let ifOr = ifFunction(dotNameStr, statement,
          start+dotNameLen, variables, skip)
        if ifOr.isMessage:
          return ifOr
        let length = dotNameLen + ifOr.value.length
        return newValueAndLengthOr(ifOr.value.value, length)

      if not skip:
        if not isFunctionName(dotNameStr):
          # The function does not exist: $1.
          return newValueAndLengthOr(wInvalidFunction, dotNameStr, start)

      let fvl = getFunctionValueAndLength(dotNameStr, statement,
        start+dotNameLen, variables, false, skip)
      if fvl.isMessage:
        return fvl
      let length = dotNameLen+fvl.value.length
      let valueAndLength = newValueAndLength(fvl.value.value,
        length)
      return newValueAndLengthOr(valueAndLength)

    if skip:
      return newValueAndLengthOr(newValue(0), dotNameLen)

    # We have a variable.
    let valueOrWarning = getVariable(variables, dotNameStr)
    if valueOrWarning.kind == vwWarning:
      let warningData = newWarningData(valueOrWarning.warningData.warning,
        valueOrWarning.warningData.p1, start)
      return newValueAndLengthOr(warningData)
    return newValueAndLengthOr(valueOrWarning.value, dotNameLen)
  else:
    # Expected a string, number, variable, list or function.
    return newValueAndLengthOr(wInvalidRightHandSide, "", start)

proc getValueAndLength*(statement: Statement, start: Natural, variables:
    Variables, skip: bool): OpResultWarn[ValueAndLength] =
  ## Return the value and length of the item that the start parameter
  ## points at which is a string, number, variable, function or list.
  ## The length returned includes the trailing whitespace after the
  ## item. So the ending position is pointing at the end of the
  ## statement, or at the first whitspace character after the item.
  ## When skip is true, the return value is 0 and functions are not
  ## executed.

  when showPos:
    showDebugPos(statement, start, "s")

  result = getValueAndLengthWorker(statement, start, variables, skip)

  when showPos:
    var pos: Natural
    if result.isMessage:
      pos = result.message.pos
    else:
      pos = start + result.value.length
    showDebugPos(statement, pos, "f")

proc runStatement*(statement: Statement, variables: Variables):
    OpResultWarn[VariableData] =
  ## Run one statement and return the variable dot name string,
  ## operator and value.

  # Get the variable dot name string and match the surrounding white
  # space.
  let matchesO = matchDotNames(statement.text, 0)
  if not isSome(matchesO):
    # Statement does not start with a variable name.
    return newVariableDataOr(wMissingStatementVar)
  let (_, dotNameStr, leftParen, dotNameLen) = matchesO.get3GroupsLen()

  if leftParen != "":
    # No functions allow on the left hand side.
    # Statement does not start with a variable name.
    return newVariableDataOr(wMissingStatementVar)

  # Get the equal sign or &= and following whitespace.
  let operatorO = matchEqualSign(statement.text, dotNameLen)
  if not operatorO.isSome:
    # Missing operator, = or &=.
    return newVariableDataOr(wInvalidVariable, "", dotNameLen)
  let operatorMatch = operatorO.get()

  # Get the right hand side value and match the following whitespace.
  let vlOr = getValueAndLength(statement,
    dotNameLen + operatorMatch.length, variables, false)
  if vlOr.isMessage:
    return newVariableDataOr(vlOr.message)
  let value = vlOr.value.value
  let length = vlOr.value.length

  # Check that there is not any unprocessed text following the value.
  let pos = dotNameLen + operatorMatch.length + length
  if pos != statement.text.len:
    # Unused text at the end of the statement.
    return newVariableDataOr(wTextAfterValue, "", pos)

  # Return the variable dot name and value.
  let operator = operatorMatch.getGroup()
  result = newVariableDataOr(dotNameStr, operator, value)

proc runCommand*(env: var Env, cmdLines: CmdLines, variables: var Variables) =
  ## Run a command and fill in the variables dictionaries.

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

    # Assign the variable if possible.
    let warningDataO = assignVariable(variables,
      variableData.dotNameStr, variableData.value, variableData.operator)
    if isSome(warningDataO):
      env.warnStatement(statement, warningDataO.get())
