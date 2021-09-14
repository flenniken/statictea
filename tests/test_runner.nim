import std/unittest
import std/os
import std/strutils
import runner

proc createFile*(filename: string, content: string) =
  ## Create a file with the given content.
  var file = open(filename, fmWrite)
  file.write(content)
  file.close()

proc parseRunCommandLine*(cmdLine: string = ""): OpResult[RunArgs] =
  let argv = cmdLine.splitWhitespace()
  result = parseRunCommandLine(argv)

suite "runner.nim":

  test "main version":
    check 1 == 1

  test "getCmd":
    check getCmd("asdfasdf") == "other"
    check getCmd("#") == "#"
    check getCmd("\n") == ""
    check getCmd("\r\n") == ""
    check getCmd("id") == "id"
    check getCmd("file") == "file"
    check getCmd("endfile") == "endfile"
    check getCmd("expected") == "expected"

  test "getCmd2":
    check getCmd("# comment") == "#"
    check getCmd("dd\n") == "other"
    check getCmd(" \r\n") == "other"
    check getCmd("--- id ") == "id"
    check getCmd(" --- file ") == "file"
    check getCmd("- - -endfile") == "endfile"
    check getCmd("--  --  --expected") == "expected"

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

  test "parseRunCommandLine -l":
    let cmdLines = ["-l", "--leaveTempDir"]
    for cmdLine in cmdLines:
      let argsOp = parseRunCommandLine(cmdLine)
      check argsOp.kind == opValue
      let args = argsOp.value
      check args.help == false
      check args.version == false
      check args.filename == ""
      check args.directory == ""
      check args.leaveTempDir == true

  test "parseRunCommandLine -v":
    let cmdLines = ["-v", "--version"]
    for cmdLine in cmdLines:
      let argsOp = parseRunCommandLine(cmdLine)
      check argsOp.kind == opValue
      let args = argsOp.value
      check args.help == false
      check args.version == true
      check args.leaveTempDir == false
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

  test "parseRunCommandLine -f file -l":
    let cmdLines = ["-l -f=name", "--filename=name --leaveTempDir"]
    for cmdLine in cmdLines:
      let argsOp = parseRunCommandLine(cmdLine)
      check argsOp.kind == opValue
      let args = argsOp.value
      check args.help == false
      check args.version == false
      check args.leaveTempDir == true
      check args.filename == "name"
      check args.directory == ""

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

  test "parseRunFileLine name newline":
    let fileLineOp = parseRunFileLine("file name.html\n")
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

  test "runFilename missing file":
    let args = newRunArgs()
    let rcAndMessageOp = runFilename(args)
    check rcAndMessageOp.isMessage
    check rcAndMessageOp.message == "File not found: ''."

  test "runFilename empty.stf":
    let filename = "testfiles/empty.stf"
    createFile(filename, "")
    let args = newRunArgs(filename = filename)
    let rcAndMessageOp = runFilename(args)
    check rcAndMessageOp.isMessage
    check rcAndMessageOp.message == "Empty file: 'testfiles/empty.stf'."
    discard tryRemoveFile(filename)

  test "runFilename not stf":
    let filename = "testfiles/not-stf.stf"
    createFile(filename, "not a stf file")
    let args = newRunArgs(filename = filename)
    let rcAndMessageOp = runFilename(args)
    check rcAndMessageOp.isMessage
    let message = """File type not supported.
expected: id stf file version 0.0.0
got: not a stf file
"""
    check rcAndMessageOp.message == message
    check dirExists(filename & ".tempdir") == false
    discard tryRemoveFile(filename)

  test "runFilename do nothing":
    let filename = "testfiles/do-nothing.stf"
    let content = """
id stf file version 0.0.0
"""
    createFile(filename, content)
    let args = newRunArgs(filename = filename)
    let rcAndMessageOp = runFilename(args)
    check rcAndMessageOp.value == newRcAndMessage(0, "")
    check dirExists(filename & ".tempdir") == false
    discard tryRemoveFile(filename)

  test "runFilename comments":
    let filename = "testfiles/comments.stf"
    let content = """
id stf file version 0.0.0
# This is a do nothing file with comments.
# Comments have # as the first character of
# the line.
"""
    createFile(filename, content)
    let args = newRunArgs(filename = filename)
    let rcAndMessageOp = runFilename(args)
    check rcAndMessageOp.value == newRcAndMessage(0, "")
    check dirExists(filename & ".tempdir") == false
    discard tryRemoveFile(filename)

  test "runFilename leave":
    let filename = "testfiles/leave.stf"
    let tempdir = filename & ".tempdir"
    removeDir(tempdir)
    let content = """
id stf file version 0.0.0
"""
    createFile(filename, content)
    let args = newRunArgs(filename = filename, leaveTempDir = true)
    let rcAndMessageOp = runFilename(args)
    if rcAndMessageOp.isMessage:
      echo rcAndMessageOp.message
    check rcAndMessageOp.value == newRcAndMessage(0, "")
    check dirExists(tempdir) == true
    removeDir(tempdir)
    check dirExists(tempdir) == false
    discard tryRemoveFile(filename)

  test "make file":
    let filename = "testfiles/onefile.stf"
    let tempdir = filename & ".tempdir"
    removeDir(tempdir)
    let content = """
id stf file version 0.0.0
# This stf creates a file, that's all.
--- file afile.txt
contents of
the file
--- endfile
"""
    createFile(filename, content)
    let args = newRunArgs(filename = filename, leaveTempDir = true)
    let rcAndMessageOp = runFilename(args)
    check rcAndMessageOp.value == newRcAndMessage(0, "")

    check dirExists(tempdir) == true
    let afile = joinPath(tempdir, "afile.txt")
    check fileExists(afile)
    let afileContent = readFile(afile)
    check afileContent == """
contents of
the file
"""
    removeDir(tempdir)
    discard tryRemoveFile(filename)

  test "make two files":
    let filename = "testfiles/twofiles.stf"
    let tempdir = filename & ".tempdir"
    removeDir(tempdir)
    let content = """
id stf file version 0.0.0
# This stf creates files.

--- file afile.txt
contents of
the file
--- endfile

--- file bfile.txt
contents of b
the second file
--- endfile

"""
    createFile(filename, content)
    let args = newRunArgs(filename = filename, leaveTempDir = true)
    let rcAndMessageOp = runFilename(args)
    check rcAndMessageOp.value == newRcAndMessage(0, "")

    check dirExists(tempdir) == true
    let afile = joinPath(tempdir, "afile.txt")
    check fileExists(afile)
    let bfile = joinPath(tempdir, "bfile.txt")
    check fileExists(bfile)
    let afileContent = readFile(afile)
    check afileContent == """
contents of
the file
"""
    let bfileContent = readFile(bfile)
    check bfileContent == """
contents of b
the second file
"""
    removeDir(tempdir)
    discard tryRemoveFile(filename)

  test "make empty file":
    let filename = "testfiles/emptyfile.stf"
    let tempdir = filename & ".tempdir"
    removeDir(tempdir)
    let content = """
id stf file version 0.0.0
# This stf creates an empty file.
--- file emptyfile.txt
--- endfile
"""
    createFile(filename, content)
    let args = newRunArgs(filename = filename, leaveTempDir = true)
    let rcAndMessageOp = runFilename(args)
    check rcAndMessageOp.value == newRcAndMessage(0, "")

    check dirExists(tempdir) == true
    let emptyfile = joinPath(tempdir, "emptyfile.txt")
    check fileExists(emptyfile)
    check getFileSize(emptyfile) == 0
    removeDir(tempdir)
    discard tryRemoveFile(filename)

  test "missing endfile":
    let filename = "testfiles/missingendfile.stf"
    let tempdir = filename & ".tempdir"
    removeDir(tempdir)
    let content = """
id stf file version 0.0.0
# This stf creates an empty file.
--- file missingfile.txt
testing
1
2
3
"""
    createFile(filename, content)
    let args = newRunArgs(filename = filename, leaveTempDir = true)
    let rcAndMessageOp = runFilename(args)
    check rcAndMessageOp.isMessage
    check rcAndMessageOp.message == "The endfile line was missing."

    check dirExists(tempdir) == true
    let emptyfile = joinPath(tempdir, "missingfile")
    check fileExists(emptyfile) == false
    removeDir(tempdir)
    discard tryRemoveFile(filename)
