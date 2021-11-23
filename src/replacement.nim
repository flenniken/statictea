## Handle the replacement block lines.

# The replacement block may consist of many lines and the block may
# repeat many times.
#
# If the block only repeats once, you can make one pass through the file
# reading the lines and making variable replacements as you go.
#
# To support multiple repeating blocks you could read all the lines into
# memory but that requires too much memory for big blocks with long
# lines.
#
# You could make multiple passes over the block, once for each repeat by
# seeking back in the template. However, that doesn't work for the stdin
# stream.
#
# What we do is read the lines from the template, compile them and store
# them in a temp file in a format that is easy to write out.
#
# The temp file consists of parts of lines called segments. There are
# segments for strings and segments for variables.
#
# Segment types:
#
# * 0 string segment without ending newline
# * 1 string segment with ending newline
# * 2 variable segment
# * 3 string segment that ends a line without a newline
# * 4 variable segment that ends a line without a newline
#
# For the example replacement block:
#
# Test segments
# {s.tea}
# This is a test { s.name } line\n
# Second line {h.tea}  \r\n
# third {variable} test\n
#
# It gets saved to the temp file as shown below. The underscores show
# ending spaces. Each line ends with a newline that's not shown.
#
# 1,Test segments
# 3,1   ,5   ,{s.tea}
# 0,This is a test_
# 2,2   ,6   ,{ s.name }
# 1, line
# 0,Second line_
# 2,1   ,5   ,{h.tea}
# 1,  \r
# 0,third_
# 2,1   ,8   ,{variable}
# 1, test
#
# A string segment starts with the segment type number 0 or 1. A type
# 1 segment means the template text ends with a new line and a type 0
# segment means the template text does not end with a new line.  After
# the type digit is a comma followed the string from the line followed
# by a newline.
#
# All segments end with a newline, whether it exists in the template
# or not. If a template line uses cr/lf, the segment will end with
# cr/lf. The segment number tells you whether to write out the ending
# newline or not to the result file. The template line endings are
# preserved in the result.
#
# Segment text is utf8. The bracketed variables are ascii but the
# strings are utf8 encoded.
#
# A variable segment, type 2 and 3 are similar to the string segments
# that type 2 does not end with a new line and 3 does.  The variable
# segment contains the bracketed variable as it exists in the
# replacement block with the brackets and leading and trailing white
# if any, i.e., "{ t.row }".  The segment starts with two numbers
# telling where the variable dotNameStr starts and its length. The variable
# segment numbers are left aligned and padded with spaces so the
# bracketed text part always starts at the same index.
#
# Variable Segments:
#
# * first number is 2 or 3.
#
# * second number is the index where the variable starts. There are
#   four digits reserved for it to account for the maximum line length
#   of about 1k. A variable can have a lot of padding. {      var      }.
#
# * The third number is the length of the variable dotNameStr. There are 4
#   digits reserved for it since a variable's maximum length is about 1k.

import std/options
import std/streams
import std/strformat
import std/strutils
import regexes
import env
import vartypes
import parseCmdLine
import readLines
import matches
import messages
import variables
import tempFile
import parseNumber
import tostring

type
  SegmentType = enum
    ## A replacement block line is divided into segments of these types.
    middle,   ## String segment in the middle of the line.
    newline,  ## String segment with ending newline that ends a line.
    variable, ## Variable segment in the middle.
    endline,  ## String segment that ends a line without a newline.
    endVariable ## Variable segment that ends a line without a newline.

  ReplaceLineKind* = enum
    ## Line type returned by yieldReplacementLine.
    rlReplaceLine, ## A replacement block line.
    rlEndblockLine ## The endblock line.

  ReplaceLine* = object
    ## Line information returned by yieldReplacementLine.
    kind*: ReplaceLineKind
    line*: string

func newReplaceLine*(kind: ReplaceLineKind, line: string): ReplaceLine =
  ## Return a ReplaceLine object.
  return ReplaceLine(kind: kind, line: line)

