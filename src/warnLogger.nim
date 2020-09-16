## Global warn logger.

import streams

var warnStream: Stream
var isStderrStream: bool

proc openWarnLog*(stderrStream: bool) =
  if stderrStream:
    warnStream = newFileStream(stderr)
  else:
    warnStream = newStringStream()
  isStderrStream = stderrStream

proc closeWarnLog*() =
  if warnStream != nil:
    warnStream.close()

proc warn*(message: string) =
  if warnStream != nil:
    warnStream.writeLine(message)

proc readWarnLines*(): seq[string] =
  if warnStream != nil and not isStderrStream:
    warnStream.setPosition(0)
    for line in warnStream.lines():
      result.add line

proc clearWarnLog*() =
  if warnStream != nil:
    warnStream.close()
    openWarnLog(isStderrStream)
