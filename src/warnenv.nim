## Global warning log environment.

import streams
import warnings

var warnStream: Stream

proc closeWarnStream*() =
  ## Close the warning stream. If not open, do nothing.
  if warnStream != nil:
    warnStream.close()
    warnStream = nil

proc warn*(filename: string, lineNum: int, warning: Warning,
           p1: string = "", p2: string = "") =
  ## Write to the warning stream. Do nothing when it's not open. If
  ## there is an io error writing, close the stream.
  if warnStream == nil:
    return
  let line = getWarning(filename, lineNum, warning, p1, p2)
  try:
    warnStream.writeLine(line)
  except:
    closeWarnStream()

when not defined(test):
  proc openWarnStream*(stderrStream: bool) =
    ## Open the strerr as the warning stream.
    if warnStream != nil:
      return
    warnStream = newFileStream(stderr)
else:
  proc openWarnStream*() =
    ## Open the warning stream as either the stderr stream or a
    ## string stream.
    if warnStream != nil:
      return
    warnStream = newStringStream()

  proc readWarnLines*(): seq[string] =
    # Read the warning lines from the string stream.
    if warnStream == nil:
      return
    warnStream.setPosition(0)
    for line in warnStream.lines():
      result.add line
