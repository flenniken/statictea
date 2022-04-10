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

type
  # todo: what is the maximum statement length?
  Statement* = object
    ## A Statement object stores the statement text and where it
    ## @:starts in the template file.
    ## @:
    ## @:* lineNum -- Line number starting at 1 where the statement
    ## @:             starts.
    ## @:* start -- Column position starting at 1 where the statement
    ## @:           starts on the line.
    ## @:* text -- The statement text.
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

func newValueAndLengthOr*(val: ValueAndLength):
    OpResultWarn[ValueAndLength] =
  ## Create a OpResultWarn[ValueAndLength].
  result = opValueW[ValueAndLength](val)

func newVariableDataOr*(warning: Warning, p1 = "", pos = 0):
    OpResultWarn[VariableData] =
  ## Create a OpResultWarn[VariableData] warning.
  let warningData = newWarningData(warning, p1, pos)
  result = opMessageW[VariableData](warningData)

func newVariableDataOr*(warningData: WarningData):
    OpResultWarn[VariableData] =
  ## Create a OpResultWarn[VariableData] warning.
  result = opMessageW[VariableData](warningData)

func newVariableDataOr*(dotNameStr: string, operator = "=", value: Value):
    OpResultWarn[VariableData] =
  ## Create a OpResultWarn[VariableData] value.
  let val = newVariableData(dotNameStr, operator, value)
  result = opValueW[VariableData](val)

func newLengthOr*(warning: Warning, p1 = "", pos = 0):
    OpResultWarn[Natural] =
  ## Create a OpResultWarn[Natural] warning.
  let warningData = newWarningData(warning, p1, pos)
  result = opMessageW[Natural](warningData)

func newLengthOr*(pos: Natural): OpResultWarn[Natural] =
  ## Create a OpResultWarn[Natural] value.
  result = opValueW[Natural](pos)

func newStatement*(text: string, lineNum: Natural = 1,
    start: Natural = 1): Statement =
  ## Create a new statement.
  result = Statement(lineNum: lineNum, start: start, text: text)

proc startColumn*(start: Natural): string =
  ## Return enough spaces to point at the warning column.  Used under
  ## the statement line.
  for ix in 0..<start:
    result.add(' ')
  result.add("^")

proc getWarnStatement*(statement: Statement,
    warningData: WarningData,
    templateFilename: string): string =
  ## Return a multiline error message.

  var fragment: string
  var extraStart = ""
  var extraEnd = ""
  let fragmentMax = 60
  let halfFragment = fragmentMax div 2
  var startPos: int
  var endPos: int
  var pointerPos: int

  let warning = warningData.warning
  let p1 = warningData.p1
  let start = warningData.pos

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

proc newValueAndLength*(value: Value, length: Natural): ValueAndLength =
  ## Create a newValueAndLength object.
  result = ValueAndLength(value: value, length: length)

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

  let value = Value(kind: vkString, stringv: parsedString.str)
  result = newValueAndLengthOr(value, parsedString.pos - start)

proc getNumber*(statement: Statement, start: Natural):
    OpResultWarn[ValueAndLength] =
  ## Return the literal number value and match length from the
  ## statement. The start index points at a digit or minus sign.

  # Check that we have a statictea number.
  let matchesO = matchNumber(statement.text, start)
  if not matchesO.isSome:
    return newValueAndLengthOr(wNotNumber, "", start)

  # The decimal point determines whether the number is an integer or
  # float.
  let matches = matchesO.get()
  let decimalPoint = matches.getGroup()
  var value: Value
  if decimalPoint == ".":
    # Parse the float.
    let floatPosO = parseFloat64(statement.text, start)
    if not floatPosO.isSome:
      return newValueAndLengthOr(wNumberOverFlow, "", start)
    let floatPos = floatPosO.get()
    value = Value(kind: vkFloat, floatv: floatPos.number)
    assert floatPos.length <= matches.length
  else:
    # Parse the int.
    let intPosO = parseInteger(statement.text, start)
    if not intPosO.isSome:
      return newValueAndLengthOr(wNumberOverFlow, "", start)
    let intPos = intPosO.get()
    value = Value(kind: vkInt, intv: intPos.integer)
    assert intPos.length <= matches.length
  result = newValueAndLengthOr(value, matches.length)

func skipParameter(statement: Statement, start: Natural):
     OpResultWarn[Natural] =
  ## Skip the next parameter.  Start is pointing at the parameter to
  ## skip.  Return the position of the next parameter or the right
  ## parentheses.  If there is a problem, return an warning message
  ## which points at the problem position.

  discard

