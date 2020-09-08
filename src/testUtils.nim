import streams

when defined(test):

  proc readLines*(stream: Stream): seq[string] =
    stream.setPosition(0)
    for line in stream.lines():
      result.add line
