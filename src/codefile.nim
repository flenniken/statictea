## Run code file.

import std/options
import std/os
import std/streams
import env
import messages
import opresultwarn
import readLines
import runCommand
import variables
import vartypes
import warnings

proc matchTripleOrPlusSign*(line: string): (string, string) =
  ## Match the optional """ or + at the end of the line. This tells
  ## whether the statement continues on the next line for code files.
  ## A match has two groups. The first group contains triple quotes,
  ## plus sign or nothing.  The second group contains cr, crlf or
  ## nothing.

  # line endings to match:
  # +
  # """
  # n
  # +n
  # """n
  # rn
  # +rn
  # """rn

  var two = ""
  var ix = line.len - 1
  while true:
    if ix < 0:
      return ("", two)
    if line[ix] == '+':
      return ("+", two)
    if line[ix] == '"':
      if line.len >= ix-2 and line[ix-1] == '"' and line[ix-2] == '"':
        return ("\"\"\"", two)
      else:
        return ("", two)
    if two == "":
      if line[ix] != '\n':
        return ("", two)
      two = "\n"
    else: # two == "\n"
      if line[ix] != '\r':
        return ("", two)
      two = "\r\n"
    dec(ix)

proc readStatement*(env: var Env, lb: var LineBuffer): Option[Statement] =
  ## Read the next statement from the file.

  type
    State = enum
      ## Parsing states.
      start, plusSign, multiline

  var text: string
  var state = start
  while true:
    # Read a line.
    var line = lb.readline()

    if line == "":
      var messageId: MessageId
      case state
        of start:
          return # done
        of plusSign:
          # Out of lines looking for the plus sign line.
          messageId = wNoPlusSignLine
        of multiline:
          # Out of lines looking for the multiline string.
          messageId = wIncompleteMultiline
      env.warn(lb.getLineNum(), newWarningData(messageId))
      return

    # Match the optional """ or + at the end of the line. This tells
    # whether the statement continues on the next line.
    let (one, ending) = matchTripleOrPlusSign(line)
    # todo: simplify this. bools for plusSign and tripleQuotes?

    let plusSign = if one == "+": one else: ""
    let tripleQuotes = if one == "\"\"\"": one else: ""

    let endingPos = line.len - ending.len
    let plusPos = line.len - ending.len - plusSign.len
    let triplePos = line.len - ending.len - tripleQuotes.len

    case state:
      of start:
        if plusSign.len > 0:
          state = State.plusSign

          # Use the line up to the plus sign.
          text.add(line[0 .. (plusPos-1)])

        elif tripleQuotes.len > 0:
          state = multiline
          # Use the line from the start up to and including the
          # quotes.
          text.add(line[0 .. (triplePos+2)])
        else:
          # Use the line up to the line ending.
          text.add(line[0 .. (endingPos-1)])
          break # done

      of State.plusSign:
        if plusSign.len > 0:
          # Use the line up to the plus sign.
          let plusPos = line.len - ending.len - plusSign.len
          text.add(line[0 .. (plusPos-1)])
        elif tripleQuotes.len > 0:
          state = multiline
          # Use the line from the start up to and including the
          # quotes.
          text.add(line[0 .. (triplePos+2)])
        else:
          # Use the line up to the line ending.
          text.add(line[0 .. (endingPos - 1)])
          break # done

      of multiline:
        if tripleQuotes.len > 0:
          state = start
          # Add the line from the start up to and including the
          # quotes.
          text.add(line[0 .. (triplePos+2)])
          break # done
        else:
          # Use the whole line including the line ending.
          text.add(line)

  result = some(newStatement(text, lb.getLineNum()))

# todo: add a stream version of runCodeFile.

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
    let statementO = readStatement(env, lb)
    if not statementO.isSome:
      break # done
    let statement = statementO.get()

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
      variableData.dotNameStr, variableData.value,
      variableData.operator, inCodeFile = true)
    if isSome(warningDataO):
      env.warnStatement(statement, warningDataO.get(), filename)

  # Close the stream and file.
  stream.close()

proc runCodeFiles*(env: var Env, variables: var Variables, codeList: seq[string]) =
  ## Run each code file and populate the variables.
  discard