# Forward reference to getValueAndLength since we call it recursively.
proc getValueAndLength(statement: Statement, start: Natural, variables:
    Variables): OpResultWarn[ValueAndLength]

# Call chain:
# - runStatement
# - getValueAndLength
# - getVarOrFunctionValue
# - getFunctionValueAndLength
# - getValueAndLength

proc ifFunction*(
    functionName: string,
    statement: Statement,
    start: Natural,
    variables: Variables,
    list=false): OpResultWarn[ValueAndLength] =
  ## Handle the if0 and if1 functions which conditionally run one of
  ## their parameters.  Return the function's value and the position
  ## after trailing whitespace.  Start points at the first parameter.

  # if0(cond, then, else)
  # if1(cond, then, else)

  # Get the condition's integer value.
  let valueAndLengthOr = getValueAndLength(statement, start, variables)
  if valueAndLengthOr.isMessage:
    return valueAndLengthOr
  let valueAndLength = valueAndLengthOr.value
  let condition = valueAndLength.value
  var pos = start + valueAndLength.length

  # Make sure the condition is an integer.
  if condition.kind != vkInt:
    # The parameter must be an integer.
    return newValueAndLengthOr(wExpectedInteger)

  # Determine whether we execute the second or third parameter.
  var getSecond: bool
  if (condition.intv == 0 and functionName == "if0") or
     (condition.intv == 1 and functionName == "if1"):
    # Return the second parameter.
    getSecond = true
  else:
    # Return the third parameter.
    getSecond = false

    # Skip the second parameter.
    let skipLenOr = skipParameter(statement, pos)
    if skipLenOr.isMessage:
      return newValueAndLengthOr(skipLenOr.message)
    pos = pos + skipLenOr.value

  # Get the "then" or "else" value pointed at by pos.
  let valOr = getValueAndLength(statement, pos, variables)
  if valOr.isMessage:
    return valOr
  pos = pos + valOr.value.length

  if getSecond:
    # Skip the third parameter.
    let skipLenOr = skipParameter(statement, pos)
    if skipLenOr.isMessage:
      return newValueAndLengthOr(skipLenOr.message)
    pos = pos + skipLenOr.value

  result = newValueAndLengthOr(valueAndLength.value, pos)

proc getFunctionValueAndLength*(
    functionName: string,
    statement: Statement,
    start: Natural,
    variables: Variables,
    list=false): OpResultWarn[ValueAndLength] =
  ## Collect the function parameters then call it and return the
  ## function's value and the position after trailing whitespace.
  ## Start points at the first parameter.

  var parameters: seq[Value] = @[]
  var parameterStarts: seq[Natural] = @[]
  var pos = start

  # If we get a right parentheses or right bracket, there are no parameters.
  let symbol = if list: gRightBracket else: gRightParentheses
  let startSymbolO = matchSymbol(statement.text, symbol, pos)
  if startSymbolO.isSome:
    pos = pos + startSymbolO.get().length
  else:
    while true:
      # Get the parameter's value.
      let valueAndLengthOr = getValueAndLength(statement, pos, variables)
      if valueAndLengthOr.isMessage:
        return valueAndLengthOr
      let valueAndLength = valueAndLengthOr.value

      parameters.add(valueAndLength.value)
      parameterStarts.add(pos)

      pos = pos + valueAndLength.length

      # Get the comma or ) or ] and white space following the value.
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

  result = newValueAndLengthOr(funResult.value, pos-start)

proc getVarOrFunctionValue*(statement: Statement, start: Natural,
    variables: Variables): OpResultWarn[ValueAndLength] =
  ## Return the value and length that "start" points at. Start points
  ## at the name of a variable or name of a function or a list.  The
  ## length returned includes the trailing whitespace. Start points at
  ## the first non-whitespace character of the right hand side or at
  ## the start of a function parameter.

  # Get the variable or function name. Match the surrounding white
  # space.
  let dotNameStrO = matchDotNames(statement.text, start)
  assert dotNameStrO.isSome
  let matches = dotNameStrO.get()
  let groups = matches.getGroups(3)
  # let whitespace = groups[0]
  let dotNameStr = groups[1]
  let leftParen = groups[2]
  let dotNameLen = matches.length

  if leftParen == "(":
    # We have a function, run it and return its value.

    # Make sure the function exists.
    let functionName = dotNameStr
    if not isFunctionName(functionName):
      # The function does not exist: $1.
      return newValueAndLengthOr(wInvalidFunction, functionName, start)

    # Handle the special conditional excecution functions.
    # if functionName in ["if0", "if1"]:
    #   return ifFunction(functionName, statement,
    #     start+dotNameLen, variables)

    # Get the function's value and length.
    let funValueLengthOr = getFunctionValueAndLength(functionName, statement,
      start+dotNameLen, variables)
    if funValueLengthOr.isMessage:
      return funValueLengthOr
    let funValueLength = funValueLengthOr.value

    # Return the value and length.
    let valueAndLength = newValueAndLength(funValueLength.value,
      dotNameLen+funValueLength.length)
    result = newValueAndLengthOr(valueAndLength.value, valueAndLength.length)
  else:
    # We have a variable, look it up and return its value.
    let valueOrWarning = getVariable(variables, dotNameStr)
    if valueOrWarning.kind == vwWarning:
      return newValueAndLengthOr(valueOrWarning.warningData.warning,
        valueOrWarning.warningData.p1, start)

    result = newValueAndLengthOr(valueOrWarning.value, dotNameLen)

