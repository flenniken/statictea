import unittest
import tempFile
import os
import options

suite "tempFile.nim":

  test "openTempFile close delete":
    var tempFileO = openTempFile()
    check tempFileO.isSome
    var tempFile = tempFileO.get()
    check tempFile.filename != ""
    check tempFile.file != nil
    tempFile.closeDelete()

  test "openTempFile close use delete":
    var tempFileO = openTempFile()
    check tempFileO.isSome
    var tempFile = tempFileO.get()
    tempFile.file.write("this is a test\n")
    tempFile.file.write("line 2\n")
    tempFile.file.close()

    var fh = open(tempFile.filename, fmRead)
    let line1 = readline(fh)
    let line2 = readline(fh)
    fh.close()

    discard tryRemoveFile(tempFile.filename)

    check line1 == "this is a test"
    check line2 == "line 2"

  test "openTempFile truncate":
    var tempFileO = openTempFile()
    check tempFileO.isSome
    var tempFile = tempFileO.get()
    tempFile.file.write("this is a test\n")
    tempFile.file.write("line 2\n")
    tempFile.truncate()
    tempFile.file.write("after truncate\n")
    tempFile.file.write("two lines for testing\n")
    tempFile.file.close()

    var fh = open(tempFile.filename, fmRead)
    let line1 = readline(fh)
    let line2 = readline(fh)
    fh.close()

    discard tryRemoveFile(tempFile.filename)

    check line1 == "after truncate"
    check line2 == "two lines for testing"
