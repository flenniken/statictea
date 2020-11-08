import unittest
import env
import streams
import matches
import readlines
import options
import parseCmdLine
import processLinesReturnCmd
import strutils

suite "processLinesReturnCmd.nim":

  test "processLinesReturnCmd":
    let content = "<--!$ nextline -->\n"

    var prepostTable = getPrepostTable()
    var prefixMatcher = getPrefixMatcher(prepostTable)
    var commandMatcher = getCommandMatcher()
    var inStream = newStringStream(content)
    var outStream = newStringStream()
    var lineBufferO = newLineBuffer(inStream, templateFilename="template.html")
    var lb = lineBufferO.get()
    var cmdLines: seq[string] = @[]
    var cmdLineParts: seq[LineParts] = @[]

    var env = openEnv("_processLinesReturnCmd.log")

    processLinesReturnCmd(env, lb, prepostTable, prefixMatcher,
      commandMatcher, outStream, cmdLines, cmdLineParts)

    let (logLines, errLines, outLines) = env.readCloseDelete()

    echo "logLines: $1" % $logLines
    echo "errLines: $1" % $errLines
    echo "outLines: $1" % $outLines
    echo "cmdLines: $1" % $cmdLines

    outStream.setPosition(0)
    var output = outStream.readAll()
    outStream.close()
    echo "output: $1" % output
