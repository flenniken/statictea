## Run a command.
import tpub
import strutils
import warnings
import env
import vartypes
import matches
import options
import parseCmdLine
import tables

iterator statements(cmdLines: seq[string], cmdLineParts: seq[LineParts]): string {.tpub.} =
  ## Iterate through the command's statements.  Statements are
  ## separated by semicolons. Ignore blank statements.
  echo "iterator statements"

proc runStatement(env: var Env, statement: string):
                 Option[tuple[name: string, value:Value]] {.tpub.} =
  echo "runStatement"

proc runCommand*(env: var Env, cmdLines: seq[string],
    cmdLineParts: seq[LineParts],
    serverVars: VarsDict, sharedVars: VarsDict): VarsDict =
  ## Run a command and return the local variables defined by it.

  # Loop over the statements and run each one.
  for statement in statements(cmdLines, cmdLineParts):
    # Run the statement.  When there is a statement error, no
    # nameValue is returned and we skip the statement.
    let nameValueO = runStatement(env, statement)
    if nameValueO.isSome():
      let tup = nameValueO.get()
      result[tup.name] = tup.value
