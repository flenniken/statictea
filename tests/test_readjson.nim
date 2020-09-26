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

suite "readjson.nim":

  test "readJson":
    var value: Value

    openWarnStream(newStringStream())
    openLogFile("_readJson.log")

    let jsonFilename = "_readJson.json"
    createFile(jsonFilename, "5")
    var vars = initTable[string, Value]()
    readJson(jsonFilename, vars)
    discard tryRemoveFile(jsonFilename)

    let warnLines = readAndClose()
    for line in warnLines:
      echo line
    var logLines = logReadDelete(20)
    for line in logLines:
      echo line
