## Run code file.

import std/options
import std/os
import std/streams
import std/strutils
import env
import messages
import opresultwarn
import readLines
import runCommand
import variables
import vartypes
import warnings

# process the file line by line
# + newline and """ \w newline continue the statement

proc runCodeFile*(env: var Env, filename: string, variables: var Variables) =
  ## Run the code file and fill in the variables.

  if not fileExists(filename):
    # File not found: $1.
    env.warn(wFileNotFound, filename)
    return

  # Create a stream out of the file.
  var stream: Stream
  stream = newFileStream(filename)
  if stream == nil:
    # Unable to open file: $1.
    env.warn(wUnableToOpenFile, filename)
    return

  # Allocate a buffer for reading lines. Return when not enough memory.
  let lineBufferO = newLineBuffer(stream, filename = filename)
  if not lineBufferO.isSome():
    # Not enough memory for the line buffer.
    env.warn(wNotEnoughMemoryForLB)
    return
  var lb = lineBufferO.get()

  # Read and process code lines.
  while true:
    # Read a line.
    var line = lb.readline()
    if line == "":
      break

    line.removeSuffix()
    let statement = newStatement(line)

    # Run the statement and get the variable, operator and value.
    let variableDataOr = runStatement(statement, variables)
    if variableDataOr.isMessage:
      env.warnStatement(statement, variableDataOr.message)
      continue
    let variableData = variableDataOr.value

    # Return function exit.
    if variableData.operator == "exit":
      if variableData.value.kind != vkString:
        # Expected 'skip', 'stop' or '' for the block command return value.
        env.warnStatement(statement, newWarningData(wSkipStopOrEmpty))
        continue
      break # done

    # A bare if without taking a return.
    if variableData.operator == "":
      continue

    # Assign the variable if possible.
    let warningDataO = assignVariable(variables,
      variableData.dotNameStr, variableData.value, variableData.operator)
    if isSome(warningDataO):
      env.warnStatement(statement, warningDataO.get(), filename)

  # Close the stream and file.
  stream.close()
