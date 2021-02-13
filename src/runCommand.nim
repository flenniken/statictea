## Run a command.

import tpub
import regexes
import env
import vartypes
import options
import parseCmdLine
import tables
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


proc warn(message: string) =
  echo "replace with the real warning"
  echo message

iterator yieldStatements(cmdLines: seq[string], cmdLineParts:
    seq[LineParts], allSpaceTabMatcher: Matcher): Statement {.tpub.} =
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
          if notEmptyOrSpaces(allSpaceTabMatcher, text):
            yield Statement(text: text, lineNum: lineNum, start: start)
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
  if notEmptyOrSpaces(allSpaceTabMatcher, text):
    yield Statement(text: text, lineNum: lineNum, start: start)

proc getString*(env: var Env, compiledMatchers: Compiledmatchers,
    statement: Statement, start: Natural): Option[ValueAndLength] =
  ## Return a literal string value and the length of the match.  The
  ## start parameter is the index of the first quote in the statement
  ## and the return length includes optional trailing white space
  ## after the last quote.

  # Check that we have a statictea string.
  var matchesO = compiledMatchers.stringMatcher.getMatches(
    statement.text, start)
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

proc getNumber*(env: var Env, compiledMatchers: Compiledmatchers,
    statement: Statement, start: Natural): Option[ValueAndLength] =
  ## Return the literal number value from the statement. We expect a
  ## number because it starts with a digit or minus sign.

  # Check that we have a statictea number.
  var matchesO = compiledMatchers.numberMatcher.getMatches(
    statement.text, start)
  if not matchesO.isSome:
    env.warnStatement(statement, wNotNumber, start)
    return

  # The decimal point determines whether the number is an integer or
  # float.
  var value: Value
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
proc getValue(env: var Env, compiledMatchers: Compiledmatchers,
              statement: Statement, start: Natural, variables:
                Variables): Option[ValueAndLength]

proc getFunctionValue*(env: var Env, compiledMatchers:
    Compiledmatchers, function: FunctionPtr, statement:
    Statement, start: Natural, variables: Variables): Option[ValueAndLength] =
  ## Collect the function parameter values then call it. Start should
  ## be pointing at the first parameter.

  var parameters: seq[Value] = @[]
  var parameterStarts: seq[Natural] = @[]
  var pos = start

  # If we get a right parentheses, there are no parameters.
  let rightParenO = getMatches(compiledMatchers.rightParenthesesMatcher,
                              statement.text, pos)
  if rightParenO.isSome:
    pos = pos + rightParenO.get().length
  else:
    while true:
      # Get the parameter's value.
      let valueAndLengthO = getValue(env, compiledMatchers, statement,
                                     pos, variables)
      if not valueAndLengthO.isSome:
        return

      parameters.add(valueAndLengthO.get().value)
      parameterStarts.add(pos)

      pos = pos + valueAndLengthO.get().length

      # Get the comma or right parentheses and white space following the value.
      let commaParenO = getMatches(compiledMatchers.commaParenthesesMatcher,
                                  statement.text, pos)
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
    env.warn(statement.lineNum, funResult.warning, funResult.p1, funResult.p2)
    env.warnStatement(statement, wInvalidStatement, parameterStarts[funResult.parameter])
    return

  result = some(ValueAndLength(value: funResult.value, length: pos-start))

proc getVariable*(env: var Env, statement: Statement, variables:
                  Variables, nameSpace: string, varName: string,
                  start: Natural): Option[Value] =
  ## Look up the variable and return its value. Show an error when the
  ## variable doesn't exists.

  let dictO = getNamespaceDict(variables, namespace)
  if not isSome(dictO):
    env.warnStatement(statement, wInvalidNameSpace, start, nameSpace)
    return
  let dict = dictO.get()
  if not dict.contains(varName):
    env.warnStatement(statement, wVariableMissing, start, nameSpace & varName)
    return
  result = some(dict[varName])

# a = len(name)
# a = len (name)
# a = concat(name, " ", asdf)
# a = concat(upper(name), " ", asdf)

# A function name looks like a variable without the namespace part and
# it is followed by a (.

