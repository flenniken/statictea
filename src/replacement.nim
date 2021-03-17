##[

Methods to handle the replacement block lines.

newTempSegments
yieldReplacementLine
storeLineSegments
writeTempSegments
closeDelete

]##


import regexes
import env
import vartypes
import options
import parseCmdLine
import readLines
import matches
import warnings
import variables
import streams
import variables
import tempFile
import parseNumber
import strformat
import strutils
import tpub

type
  SegmentType = enum
    ## A replacement block line is divided into segments of these types.
    middle,   # String segment in the middle of the line.
    newline,  # String segment with ending newline that ends a line.
    variable, # Variable segment in the middle.
    endline   # String segment that ends a line without a newline.
    endVariable # Variable segment that ends a line without a newline.

#[

The replacement block may consist of many lines and the block may
repeat many times.

If the block only repeats once, you can make one pass through the file
reading the lines and making variable replacements as you go.

To support multiple repeating blocks you could read all the lines into
memory but that requires too much memory for big blocks with long
lines.

You could make multiple passes over the block, once for each repeat by
seeking back in the template. However, that doesn't work for the stdin
stream.

What we do is read the lines from the template, compile them and store
them in a temp file in a format that is easy to write out.

The temp file consists of parts of lines called segments. There are
segments for strings and segments for variables.

Segment types:

* 0 string segment without ending newline
* 1 string segment with ending newline
* 2 variable segment
* 3 string segment that ends a line without a newline
* 4 variable segment that ends a line without a newline

For the example replacement block:

This is a test { s.name } line\n
Second line {h.tea}  \r\n
third {variable} test\n
forth line

It gets saved to the temp file as shown below. The underscores show
ending spaces. Each line ends with a newline that's not shown.

0,This is a test_
2,2   ,2,4  ,{ s.name }
1, line
0,Second line_
2,1   ,2,3  ,{h.tea}
1,  \r
0,third_
2,1   ,0,8  ,{variable}
1, test
3, forth line

A string segment starts with segment type number, followed by a comma then the line
text. For 0 segments you write to the result file the text starting at
index 2 to the end minus 1 so the newline isn't written.  For 1
segments you write from index 2 to the end. This preserves line
ending, both cr lf and lf.

The variable segments start with some numbers telling where the
variable namespace and name are in the segment. The variable segment
numbers are left aligned and padded with spaces so the text part
always starts at index 13.

Variable Segments:

* first number is 2

* second number is the index where the namespace starts. There are
  four digits reserved for it to account for the maximum line length
  of about 1k. A variable can have a lot of padding. {      var      }.

* The third number is the length of the namespace, either 2 or 0.
  It's 0 when there is no namespace.

* The fourth number is the length of the variable name. There are 3
  digits reserved for it since a variable's maximum length is 256
  ascii characters.

]#

const
  replacementBufferSize = 2*1024 # Space reserved for the replacement block line buffer.
  maxLineLen = defaultMaxLineLen + 20 # 20 more than a template line for the segment prefix info.

type
  TempSegments = object
    ## A temporary file to store the parsed replacement block.
    tempFile: TempFile
    lb: LineBuffer

  TempFileStream = object
    tempFile*: TempFile
    stream*: Stream

proc getTempFileStream(): Option[TempFileStream] {.tpub.} =
  ## Get a temporary file and an associated stream.

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

proc stringSegment(line: string, start: Natural, finish: Natural): string {.tpub.} =
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

proc varSegment(bracketedVar: string, namespacePos: Natural,
                 namespaceLen: Natural, varNameLen: Natural, atEnd: bool): string {.tpub.} =
  ## Return a variable segment. The bracketedVar is a string starting
  ## with { and ending with } that has a variable inside with optional
  ## whitespace around the variable, i.e. "{ s.name }". The atEnd
  ## parameter is true when the bracketedVar ends the line without an
  ## ending newline.
  assert namespacePos <= 9999
  assert namespaceLen == 2 or namespaceLen == 0
  assert varNameLen <= 256
  assert bracketedVar.len > 2
  assert bracketedVar[0] == '{'
  assert bracketedVar[^1] == '}'
  # 2,namespacePos
  # | |    namespaceLen
  # | |    | varNameLen
  # | |    | |   bracketedVar
  # | |    | |   |
  # 2,2   ,2,4  ,{ s.name }
  var segmentValue: string
  if atEnd:
    segmentValue = $ord(endVariable)
  else:
    segmentValue = $ord(variable)
  result.add("{segmentValue},{namespacePos:<4},{namespaceLen},{varNameLen:<3},{bracketedVar}\n".fmt)

