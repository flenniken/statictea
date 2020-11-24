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

type
  State = enum
    ## Finite state machine states for finding statements.
    start, double, single, slashdouble, slashsingle

  Statement* = object
    ## A Statement object stores the statement text and the lineNum
    ## and position where it starts in the template.
    lineNum*: Natural
    start*: Natural
    text*: string

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


proc getString(env: var Env, compiledMatchers: Compiledmatchers, statement: Statement, start: Natural): Option[Value] =
  echo "getString"

# todo: we need to calculate the line number for the statement. It may
# be split across multiple lines.


proc getNumber*(env: var Env, compiledMatchers: Compiledmatchers,
    statement: Statement, start: Natural): Option[Value] =
  ## Return the literal number value from the statement. We expect a
  ## number because it starts with a digit or minus sign.

  # todo: pass this in
  let filename = "template.html"
  let lineNum = 23

  # Check that we have a statictea number.
  var matchesO = compiledMatchers.numberMatcher.getMatches(statement.text, start)
  if not matchesO.isSome:
    env.warn(filename, lineNum, wNotNumber)
    return

  # The decimal point determines whether the number is an int or
  # float.
  var value: Value
  let matches = matchesO.get()
  let decimalPoint = matches.getGroup()
  if decimalPoint == ".":
    # Parse the float.
    let floatPosO = parseFloat64(statement.text, start)
    if not floatPosO.isSome:
      env.warn(filename, lineNum, wNumberOverFlow)
      return
    result = some(Value(kind: vkFloat, floatv: floatPosO.get().number))
  else:
    # Parse the int.
    let intPosO = parseInteger(statement.text, start)
    if not intPosO.isSome:
      env.warn(filename, lineNum, wNumberOverFlow)
      return
    result = some(Value(kind: vkInt, intv: intPosO.get().integer))

proc getVarOrFunctionValue(env: var Env, compiledMatchers: Compiledmatchers,
                           statement: Statement, start: Natural): Option[Value] =
  echo "getVarOrFunctionValue"

proc getValue(env: var Env, compiledMatchers: Compiledmatchers,
      statement: Statement, start: Natural): Option[Value] =

  # If the value starts with a quote, it's a string.
  # quote - string
  # digit or minus sign - number
  # a-zA-Z - variable or function
  assert start < statement.text.len

  let char = statement.text[start]

  if char == '\'' or char == '"':
    result = getString(env, compiledMatchers, statement, start)
  elif char in { '0' .. '9', '-' }:
    result = getNumber(env, compiledMatchers, statement, start)
  elif isLowerAscii(char) or isUpperAscii(char):
    result = getVarOrFunctionValue(env, compiledMatchers, statement, start)
  else:
    warn("Invalid character, expected a string, number, variable or function.")
    discard

proc runStatement(env: var Env, statement: Statement, compiledMatchers: Compiledmatchers):
    Option[tuple[nameSpace: string, varName: string, value:Value]] {.tpub.} =
  ## Run one statement.

  # Get the variable name. Match the surrounding white space and the
  # equal sign.
  let matchesO = getMatches(compiledMatchers.variableMatcher, statement.text)
  if not matchesO.isSome:
    env.warn(env.templateFilename, statement.lineNum, wMissingStatementVar, $statement.start)
    return
  let matches = matchesO.get()
  let (nameSpace, varName) = matches.get2Groups()

  # Get the right hand side value.
  let valueO = getValue(env, compiledMatchers, statement, matches.length)
  if not matchesO.isSome:
    return
  result = some((nameSpace, varName, valueO.get()))

proc assignSystemVar(env: var Env, nameSpace: string, value: Value) =
  echo "assignSystemVar"

# todo: pass in the system vars.
proc runCommand*(env: var Env, cmdLines: seq[string],
    cmdLineParts: seq[LineParts],
    serverVars: VarsDict, sharedVars: VarsDict,
    compiledMatchers: CompiledMatchers): VarsDict =
  ## Run a command and return the local variables defined by it.

  # Loop over the statements and run each one.
  for statement in yieldStatements(cmdLines, cmdLineParts):
    # Run the statement.  When there is a statement error, no
    # nameValue is returned and we skip the statement.
    let nameValueO = runStatement(env, statement, compiledMatchers)
    if nameValueO.isSome():
      # Assign the variable to its dictionary.
      let tup = nameValueO.get()
      let (nameSpace, varName, value) = tup
      case nameSpace:
        of "":
          result[varName] = value
        of "t.":
          assignSystemVar(env, nameSpace, value)
        of "s.", "h.":
          warn("You cannot overwrite the server or shared variables.")
        else:
          warn("Unknown variable namespace: $1." % nameSpace)

when defined(test):
  proc newIntValueO*(number: int | int64): Option[Value] =
    result = some(Value(kind: vkInt, intv: number))

  proc newFloatValueO*(number: float64): Option[Value] =
    result = some(Value(kind: vkFloat, floatv: number))
