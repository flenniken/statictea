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

type
  State = enum
    ## Finite state machine states for finding statements.
    start, double, single, slashdouble, slashsingle

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

proc runStatement(env: var Env, statement: string, variableMatcher: Matcher):
    Option[tuple[name: string, value:Value]] {.tpub.} =
  ## Run one statement.

  # Get the variable name. Match the surrounding white space and the
  # equal sign.
  let matchesO = getMatches(variableMatcher, statement)
  if not matchesO.isSome:
    env.warn("The statement does not start with a variable name.")
    return
  var matches = matchesO.get()
  var (nameSpace, varName) = matches.get2Groups()


  # Get the right hand side.


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
      let tup = nameValueO.get()
      result[tup.name] = tup.value
