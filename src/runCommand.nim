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

proc warn(message: string) =
  echo "replace with the real warning"
  echo message

iterator yieldStatements(cmdLines: seq[string], cmdLineParts: seq[LineParts]): string {.tpub.} =
  ## Iterate through the command's statements.  Statements are
  ## separated by semicolons and are not empty or all spaces.

  # In the start state we output a statement when a semicolon is
  # found. We transition when a quote is found, either to a double
  # quote state or single quote state. In one of the quote states we
  # transition back to the start state when another quote is found of
  # the same kind or we transition to a slash state when a slash is
  # found. The slash states transition back to their quote state on
  # the next character.
  assert cmdLines.len == cmdLineParts.len

  let spaceTabMatcher = getSpaceTabMatcher()
  var statement = newStringOfCap(defaultMaxLineLen)
  var state = start
  for ix in 0 ..< cmdLines.len:
    let line = cmdLines[ix]
    let lp = cmdLineParts[ix]
    for pos in lp.middleStart ..< lp.middleStart+lp.middleLen:
      let ch = line[pos]
      if state == start:
        if ch == ';':
          if notEmptyOrSpaces(spaceTabMatcher, statement):
            yield(statement)
          statement.setLen(0)
          continue
        elif ch == '"':
          state = double
        elif ch == '\'':
          state = single
      elif state == double:
        if ch == '"':
          state = start
        elif ch == '\\':
          state = slashdouble
      elif state == single:
        if ch == '\'':
          state = start
        elif ch == '\\':
          state = slashsingle
      elif state == slashsingle:
        state = single
      elif state == slashdouble:
        state = double
      statement.add(ch)
  if notEmptyOrSpaces(spaceTabMatcher, statement):
    yield statement

proc getString(env: var Env, compiledMatchers: Compiledmatchers, statement: string, start: Natural): Option[Value] =
  echo "getString"

# todo: need templateFilename and line number to output error messages.

proc getNumber*(env: var Env, compiledMatchers: Compiledmatchers, statement: string, start: Natural): Option[Value] =
  ## Return the literal number value from the statement.

  # todo: pass this in
  let filename = "template.html"
  let lineNum = 23
  var matcher = getNumberMatcher()

  var matchesO = matcher.getMatches(statement, start)
  if not matchesO.isSome:
    env.warn(filename, lineNum, wNotNumber)
    return
  var matches = matchesO.get()
  if matches.length != statement.len - start:
    env.warn(filename, lineNum, wSkippingTextAfterNum)

  var value: Value
  let decimalPoint = matches.getGroup()
  if decimalPoint == ".":
    let floatPosO = parseFloat64(statement, start)
    if not floatPosO.isSome:
      env.warn(filename, lineNum, wNumberOverFlow)
      return
    value = Value(kind: vkFloat, floatv: floatPosO.get().number)
  else:
    let intPosO = parseInteger(statement, start)
    if not intPosO.isSome:
      env.warn(filename, lineNum, wNumberOverFlow)
      return
    value = Value(kind: vkInt, intv: intPosO.get().integer)
  result = some(value)

proc getVarOrFunctionValue(env: var Env, compiledMatchers: Compiledmatchers, statement: string, start: Natural): Option[Value] =
  echo "getVarOrFunctionValue"

proc getValue(env: var Env, compiledMatchers: Compiledmatchers, statement: string, start: Natural): Option[Value] =

  # If the value starts with a quote, it's a string.
  # quote - string
  # digit or minus sign - number
  # a-zA-Z - variable or function
  assert start < statement.len

  let char = statement[start]

  if char == '\'' or char == '"':
    result = getString(env, compiledMatchers, statement, start)
  elif char in { '0' .. '9', '-' }:
    result = getNumber(env, compiledMatchers, statement, start)
  elif isLowerAscii(char) or isUpperAscii(char):
    result = getVarOrFunctionValue(env, compiledMatchers, statement, start)
  else:
    warn("Invalid character, expected a string, number, variable or function.")
    discard

proc runStatement(env: var Env, statement: string, compiledMatchers: Compiledmatchers):
    Option[tuple[nameSpace: string, varName: string, value:Value]] {.tpub.} =
  ## Run one statement.

  # Get the variable name. Match the surrounding white space and the
  # equal sign.
  let matchesO = getMatches(compiledMatchers.variableMatcher, statement)
  if not matchesO.isSome:
    warn("The statement does not start with a variable name.")
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
