## Shared test code.

when defined(test):
  import std/streams
  import std/os
  import std/times
  import std/options
  import std/strutils
  import messages
  import args
  import linebuffer
  import env
  import comparelines
  import parseCmdLine
  import vartypes

  proc readXLines*(lb: var LineBuffer, maxLines: Natural = high(Natural)): seq[string] =
    ## Read lines from a LineBuffer returning line endings but don't
    ## @:read more than the maximum number of lines. Reading starts at
    ## @:the current lb's current position and the position at the end
    ## @:is ready for reading the next line.
    var count = 0
    while true:
      if count >= maxLines:
        break
      var line = lb.readline()
      if line == "":
        break
      result.add(line)
      inc(count)

  proc readXLines*(stream: Stream,
    maxLineLen: int = defaultMaxLineLen,
    bufferSize: int = defaultBufferSize,
    filename: string = "",
    maxLines: Natural = high(Natural)
  ): seq[string] =
    ## Read all lines from a stream returning line endings but don't
    ## read more than the maximum number of lines.
    stream.setPosition(0)
    var lineBufferO = newLineBuffer(stream)
    if not lineBufferO.isSome:
      return
    var lb = lineBufferO.get()
    result = readXLines(lb, maxLines)

  proc readXLines*(filename: string,
    maxLineLen: int = defaultMaxLineLen,
    bufferSize: int = defaultBufferSize,
    maxLines: Natural = high(Natural)
  ): seq[string] =
    ## Read all lines from a file returning line endings but don't
    ## read more than the maximum number of lines.
    var stream = newFileStream(filename)
    if stream == nil:
      return
    result = readXLines(stream, maxLineLen, bufferSize, filename, maxLines)
    stream.close

  func bytesToString*(buffer: openArray[uint8|char]): string =
    ## Create a string from bytes in a buffer. A nim string is UTF-8
    ## incoded but it isn't validated so it is just a string of bytes.
    if buffer.len == 0:
      return ""
    result = newStringOfCap(buffer.len)
    for ix in 0 .. buffer.len-1:
      result.add((char)buffer[ix])

  proc createFile*(filename: string, content: string) =
    ## Create a file with the given content.
    var file = open(filename, fmWrite)
    file.write(content)
    file.close()

  proc gotExpected*(got: string, expected: string, message = ""): bool =
    ## Return true when the got string matches the expected string,
    ## otherwise return false and show the differences.
    if got != expected:
      if message != "":
        echo message
      echo "     got: " & got
      echo "expected: " & expected
      return false
    return true

  template gotExpectedResult*(got: string, expected: string, message = "") =
    ## Compare got with expected and show the differences if any. Set
    ## the result variable to false when there are differences, else
    ## leave result as is.
    ## @:
    ## @:Example usage:
    ## @:
    ## @:~~~
    ## @:result = gotExpected($handled, $eHandled, "handled:")
    ## @:gotExpectedResult(retLeftName, eLeftName, "left name:")
    ## @:gotExpectedResult($retOperator, $eOperator, "operator:")
    ## @:~~~~

    if got != expected:
      if message != "":
        echo message
      echo "     got: " & got
      echo "expected: " & expected
      result = false

  func splitContent*(content: string, startLine: Natural, numLines: Natural): seq[string] =
    ## Split the content string at newlines and return a range of the
    ## lines.  startLine is the index of the first line.
    let split = splitNewLines(content)
    let endLine = startLine + numLines - 1
    if startLine <= endLine and endLine < split.len:
       result.add(split[startLine .. endLine])

  func splitContentPick*(content: string, picks: openArray[int]): seq[string] =
    ## Split the content then return the picked lines by line index.
    let split = splitNewLines(content)
    for ix in picks:
      if ix >= 0 and ix < split.len:
        result.add(split[ix])

  proc echoNewline*(str: string) =
    ## Print a line to the screen and display the line endings as \n
    ## or \r\n.
    var newstr = str.replace("\r\n", r"\r\n")
    echo newstr.replace("\n", r"\n")

  proc closeReadDeleteLog*(env: var Env, maximum: Natural = high(Natural)): seq[string] =
    ## Close the log file, read its lines, then delete the
    ## file. Return the lines read but don't read more than maximum
    ## lines. Lines contain the line endings.
    if env.logFile != nil:
      env.logFile.close()
      env.logFile = nil
      result = readXLines(env.logFilename, maximum)
      discard tryRemoveFile(env.logFilename)

  # A string stream content disappears when you close it where as a
  # file's content still exists on disk. To work with both types of
  # streams you need to read the content before closing and you need
  # to set the stream position to the start to read all the content.

  proc readAndClose*(stream: Stream): seq[string] =
    ## Read and return all the lines including line endings from the
    ## stream then close it.
    result = readXLines(stream)
    stream.close()

  proc readCloseDeleteEnv*(env: var Env): tuple[
      logLines: seq[string],
      errLines: seq[string],
      outLines: seq[string],
      resultLines: seq[string],
      templateLines: seq[string]] =
    ## Read the env's streams, then close and delete them. Return the
    ## streams content.

    result.logLines = env.closeReadDeleteLog(100)
    if env.closeErrStream:
      result.errLines = env.errStream.readAndClose()
    if env.closeOutStream:
      result.outLines = env.outStream.readAndClose()
    if env.closeResultStream:
      result.resultLines = env.resultStream.readAndClose()
    if env.closeTemplateStream:
      result.templateLines = env.templateStream.readAndClose()
      discard tryRemoveFile(env.templateFilename)


  proc expectedItem*[T](name: string, item: T, expectedItem: T): bool =
    ## Compare the item with the expected item and show them when
    ## different. Return true when they are the same.

    if item == expectedItem:
      result = true
    else:
      echo "$1" % name
      echoNewline "     got: $1" % $item
      echoNewline "expected: $1" % $expectedItem
      result = false

  proc expectedItems*[T](name: string, items: seq[T], expectedItems:
                         seq[T]): bool =
    ## Compare the items with the expected items and show them when
    ## different. Return true when they are the same.

    if items == expectedItems:
      result = true
    else:
      if items.len != expectedItems.len:
        echo "~~~~~~~~~~ $1 ($2)~~~~~~~~~~~:" % [name, $items.len]
        for item in items:
          echoNewline $item
        echo "~~~~~~ expected $1 ($2)~~~~~~:" % [name, $expectedItems.len]
        for item in expectedItems:
          echoNewline $item
      else:
        echo "~~~~~~~~~~ $1 ~~~~~~~~~~~:" % name
        for ix in 0 ..< items.len:
          if items[ix] == expectedItems[ix]:
            echoNewline "$1 (same):      got: $2" % [$ix, $items[ix]]
            echoNewline "$1 (same): expected: $2" % [$ix, $expectedItems[ix]]
          else:
            echoNewline "$1       :      got: $2" % [$ix, $items[ix]]
            echoNewline "$1       : expected: $2" % [$ix, $expectedItems[ix]]
      result = false

  proc compareLogLine*(logLine: string, eLogLine: string): Option[tuple[ix: int, eix: int]] =
    ## Compare the two log lines, skipping variable parts. If they
    ## differ, return the position in each line where they differ. If
    ## the expected line has a X in it, that character is skipped. If
    ## it has a *, zero or more characters are skipped.  This simple
    ## regex is used instead of full regex so you don't have to escape
    ## all the special regex characters.

    #      got: 2020-10-01 08:21:28.618; statictea.nim(2652); version: 0.1.0"
    #                                                            ^
    # expected: XXXX-XX-XX XX:XX:XX.XXX; statictea.nim(X*); verzion: X*.X*.X*"
    #                                                          ^
    var eix = 0
    var ix = 0
    let logLineLen = logLine.len
    let eLogLineLen = eLogLine.len
    while true:
      if ix == logLineLen or eix == eLogLineLen:
        if ix != logLineLen or eix != eLogLineLen:
          return some((ix, eix))
        return
      var ch = logLine[ix]
      var eCh = eLogLine[eix]
      case eCh
      of 'X':
        discard
      of '*':
        # Get the next expected character and search for it in the
        # current position in the log line. If there is no next
        # expected character, we match everything to the end of the
        # line. When the expected character is found, go back to
        # normal matching.
        inc(eix)
        if eix == eLogLineLen:
          return # Match to the end of the line.
        eCh = eLogLine[eix]
        var pos = find(logLine, eCh, ix)
        if pos == -1:
          return some((ix, eix))
        ix = pos
      else:
        if ch != eCh:
          return some((ix, eix))
      inc(ix)
      inc(eix)

  proc compareLogLinesMatches*(logLines: seq[string], eLogLines: seq[string]): seq[int] =
    ## Compare the two sets of log lines, skipping variable parts. If
    ## the expected line has a X in it, that character is skipped. If
    ## it has a *, zero or more characters are skipped.  More actual
    ## lines may exist then expected lines. The expected lines must
    ## appear in order but there may be other lines around them.
    ## Return the indexes of the expected log lines that match.

    var start = 0
    for eix, eLogLine in eLogLines:
      if start == logLines.len:
        break
      for ix, logLine in logLines[start .. ^1]:
        let diffsO = compareLogLine(logLine, eLogLine)
        if not diffsO.isSome:
          result.add(eix)
          start = start + ix + 1
          break

  proc showLogLinesAndExpected*(logLines: seq[string], eLogLines: seq[string], matches: seq[int]) =
    ## Show the log lines and expected log lines. The matches list
    ## contains the indexes of the expected log lines that match.
    echo "-------- logLines ---------"
    for logLine in logLines:
      echoNewLine "   line: " & logLine
    echo "-------- eLogLines ---------"
    for eix, eLogLine in eLogLines:
      if matches.contains(eix):
        echoNewLine "  found: " & eLogLine
      else:
        echoNewLine "missing: " & eLogLine

  proc compareLogLines*(logLines: seq[string], eLogLines: seq[string]): bool =
    ## Compare the log lines with the expected log lines and when
    ## different show the differences. Each expected line must match
    ## the log lines and in the correct order, but other log lines are
    ## ignored. Expected log lines can use X and * to skip variable
    ## content.
    var matches = compareLogLinesMatches(logLines, eLogLines)
    if matches.len == eLogLines.len:
      return true
    showLogLinesAndExpected(logLines, eLogLines, matches)

  proc openEnvTest*(logFilename: string, templateContent: string = ""): Env =
    ## Return an Env object with open log, error, out, template and
    ## result streams. The given log file is used for the log
    ## stream. A template file is created from the template content.
    ## The error, out, and result streams get created as string type
    ## streams.

    var templateFilename = "template.html"
    createFile(templateFilename, templateContent)
    let templateStream = newFileStream(templateFilename, fmRead)
    assert templateStream != nil

    result = Env(
      errStream: newStringStream(), closeErrStream: true,
      outStream: newStringStream(), closeOutStream: true,
      templateFilename: templateFilename,
      templateStream: templateStream,
      closeTemplateStream: true,
    )
    openLogFile(result, logFilename)
    checkLogSize(result)

    result.resultStream = newStringStream()
    result.closeResultStream = true

  proc readCloseDeleteCompare*(env: var Env,
      eLogLines: seq[string] = @[],
      eErrLines: seq[string] = @[],
      eOutLines: seq[string] = @[],
      eResultLines: seq[string] = @[],
      eTemplateLines: seq[string] = @[],
      showLog: bool = false
    ): bool =
    ## Read the env streams then close and delete them. Compare the
    ## streams with the expected content. Return true when they are
    ## the same. For the log lines compare verifies that all the
    ## expected lines compare and ignores the other lines that may
    ## exist. The template lines are ignored when eTemplateLines is
    ## not set.
    result = true
    let (logLines, errLines, outLines, resultLines, templateLines) = env.readCloseDeleteEnv()

    if showLog:
      echo "------- log lines:"
      echo logLines
      echo "-------"

    if not compareLogLines(logLines, eLogLines):
      result = false
    if not expectedItems("errLines", errLines, eErrLines):
      result = false
    if not expectedItems("outLines", outLines, eOutLines):
      result = false
    if not expectedItems("resultLines", resultLines, eResultLines):
      result = false

    if eTemplateLines.len > 0:
      if not expectedItems("templateLines", templateLines, eTemplateLines):
        result = false

  proc newLineParts*(
      prefix: string = "<!--$",
      command: string = "nextline",
      codeStart: Natural = 0,
      codeLen: Natural = 0,
      commentLen: Natural = 0,
      continuation: bool = false,
      postfix: string = "-->",
      ending: string = "\n",
      lineNum: Natural = 1): LineParts =
    ## Return a new LineParts object. The default is: <!--$ nextline -->\n.
    result = LineParts(prefix: prefix, command: command,
      codeStart: codeStart, codeLen: codeLen, commentLen: commentLen,
      continuation: continuation, postfix: postfix,
      ending: ending, lineNum: lineNum)

  func newDummyFunctionSpec*(
      functionName: string = "zero",
      signatureCode: string = "i",
      builtIn = false,
      docComments = newSeq[string](),
      filename = "test.nim",
      lineNum = 0,
      numLines = 3,
      functionPtr: FunctionPtr = nil,
      statementLines = newSeq[Statement]()): FunctionSpec =
    # Create a function spec for testing.

    func zero(variables: Variables, parameters: seq[Value]): FunResult =
      result = newFunResult(newValue(0))
    var functionPtrDefault: FunctionPtr
    if functionPtr == nil:
      functionPtrDefault = zero
    else:
      functionPtrDefault = functionPtr
    let signatureO = newSignatureO(functionName, signatureCode)
    var docCommentsList: seq[string]
    if docCommentsList.len == 0:
      docCommentsList.add("Return the number 0.")
    else:
      docCommentsList = docComments
    var statementLinesList: seq[Statement]
    if statementLinesList.len == 0:
      statementLinesList.add(newStatement("return 0"))
    else:
      statementLinesList = statementLines
    let builtIn = false
    result = newFunc(builtIn, signatureO.get(), docCommentsList, filename,
      lineNum, numLines, statementLinesList, functionPtrDefault)
