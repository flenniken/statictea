## Handle the replacement block lines.
## @:
## @:To support replacement blocks that consists of many lines and blocks
## @:that repeat many times, we read the replacement block and compile
## @:and store it in a temp file in a format that is easy to write out
## @:multiple times.
## @:
## @:The temporary file consists of parts of lines called segments. There
## @:are segments for the variables in the line and segments for the rest
## @:of the text.
## @:
## @:Segments are a text format containing a number (type), a comma and a
## @:string.
## @:
## @:All segments end with a newline. If a template line uses cr/lf, the
## @:segment will end with cr/lf.  The segment type tells you whether to
## @:write out the ending newline or not to the result file.
## @:
## @:Segment text are bytes. The bracketed variables are ascii.
## @:
## @:A bracketed variable does not contain space around the variable.
## @:{var} not { var }.
## @:
## @:To use a left bracket in a replacement block you use two left brackets, {{,
## @:{{ results in {.

import std/options
import std/streams
import std/strformat
import std/strutils
import env
import vartypes
import parseCmdLine
import linebuffer
import matches
import messages
import variables
import tempFile
import opresult
import warnings

type
  SegmentType = enum
    ## A replacement block line is divided into segments of different
    ## types.
    ##
    ## * middle -- String segment in the middle of the line.
    ##
    ## ~~~
    ## ... segment{var} ... => 0,segment\n
    ## ~~~~
    ##
    ## * newline -- String segment with ending newline that ends a line.
    ##
    ## ~~~
    ## ... segment\n => 1,segment\n
    ## ... segment\r\n => 1,segment\r\n
    ## ~~~~
    ##
    ## * variable -- Variable segment in the middle.
    ##
    ## ~~~
    ## ... {var} ... => 2,{var}\n
    ## ~~~~
    ##
    ## * endline --  String segment that ends a line without a newline.
    ##
    ## ~~~
    ## ... segment => 3,segment\n
    ## ~~~~
    ##
    ## * endVariable -- Variable segment that ends a line without a newline.
    ## ~~~
    ## ... {var} => 4,{var}\n
    ## ~~~~
    middle,     # 0
    newline,    # 1
    variable,   # 2
    endline,    # 3
    endVariable # 4

  ReplaceLineKind* = enum
    ## Line type returned by yieldReplacementLine.
    ##
    ## * rlNoLine -- Value when not initialized.
    ## * rlReplaceLine -- A replacement block line.
    ## * rlEndblockLine -- The endblock command line.
    ## * rlNormalLine -- The last line when maxLines was exceeded.
    rlNoLine, rlReplaceLine, rlEndblockLine, rlNormalLine

  ReplaceLine* = object
    ## Line information returned by yieldReplacementLine.
    kind*: ReplaceLineKind
    line*: string

  StringOr* = OpResultWarn[string]
    ## A string or a warning.

  TempSegments = object
    ## A temporary file to store the parsed replacement block.
    tempStream: TempFileStream
    lb: LineBuffer

func newStringOr*(warning: MessageId, p1: string = "", pos = 0):
     StringOr =
  ## Return a new StringOr object containing a warning.
  let warningData = newWarningData(warning, p1, pos)
  result = opMessageW[string](warningData)

func newStringOr*(warningData: WarningData): StringOr =
  ## Return a new StringOr object containing a warning.
  result = opMessageW[string](warningData)

func newStringOr*(str: string): StringOr =
  ## Return a new StringOr object containing a string.
  result = opValueW[string](str)

func newReplaceLine*(kind: ReplaceLineKind, line: string): ReplaceLine =
  ## Return a new ReplaceLine object.
  return ReplaceLine(kind: kind, line: line)

func `$`*(replaceLine: ReplaceLine): string =
  ## Return a string representation of a ReplaceLine object.
  result = $replaceLine.kind & ": \"" & replaceLine.line & "\""

const
  replacementBufferSize = 2*1024
    ## Space reserved for the replacement block line buffer.
  maxLineLen = defaultMaxLineLen + 20
    ## The max segment line length. Add 20 for the segment prefix.

proc seekToStart(tempSegments: var TempSegments) =
  ## Seek to the start of the TempSegments file so you can read the
  ## same segments again with readNextSegment.
  tempSegments.lb.reset()

proc readNextSegment(env: var Env, tempSegments: var TempSegments): string =
  ## Read the next segment from TempSegments. Return "" when there are
  ## no more segments.
  result = tempSegments.lb.readline()

proc stringSegment*(fragment: string, atEnd: bool): string =
  ## Return a string segment made from the fragment. AtEnd is true
  ## when the fragment ends the line.
  let length = fragment.len
  if length == 0:
    if atEnd:
      return "3,\n"
    else:
      return "0,\n"

  var ending: string
  var segmentType: SegmentType
  if atEnd:
    # The segment ends the line.
    if fragment[length-1] == '\n':
      segmentType = newline # 1
      ending = ""
    else:
      segmentType = endline # 3
      ending = "\n"
  else:
    segmentType = middle # 0
    ending = "\n"

  result = "$1,$2$3" % [$ord(segmentType), fragment, ending]