proc getList(statement: Statement, start: Natural,
    variables: Variables): OpResultWarn[ValueAndLength] =
  ## Return the literal list value and match length from the
  ## statement. The start index points at [.

  # Match the left bracket and whitespace.
  let startSymbolO = matchSymbol(statement.text, gLeftBracket, start)
  assert startSymbolO.isSome
  let startSymbol = startSymbolO.get()

  # Get the list.
  let funValueLengthOr = getFunctionValueAndLength("list", statement,
    start+startSymbol.length, variables, true)
  if funValueLengthOr.isMessage:
    return funValueLengthOr
  let funValueLength = funValueLengthOr.value

  # Return the value and length.
  let valueAndLength = newValueAndLength(funValueLength.value,
    funValueLength.length+startSymbol.length)
  result = newValueAndLengthOr(valueAndLength)

proc getValueAndLength(statement: Statement, start: Natural, variables:
    Variables): OpResultWarn[ValueAndLength] =
  ## Return the value and length of the item that "start" points at.
  ## The length returned includes the trailing whitespace. Start
  ## points at the first non-whitespace character of the right hand
  ## side or at the start of a function parameter.

  # The first character determines its type.
  # * quote -- string
  # * digit or minus sign -- number
  # * a-zA-Z -- variable or function
  # * [ -- a list

  # Make sure start is pointing to something.
  if start >= statement.text.len:
    # Expected a string, number, variable, list or function.
    return newValueAndLengthOr(wInvalidRightHandSide, "", start)

  ## Call the correct get function based on the first character.
  let char = statement.text[start]
  if char == '"':
    result = getString(statement, start)
  elif char in {'0' .. '9', '-'}:
    result = getNumber(statement, start)
  elif isLowerAscii(char) or isUpperAscii(char):
    result = getVarOrFunctionValue(statement, start, variables)
  elif char == '[':
    result = getList(statement, start, variables)
  else:
    # Expected a string, number, variable, list or function.
    return newValueAndLengthOr(wInvalidRightHandSide, "", start)

proc runStatement*(statement: Statement, variables: Variables):
    OpResultWarn[VariableData] =
  ## Run one statement and return the variable dot name string,
  ## operator and value.

  # Get the variable dot name string and match the surrounding white
  # space.
  let dotNameMatchesO = matchDotNames(statement.text, 0)
  if not isSome(dotNameMatchesO):
    # Statement does not start with a variable name.
    return newVariableDataOr(wMissingStatementVar)
  let matches = dotNameMatchesO.get()
  let groups = matches.getGroups(3)
  # let whitespace = groups[0]
  let dotNameStr = groups[1]
  let leftParen = groups[2]

  if leftParen != "":
    # Statement does not start with a variable name.
    return newVariableDataOr(wMissingStatementVar)
  let dotNameLen = matches.length

  # Get the equal sign or &= and following whitespace.
  let operatorO = matchEqualSign(statement.text, dotNameLen)
  if not operatorO.isSome:
    # Invalid variable or missing equal operator.
    return newVariableDataOr(wInvalidVariable)
  let operatorMatch = operatorO.get()

  # Get the right hand side value and match the following whitespace.
  let valueAndLengthOr = getValueAndLength(statement,
    dotNameLen + operatorMatch.length, variables)
  if valueAndLengthOr.isMessage:
    return newVariableDataOr(valueAndLengthOr.message)
  let value = valueAndLengthOr.value.value
  let length = valueAndLengthOr.value.length

  # Check that there is not any unprocessed text following the value.
  let pos = dotNameLen + operatorMatch.length + length
  if pos != statement.text.len:
    # Unused text at the end of the statement.
    return newVariableDataOr(wTextAfterValue, "", pos)

  # Return the variable dot name and value.
  let operator = operatorMatch.getGroups(1)[0]
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
