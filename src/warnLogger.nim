## Global warn logger.

import streams

var warnStream: Stream
var isStderrStream: bool

proc openWarnLog*(stderrStream: bool) =
  ## Open the warning stream as either the stderr stream or a
  ## string stream.
  if warnStream != nil:
    return
  if stderrStream:
    warnStream = newFileStream(stderr)
  else:
    warnStream = newStringStream()
  isStderrStream = stderrStream

proc closeWarnLog*() =
  ## Close the warning stream. If not open, do nothing.
  if warnStream != nil:
    warnStream.close()
    warnStream = nil

proc warn*(message: string) =
  ## Write to the warning stream. Do nothing when it's not open. If
  ## there is an io error writing, close the stream.
  if warnStream == nil:
    return
  try:
    warnStream.writeLine(message)
  except:
    closeWarnLog()

proc readWarnLines*(): seq[string] =
  # Read the warning lines from the string stream. Return nothing for
  # stderr.
  if warnStream != nil and not isStderrStream:
    warnStream.setPosition(0)
    for line in warnStream.lines():
      result.add line
