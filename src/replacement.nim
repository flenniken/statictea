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
import sets
import parseNumber
import strformat
import strutils

#[

The replacement block may consist of many lines and it may repeat many
times.

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

The temp file consites of three types of lines called segments. One
type for strings without and an ending newline, one for strings with a
newline and one type for variables.

Segment types:

* 0 string segment without ending newline
* 1 string segment with ending newline
* 2 variable segment

For the example replacement block with three lines:

This is a test { s.name } line\n
Second line {h.tea}  \r\n
third {variable} test\n

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

A string segment starts with 0 or 1, followed by a comma then the line
text. For 0 segments you write to the result file the text starting at
index 2 to the end minus 1 so the newline isn't written.  For 1
segments you write from index 2 to the end. This preserves line
ending, both cr lf and lf.

The variable segments start with some numbers telling where the
variable namespace and name are in the segment. The variable segment
numbers are left aligned and padded with spaces so the text part
always starts at index 13.

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
  replacementBufferSize* = 2*1024 # Space reserved for the replacement block line buffer.
  maxLineLen* = defaultMaxLineLen + 20 # 20 more than a template line for the segment prefix info.

type
  TempSegments* = object
    tempFile*: TempFile
    lb*: LineBuffer
    oneWarnTable*: HashSet[string]

  TempFileStream* = object
    tempFile*: TempFile
    stream*: Stream

# todo: delete replaceLine or use it.
proc replaceLine*(env: var Env, compiledMatchers: CompiledMatchers,
                  variables: Variables, lineNum: int, line: string, stream: Stream) =
  ## Replace the variable content in the line and output to the given
  ## stream.
  var pos = 0
  var nextPos: int

  while true:
    # Get the text before the variable including the left bracket.
    let beforeVarO = getMatches(compiledMatchers.leftBracketMatcher,
                                line, pos)
    if not beforeVarO.isSome:
      # Output the rest of the line as is.
      stream.write(line[pos .. ^1])
      break
    let beforeVar = beforeVarO.get()

    # Match the variable. It matches leading and trailing whitespace.
    let variableO = getMatches(compiledMatchers.variableMatcher,
                                line, pos + beforeVar.length)
    if not variableO.isSome:
      nextPos = pos + beforeVar.length
      stream.write(line[pos ..< nextPos])
      pos = nextPos
      continue
    let variable = variableO.get()
    let (whitespace, nameSpace, varName) = variable.get3Groups()

    # Check that the variable ends with a right bracket.
    nextPos = pos + beforeVar.length + variable.length
    if nextPos == line.len or line[nextPos] != '}':
      stream.write(line[pos ..< nextPos])
      pos = nextPos
      continue

    # Look up the variable's value.
    let valueO = getVariable(variables, namespace, varName)
    if not isSome(valueO):
      env.warn(lineNum, wMissingReplacementVar, namespace, varName)
      nextPos = pos + beforeVar.length + variable.length + 1
      stream.write(line[pos ..< nextPos])
      pos = nextPos
      continue
    let value = valueO.get()

    # Write out the text before the variable and the variable's value.
    stream.write(line[pos ..< (pos + beforeVar.length - 1)])
    stream.write($value)

    pos = pos + beforeVar.length + variable.length + 1

proc getTempFileStream*(): Option[TempFileStream] =
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

proc closeDelete*(tempSegments: TempSegments) =
  ## Close the TempSegments and delete its backing temporary file.
  tempSegments.tempFile.closeDelete()

proc seekToStart*(tempSegments: var TempSegments) =
  ## Seek to the start of the TempSegments file so you can read the
  ## same segments again with readNextSegment.
  tempSegments.lb.reset()

proc readNextSegment*(env: var Env, tempSegments: var TempSegments): string =
  ## Read the next segment from TempSegments. Return "" when there are
  ## no more segments.
  result = tempSegments.lb.readline()

proc stringSegment*(line: string, start: Natural, finish: Natural): string =
  ## Return the string segment.
  if start >= line.len or start < 0 or
     finish > line.len or finish <= 0 or
     finish - start <= 0:
    result = "0,\n"
  else:
    if line[finish-1] == '\n':
      result = "1,$1" % [line[start .. finish-1]]
    else:
      result = "0,$1\n" % [line[start .. finish-1]]

