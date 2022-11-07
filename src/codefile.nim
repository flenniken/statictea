## Run code files.

import std/options
import std/os
import std/streams
import std/strutils
import env
import messages
import opresultwarn
import linebuffer
import runCommand
import variables
import vartypes
import warnings
import utf8decoder

const
  tripleQuotes* = "\"\"\""
    ## Triple quotes for building strings.

type
  Found* = enum
    ## The line endings found.
    ## * nothing = no special ending
    ## * plus = +
    ## * triple = """
    ## * newline = \\n
    ## * plus_n = +\\n
    ## * triple_n = """\\n
    ## * crlf = \\r\\n
    ## * plus_crlf = +\\r\\n
    ## * triple_crlf = """\\r\\n
    nothing,
    plus,       # +
    triple,     # """
    newline,    # n
    plus_n,     # +n
    triple_n,   # """n
    crlf,       # rn
    plus_crlf,  # +rn
    triple_crlf # """rn

func isTriple(line: string, ch: char, ix: Natural): bool =
  if ch == '"' and line.len >= ix-2 and
      line[ix-1] == '"' and line[ix-2] == '"':
    result = true

proc matchTripleOrPlusSign*(line: string): Found =
  ## Match the optional """ or + at the end of the line. This tells
  ## whether the statement continues on the next line for code files.

  type
    Have = enum
      have_nothing, have_lf, have_cr

  var state = have_nothing
  var ix = line.len - 1
  while true:
    if ix < 0 or ix >= line.len:
      case state:
      of have_nothing:
        return nothing
      of have_lf:
        return newline
      of have_cr:
        return crlf
    var ch = line[ix]
    case state:
    of have_nothing:
      if ch == '\n':
        state = have_lf
        dec(ix)
        continue
      if ch == '+':
        return plus
      elif isTriple(line, ch, ix):
        return triple
      return nothing
    of have_lf:
      if ch == '\r':
        state = have_cr
        dec(ix)
        continue
      if ch == '+':
        return plus_n
      elif isTriple(line, ch, ix):
        return triple_n
      return newline
    of have_cr:
      if ch == '+':
        return plus_crlf
      elif isTriple(line, ch, ix):
        return triple_crlf
      return crlf

proc addText*(line: string, found: Found, text: var string) =
  ## Add the line up to the line-ending to the text string.
  var skipNum: Natural
  var addNewline = false
  case found:
  of nothing:
    skipNum = 0
  of plus:
    skipNum = 1
  of triple:
    # Include the quotes.
    skipNum = 0
    addNewline = true
  of newline:
    skipNum = 1
  of plus_n:
    skipNum = 2
  of triple_n:
    # Include the quotes and newline
    skipNum = 0
  of crlf:
    skipNum = 2
  of plus_crlf:
    skipNum = 3
  of triple_crlf:
    # Include the quotes.
    skipNum = 2
    addNewline = true

  var endPos = line.len - 1 - skipNum
  if endPos < -1:
    endPos = -1
  text.add(line[0 .. endPos])
  if addNewline:
    text.add('\n')

proc readStatement*(env: var Env, lb: var LineBuffer): Option[Statement] =
  ## Read the next statement from the file reading multiple lines if
  ## needed.

  type
    State = enum
      ## Parsing states.
      start, plusSign, multiline

  var text: string
  var state = start
  while true:
    # Read a line.
    var line = lb.readline()

    # Validate the line is UTF-8.
    let invalidPos = validateUtf8String(line)
    if invalidPos != -1:
      let statement = newStatement(line, lb.getLineNum())
      env.warnStatement(statement,
        newWarningData(wInvalidUtf8ByteSeq, $invalidPos, invalidPos), lb.getfilename)
      return

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
      env.warn(lb.getFilename, lb.getLineNum(), newWarningData(messageId))
      return

    # Match the optional """ or + at the end of the line. This tells
    # whether the statement continues on the next line.
    let found = matchTripleOrPlusSign(line)

    case state:
      of start:
        if found == plus or found == plus_n or found == plus_crlf:
          state = plusSign
        elif found == triple or found == triple_n or found == triple_crlf:
          state = multiline

          # Check for the case where there are starting and ending
          # triple quotes on the same line. This catches the mistake
          # like: a = """xyx""".
          let triplePos = line.find(tripleQuotes)
          if triplePos != -1 and triplePos+4 != line.len:
            # Triple quotes must always end the line.
            let statement = newStatement(line, lb.getLineNum())
            env.warnStatement(statement,
              newWarningData(wTripleAtEnd, "", triplePos+3), lb.getfilename)
            return

        addText(line, found, text)
        if state == start:
          break # done

      of plusSign:
        if not (found == plus or found == plus_n or found == plus_crlf):
          state = start
        addText(line, found, text)
        if state == start:
          break # done

      of multiline:
        if found == triple or found == triple_n or found == triple_crlf:
          state = start
          addText(line, found, text)
        else:
          # Add the whole line.
          addText(line, nothing, text)
        if state == start:
          break # done

  result = some(newStatement(text, lb.getLineNum()))

proc runCodeFile*(env: var Env, variables: var Variables, filename: string) =
  ## Run the code file and fill in the variables.

  if not fileExists(filename):
    # File not found: $1.
    env.warnNoFile(wFileNotFound, filename)
    return

  # Create a stream out of the file.
  var stream: Stream
  stream = newFileStream(filename)
  if stream == nil:
    # Unable to open file: $1.
    env.warnNoFile(wUnableToOpenFile, filename)
    return

  # Allocate a buffer for reading lines. Return when not enough memory.
  let lineBufferO = newLineBuffer(stream, filename = filename)
  if not lineBufferO.isSome():
    # Not enough memory for the line buffer.
    env.warnNoFile(wNotEnoughMemoryForLB)
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
      env.warnStatement(statement, variableDataOr.message, sourceFilename = filename)
      continue
    let variableData = variableDataOr.value

    # echo "variableData = $1" % $variableData

    # Handle a return function exit.
    if variableData.operator == "exit":
      if not (variableData.value.kind == vkString and
              variableData.value.stringv == "stop"):
        # Use '...return(\"stop\")...' in a code file.
        env.warnStatement(statement, newWarningData(wUseStop),
          sourceFilename = filename)
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
  for filename in codeList:
    runCodeFile(env, variables, filename)
    resetVariables(variables)
