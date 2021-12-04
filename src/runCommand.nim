## Run a command.

import std/options
import std/strUtils
import parseCmdLine
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

type
  State = enum
    ## Finite state machine states for finding statements.
    start, double, single, slashdouble, slashsingle

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

#[

When an error is detected on a statement, the error message tells the
line and column position where the statement starts.  To do this we
store the line and start position with each statement.

# lines:
    0123456789 123456789 123456789 123456789
1:  <--$ block a = 5; b = \-->
2:  <--$ : "hello"; \-->
3:  <--$ : c = t.len(s.header) -->

statements:
1:  a = 5
2:  _b = "hello"
3:  _c = t.len(s.header)_

statement 1 starts at line 1, position 11.
statement 2 starts at line 1, position 18.
statement 3 starts at line 3, position 7.

]#


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

proc warnStatement*(env: var Env, statement: Statement, warning:
                    Warning, start: Natural, p1: string = "", p2:
                                         string = "") =
  ## Show an invalid statement with a pointer pointing at the start of
  ## the problem. Long statements are trimmed around the problem area.

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

  var message = """
$1
statement: $2
           $3""" % [
    getWarning(env.templateFilename, statement.lineNum, warning, p1, p2),
    fragment,
    startColumn(pointerPos)
  ]
  env.outputWarning(message)

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
  ## Iterate through the command's statements.  Statements are
  ## separated by semicolons or newlines and are not empty or all
  ## spaces.

  # To find the semicolons that separate statements we use a finite
  # state machine.  In the start state we output a statement when a
  # semicolon is found. We transition when a quote is found, either to
  # a double quote state or single quote state. In one of the quote
  # states we transition back to the start state when another quote is
  # found of the same kind or we transition to a slash state when a
  # slash is found. The slash states transition back to their quote
  # state on the next character.

  var text = newStringOfCap(defaultMaxLineLen)
  var lineNum: Natural
  var start: Natural
  if cmdLines.lines.len > 0:
    lineNum = cmdLines.lineParts[0].lineNum
    start = cmdLines.lineParts[0].middleStart
  var state = State.start
  for ix in 0 ..< cmdLines.lines.len:
    let line = cmdLines.lines[ix]
    let lp = cmdLines.lineParts[ix]
    for pos in lp.middleStart ..< lp.middleStart+lp.middleLen:
      let ch = line[pos]
      if state == State.start:
        if ch == ';':
          if notEmptyOrSpaces(text):
            yield newStatement(text, lineNum, start)
          text.setLen(0)
          lineNum = lp.lineNum
          start = pos + 1 # After the semicolon.
          continue
        elif ch == '"':
          state = double
        elif ch == '\'':
          state = single
      elif state == double:
        if ch == '"':
          state = State.start
        elif ch == '\\':
          state = slashdouble
      elif state == single:
        if ch == '\'':
          state = State.start
        elif ch == '\\':
          state = slashsingle
      elif state == slashsingle:
        state = single
      elif state == slashdouble:
        state = double
      text.add(ch)

    # A statement is terminated by the end of the line by default.
    if not lp.continuation:
      if notEmptyOrSpaces(text):
        yield newStatement(text, lineNum, start)
      # Setup variables for the next line, if there is one.
      text.setLen(0)
      if cmdLines.lines.len > ix+1:
        lineNum = lp.lineNum + 1
        start = cmdLines.lineParts[ix+1].middleStart

  if notEmptyOrSpaces(text):
    yield newStatement(text, lineNum, start)

proc getString*(env: var Env, prepostTable: PrepostTable,
    statement: Statement, start: Natural): Option[ValueAndLength] =
  ## Return a literal string value and match length from a statement. The
  ## start parameter is the index of the first quote in the statement
  ## and the return length includes optional trailing white space
  ## after the last quote.

  let str = statement.text

  # Parse the json string and remove escaping.
  let parsedString = parseJsonStr(str, start+1)
  if parsedString.messageId != MessageId(0):
    env.warnStatement(statement, parsedString.messageId, parsedString.pos)
    return
  let valueAndLength = newValueAndLength(newValue(parsedString.str),
    parsedString.pos - start)
  let literal = parsedString.str

  let value = Value(kind: vkString, stringv: literal)
  result = some(ValueAndLength(value: value, length: valueAndLength.length))