proc varSegment*(bracketedVar: string, namespacePos: Natural,
                namespaceLen: Natural, varNameLen: Natural): string =
  ## Return a variable segment.
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
  result.add("2,{namespacePos:<4},{namespaceLen},{varNameLen:<3},{bracketedVar}\n".fmt)

proc lineToSegments*(compiledMatchers: CompiledMatchers, line: string): seq[string] =
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
    result.add(varSegment(bracketedVar, namespacePos, nameSpace.len, varName.len))

    pos = nextPos

proc storeLineSegments*(env: var Env, tempSegments: TempSegments,
                        compiledMatchers: Compiledmatchers, line: string) =
  ## Divide the line into segments and write them to the TempSegments' temp file.
  let segments = lineToSegments(compiledMatchers, line)
  for segment in segments:
    tempSegments.tempFile.file.write(segment)

func parseVarSegment*(segment: string): tuple[namespace: string, name: string] =
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

proc writeSegment(env: var Env, lineNum: Natural, variables:
                  Variables, oneWarnTable: var HashSet[string], segment: string, stream: Stream) =
  ## Write one segment to the given stream.

  # Write out each type of segment.
  case segment[0]:
  of '0':
    stream.write(segment[2 .. ^2])
  of '1':
    stream.write(segment[2 .. ^1])
  of '2':
    # Update variable content and write out the updated segment.

    # Get the variable name.
    let (namespace, varName) = parseVarSegment(segment)

    # Look up the variable's value.
    let valueO = getVariable(variables, namespace, varName)
    if isSome(valueO):
      # Write the variables value.
      stream.write($valueO.get())
    else:
      # The variable is missing. Write the original variable name
      # text with spacing and brackets.  Warn about the missing
      # variable but only once per variable.
      if not oneWarnTable.containsOrIncl(namespace & varName):
        env.warn(lineNum, wMissingReplacementVar, namespace, varName)
      stream.write(segment[13 .. ^2])
  else:
    discard

# todo: handle line numbers better so you know which line the missing var is on.

proc writeTempSegments*(env: var Env, tempSegments: var TempSegments,
                        lineNum: Natural, variables: Variables, stream: Stream) =
  ## This procedure writes the updated replacement block to the result
  ## stream.  It does it by writing all the stored segments and
  ## updating variable segments as it goes.

  # Seek to the beginning of the temp file.
  tempSegments.seekToStart()

  var rLineNum = lineNum
  while true:
    let segment = readNextSegment(env, tempSegments)
    if segment == "":
       break # No more segments.
    if segment[0] == '1':
      inc(rLineNum)
    writeSegment(env, rLineNum, variables, tempSegments.oneWarnTable, segment, stream)

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

proc fillTempSegments*(env: var Env, tempSegments: TempSegments, lb: var LineBuffer,
                              compiledMatchers: CompiledMatchers,
                              command: string, repeat: Natural,
                              variables: Variables) =
  ## Read the replacement block lines from the template and store
  ## their segments in TempSegments.

  # For the nextline command, process the next line and return.
  if command == "nextline":
    let line = lb.readline()
    storeLineSegments(env, tempSegments, compiledMatchers, line)
    return

  let maxLines = getTeaVarInt(variables, "maxLines")
  var count = 0

  while true:
    # Stop is we reach the maximum line count for a replacement block.
    if count >= maxLines:
      env.warn(lb.lineNum, wExceededMaxLine)
      break

    # Read the next template replacement block line.
    let line = lb.readline()
    if line == "":
      break # No more lines.

    # Look for an endblock command and stop when found.
    var linePartsO = parseCmdLine(env, compiledMatchers, line, lb.lineNum)
    if linePartsO.isSome:
      if linePartsO.get().command == "endblock":
        break # done, found endblock

    # Store the line segments.
    storeLineSegments(env, tempSegments, compiledMatchers, line)
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
  fillTempSegments(env, result.get(), lb, compiledMatchers, command,
                   repeat, variables)

when defined(test):
  proc echoSegments*(tempSegments: TempSegments) =
    tempSegments.lb.stream.echoStream()
