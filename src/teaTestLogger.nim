## Global logger for testing.

import streams

var testStream: Stream

proc openTestLog*() =
  testStream = newStringStream()

proc closeTestLog*() =
  testStream.close()

proc readTestLines*(): seq[string] =
  ## Read all the lines in the stream.
  testStream.setPosition(0)
  for line in testStream.lines():
    result.add line

proc clearTestLog*() =
  testStream.close()
  testStream = newStringStream()

proc log*(message: string) =
  testStream.writeLine(message)
