## Run a command.

import tpub
import regexes
import env
import vartypes
import options
import parseCmdLine
import readLines
import matches
import strUtils
import warnings
import parseNumber
import unicode
import variables
import runFunction

type
  State = enum
    ## Finite state machine states for finding statements.
    start, double, single, slashdouble, slashsingle

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

# todo: test slash characters in strings.

iterator yieldStatements(cmdLines: seq[string], cmdLineParts:
    seq[LineParts]): Statement {.tpub.} =
  ## Iterate through the command's statements.  Statements are
  ## separated by semicolons and are not empty or all spaces.

  # To find the semicolons that separate statements we use a finite
  # state machine.  In the start state we output a statement when a
  # semicolon is found. We transition when a quote is found, either to
  # a double quote state or single quote state. In one of the quote
  # states we transition back to the start state when another quote is
  # found of the same kind or we transition to a slash state when a
  # slash is found. The slash states transition back to their quote
  # state on the next character.

  assert cmdLines.len == cmdLineParts.len

  var text = newStringOfCap(defaultMaxLineLen)
  var lineNum: Natural
  var start: Natural
  if cmdLines.len > 0:
    lineNum = cmdLineParts[0].lineNum
    start = cmdLineParts[0].middleStart
  var state = State.start
  for ix in 0 ..< cmdLines.len:
    let line = cmdLines[ix]
    let lp = cmdLineParts[ix]
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
      if cmdLines.len > ix+1:
        lineNum = lp.lineNum + 1
        start = cmdLineParts[ix+1].middleStart

  if notEmptyOrSpaces(text):
    yield Statement(text: text, lineNum: lineNum, start: start)

proc getString*(env: var Env, prepostTable: PrepostTable,
    statement: Statement, start: Natural): Option[ValueAndLength] =
  ## Return a literal string value and the length of the match.  The
  ## start parameter is the index of the first quote in the statement
  ## and the return length includes optional trailing white space
  ## after the last quote.

  # Check that we have a statictea string.
  var matchesO = matchString(statement.text, start)
  if not matchesO.isSome:
    env.warnStatement(statement, wNotString, start)
    return

  # Get the string. The string is either in s1 or s2, s1 means single
  # quotes were used, s2 double.
  let matches = matchesO.get()
  let (s1, s2) = matches.get2Groups()
  var str = if (s1 == ""): s2 else: s1

  # Validate the utf-8 bytes.
  var pos = validateUtf8(str)
  if pos != -1:
    env.warnStatement(statement, wInvalidUtf8, start + pos + 1)
    return

  let value = Value(kind: vkString, stringv: str)
  result = some(ValueAndLength(value: value, length: matches.length))

proc getNumber*(env: var Env, prepostTable: PrepostTable,
    statement: Statement, start: Natural): Option[ValueAndLength] =
  ## Return the literal number value from the statement. We expect a
  ## number because it starts with a digit or minus sign.

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
    PrepostTable, function: FunctionPtr, statement:
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

  # Run the function.
  let funResult = function(parameters)
  if funResult.kind == frWarning:
    env.warn(statement.lineNum, funResult.warningData.warning,
             funResult.warningData.p1, funResult.warningData.p2)
    env.warnStatement(statement, wInvalidStatement, parameterStarts[funResult.parameter])
    return

  result = some(ValueAndLength(value: funResult.value, length: pos-start))

proc getVariable*(env: var Env, statement: Statement, variables:
                  Variables, nameSpace: string, varName: string,
                  start: Natural): Option[Value] =
  ## Look up the variable and return its value. Show an error when the
  ## variable doesn't exists.

  let value0 = getVariable(variables, nameSpace, varName)
  if not isSome(value0):
    env.warnStatement(statement, wVariableMissing, start, nameSpace & varName)
    return
  result = some(value0.get())

# a = len(name)
# a = len (name)
# a = concat(name, " ", asdf)
# a = concat(upper(name), " ", asdf)

# A function name looks like a variable without the namespace part and
# it is followed by a (.