proc getVarOrFunctionValue*(env: var Env, compiledMatchers:
           Compiledmatchers, statement: Statement,
           start: Natural, variables: Variables): Option[ValueAndLength] =
  ## Return the statement's right hand side value and the length
  ## matched when the right hand side is a variable or a function. The
  ## right hand side starts at the index specified by start.

  # Get the variable or function name. Match the surrounding white space.
  let variableO = getMatches(compiledMatchers.variableMatcher,
                             statement.text, start)
  assert variableO.isSome

  let variable = variableO.get()
  let (whitespace, nameSpace, varName) = variable.get3Groups()
  if nameSpace == "":
    # We have a variable or a function.
    let parenthesesO = getMatches(compiledMatchers.leftParenthesesMatcher,
                                statement.text, start+variable.length)
    if parenthesesO.isSome:
      # We have a function, run it.

      var functionO = getFunction(varName)
      if not isSome(functionO):
        env.warnStatement(statement, wInvalidFunction, start, varName)
        return
      var function = functionO.get()
      let parentheses = parenthesesO.get()
      let funValueLengthO = getFunctionValue(env, compiledMatchers, function, statement,
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

proc getValue(env: var Env, compiledMatchers: Compiledmatchers,
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
    result = getString(env, compiledMatchers, statement, start)
  elif char in {'0' .. '9', '-'}:
    result = getNumber(env, compiledMatchers, statement, start)
  elif isLowerAscii(char) or isUpperAscii(char):
    result = getVarOrFunctionValue(env, compiledMatchers, statement,
                                   start, variables)
  else:
    env.warnStatement(statement, wInvalidRightHandSide, start)

  # let valueAndLength = result.get()
  # env.warnStatement(statement, wStackTrace, start+valueAndLength.length,  "leave getValue")

proc assignTeaVariable*(env: var Env, statement: Statement, variables:
                       var Variables, varName: string, value: Value,
                           varPos: Natural, valuePos: Natural) =
  ## Assign the given tea variable with the given value.  Show
  ## warnings when it's not possible to make the assignment.

  case varName:
    of "maxLines":
      # The maxLines variable must be an integer >= 0.
      if value.kind == vkInt and value.intv >= 0:
        variables[varName] = value
      else:
        env.warnStatement(statement, wInvalidMaxCount, valuePos)
    of "maxRepeat":
      # The maxRepeat variable must be an integer >= t.repeat.
      if value.kind == vkInt and value.intv >= variables["repeat"].intv:
        variables[varName] = value
      else:
        env.warnStatement(statement, wInvalidMaxRepeat, valuePos)
    of "content":
      # Content must be a string.
      if value.kind == vkString:
        variables[varName] = value
      else:
        env.warnStatement(statement, wInvalidTeaContent, valuePos)
    of "output":
      # Output must be a string of "result", etc.
      if value.kind == vkString:
        if value.stringv in outputValues:
          variables[varName] = value
          return
      env.warnStatement(statement, wInvalidOutputValue, valuePos, $value)
    of "repeat":
      # Repeat is an integer >= 0 and <= t.maxRepeat.
      if value.kind == vkInt and value.intv >= 0 and
         value.intv <= variables["maxRepeat"].intv:
        variables[varName] = value
      else:
        env.warnStatement(statement, wInvalidRepeat, valuePos, $value)
    of "server", "shared", "local", "global", "row", "version":
      env.warnStatement(statement, wReadOnlyTeaVar, varPos, varName)
    else:
      env.warnStatement(statement, wInvalidTeaVar, varPos, varName)

proc runStatement*(env: var Env, statement: Statement,
                   compiledMatchers: Compiledmatchers, variables: var Variables) =
  ## Run one statement. Return the variable namespace, name and value.

  # Get the variable name. Match the surrounding white space.
  let variableO = getMatches(compiledMatchers.variableMatcher, statement.text)
  if not variableO.isSome:
    env.warnStatement(statement, wMissingStatementVar, 0)
    return
  let variable = variableO.get()
  let (whitespace, nameSpace, varName) = variable.get3Groups()

  # Get the equal sign and following whitespace.
  let equalSignO = getMatches(compiledMatchers.equalSignMatcher,
                              statement.text, variable.length)
  if not equalSignO.isSome:
    env.warnStatement(statement, wInvalidVariable, 0)
    return
  let equalSign = equalSignO.get()

  # Get the right hand side value.
  let valueAndLengthO = getValue(env, compiledMatchers, statement,
                                 variable.length + equalSign.length,
                                 variables)
  if not valueAndLengthO.isSome:
    return

  # Check that there is not any unprocessed text following the value.
  let value = valueAndLengthO.get().value
  let length = valueAndLengthO.get().length
  let pos = variable.length + equalSign.length + length
  if pos != statement.text.len:
    env.warnStatement(statement, wTextAfterValue, pos)
    return

  # Assign the variable to its dictionary.
  case nameSpace:
    of "":
      variables["local"].dictv[varName] = value
    of "g.":
      variables["global"].dictv[varName] = value
    of "t.":
      assignTeaVariable(env, statement, variables,
        varName, value, 0, variable.length + equalSign.length)
    of "s.", "h.":
      env.warnStatement(statement, wReadOnlyDictionary, 0)
    else:
      env.warnStatement(statement, wInvalidNameSpace, 0, nameSpace)

proc runCommand*(env: var Env, cmdLines: seq[string], cmdLineParts:
                 seq[LineParts], compiledMatchers: CompiledMatchers,
                 variables: var Variables) =
  ## Run a command and fill in the variables dictionaries.

  # Clear the local variables and set the tea vars to their initial
  # state.
  resetVariables(variables)

  # Loop over the statements and run each one.
  for statement in yieldStatements(cmdLines, cmdLineParts,
      compiledMatchers.allSpaceTabMatcher):
    # Run the statement and assign the return value to the variable.
    # When there is a statement error, the statement is skipped.
    runStatement(env, statement, compiledMatchers, variables)


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
