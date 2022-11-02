## Shared test code.


when defined(test):
  import comparelines

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
