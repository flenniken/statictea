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

const
  outputValues = ["result", "stderr", "log", "skip"]

type
  State = enum
    ## Finite state machine states for finding statements.
    start, double, single, slashdouble, slashsingle

  Statement* = object
    ## A Statement object stores the statement text and the lineNum
    ## and column position starting at 1 where the statement starts on
    ## the line.
    # todo: change column to an index. Still show as 1 based.
    lineNum*: Natural
    start*: Natural
    text*: string

  ValueAndLength* = object
    ## A value and the length of the matching text in the statement.
    ## For the example statement: "var = 567 ". The value 567 starts
    ## index 6 and the matching length is 4 because it includes the
    ## trailing spaces. For example "id = row( 3 )" the value is 3 and
    ## the length is 2.
    value*: Value
    length*: Natural

func `$`*(s: Statement): string =
  ## A string representation of a Statement.
  result = "$1, $2: '$3'" % [$s.lineNum, $s.start, s.text]

func `==`*(s1: Statement, s2: Statement): bool =
  ## True true when the two statements are equal.
  if s1.lineNum == s2.lineNum and s1.start == s2.start and
      s1.text == s2.text:
    result = true

func newStatement*(text: string, lineNum: Natural = 1,
    start: Natural = 1): Statement =
  result = Statement(lineNum: lineNum, start: start, text: text)

proc startColumn*(start: Natural): string =
  ## Return a string containing the number of spaces and symbols to
  ## point at the line start value used under the statement line.
  for ix in 0..<start:
    result.add(' ')
  result.add("^")

proc warnStatement*(env: var Env, statement: Statement, warning:
                    Warning, start: Natural, p1: string = "", p2:
                                         string = "") =
  ## Warn about an invalid statement. Show and tell the statement with
  ## the problem.  Start is the position in the statement where the
  ## problem starts. If the statement is long, trim it around the
  ## problem area.

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

  env.warn(statement.lineNum, warning, p1, p2)
  env.warn("statement: $1" % fragment)
  env.warn("           $1" % startColumn(pointerPos))


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

  # todo: pass in the spaceTabMatcher?
  let spaceTabMatcher = getSpaceTabMatcher()
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
          if notEmptyOrSpaces(spaceTabMatcher, text):
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
  if notEmptyOrSpaces(spaceTabMatcher, text):
    yield Statement(text: text, lineNum: lineNum, start: start)

proc getString*(env: var Env, compiledMatchers: Compiledmatchers,
    statement: Statement, start: Natural): Option[ValueAndLength] =
  ## Return a literal string value and the length of the match.  The
  ## start parameter is the index of the first quote in the statement
  ## and the return length includes optional trailing white space
  ## after the last quote.

  # Check that we have a statictea string.
  var matchesO = compiledMatchers.stringMatcher.getMatches(statement.text, start)
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
  var matchesO = compiledMatchers.numberMatcher.getMatches(statement.text, start)
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

proc getFunctionValue(env: var Env, compiledMatchers:
                      Compiledmatchers, name: string, statement:
                        Statement, start: Natural, variables: Variables):
                          Option[ValueAndLength] =
  echo "asdf"

proc getVariable*(env: var Env, statement: Statement, variables:
                  Variables, nameSpace: string, varName: string, start: Natural): Option[Value] =
  ## Look up the variable and return its value. Show an error when the
  ## variable doesn't exists.
  case nameSpace:
    of "":
      if varName in variables.local:
        return some(variables.local[varName])
    of "s.":
      if varName in variables.server:
        return some(variables.server[varName])
    of "h.":
      if varName in variables.shared:
        return some(variables.shared[varName])
    of "g.":
      if varName in variables.global:
        return some(variables.global[varName])
    of "t.":
      if varName in variables.tea:
        return some(variables.tea[varName])
    else:
      # Invalid namespace.
      env.warnStatement(statement, wInvalidNameSpace, start, nameSpace)
      return

  # Variable does not exists.
  env.warnStatement(statement, wVariableMissing, start, nameSpace & varName)

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
  ## matched. The right hand side starts at the index specified by
  ## start.

  # Get the variable or function name. Match the surrounding white space.
  let variableO = getMatches(compiledMatchers.variableMatcher, statement.text, start)
  if not variableO.isSome:
    # Shouldn't hit this line.
    env.warnStatement(statement, wInvalidRightHandSide, start)
    return
  let variable = variableO.get()
  let (nameSpace, varName) = variable.get2Groups()
  if nameSpace == "":
    # We have a variable or a function.
    let parenthesesO = getMatches(compiledMatchers.leftParenthesesMatcher,
                                statement.text, variable.length)
    if parenthesesO.isSome:
      # We have a function, run it.
      let parentheses = parenthesesO.get()
      return getFunctionValue(env, compiledMatchers, varName, statement,
                              variable.length+parentheses.length, variables)

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

  assert start < statement.text.len

  let char = statement.text[start]

  if char == '\'' or char == '"':
    result = getString(env, compiledMatchers, statement, start)
  elif char in { '0' .. '9', '-' }:
    result = getNumber(env, compiledMatchers, statement, start)
  elif isLowerAscii(char) or isUpperAscii(char):
    result = getVarOrFunctionValue(env, compiledMatchers, statement,
                                   start, variables)
  else:
    env.warnStatement(statement, wInvalidRightHandSide, start)