proc getVarOrFunctionValue*(env: var Env, prepostTable:
           PrepostTable, statement: Statement,
           start: Natural, variables: Variables): Option[ValueAndLength] =
  ## Return the statement's right hand side value and the length
  ## matched. The right hand side must be a variable or a
  ## function. The right hand side starts at the index specified by
  ## start.

  # Get the variable or function name. Match the surrounding white space.
  let variableO = matchVariable(statement.text, start)
  assert variableO.isSome

  let variable = variableO.get()
  let (_, nameSpace, varName) = variable.get3Groups()
  if nameSpace == "":
    # We have a variable or a function.
    let parenthesesO = matchLeftParentheses(statement.text, start+variable.length)
    if parenthesesO.isSome:
      # We have a function, run it.

      var functionO = getFunction(varName)
      if not isSome(functionO):
        env.warnStatement(statement, wInvalidFunction, start, varName)
        return
      var function = functionO.get()
      let parentheses = parenthesesO.get()
      let funValueLengthO = getFunctionValue(env, prepostTable, function, statement,
                              start+variable.length+parentheses.length, variables)
      if not isSome(funValueLengthO):
        return
      let funValueLength = funValueLengthO.get()
      return some(ValueAndLength(value: funValueLength.value,
        length: variable.length+parentheses.length+funValueLength.length))

  # We have a variable, look it up and return its value.  Show a
  # warning when the variable doesn't exist.
  let valueO = getVariable(env, statement, variables, nameSpace,
                           varName, start)
  if isSome(valueO):
    result = some(ValueAndLength(value: valueO.get(), length: variable.length))

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

  assert start < statement.text.len

  let char = statement.text[start]

  if char == '\'' or char == '"':
    result = getString(env, prepostTable, statement, start)
  elif char in {'0' .. '9', '-'}:
    result = getNumber(env, prepostTable, statement, start)
  elif isLowerAscii(char) or isUpperAscii(char):
    result = getVarOrFunctionValue(env, prepostTable, statement,
                                   start, variables)
  else:
    env.warnStatement(statement, wInvalidRightHandSide, start)

  # let valueAndLength = result.get()
  # env.warnStatement(statement, wStackTrace, start+valueAndLength.length,  "leave getValue")

proc runStatement*(env: var Env, statement: Statement,
    prepostTable: PrepostTable, variables: var Variables): Option[VariableData] =
  ## Run one statement. Return the variable namespace, name and value.

  # Get the variable name. Match the surrounding white space.
  let variableO = matchVariable(statement.text, 0)
  if not variableO.isSome:
    env.warnStatement(statement, wMissingStatementVar, 0)
    return
  let variable = variableO.get()
  let (_, nameSpace, varName) = variable.get3Groups()

  # Get the equal sign and following whitespace.
  let equalSignO = matchEqualSign(statement.text, variable.length)
  if not equalSignO.isSome:
    env.warnStatement(statement, wInvalidVariable, 0)
    return
  let equalSign = equalSignO.get()

  # Get the right hand side value.
  let valueAndLengthO = getValue(env, prepostTable, statement,
                                 variable.length + equalSign.length,
                                 variables)
  if not valueAndLengthO.isSome:
    return

  # Check that there is not any unprocessed text following the value.
  let value = valueAndLengthO.get().value
  let length = valueAndLengthO.get().length
  var pos = variable.length + equalSign.length + length
  if pos != statement.text.len:
    env.warnStatement(statement, wTextAfterValue, pos)
    return

  let warningDataPosO = validateVariable(variables, nameSpace, varName, value)
  if isSome(warningDataPosO):
    let warningDataPos = warningDataPosO.get()
    var warningPos: Natural
    if warningDataPos.warningSide == wsVarName:
      warningPos = 0
    else:
      warningPos = variable.length + equalSign.length
    let warningData = warningDataPos.warningData
    env.warnStatement(statement, warningData.warning, warningPos, warningData.p1, warningData.p2)
    return

  result = some(newVariableData(nameSpace, varName, value))

proc runCommand*(env: var Env, cmdLines: seq[string], cmdLineParts:
                 seq[LineParts], prepostTable: PrepostTable,
                 variables: var Variables) =
  ## Run a command and fill in the variables dictionaries.

  # Clear the local variables and set the tea vars to their initial
  # state.
  resetVariables(variables)

  # Loop over the statements and run each one.
  for statement in yieldStatements(cmdLines, cmdLineParts):
    # Run the statement and assign the return value to the variable.
    # When there is a statement error, the statement is skipped.
    let variableDataO = runStatement(env, statement, prepostTable, variables)
    if isSome(variableDataO):
      let vd = variableDataO.get()
      assignVariable(variables, vd.nameSpace, vd.varName, vd.value)

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
