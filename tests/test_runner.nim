import std/unittest
import std/os
import std/strutils
import runner

proc parseRunnerCommandLine*(cmdLine: string = ""): OpResult[Args] =
  let argv = cmdLine.splitWhitespace()
  result = parseRunnerCommandLine(argv)

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

  test "parseRunnerCommandLine -h":
    let cmdLines = ["-h", "--help"]
    for cmdLine in cmdLines:
      let argsOp = parseRunnerCommandLine(cmdLine)
      check argsOp.kind == opValue
      let args = argsOp.value
      check args.help == true
      check args.version == false
      check args.filename == ""
      check args.directory == ""

  test "parseRunnerCommandLine -v":
    let cmdLines = ["-v", "--version"]
    for cmdLine in cmdLines:
      let argsOp = parseRunnerCommandLine(cmdLine)
      check argsOp.kind == opValue
      let args = argsOp.value
      check args.help == false
      check args.version == true
      check args.filename == ""
      check args.directory == ""

  test "parseRunnerCommandLine -f":
    let cmdLines = ["-f=hello.stf", "--filename=hello.stf"]
    for cmdLine in cmdLines:
      let argsOp = parseRunnerCommandLine(cmdLine)
      check argsOp.kind == opValue
      let args = argsOp.value
      check args.help == false
      check args.version == false
      check args.filename == "hello.stf"
      check args.directory == ""

  test "parseRunnerCommandLine -d":
    let cmdLines = ["-d=testfolder", "--directory=testfolder"]
    for cmdLine in cmdLines:
      let argsOp = parseRunnerCommandLine(cmdLine)
      check argsOp.kind == opValue
      let args = argsOp.value
      check args.help == false
      check args.version == false
      check args.filename == ""
      check args.directory == "testfolder"

  test "parseRunnerCommandLine -f file":
    let cmdLines = ["-f testfolder", "--filename testfolder"]
    for cmdLine in cmdLines:
      let argsOp = parseRunnerCommandLine(cmdLine)
      check argsOp.kind == opMessage
      check argsOp.message == "Missing filename. Use -f=filename"

  test "parseRunnerCommandLine -d file":
    let cmdLines = ["-d testfolder", "--directory testfolder"]
    for cmdLine in cmdLines:
      let argsOp = parseRunnerCommandLine(cmdLine)
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
    check fileOp.message.startsWith("Unable to create the file:")
    
    # Remove the temp dir.
    setFilePermissions(folder, {fpUserRead, fpGroupRead, fpUserWrite})
    removeDir(folder)
    check dirExists(folder) == false
