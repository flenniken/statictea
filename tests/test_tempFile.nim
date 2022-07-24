import std/unittest
import std/os
import std/options
import std/streams
import tempFile

suite "tempFile.nim":

  test "openTempFile close delete":
    var tempFileO = openTempFile()
    require tempFileO.isSome
    var tempFile = tempFileO.get()
    check tempFile.filename != ""
    check tempFile.file != nil
    tempFile.closeDeleteFile()

  test "openTempFile close use delete":
    var tempFileO = openTempFile()
    require tempFileO.isSome
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

  test "openTempFileStream":
    let tempFileStreamO = openTempFileStream()
    require isSome(tempFileStreamO)
    let tempFileStream = tempFileStreamO.get()
    check tempFileStream.stream != nil

    # Use the stream.
    let testText = "some test text"
    tempFileStream.stream.write(testText)

    # Seek to the start and read the stream.
    tempFileStream.stream.setPosition(0)
    let line = tempFileStream.stream.readline()
    check line == testText

    # Close the stream and delete the temp file.
    tempFileStream.closeDeleteStream()