proc getNumber*(env: var Env, prepostTable: PrepostTable,
    statement: Statement, start: Natural): Option[ValueAndLength] =
  ## Return the literal number value and match length from the
  ## statement. The start index points at a digit or minus sign.

  # Check that we have a statictea number.
  var matchesO = matchNumber(statement.text, start)
  if not matchesO.isSome:
    env.warnStatement(statement, wNotNumber, start)
    return

  # The decimal point determines whether the number is an integer or
  # float.
  let matches = matchesO.get()
  let decimalPoint = matches.getGroup()
  if decimalPoint == ".":
    # Parse the float.
    let floatPosO = parseFloat64(statement.text, start)
    if not floatPosO.isSome:
      env.warnStatement(statement, wNumberOverFlow, start)
      return
    let floatPos = floatPosO.get()
    let value = Value(kind: vkFloat, floatv: floatPos.number)
    assert floatPos.length <= matches.length
    result = some(ValueAndLength(value: value, length: matches.length))
  else:
    # Parse the int.
    let intPosO = parseInteger(statement.text, start)
    if not intPosO.isSome:
      env.warnStatement(statement, wNumberOverFlow, start)
      return
    let intPos = intPosO.get()
    let value = Value(kind: vkInt, intv: intPos.integer)
    assert intPos.length <= matches.length
    result = some(ValueAndLength(value: value, length: matches.length))

# Forward reference needed because we call getValue recursively.
proc getValue(env: var Env, prepostTable: PrepostTable,
              statement: Statement, start: Natural, variables:
                Variables): Option[ValueAndLength]

proc getFunctionValue*(env: var Env, prepostTable:
    PrepostTable, functionName: string, statement:
    Statement, start: Natural, variables: Variables): Option[ValueAndLength] =
  ## Collect the function parameter values then call it. Start should
  ## be pointing at the first parameter.

  var parameters: seq[Value] = @[]
  var parameterStarts: seq[Natural] = @[]
  var pos = start

  # If we get a right parentheses, there are no parameters.
  let rightParenO = matchRightParentheses(statement.text, pos)
  if rightParenO.isSome:
    pos = pos + rightParenO.get().length
  else:
    while true:
      # Get the parameter's value.
      let valueAndLengthO = getValue(env, prepostTable, statement,
                                     pos, variables)
      if not valueAndLengthO.isSome:
        return

      parameters.add(valueAndLengthO.get().value)
      parameterStarts.add(pos)

      pos = pos + valueAndLengthO.get().length

      # Get the comma or right parentheses and white space following the value.
      let commaParenO = matchCommaParentheses(statement.text, pos)
      if not commaParenO.isSome:
        env.warnStatement(statement, wMissingCommaParen, pos)
        return
      let commaParen = commaParenO.get()
      pos = pos + commaParen.length
      let symbol = commaParen.getGroup()
      if symbol == ")":
        break

  # Lookup the function.
  let functionSpecO = getFunction(functionName, parameters)
  if not isSome(functionSpecO):
    # The function doesn't exist: name
    env.warnStatement(statement, wInvalidFunction, start, functionName)
    return
  let functionSpec = functionSpecO.get()

  # Call the function.
  let funResult = functionSpec.functionPtr(parameters)
  if funResult.kind == frWarning:
    var warningPos: int
    if funResult.parameter < parameterStarts.len:
      warningPos = parameterStarts[funResult.parameter]
    else:
      warningPos = start
    env.warnStatement(statement, funResult.warningData.warning,
      warningPos, funResult.warningData.p1, funResult.warningData.p2)
    return

  result = some(ValueAndLength(value: funResult.value, length: pos-start))

proc getVarOrFunctionValue*(env: var Env, prepostTable:
           PrepostTable, statement: Statement,
           start: Natural, variables: Variables): Option[ValueAndLength] =
  ## Return the statement's right hand side value and the length
  ## matched. The right hand side must be a variable or a
  ## function. The right hand side starts at the index specified by
  ## start.

  # Get the variable or function name. Match the surrounding white space.
  let matches0 = matchDotNames(statement.text, start)
  assert matches0.isSome
  let matches = matches0.get()
  let (_, dotNameStr) = matches.get2Groups()

  # todo: add an optional left parentheses in the matchDotNames procedures.

  # Look for a function. A function name looks like a variable
  # followed by a left parentheses.
  let parenthesesO = matchLeftParentheses(statement.text, start+matches.length)
  if parenthesesO.isSome:
    # We have a function, run it and return its value.

    # todo: you cannot call a function with a dotname: a.b.len(). support this?
    var functionName = dotNameStr

    if not isFunctionName(functionName):
      env.warnStatement(statement, wInvalidFunction, start, functionName)
      return
    let parentheses = parenthesesO.get()
    let funValueLengthO = getFunctionValue(env, prepostTable, functionName, statement,
                            start+matches.length+parentheses.length, variables)
    if not isSome(funValueLengthO):
      return
    let funValueLength = funValueLengthO.get()
    result = some(ValueAndLength(value: funValueLength.value,
      length: matches.length+parentheses.length+funValueLength.length))
  else:
    # We have a variable, look it up and return its value.  Show a
    # warning when the variable doesn't exist.
    let valueOrWarning = getVariable(variables, dotNameStr)
    if valueOrWarning.kind == vwWarning:
      # todo: show the correct error message.
      env.warnStatement(statement, wVariableMissing, start, dotNameStr)
      return
    result = some(newValueAndLength(valueOrWarning.value, matches.length))