func `$`*(replaceLine: ReplaceLine): string =
  ## Return a string representation of a ReplaceLine.
  result = $replaceLine.kind & ": \"" & replaceLine.line & "\""

const
  replacementBufferSize = 2*1024
    ## Space reserved for the replacement block line buffer.
  maxLineLen = defaultMaxLineLen + 20
    ## 20 more than a template line for the segment prefix info.

type
  TempSegments = object
    ## A temporary file to store the parsed replacement block.
    tempFile: TempFile
    lb: LineBuffer

  TempFileStream = object
    ## Temporary file and associated stream.
    tempFile*: TempFile
    stream*: Stream

proc getTempFileStream*(): Option[TempFileStream] =
  ## Create a stream from a temporary file and return both.

  # Get a temp file.
  let tempFileO = openTempFile()
  if not isSome(tempFileO):
    return
  let tempFile = tempFileO.get()

  # Create a stream from the temp file.
  var stream = newFileStream(tempFile.file)
  if stream == nil:
    tempFile.closeDelete()
    return
  result = some(TempFileStream(tempFile: tempFile, stream: stream))

proc seekToStart(tempSegments: var TempSegments) =
  ## Seek to the start of the TempSegments file so you can read the
  ## same segments again with readNextSegment.
  tempSegments.lb.reset()

proc readNextSegment(env: var Env, tempSegments: var TempSegments): string =
  ## Read the next segment from TempSegments. Return "" when there are
  ## no more segments.
  result = tempSegments.lb.readline()

proc stringSegment*(line: string, start: Natural, finish: Natural): string =
  ## Return the string segment. The line contains the segment starting at
  ## the given position and ending at finish position in the line (1
  ## after). If the start and finish are at the end, output a endline segment.

  let length = finish - start

  assert length > 0
  assert start + length <= line.len

  var ending = "\n"
  var segmentType: SegmentType

  if finish == line.len:
    # At end of line.
    if line[finish-1] == '\n':
      segmentType = newline
      ending = ""
    else:
      segmentType = endline
  else:
    segmentType = middle

  result = "$1,$2$3" % [$ord(segmentType), line[start ..< finish], ending]

# todo: don't allow spaces around the dotNameStr inside the brackets?

proc varSegment*(bracketedVar: string, dotNameStrPos: Natural,
                 dotNameStrLen: Natural, atEnd: bool): string =
  ## Return a variable segment. The bracketedVar is a string starting
  ## with { and ending with } that has a variable inside with optional
  ## whitespace around the variable, i.e. "{ s.name }". The atEnd
  ## parameter is true when the bracketedVar ends the line without an
  ## ending newline.
  assert dotNameStrPos <= 9999
  assert dotNameStrLen <= 9999
  assert bracketedVar.len > 2
  assert bracketedVar[0] == '{'
  assert bracketedVar[^1] == '}'
  # 2,dotNameStrPos
  # | |    dotNameStrLen
  # | |    |    bracketedVar
  # | |    |    |
  # 2,2   ,6   ,{ s.name }
  var segmentValue: string
  if atEnd:
    segmentValue = $ord(endVariable)
  else:
    segmentValue = $ord(variable)
  result.add("{segmentValue},{dotNameStrPos:<4},{dotNameStrLen:<4},{bracketedVar}\n".fmt)