proc varSegment*(dotName: string, atEnd: bool): string =
  ## Return a variable segment made from the dot name. AtEnd is true
  ## when the bracketed variable ends the line.
  let segmentValue = $ord(if atEnd: endVariable else: variable)
  result.add("{segmentValue},{{{dotName}}}\n".fmt)

proc lineToSegments*(line: string): seq[string] =
  ## Convert a line to a list of segments. No warnings.

  type
    State = enum
      ## Parsing states.
      text, bracket, variable

  var pos = 0
  var state = text
  var fragment = newStringOfCap(line.len)
  var dotName = newStringOfCap(line.len)

  # Loop through the text one byte at a time and build segments.
  while true:
    case state
    of text:
      if pos >= line.len:
        if fragment.len > 0:
          result.add(stringSegment(fragment, true))
        break # done
      let ch = line[pos]
      if ch == '{':
        state = bracket
      else:
        fragment.add(ch)
      inc(pos)
    of bracket:
      if pos >= line.len:
        # No ending bracket.
        fragment.add('{')
        result.add(stringSegment(fragment, true))
        break # done
      let ch = line[pos]
      case ch
      of '{':
        # Two left brackets in a row equal one bracket.
        fragment.add('{')
        state = text
      of 'a' .. 'z', 'A' .. 'Z':
        dotName.add(ch)
        state = variable
      else:
        # Invalid variable name; names start with an ascii letter.
        fragment.add('{')
        fragment.add(ch)
        state = text
      inc(pos)
    of variable:
      if pos >= line.len:
        # No ending bracket.
        if fragment.len > 0:
          result.add(stringSegment(fragment, true))
        if dotName.len > 0:
          result.add(varSegment(dotName, true))
        break # done
      let ch = line[pos]
      case ch
      of '}':
        # We got a variable.
        if fragment.len > 0:
          result.add(stringSegment(fragment, false))
          fragment = ""
        if dotName.len > 0:
          result.add(varSegment(dotName, (pos+1 == line.len)))
          dotName = ""
        state = text
        inc(pos)
      of 'a' .. 'z', '.', 'A' .. 'Z', '0' .. '9', '_':
        dotName.add(ch)
        inc(pos)
      else:
        # Invalid variable name; names contain letters, digits or underscores.
        fragment.add('{')
        fragment.add(dotName)
        dotName = ""
        state = text

func varSegmentDotName*(segment: string): string =
  ## Given a variable segment, return its dot name.
  # 2,{s.name}\n
  result = segment[3 ..< (segment.len - 2)]

func getOutputStream(env: Env, output: string): Stream =
  ## Return the environment's stream specified by the output
  ## parameter. Output is "result", "stderr" or "stdout". Nil is
  ## returned for other output values.
  case output
  of "result":
    # The block output goes to the result file (default).
    result = env.resultStream
  of "stderr":
    # The block output goes to standard error.
    result = env.errStream
  of "stdout":
    # The block output goes to standard out.
    result = env.outStream
  else:
    # of "log", "skip":
    result = nil

proc writeTempSegments*(env: var Env, tempSegments: var TempSegments,
                        lineNum: Natural, variables: Variables) =
  ## Write the replacement block's stored segments to the result
  ## stream with the variables filled in.  The lineNum is the
  ## beginning line of the replacement block.

  # Seek to the beginning of the temp file.
  tempSegments.seekToStart()

  # Determine where to write the result.
  let output = getTeaVarStringDefault(variables, "output")
  if output == "skip":
    return
  let stream = getOutputStream(env, output)

  # Read the store segments and write them out.
  var line: string
  var rLineNum = lineNum
  while true:
    let segment = readNextSegment(env, tempSegments)
    if segment == "":
      assert line == ""
      break # No more segments.

    let segmentType = SegmentType(ord(segment[0]) - 0x30)

    # Increment the line number when the segment ends with a newline.
    if segmentType == newline:
      inc(rLineNum)

    # Get the segment string.
    var segString: string
    case segmentType
    of variable, endVariable:
      # Use the variable's value for the segment string.

      # Get the variable name.
      let dotNameStr = varSegmentDotName(segment)

      # Look up the variable's value.
      let valueOr = getVariable(variables, dotNameStr)
      if valueOr.isValue:
        # Convert the variable to a string.
        let valueStr = valueToStringRB(valueOr.value)
        segString = valueStr
      else:
        # The replacement variable doesn't exist: $1.
        env.warn(env.templateFilename, rLineNum, wMissingReplacementVar, dotNameStr)
        segString = segment[2 .. ^2]
    of newline:
      # The segment ends with a newline.
      segString = segment[2 .. ^1]
    of middle, endline:
      # The segment does not end with a newline.
      segString = segment[2 .. ^2]

    # Append the segment string to the current line.
    line.add(segString)

    # Write out completed lines.
    if segmentType == newline or segmentType == endline or segmentType == endVariable:
      if output == "log":
        env.logLine(env.templateFilename, rLineNum-1, line)
      else:
        assert(stream != nil)
        stream.write(line)
      line = ""

