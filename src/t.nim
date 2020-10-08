# try out things here
# build and run with "n tt"

import streams

let templateStream = newFileStream("hello.html", fmRead)
defer: templateStream.close()
let resultStream = newFileStream("result.html", fmWrite)
defer: resultStream.close()

resultStream.writeLine("my result")
