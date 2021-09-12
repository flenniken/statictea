import std/unittest
import std/os
import std/strutils
import runner

proc parseRunCommandLine*(cmdLine: string = ""): OpResult[RunArgs] =
  let argv = cmdLine.splitWhitespace()
  result = parseRunCommandLine(argv)

suite "runner.nim":

  test "main version":
    check 1 == 1

  test "createFolder":
    let tempDirName = "createFolderTest"
    let rcAndMessageOp = createFolder(tempDirName)
    check dirExists(tempDirName)
    removeDir(tempDirName)
    check dirExists(tempDirName) == false
    check rcAndMessageOp.kind == opValue
    let rcAndMessage = rcAndMessageOp.value
    check rcAndMessage.rc == 0
    check rcAndMessage.message == ""

  test "createFolder error":
    # Try to create a folder in a readonly folder.

    # Create a folder in the temp folder then set it readonly.
    let parentFolder = joinPath(getTempDir(), "createFolderError")
    createDir(parentFolder)
    var permissions = getFilePermissions(parentFolder)
    # echo "permissions = " & $permissions
    setFilePermissions(parentFolder, {fpUserRead, fpGroupRead})
    permissions = getFilePermissions(parentFolder)
    # echo "permissions = " & $permissions

    # Try to create a folder in the readonly folder.
    let dirName = joinPath(parentFolder, "createFolderTest")
    let rcAndMessageOp = createFolder(dirName)

    # Check for the expected error.
    check dirExists(dirName) == false
    check rcAndMessageOp.kind == opMessage
    check rcAndMessageOp.message != ""
    # echo rcAndMessageOp.message

    # Remove the temp dir.
    setFilePermissions(parentFolder, {fpUserRead, fpGroupRead, fpUserWrite})
    removeDir(parentFolder)
    check dirExists(parentFolder) == false

  test "parseRunCommandLine -h":
    let cmdLines = ["-h", "--help"]
    for cmdLine in cmdLines:
      let argsOp = parseRunCommandLine(cmdLine)
      check argsOp.kind == opValue
      let args = argsOp.value
      check args.help == true
      check args.version == false
      check args.filename == ""
      check args.directory == ""

  test "parseRunCommandLine -v":
    let cmdLines = ["-v", "--version"]
    for cmdLine in cmdLines:
      let argsOp = parseRunCommandLine(cmdLine)
      check argsOp.kind == opValue
      let args = argsOp.value
      check args.help == false
      check args.version == true
      check args.filename == ""
      check args.directory == ""

  test "parseRunCommandLine -f":
    let cmdLines = ["-f=hello.stf", "--filename=hello.stf"]
    for cmdLine in cmdLines:
      let argsOp = parseRunCommandLine(cmdLine)
      check argsOp.kind == opValue
      let args = argsOp.value
      check args.help == false
      check args.version == false
      check args.filename == "hello.stf"
      check args.directory == ""

  test "parseRunCommandLine -d":
    let cmdLines = ["-d=testfolder", "--directory=testfolder"]
    for cmdLine in cmdLines:
      let argsOp = parseRunCommandLine(cmdLine)
      check argsOp.kind == opValue
      let args = argsOp.value
      check args.help == false
      check args.version == false
      check args.filename == ""
      check args.directory == "testfolder"

  test "parseRunCommandLine -f file":
    let cmdLines = ["-f testfolder", "--filename testfolder"]
    for cmdLine in cmdLines:
      let argsOp = parseRunCommandLine(cmdLine)
      check argsOp.kind == opMessage
      check argsOp.message == "Missing filename. Use -f=filename"

  test "parseRunCommandLine -d file":
    let cmdLines = ["-d testfolder", "--directory testfolder"]
    for cmdLine in cmdLines:
      let argsOp = parseRunCommandLine(cmdLine)
      check argsOp.kind == opMessage
      check argsOp.message == "Missing directory name. Use -d=directory"

  test "openNewFile":

    let folder = getTempDir()
    let filename = "openNewFile"
    let fileOp = openNewFile(folder, filename)
    check fileOp.kind == opValue
    let file = fileOp.value
    file.write("this is a test\n")
    file.close()

    let path = joinPath(folder, filename)
    check fileExists(path)
    discard tryRemoveFile(path)

  test "openNewFile error":

    # Create a temp folder and set it readonly.
    let folder = joinPath(getTempDir(), "createFolderError")
    createDir(folder)
    setFilePermissions(folder, {fpUserRead, fpGroupRead})

    let filename = "openNewFile"
    let fileOp = openNewFile(folder, filename)
    check fileOp.kind == opMessage
    # echo fileOp.message
    check fileOp.message.startsWith("Unable to create the file")

    # Remove the temp dir.
    setFilePermissions(folder, {fpUserRead, fpGroupRead, fpUserWrite})
    removeDir(folder)
    check dirExists(folder) == false

  test "parseRunFileLine name":
    let fileLineOp = parseRunFileLine("file name.html")
    check fileLineOp.isValue
    check fileLineOp.value.filename == "name.html"
    check fileLineOp.value.noLastEnding == false

  test "parseRunFileLine ---name":
    let fileLineOp = parseRunFileLine("--- file name.html ---")
    check fileLineOp.isValue
    check fileLineOp.value.filename == "name.html"
    check fileLineOp.value.noLastEnding == false

  test "parseRunFileLine name with spaces":
    let fileLineOp = parseRunFileLine("----  ---- -- file    name.html  ")
    check fileLineOp.isValue
    check fileLineOp.value.filename == "name.html"
    check fileLineOp.value.noLastEnding == false

  test "parseRunFileLine name and noLastEnding":
    let fileLineOp = parseRunFileLine("----------file name.html noLastEnding")
    check fileLineOp.isValue
    check fileLineOp.value.filename == "name.html"
    check fileLineOp.value.noLastEnding == true

  test "parseRunFileLine name and noLastEnding":
    let fileLineOp = parseRunFileLine("----------file   name.html   noLastEnding  ")
    check fileLineOp.isValue
    check fileLineOp.value.filename == "name.html"
    check fileLineOp.value.noLastEnding == true

  test "parseRunFileLine name noLastEnding command":
    let fileLineOp = parseRunFileLine("file name.html noLastEnding command")
    check fileLineOp.isValue
    check fileLineOp.value.filename == "name.html"
    check fileLineOp.value.noLastEnding == true
    check fileLineOp.value.command == true
    check fileLineOp.value.nonZeroReturn == false

  test "parseRunFileLine name noLastEnding command nonZeroReturn":
    let fileLineOp = parseRunFileLine("file name.html noLastEnding command nonZeroReturn")
    check fileLineOp.isValue
    check fileLineOp.value.filename == "name.html"
    check fileLineOp.value.noLastEnding == true
    check fileLineOp.value.command == true
    check fileLineOp.value.nonZeroReturn == true

  test "parseRunFileLine name command nonZeroReturn":
    let fileLineOp = parseRunFileLine("file name.html command nonZeroReturn")
    check fileLineOp.isValue
    check fileLineOp.value.filename == "name.html"
    check fileLineOp.value.noLastEnding == false
    check fileLineOp.value.command == true
    check fileLineOp.value.nonZeroReturn == true

  test "parseRunFileLine name command ":
    let fileLineOp = parseRunFileLine("file name.html command")
    check fileLineOp.isValue
    check fileLineOp.value.filename == "name.html"
    check fileLineOp.value.noLastEnding == false
    check fileLineOp.value.command == true
    check fileLineOp.value.nonZeroReturn == false

  test "parseRunFileLine error":
    let fileLineOp = parseRunFileLine("----------filename.html")
    check fileLineOp.isMessage
    check fileLineOp.message == "Invalid file line: ----------filename.html"

  test "parseRunExpectedLine happy path":
    let runExpectedLineOp = parseRunExpectedLine("expected file1 == file2")
    check runExpectedLineOp.isValue
    check runExpectedLineOp.value.filename1 == "file1"
    check runExpectedLineOp.value.filename2 == "file2"

  test "parseRunExpectedLine spaces":
    let runExpectedLineOp = parseRunExpectedLine("------ expected   file1   ==  file2 --")
    check runExpectedLineOp.isValue
    check runExpectedLineOp.value.filename1 == "file1"
    check runExpectedLineOp.value.filename2 == "file2"

  test "parseRunExpectedLine error":
    let runExpectedLineOp = parseRunExpectedLine("----------filename.html")
    check runExpectedLineOp.isMessage
    check runExpectedLineOp.message == "Invalid expected line: ----------filename.html"

  test "parseRunExpectedLine missing file":
    let runExpectedLineOp = parseRunExpectedLine("expected file1")
    check runExpectedLineOp.isMessage
    check runExpectedLineOp.message == "Invalid expected line: expected file1"



  # test "runFilename":
  #   let args = newRunArgs(filename = "hello.stf")
  #   rcAndMessageOp = runFilename(args)