proc lineToSegments*(prepostTable: PrepostTable, line: string): seq[string] =
  ## Convert a line to a list of segments.

  var pos = 0
  var nextPos: int

  # This is a test { s.name } line\n
  # 0,This is a test_
  # 2,2   ,2,4  ,{ s.name }
  # 1, line

  while true:
    if pos >= line.len:
      break
    # Get the text before the variable including the left bracket.
    let beforeVarO = matchLeftBracket(line, pos)
    if not beforeVarO.isSome:
      # No variable, output the rest of the line as is.
      result.add(stringSegment(line, pos, line.len))
      break
    let beforeVar = beforeVarO.get()

    # Match the variable. It matches leading and trailing whitespace.
    let matches0 = matchDotNames(line, pos + beforeVar.length)
    if not matches0.isSome:
      # Found left bracket but no variable, output what we have.
      nextPos = pos + beforeVar.length
      result.add(stringSegment(line, pos, nextPos))
      pos = nextPos
      continue
    let matches = matches0.get()
    let (whitespace, dotNameStr) = matches.get2Groups()

    # Check that the variable ends with a right bracket.
    nextPos = pos + beforeVar.length + matches.length
    if nextPos >= line.len or line[nextPos] != '}':
      # No closing bracket, so not it's not a variable, output what we
      # have.
      result.add(stringSegment(line, pos, nextPos))
      pos = nextPos
      continue

    # We have a variable.

    # Output the text before the variable not including the left bracket.
    let start = pos + beforeVar.length - 1
    if beforeVar.length > 1:
      result.add(stringSegment(line, pos, start))

    # Write out the variable including the left and right brackets.
    nextPos = start + matches.length + 2
    let bracketedVar = line[start ..< nextPos]
    let dotNameStrPos = whitespace.len + 1
    let atEnd = (nextPos >= line.len)
    let varSeg = varSegment(bracketedVar, dotNameStrPos, dotNameStr.len, atEnd)
    result.add(varSeg)
    pos = nextPos

func parseVarSegment*(segment: string): string =
  ## Parse a variable type segment and return the dotNameStr.

  # Example variable segments showing limits:
  # 2,1024,1024,{ s.name }
  # 2,2   ,6   ,{ s.name }
  # 0123456789 123456789 0123456789

  let dotNameStrPos = parseInteger(segment, 2).get().integer + 12
  let dotNameStrLen = parseInteger(segment, 7).get().integer
  result = segment[dotNameStrPos ..< dotNameStrPos + dotNameStrLen]

proc getSegmentString(env: var Env, lineNum: Natural, variables: Variables, segment: string):
    tuple[kind: SegmentType, str: string] =
  ## Return the segment's type and string with the variables
  ## substituted. If a variable is missing, write a warning message
  ## and return the string as is.

  # Get the segment type from the first character of the segment.
  let segmentType = SegmentType(ord(segment[0]) - 0x30)

  # Handle each type of segment.
  case segmentType:
  of middle:
    # String segment without ending newline.
    result = (middle, segment[2 .. ^2])
  of newline:
    # String segment with ending newline.
    result = (newline, segment[2 .. ^1])
  of variable, endVariable:
    # Variable segment. Subsitute the variable content, if possible.

    # Get the variable name.
    let dotNameStr = parseVarSegment(segment)

    # Look up the variable's value.
    let valueOrWarning = getVariable(variables, dotNameStr)
    if valueOrWarning.kind == vwValue:
      # Convert the variable to a string.
      let valueStr = valueToStringRB(valueOrWarning.value)
      result = (segmentType, valueStr)
    else:
      # The variable is missing. Write the original variable name
      # text with spacing and brackets.
      env.warn(lineNum, wMissingReplacementVar, dotNameStr)
      result = (segmentType, segment[12 .. ^2])
  of endline:
    # String segment ending the line without ending newline.
    result = (endline, segment[2 .. ^2])

