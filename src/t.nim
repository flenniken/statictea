# try out things here
# build and run with "n tt"
import streams
import testUtils
import os

proc createFile*(filename: string, content: string) =
  var file = open(filename, fmWrite)
  file.write(content)
  file.close()

let templateFilename = "template.html"
let content = "Hello"
createFile(templateFilename, content)
var stream = newFileStream(templateFilename)

var buffer: array[1024, byte]
var bytesRead = stream.readData(buffer.addr, buffer.sizeof)

doAssert bytesRead == 5
doAssert stream.atEnd() == true
stream.close()

discard tryRemoveFile(templateFilename)
