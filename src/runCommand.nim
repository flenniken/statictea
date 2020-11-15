## Run a command.

import tpub
# import strutils
# import warnings
import env
import vartypes
# import matches
import options
import parseCmdLine
import tables

type
  State = enum
    start, double, single

iterator yieldStatements(cmdLines: seq[string], cmdLineParts: seq[LineParts]): string {.tpub.} =
  ## Iterate through the command's statements.  Statements are
  ## separated by semicolons that are not quoted. Ignore blank
  ## statements.

  # In the start state we output a statement when a semicolon is
  # found. We transition when a quote is found, either to a double
  # quote state or single quote state. In one of the quote states we
  # transition back to the start state when another quote is found of
  # the same kind.

  assert cmdLines.len == cmdLineParts.len
  var statement = newStringOfCap(cmdLines.len)
  var state = start
  for ix in 0 ..< cmdLines.len:
    let line = cmdLines[ix]
    let lp = cmdLineParts[ix]
    for pos in lp.middleStart ..< lp.middleStart+lp.middleLen:
      let ch = line[pos]
      if state == start:
        if ch == ';':
          yield statement
          statement.setLen(0)
          continue
        elif ch == '"':
          state = double
        elif ch == '\'':
          state = single
      elif state == double:
        if ch == '"':
          state = start
      elif state == single:
        if ch == '\'':
          state = start
      statement.add(ch)
  if statement.len > 0:
    yield statement

proc runStatement(env: var Env, statement: string):
                 Option[tuple[name: string, value:Value]] {.tpub.} =
  echo "runStatement"

proc runCommand*(env: var Env, cmdLines: seq[string],
    cmdLineParts: seq[LineParts],
    serverVars: VarsDict, sharedVars: VarsDict): VarsDict =
  ## Run a command and return the local variables defined by it.

  # Loop over the statements and run each one.
  for statement in yieldStatements(cmdLines, cmdLineParts):
    # Run the statement.  When there is a statement error, no
    # nameValue is returned and we skip the statement.
    let nameValueO = runStatement(env, statement)
    if nameValueO.isSome():
      let tup = nameValueO.get()
      result[tup.name] = tup.value