proc getValue(env: var Env, prepostTable: PrepostTable,
              statement: Statement, start: Natural, variables:
                Variables): Option[ValueAndLength] =
  ## Return the statements right hand side value and the length
  ## matched. The right hand side starts at the index specified by
  ## start.

  # The first character of the right hand side value determines its
  # type.
  # * quote -- string
  # * digit or minus sign -- number
  # * a-zA-Z -- variable or function

  # env.warnStatement(statement, wStackTrace, start,  "enter getValue")

  if start >= statement.text.len:
    env.warnStatement(statement, wInvalidRightHandSide, start)
    return

  let char = statement.text[start]

  if char == '"':
    result = getString(env, prepostTable, statement, start)
  elif char in {'0' .. '9', '-'}:
    result = getNumber(env, prepostTable, statement, start)
  elif isLowerAscii(char) or isUpperAscii(char):
    result = getVarOrFunctionValue(env, prepostTable, statement,
                                   start, variables)
  else:
    env.warnStatement(statement, wInvalidRightHandSide, start)

proc runStatement*(env: var Env, statement: Statement,
    prepostTable: PrepostTable, variables: var Variables): Option[VariableData] =
  ## Run one statement and assign a variable. Return the variable dot
  ## name string and value.

  # Get the variable dot name string and match the surrounding white space.
  let dotNameMatchesO = matchDotNames(statement.text, 0)
  if not isSome(dotNameMatchesO):
    env.warnStatement(statement, wMissingStatementVar, 0)
    return
  let dotNameMatches = dotNameMatchesO.get()
  let (_, dotNameStr) = dotNameMatches.get2Groups()

  # Get the equal sign and following whitespace.
  let equalSignO = matchEqualSign(statement.text, dotNameMatches.length)
  if not equalSignO.isSome:
    env.warnStatement(statement, wInvalidVariable, 0)
    return
  let equalSign = equalSignO.get()

  # Get the right hand side value.
  let valueAndLengthO = getValue(env, prepostTable, statement,
                                 dotNameMatches.length + equalSign.length,
                                 variables)
  if not valueAndLengthO.isSome:
    return

  # Check that there is not any unprocessed text following the value.
  let value = valueAndLengthO.get().value
  let length = valueAndLengthO.get().length
  var pos = dotNameMatches.length + equalSign.length + length
  if pos != statement.text.len:
    env.warnStatement(statement, wTextAfterValue, pos)
    return

  # Assign the variable if possible.
  let warningDataO = assignVariable(variables, dotNameStr, value, equalSign.getGroup())
  if isSome(warningDataO):
    let warningData = warningDataO.get()
    env.warnStatement(statement, warningData.warning, 0, warningData.p1, warningData.p2)
    return

  # Return the variable and value for testing.
  result = some(newVariableData(dotNameStr, value))

proc runCommand*(env: var Env, cmdLines: CmdLines, prepostTable: PrepostTable,
    variables: var Variables) =
  ## Run a command and fill in the variables dictionaries.

  # Clear the local variables and set the tea vars to their initial
  # state.
  resetVariables(variables)

  # Loop over the statements and run each one.
  for statement in yieldStatements(cmdLines):
    # Run the statement and assign a variable.  When there is a
    # statement error, the statement is skipped.
    discard runStatement(env, statement, prepostTable, variables)

when defined(test):
  proc newIntValueAndLengthO*(number: int | int64,
                              length: Natural): Option[ValueAndLength] =
    result = some(ValueAndLength(value: newValue(number), length: length))

  proc newFloatValueAndLengthO*(number: float64,
                                length: Natural): Option[ValueAndLength] =
    result = some(ValueAndLength(value: newValue(number), length: length))

  proc newStringValueAndLengthO*(str: string,
                                 length: Natural): Option[ValueAndLength] =
    result = some(ValueAndLength(value: newValue(str), length: length))
