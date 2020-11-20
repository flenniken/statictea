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

type
  State = enum
    ## Finite state machine states for finding statements.
    start, double, single, slashdouble, slashsingle

proc warn(message: string) =
 echo "replace with the real warning"

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

proc getString(env: var Env, statement: string, start: Natural): Option[Value] =
  echo "getString"

proc getNumber(env: var Env, statement: string, start: Natural): Option[Value] =
  # n = 2345
  # n = 23.45
  # n = -2345
  # n = -23.45
  #     ^
  # n = 23.45abc
  # n = 23.45 abc
  # n = -23.450000000000000...000001
  # too big
  # too small

  if intType:
    try:
      parseInt(statement, number, start)
    except ValueError:
      warn("Integer out of range."
  else:
    int length = parseBiggestFloat(statement, number, start)
    if length == 0:
      warn("Invalid float number."
      
  echo "getNumber"



proc getVarOrFunctionValue(env: var Env, statement: string, start: Natural): Option[Value] =
  echo "getVarOrFunctionValue"

proc getValue(env: var Env, statement: string, start: Natural): Option[Value] =

  # If the value starts with a quote, it's a string.
  # quote - string
  # digit, period or minus sign - number
  # a-zA-Z - variable or function
  assert start < statement.len

  let char = statement[start]

  if char == '\'' or char == '"':
    result = getString(env, statement, start)
  elif isDigit(char) or char == '-' or char == '.':
    result = getNumber(env, statement, start)
  elif isLowerAscii(char) or isUpperAscii(char):
    result = getVarOrFunctionValue(env, statement, start)
  else:
    # warn("Invalid character, expected a string, number, variable or function.")
    discard

proc runStatement(env: var Env, statement: string, variableMatcher: Matcher):
    Option[tuple[nameSpace: string, varName: string, value:Value]] {.tpub.} =
  ## Run one statement.

  # Get the variable name. Match the surrounding white space and the
  # equal sign.
  let matchesO = getMatches(variableMatcher, statement)
  if not matchesO.isSome:
    env.warn("The statement does not start with a variable name.")
    return
  let matches = matchesO.get()
  let (nameSpace, varName) = matches.get2Groups()

  # Get the right hand side value.
  let valueO = getValue(env, statement, matches.length)
  if not matchesO.isSome:
    return
  result = some((nameSpace, varName, valueO.get()))

proc assignSystemVar(env: var Env, nameSpace: string, value: Value) =
  echo "assignSystemVar"

# todo: pass in the system vars.
proc runCommand*(env: var Env, cmdLines: seq[string],
    cmdLineParts: seq[LineParts],
    serverVars: VarsDict, sharedVars: VarsDict,
    variableMatcher: Matcher): VarsDict =
  ## Run a command and return the local variables defined by it.

  # Loop over the statements and run each one.
  for statement in yieldStatements(cmdLines, cmdLineParts):
    # Run the statement.  When there is a statement error, no
    # nameValue is returned and we skip the statement.
    let nameValueO = runStatement(env, statement, variableMatcher)
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