proc writeTempSegments*(env: var Env, tempSegments: var TempSegments,
                        lineNum: Natural, variables: Variables) =
  ## Write the updated replacement block to the result stream.  It
  ## does it by writing all the stored segments and updating variable
  ## segments as it goes. The lineNum is the beginning line of the
  ## replacement block.

  # Seek to the beginning of the temp file.
  tempSegments.seekToStart()

  # Determine where to write the result.
  var log: bool
  var output = getTeaVarStringDefault(variables, "output")
  var stream: Stream
  case output
  of "result":
    # The block output goes to the result file (default).
    stream = env.resultStream
  of "stderr":
    # The block output goes to standard error.
    stream = env.errStream
  of "log":
    # The block output goes to the log file.
    log = true
  # of "skip":
  #   # The block is skipped.
  #   return
  else:
    return

  # Write the segments.
  var rLineNum = lineNum
  var line: string
  while true:
    let segment = readNextSegment(env, tempSegments)
    if segment == "":
       break # No more segments.

    # Increment the line number when the segment ends with a newline.
    assert ord(newline) == 1
    if segment[0] == '1':
      inc(rLineNum)

    let (kind, segString) = getSegmentString(env, rLineNum, variables, segment)

    line.add(segString)

    # Write out completed lines.
    if kind == newline or kind == endline or kind == endVariable:
      if log:
        env.log(line)
      else:
        stream.write(line)
      line = ""

proc allocTempSegments*(env: var Env, lineNum: Natural): Option[TempSegments] =
  ## Create a TempSegments object. This reserves memory for a line
  ## buffer and creates a backing temp file. Call the closeDelete
  ## procedure when done to free the memory and to close and delete
  ## the file.

  # Create a temporary file for the replacement block segments.
  let tempFileStreamO = getTempFileStream()
  if not isSome(tempFileStreamO):
    env.warn(lineNum, wNoTempFile)
    return
  let tempFileStream = tempFileStreamO.get()
  let tempFile = tempFileStream.tempFile
  let stream = tempFileStream.stream

  # Allocate a line buffer for reading lines.
  var lineBufferO = newLineBuffer(stream, filename = tempFile.filename,
                                  bufferSize = replacementBufferSize,
                                  maxLineLen = maxLineLen)
  if not lineBufferO.isSome():
    tempFile.closeDelete()
    env.warn(lineNum, wNotEnoughMemoryForLB)
    return

  result = some(TempSegments(tempFile: tempFile, lb: lineBufferO.get()))

proc closeDelete*(tempSegments: TempSegments) =
  ## Close the TempSegments and delete its backing temporary file.
  tempSegments.tempFile.closeDelete()

proc storeLineSegments*(env: var Env, tempSegments: TempSegments,
                        prepostTable: PrepostTable, line: string) =
  ## Divide the line into segments and write them to the TempSegments' temp file.
  let segments = lineToSegments(prepostTable, line)
  for segment in segments:
    tempSegments.tempFile.file.write(segment)

iterator yieldReplacementLine*(env: var Env, firstReplaceLine: string, lb: var
    LineBuffer, prepostTable: PrepostTable, command: string, maxLines: Natural): ReplaceLine =
  ## Yield all the replacement block lines and the endblock line too,
  ## if it exists.

  if firstReplaceLine != "":
    if command == "nextline":
      yield(newReplaceLine(rlReplaceLine, firstReplaceLine))
    else:
      var count = 0
      var line = firstReplaceLine

      while true:
        # Stop when we reach the maximum line count for a replacement block.
        if count >= maxLines:
          env.warn(lb.getLineNum(), wExceededMaxLine)
          break

        # Look for an endblock command and stop when found.
        var linePartsO = parseCmdLine(env, prepostTable, line, lb.getLineNum())
        if linePartsO.isSome:
          if linePartsO.get().command == "endblock":
            yield(newReplaceLine(rlEndblockLine, line))
            break # done, found endblock

        yield(newReplaceLine(rlReplaceLine, line))

        # Read the next template replacement block line.
        line = lb.readline()
        if line == "":
          break # No more lines.

        count.inc

proc newTempSegments*(env: var Env, lb: var LineBuffer, prepostTable: PrepostTable,
    command: string, repeat: Natural, variables: Variables): Option[TempSegments] =
  ## Read replacement block lines and return a TempSegments object
  ## containing the compiled block. Call writeTempSegments to write
  ## out the segments. Call closeDelete to close and delete the
  ## associated temp file.

  result = allocTempSegments(env, lb.getLineNum())
  if not isSome(result):
    return