proc assignTeaVariable(env: var Env, statement: Statement,
                       compiledMatchers: Compiledmatchers, variables:
                         var Variables, varName: string, value: Value,
                             start: Natural) =
  ## Assign the given tea variable with the given value.  Show
  ## warnings when it's not possible to make the assignment.

  case varName:
    of "maxLines", "maxRepeat":
      # The maxLines and maxRepeat variables must be an integer >= 0.
      if value.kind == vkInt and value.intv >= 0:
        variables.tea[varName] = value
      else:
        env.warnStatement(statement, wInvalidMaxCount, start)
    of "content":
      # Content must be a string.
      if value.kind == vkString:
        variables.tea[varName] = value
      else:
        env.warnStatement(statement, wInvalidTeaContent, start)
    of "output":
      # Output must be a string of "result", etc.
      if value.kind == vkString:
        if value.stringv in outputValues:
          variables.tea[varName] = value
          return
      env.warnStatement(statement, wInvalidOutputValue, start, $value)
    of "repeat":
      # Repeat is an integer >= 0 and <= t.maxRepeat.
      if value.kind == vkInt and value.intv >= 0 and
         value.intv <= variables.tea["maxRepeat"].intv:
        variables.tea[varName] = value
      else:
        env.warnStatement(statement, wInvalidMaxRepeat, start, $value)
    of "server", "shared", "local", "global":
      env.warnStatement(statement, wReadOnlyTeaVar, start, varName)
    else:
      env.warnStatement(statement, wInvalidTeaVar, start, varName)


proc runStatement(env: var Env, statement: Statement,
                  compiledMatchers: Compiledmatchers, variables:
                    Variables):
    Option[tuple[nameSpace: string, varName: string, value:Value]] {.tpub.} =
  ## Run one statement. Return the variable namespace, name and value.

  # Get the variable name. Match the surrounding white space.
  let variableO = getMatches(compiledMatchers.variableMatcher, statement.text)
  if not variableO.isSome:
    env.warnStatement(statement, wMissingStatementVar, 0)
    return
  let variable = variableO.get()
  let (nameSpace, varName) = variable.get2Groups()

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
  if length != statement.text.len:
    env.warnStatement(statement, wTextAfterValue, length)
    return

  result = some((nameSpace, varName, value))

proc setState*(variables: var Variables) =
  ## Clear the local dictionary and set the tea variables to their
  ## initial state.
  variables.tea["output"] = Value(kind: vkString, stringv: "result")
  variables.tea["repeat"] = Value(kind: vkInt, intv: 1)
  variables.tea["maxLines"] = Value(kind: vkInt, intv: 10)
  variables.tea["maxRepeat"] = Value(kind: vkInt, intv: 100)
  variables.tea.del("content")
  variables.local.clear()

proc runCommand*(env: var Env, cmdLines: seq[string], cmdLineParts:
                 seq[LineParts], compiledMatchers: CompiledMatchers,
                 variables: var Variables) =
  ## Run a command and fill in the variables dictionaries.

  # Clear the local variables and set the tea vars to their initial
  # state.
  setState(variables)

  # Loop over the statements and run each one.
  for statement in yieldStatements(cmdLines, cmdLineParts):
    # Run the statement.  When there is a statement error, no
    # nameValue is returned and we skip the statement.
    let nameValueO = runStatement(env, statement, compiledMatchers,
                                  variables)
    if nameValueO.isSome():
      # Assign the variable to its dictionary.
      let tup = nameValueO.get()
      let (nameSpace, varName, value) = tup
      case nameSpace:
        of "":
          variables.local[varName] = value
        of "g.":
          variables.global[varName] = value
        of "t.":
          assignTeaVariable(env, statement, compiledMatchers, variables, varName, value, 0)
        of "s.", "h.":
          env.warnStatement(statement, wReadOnlyDictionary, 0)
        else:
          env.warnStatement(statement, wInvalidNameSpace, 0, nameSpace)

when defined(test):
  proc newIntValueAndLengthO*(number: int | int64,
                              length: Natural): Option[ValueAndLength] =
    let value = Value(kind: vkInt, intv: number)
    result = some(ValueAndLength(value: value, length: length))

  proc newFloatValueAndLengthO*(number: float64,
                                length: Natural): Option[ValueAndLength] =
    let value = Value(kind: vkFloat, floatv: number)
    result = some(ValueAndLength(value: value, length: length))

  proc newStringValueAndLengthO*(str: string,
                                 length: Natural): Option[ValueAndLength] =
    let value = Value(kind: vkString, stringv: str)
    result = some(ValueAndLength(value: value, length: length))
