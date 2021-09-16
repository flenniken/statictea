import std/unittest
import std/os
import std/strutils
import runner
import tables

proc createFile*(filename: string, content: string) =
  ## Create a file with the given content.
  var file = open(filename, fmWrite)
  file.write(content)
  file.close()

proc parseRunCommandLine*(cmdLine: string = ""): OpResult[RunArgs] =
  let argv = cmdLine.splitWhitespace()
  result = parseRunCommandLine(argv)


proc testMakeDirAndFiles(filename: string, content: string,
    expectedDirAndFilesOp: OpResult[DirAndFiles]): bool =
  ## Test the makeDirAndFiles procedure. The filename is created with
  ## the content then the makeDirAndFiles procedure is called and then
  ## the result of comparing the result with the expected result is
  ## returned. The file and tempdir remain.

  # Remove the temp dir if it exists.
  let tempdir = filename & ".tempdir"
  removeDir(tempdir)

  # Create the file with the given content.
  createFile(filename, content)

  # proc makeDirAndFiles*(filename: string): OpResult[DirAndFiles] =

  # Call makeDirAndFiles.
  result = true
  let dirAndFilesOp = makeDirAndFiles(filename)
  if expectedDirAndFilesOp.isMessage and dirAndFilesOp.isValue:
    echo "Expected message but got value."
    echo "expected message: " & expectedDirAndFilesOp.message
    echo "       got value: " & $dirAndFilesOp.value
    result = false
  elif expectedDirAndFilesOp.isValue and dirAndFilesOp.isMessage:
    echo "Expected value but got message."
    echo "expected value: " & $expectedDirAndFilesOp.value
    echo "   got message: " & dirAndFilesOp.message
    result = false
  elif expectedDirAndFilesOp.isValue and dirAndFilesOp.isValue:

    let expected = expectedDirAndFilesOp.value
    let got = dirAndFilesOp.value
    if expected != got:

      # runExpectedLines: seq[RunExpectedLine]
      # runFileLines: seq[RunFileLine]

      if expected.runExpectedLines == got.runExpectedLines:
        echo "same runExpectedLines"
      else:
        echo "runExpectedLines:"
        for ix in countUp(0, max(expected.runExpectedLines.len, got.runExpectedLines.len)-1):
          var eLine = ""
          if ix < expected.runExpectedLines.len:
            eLine = $expected.runExpectedLines[ix]
          var gLine = ""
          if ix < got.runExpectedLines.len:
            gLine = $got.runExpectedLines[ix]

          echo " $1 expected: $2" % [$ix, eLine]
          echo " $1      got: $2" % [$ix, gLine]

      if expected.runFileLines == got.runFileLines:
        echo "same runFileLines"
      else:
        echo "runFileLines:"
        for ix in countUp(0, max(expected.runFileLines.len, got.runFileLines.len)-1):

          var eLine = ""
          if ix < expected.runFileLines.len:
            eLine = $expected.runFileLines[ix]
          var gLine = ""
          if ix < got.runFileLines.len:
            gLine = $got.runFileLines[ix]

          echo "$1 expected: $2" % [$(ix+1), eLine]
          echo "$1      got: $2" % [$(ix+1), gLine]

      result = false
  else:
    if expectedDirAndFilesOp.message != dirAndFilesOp.message:
      echo "expected message: " & expectedDirAndFilesOp.message
      echo "     got message: " & dirAndFilesOp.message
      result = false

proc removeFileAndTempdir(filename: string) =
  let tempdir = filename & ".tempdir"
  removeDir(tempdir)
  discard tryRemoveFile(filename)

type
  NameAndContent = object
    filename: string
    content: string

func newNameAndContent(filename: string, content: string): NameAndContent =
  result = NameAndContent(filename: filename, content: content)

proc testDir(filename: string, nameAndContentList: seq[NameAndContent]): bool =
  ## Check that the temp directory contains files with the correct
  ## content. The filename is the stf name. Remove the temp directory
  ## at the end.

  let tempdir = filename & ".tempdir"
  if dirExists(tempdir) == false:
    echo "The temp directory doesn't exist."
    echo tempdir
    return false

  var expectedFilenames = initTable[string, int]()
  result = true
  for nameAndContent in nameAndContentList:
    let filename = nameAndContent.filename
    expectedFilenames[filename] = 0
    let content = nameAndContent.content
    let path = joinPath(tempdir, filename)
    if not fileExists(path):
      echo "file doesn't exist: " & path
      result = false
    else:
      let gotContent = readFile(path)
      if gotContent != content:
        echo "unexpected content for file: " & path
        result = false

  for kind, path in walkDir(tempdir):
    # echo "kind: " & $kind
    # echo "path: " & path
    let (_, basename) = splitPath(path)
    if not (basename in expectedFilenames):
      echo "found extra file in temp dir: " & basename
      result = false

  removeFileAndTempdir(filename)

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
    # let a = newRunExpectedLine("afile.txt", "bfile.txt")
    let b = newRunFileLine("afile.txt", false, false, false)
    let c = newRunFileLine("bfile.txt", false, false, false)
    let dirAndFiles = newDirAndFiles(@[], @[b, c])
    let expected = OpResult[DirAndFiles](kind: opValue, value: dirAndFiles)
    check testMakeDirAndFiles(filename, content, expected)

    let expectedAFileContent = """
contents of
the file
"""
    let expectedBFileContent = """
contents of b
the second file
"""
    let d = newNameAndContent("afile.txt", expectedAFileContent)
    let e = newNameAndContent("bfile.txt", expectedBFileContent)
    check testDir(filename, @[d, e])

  test "make empty file":
    let filename = "testfiles/emptyfile.stf"
    let content = """
id stf file version 0.0.0
# This stf creates an empty file.
--- file emptyfile.txt
--- endfile
"""
    # let a = newRunExpectedLine("filea", "emptyfile.txt")
    let b = newRunFileLine("emptyfile.txt", false, false, false)
    let dirAndFiles = newDirAndFiles(@[], @[b])
    let expected = OpResult[DirAndFiles](kind: opValue, value: dirAndFiles)
    check testMakeDirAndFiles(filename, content, expected)

    let e = newNameAndContent("emptyfile.txt", "")
    check testDir(filename, @[e])

  test "missing endfile":
    let filename = "testfiles/missingendfile.stf"
    let content = """
id stf file version 0.0.0
# This stf creates an empty file.
--- file missingfile.txt
testing
1
2
3
"""
    # todo: change message: The endfile line is missing.
    let message = "The endfile line was missing."
    let expected = OpResult[DirAndFiles](kind: opMessage, message: message)
    check testMakeDirAndFiles(filename, content, expected)

    check testDir(filename, @[])