proc lineToSegments(compiledMatchers: CompiledMatchers, line: string): seq[string] {.tpub.} =
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
    let beforeVarO = getMatches(compiledMatchers.leftBracketMatcher,
                                line, pos)
    if not beforeVarO.isSome:
      # No variable, output the rest of the line as is.
      result.add(stringSegment(line, pos, line.len))
      break
    let beforeVar = beforeVarO.get()

    # Match the variable. It matches leading and trailing whitespace.
    let variableO = getMatches(compiledMatchers.variableMatcher,
                                line, pos + beforeVar.length)
    if not variableO.isSome:
      # Found left bracket but no variable, output what we have.
      nextPos = pos + beforeVar.length
      result.add(stringSegment(line, pos, nextPos))
      pos = nextPos
      continue
    let variable = variableO.get()

    # Check that the variable ends with a right bracket.
    nextPos = pos + beforeVar.length + variable.length
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
    let (whitespace, nameSpace, varName) = variable.get3Groups()
    nextPos = start + variable.length + 2
    let bracketedVar = line[start ..< nextPos]
    let namespacePos = whitespace.len + 1
    let atEnd = (nextPos >= line.len)
    let varSeg = varSegment(bracketedVar, namespacePos, nameSpace.len, varName.len, atEnd)
    result.add(varSeg)
    pos = nextPos

func parseVarSegment(segment: string): tuple[namespace: string, name: string] {.tpub.} =
  ## Parse a variable type segment and return the variable's namespace
  ## and name.

  # Example variable segments:
  # 2,1024,2,256,{ s.name }
  # 2,2   ,2,4  ,{ s.name }
  # 0123456789 123456789 0123456789

  let namespacePos = parseInteger(segment, 2).get().integer + 13
  let namespaceLen = if segment[7] == '2': 2 else: 0
  let namePos = namespacePos + namespaceLen
  let nameLen = parseInteger(segment, 9).get().integer

  let namespace = segment[namespacePos ..< namePos]
  let name = segment[namePos ..< namePos + nameLen]
  result = (namespace, name)

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
    let (namespace, varName) = parseVarSegment(segment)

    # Look up the variable's value.
    let valueO = getVariable(variables, namespace, varName)
    if isSome(valueO):
      # Write the variables value.
      result = (segmentType, $valueO.get())
    else:
      # The variable is missing. Write the original variable name
      # text with spacing and brackets.
      env.warn(lineNum, wMissingReplacementVar, namespace, varName)
      result = (segmentType, segment[13 .. ^2])
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

proc allocTempSegments(env: var Env, lineNum: Natural): Option[TempSegments] {.tpub.} =
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
                        compiledMatchers: Compiledmatchers, line: string) =
  ## Divide the line into segments and write them to the TempSegments' temp file.
  let segments = lineToSegments(compiledMatchers, line)
  for segment in segments:
    tempSegments.tempFile.file.write(segment)

iterator yieldReplacementLine*(env: var Env, variables: Variables, command: string, lb: var
    LineBuffer, compiledMatchers: Compiledmatchers): string =
  ## Yield all the replacement block lines and the endblock line
  ## too. When no endblock line return "" as the last line.

  var maxLines = getTeaVarIntDefault(variables, "maxLines")

  var count = 0

  while true:
    # For the nextline command, read and process one line.
    if command == "nextline" and count >= 1:
      yield("")
      break

    # Stop when we reach the maximum line count for a replacement block.
    if count >= maxLines:
      env.warn(lb.lineNum, wExceededMaxLine)
      yield("")
      break

    # Read the next template replacement block line.
    let line = lb.readline()
    if line == "":
      yield("")
      break # No more lines.

    # Look for an endblock command and stop when found.
    var linePartsO = parseCmdLine(env, compiledMatchers, line, lb.lineNum)
    if linePartsO.isSome:
      if linePartsO.get().command == "endblock":
        yield(line)
        break # done, found endblock

    yield(line)
    count.inc

proc newTempSegments*(env: var Env, lb: var LineBuffer, compiledMatchers: CompiledMatchers,
    command: string, repeat: Natural, variables: Variables): Option[TempSegments] =
  ## Read replacement block lines and return a TempSegments object
  ## containing the compiled block. Call writeTempSegments to write
  ## out the segments. Call closeDelete to close and delete the
  ## associated temp file.

  result = allocTempSegments(env, lb.lineNum)
  if not isSome(result):
    return
