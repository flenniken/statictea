import streams

when defined(test):

  proc theLines*(stream: Stream): seq[string] =
    ## Read all the lines in the stream.
    stream.setPosition(0)
    for line in stream.lines():
      result.add line

  proc theLines*(filename: string): seq[string] =
    ## Read all the lines in the file.
    for line in lines(filename):
      result.add line

  proc createFile*(filename: string, content: string) =
    var file = open(filename, fmWrite)
    file.write(content)
    file.close()