proc allocTempSegments*(env: var Env, lineNum: Natural): Option[TempSegments] =
  ## Create a TempSegments object. This reserves memory for a line
  ## buffer and creates a backing temp file. Call the closeDeleteTempSegments
  ## procedure when done to free the memory and to close and delete
  ## the file.

  # Create a temporary file for the replacement block segments.
  let tempStreamO = openTempFileStream()
  if not isSome(tempStreamO):
    # Unable to create a temporary file.
    env.warn(env.templateFilename, lineNum, wNoTempFile)
    return
  let tempStream = tempStreamO.get()
  let stream = tempStream.stream

  # Allocate a line buffer for reading lines.
  var lineBufferO = newLineBuffer(stream, filename = tempStream.filename,
                                  bufferSize = replacementBufferSize,
                                  maxLineLen = maxLineLen)
  if not lineBufferO.isSome():
    tempStream.closeDeleteStream()
    # Not enough memory for the line buffer.
    env.warn(env.templateFilename, lineNum, wNotEnoughMemoryForLB)
    return

  result = some(TempSegments(tempStream: tempStream, lb: lineBufferO.get()))

proc closeDeleteTempSegments*(tempSegments: TempSegments) =
  ## Close the TempSegments and delete its backing temporary file.
  tempSegments.tempStream.closeDeleteStream()

proc storeLineSegments*(env: var Env, tempSegments: TempSegments, line: string) =
  ## Divide the line into segments and write them to the TempSegments' temp file.
  let segments = lineToSegments(line)
  for segment in segments:
    tempSegments.tempStream.stream.write(segment)

iterator yieldReplacementLine*(env: var Env, firstReplaceLine: string,
    lb: var LineBuffer, prepostTable: PrepostTable, command: string,
    maxLines: Natural): ReplaceLine =
  ## Yield all the replacement block lines and one line after.

  if firstReplaceLine != "":
    if command == "nextline":
      yield(newReplaceLine(rlReplaceLine, firstReplaceLine))
    else:
      var count = 0
      var line = firstReplaceLine

      while true:
        # Look for an endblock command and stop when found.
        var linePartsOr = parseCmdLine(prepostTable, line, lb.getLineNum())
        if linePartsOr.isValue:
          if linePartsOr.value.command == "endblock":
            yield(newReplaceLine(rlEndblockLine, line))
            break # done, found endblock

        # Stop when we reach the maximum line count for a replacement block.
        if count >= maxLines:
          # Read t.maxLines replacement block lines without finding the endblock.
          warn(env, lb.getFilename(), lb.getLineNum(), wExceededMaxLine, "")
          yield(newReplaceLine(rlNormalLine, line))
          break

        yield(newReplaceLine(rlReplaceLine, line))

        # Read the next template replacement block line.
        line = lb.readline()
        if line == "":
          break # No more lines.

        count.inc

proc formatString*(variables: Variables, text: string): StringOr =
  ## Format a string by filling in the variable placeholders with
  ## @:their values. Generate a warning when the variable doesn't
  ## @:exist. No space around the bracketed variables.
  ## @:
  ## @:~~~
  ## @:let first = "Earl"
  ## @:let last = "Grey"
  ## @:"name: {first} {last}" => "name: Earl Grey"
  ## @:~~~~
  ## @:
  ## @:To enter a left bracket use two in a row.
  ## @:
  ## @:~~~
  ## @:"{{" => "{"
  ## @:~~~~
  type
    State = enum
      ## Parsing states.
      start, bracket, variable

  var pos = 0
  var state = start
  var newStr = newStringOfCap(text.len)
  var varStart: int

  # Loop through the text one byte at a time and add to the result
  # string.
  while true:
    case state
    of start:
      if pos >= text.len:
        break # done
      let ch = text[pos]
      if ch == '{':
        state = bracket
      else:
        newStr.add(ch)
      inc(pos)
    of bracket:
      if pos >= text.len:
        # No ending bracket.
        return newStringOr(wNoEndingBracket, "", pos)
      let ch = text[pos]
      case ch
      of '{':
        # Two left brackets in a row equal one bracket.
        state = start
        newStr.add('{')
      of 'a' .. 'z', 'A' .. 'Z':
        state = variable
        varStart = pos
      else:
        # Invalid variable name; names start with an ascii letter.
        return newStringOr(wInvalidVarNameStart, "", pos)
      inc(pos)
    of variable:
      if pos >= text.len:
        # No ending bracket.
        return newStringOr(wNoEndingBracket, "", pos)
      let ch = text[pos]
      case ch
      of '}':
        # Replace the placeholder with the variable's string
        # representation.
        let varName = text[varStart .. pos - 1]
        var valueOr = getVariable(variables, varName)
        if valueOr.isMessage:
          let wd = newWarningData(valueOr.message.warning,
            valueOr.message.p1, varStart)
          return newStringOr(wd)
        let str = valueToStringRB(valueOr.value)
        newStr.add(str)
        state = start
      of 'a' .. 'z', '.', 'A' .. 'Z', '0' .. '9', '_':
        discard
      else:
        # Invalid variable name; names contain letters, digits or underscores.
        return newStringOr(wInvalidVarName, "", pos)
      inc(pos)

  result = newStringOr(newStr)
