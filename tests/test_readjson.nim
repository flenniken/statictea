import unittest
import warnenv
import logenv
import vartypes
import streams
import tables
import readjson
import os

proc createFile(filename: string, content: string) =
  var file = open(filename, fmWrite)
  file.write(content)
  file.close()

proc testReadJson(jsonContent: string, expectedVars: Table[string, Value],
      expectedWarnLines: seq[string] = @[], expectedLogLines: seq[string] = @[]) =
    openWarnStream(newStringStream())
    openLogFile("_readJson.log")

    let jsonFilename = "_readJson.json"
    createFile(jsonFilename, jsonContent)
    var vars = initTable[string, Value]()
    readJson(jsonFilename, vars)
    discard tryRemoveFile(jsonFilename)

    let warnLines = readAndClose()
    check warnLines == expectedWarnLines
    var logLines = logReadDelete(20)
    check logLines == expectedLogLines

    check vars == expectedVars

suite "readjson.nim":

  test "readJson empty":
    let expectedVars = initTable[string, Value]()
    testReadJson("{}", expectedVars)
