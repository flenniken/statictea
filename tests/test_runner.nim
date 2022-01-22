import std/unittest
import std/os
import std/strutils
import opresult
import runner
import tables

proc createFile*(filename: string, content: string) =
  ## Create a file with the given content.
  var file = open(filename, fmWrite)
  file.write(content)
  file.close()

proc parseRunCommandLine*(cmdLine: string = ""): runner.OpResultStr[RunArgs] =
  let argv = strutils.splitWhitespace(cmdLine)
  result = parseRunCommandLine(argv)

proc showCompareLines*[T](expectedLines: seq[T], gotLines: seq[T],
    showSame = false, stopOnFirstDiff = false): bool =
  ## Compare two sets of lines and show the differences.  If no
  ## differences, return true.

  result = true
  for ix in countUp(0, max(expectedLines.len, gotLines.len)-1):
    var eLine = ""
    if ix < expectedLines.len:
      eLine = $expectedLines[ix]
    var gLine = ""
    if ix < gotLines.len:
      gLine = $gotLines[ix]

    var lineNum = $(ix+1)
    if eLine == gLine:
      if showSame:
        echo "$1     same: '$2'" % [lineNum, eLine]
    else:
      echo "$1 expected: '$2'" % [lineNum, eLine]
      echo "$1      got: '$2'" % [lineNum, gLine]
      result = false
      if stopOnFirstDiff:
        break


# todo: remove runner.OpResult and use the other one.

proc testMakeDirAndFiles(filename: string, content: string,
    expectedDirAndFilesOp: runner.OpResultStr[DirAndFiles]): bool =
  ## Test the makeDirAndFiles procedure. The filename is created with
  ## the content then the makeDirAndFiles procedure is called and then
  ## the result of comparing the result with the expected result is
  ## returned. The file and tempdir remain.

  # Remove the temp dir if it exists.
  let tempdir = filename & ".tempdir"
  removeDir(tempdir)

  # Create the file with the given content.
  createFile(filename, content)

  # proc makeDirAndFiles*(filename: string): OpResultStr[DirAndFiles] =

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

      # compareLines: seq[CompareLine]
      # runFileLines: seq[RunFileLine]

      if expected.compareLines == got.compareLines:
        echo "same compareLines"
      else:
        echo "compareLines:"
        discard showCompareLines(expected.compareLines, got.compareLines)

      if expected.runFileLines == got.runFileLines:
        echo "same runFileLines"
      else:
        echo "runFileLines:"
        discard showCompareLines(expected.runFileLines, got.runFileLines)

      result = false
  else:
    if expectedDirAndFilesOp.message != dirAndFilesOp.message:
      echo "expected message: '$1'" % expectedDirAndFilesOp.message
      echo "     got message: '$1'" % dirAndFilesOp.message
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
        let (_, basename) = splitPath(path)
        echo "expected $1:" % basename
        echo content
        echo "     got $1:" % basename
        echo gotContent
        result = false

  for kind, path in walkDir(tempdir):
    # echo "kind: " & $kind
    # echo "path: " & path
    let (_, basename) = splitPath(path)
    if not (basename in expectedFilenames):
      echo "found extra file in temp dir: " & basename
      result = false

  if result == false:
    echo "========="
  removeFileAndTempdir(filename)

proc testCompareFilesEqual(content1: string, content2: string): bool =

  let f1 = "f1.txt"
  let f2 = "f2.txt"

  createFile(f1, content1)
  createFile(f2, content2)

  result = true
  let stringOp = compareFiles(f1, f2)
  if stringOp.isValue:
    if stringOp.value != "":
      echo "expected message: '', got:"
      echo stringOp.value
      echo "---"
      result = false
  else:
    echo "got: " & stringOp.message
    result = false

  discard tryRemoveFile(f1)
  discard tryRemoveFile(f2)

proc testCompareFilesDifferent(content1: string, content2: string, expected: string): bool =

  let f1 = "f1.txt"
  let f2 = "f2.txt"

  createFile(f1, content1)
  createFile(f2, content2)

  result = true
  let stringOp = compareFiles(f1, f2)
  if stringOp.isMessage:
    # Unable to compare the files.
    if expected != stringOp.message:
      echo "Unable to compare the files."
      echo "expected: " & expected
      echo "     got: " & stringOp.message
      result = false
  else:
    # Able to compare and differences in the value.
    if expected != stringOp.value:
      echo "expected-----------"
      echo expected
      echo "     got-----------"
      echo stringOp.value
      result = false

  discard tryRemoveFile(f1)
  discard tryRemoveFile(f2)

proc testLinesSideBySide(content1: string, content2: string,
    expected: string): bool =
  ## Test linesSideBySide.

  let str = linesSideBySide(content1, content2)
  if str != expected:
    echo "got:"
    echo str
    echo "expected:"
    echo expected
    result = false
  else:
    result = true

proc testParseRunFileLine(line: string, eRunFileLine: RunFileLine): bool =
  ## Test parseRunFileLine where it is expected to pass.
  let runFileLineOp = parseRunFileLine(line)
  if runFileLineOp.isMessage:
    echo runFileLineOp.message
    return false
  if runFileLineOp.value != eRunFileLine:
    echo "expected: " & $eRunFileLine
    echo "     got: " & $runFileLineOp.value
    return false
  result = true

proc testParseExpectedLine(line: string, eCompareLine: CompareLine): bool =
  ## Test parseExpectedLine where it is expected to pass.
  let compareLineOp = parseExpectedLine(line)
  if compareLineOp.isMessage:
    echo compareLineOp.message
    return false
  if compareLineOp.value != eCompareLine:
    echo "expected: " & $eCompareLine
    echo "     got: " & $compareLineOp.value
    return false
  result = true

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
    let message = createFolder(tempDirName)
    check message == ""
    check dirExists(tempDirName)
    removeDir(tempDirName)
    check dirExists(tempDirName) == false

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
    let message = createFolder(dirName)
    check message != ""
    check dirExists(dirName) == false

    # Remove the temp dir.
    setFilePermissions(parentFolder, {fpUserRead, fpGroupRead, fpUserWrite})
    removeDir(parentFolder)
    check dirExists(parentFolder) == false

  test "parseRunCommandLine -h":
    let cmdLines = ["-h", "--help"]
    for cmdLine in cmdLines:
      let argsOp = parseRunCommandLine(cmdLine)
      check argsOp.isValue
      let args = argsOp.value
      check args.help == true
      check args.version == false
      check args.filename == ""
      check args.directory == ""

  test "parseRunCommandLine -l":
    let cmdLines = ["-l", "--leaveTempDir"]
    for cmdLine in cmdLines:
      let argsOp = parseRunCommandLine(cmdLine)
      check argsOp.isValue
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
      check argsOp.isValue
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
      check argsOp.isValue
      let args = argsOp.value
      check args.help == false
      check args.version == false
      check args.filename == "hello.stf"
      check args.directory == ""

  test "parseRunCommandLine -d":
    let cmdLines = ["-d=testfolder", "--directory=testfolder"]
    for cmdLine in cmdLines:
      let argsOp = parseRunCommandLine(cmdLine)
      check argsOp.isValue
      let args = argsOp.value
      check args.help == false
      check args.version == false
      check args.filename == ""
      check args.directory == "testfolder"

  test "parseRunCommandLine -f file":
    let cmdLines = ["-f testfolder", "--filename testfolder"]
    for cmdLine in cmdLines:
      let argsOp = parseRunCommandLine(cmdLine)
      check argsOp.isMessage
      check argsOp.message == "Missing filename. Use -f=filename"

  test "parseRunCommandLine -f file -l":
    let cmdLines = ["-l -f=name", "--filename=name --leaveTempDir"]
    for cmdLine in cmdLines:
      let argsOp = parseRunCommandLine(cmdLine)
      check argsOp.isValue
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
      check argsOp.isMessage
      check argsOp.message == "Missing directory name. Use -d=directory"

  test "openNewFile":

    let folder = getTempDir()
    let filename = "openNewFile"
    let fileOp = openNewFile(folder, filename)
    check fileOp.isValue
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
    check fileOp.isMessage
    # echo fileOp.message
    check fileOp.message.startsWith("Unable to create the file")

    # Remove the temp dir.
    setFilePermissions(folder, {fpUserRead, fpGroupRead, fpUserWrite})
    removeDir(folder)
    check dirExists(folder) == false

  test "parseRunFileLine name":
    let line = "file name.html"
    let eRunFileLine = newRunFileLine("name.html")
    check testParseRunFileLine(line, eRunFileLine)

  test "parseRunFileLine tabs":
    let line = "--\t -- file \t name.html --\t-- --"
    let eRunFileLine = newRunFileLine("name.html")
    check testParseRunFileLine(line, eRunFileLine)

  test "parseRunFileLine name newline":
    let line = "file name.html\n"
    let eRunFileLine = newRunFileLine("name.html")
    check testParseRunFileLine(line, eRunFileLine)

  test "parseRunFileLine ---name":
    let line = "--- file name.html ---"
    let eRunFileLine = newRunFileLine("name.html")
    check testParseRunFileLine(line, eRunFileLine)

  test "parseRunFileLine name with spaces":
    let line = "----  ---- -- file    name.html  "
    let eRunFileLine = newRunFileLine("name.html")
    check testParseRunFileLine(line, eRunFileLine)

  test "parseRunFileLine name and noLastEnding":
    let line = "----------file name.html noLastEnding"
    let eRunFileLine = newRunFileLine("name.html", noLastEnding = true)
    check testParseRunFileLine(line, eRunFileLine)

  test "parseRunFileLine name and noLastEnding":
    let line = "----------file   name.html   noLastEnding  "
    let eRunFileLine = newRunFileLine("name.html", noLastEnding = true)
    check testParseRunFileLine(line, eRunFileLine)

  test "parseRunFileLine name noLastEnding command":
    let line = "file name.html noLastEnding command"
    let eRunFileLine = newRunFileLine("name.html", noLastEnding =
      true, command = true)
    check testParseRunFileLine(line, eRunFileLine)

  test "parseRunFileLine name noLastEnding command nonZeroReturn":
    let line = "file name.html noLastEnding command nonZeroReturn"
    let eRunFileLine = newRunFileLine("name.html", noLastEnding =
      true, command = true, nonZeroReturn = true)
    check testParseRunFileLine(line, eRunFileLine)

  test "parseRunFileLine dashes":
    let line = "---file---name.html---noLastEnding---command---nonZeroReturn---"
    let eRunFileLine = newRunFileLine("name.html", noLastEnding =
      true, command = true, nonZeroReturn = true)
    check testParseRunFileLine(line, eRunFileLine)

  test "parseRunFileLine name command nonZeroReturn":
    let line = "file name.html command nonZeroReturn"
    let eRunFileLine = newRunFileLine("name.html", command = true,
      nonZeroReturn = true)
    check testParseRunFileLine(line, eRunFileLine)

  test "parseRunFileLine name command ":
    let line = "file name.html command"
    let eRunFileLine = newRunFileLine("name.html", command = true)
    check testParseRunFileLine(line, eRunFileLine)

  test "parseRunFileLine error":
    let fileLineOp = parseRunFileLine("----------filename.html")
    check fileLineOp.isMessage
    check fileLineOp.message == "Invalid file line: ----------filename.html"

  test "parseExpectedLine happy path":
    let line = "expected file1 == file2"
    let eCompareLine = newCompareLine("file1", "file2")
    check testParseExpectedLine(line, eCompareLine)

  test "parseExpectedLine spaces":
    let line = "------ expected   file1   ==  file2 --"
    let eCompareLine = newCompareLine("file1", "file2")
    check testParseExpectedLine(line, eCompareLine)

  test "parseExpectedLine dashes":
    let line = "---expected---file1---==---file2---"
    let eCompareLine = newCompareLine("file1", "file2")
    check testParseExpectedLine(line, eCompareLine)

  test "parseExpectedLine tabs":
    let line = "---\t--- expected \t  file1 \t  ==  \t file2 \t--"
    let eCompareLine = newCompareLine("file1", "file2")
    check testParseExpectedLine(line, eCompareLine)

  test "parseExpectedLine error":
    let runExpectedLineOp = parseExpectedLine("----------filename.html")
    check runExpectedLineOp.isMessage
    check runExpectedLineOp.message == "Invalid expected line: ----------filename.html"

  test "parseExpectedLine missing file":
    let runExpectedLineOp = parseExpectedLine("expected file1")
    check runExpectedLineOp.isMessage
    check runExpectedLineOp.message == "Invalid expected line: expected file1"

  test "runFilename empty.stf":
    let filename = "testfiles/empty.stf"
    let content = ""
    let message = "Empty file: 'testfiles/empty.stf'."
    let expected = optMessage[DirAndFiles](message)
    check testMakeDirAndFiles(filename, content, expected)
    check testDir(filename, @[])

  test "runFilename not stf":
    let filename = "testfiles/not.stf"
    let content = "not a stf file"
    let message = """
Invalid stf file first line:
expected: id stf file version 0.0.0
     got: not a stf file"""
    let expected = optMessage[DirAndFiles](message)
    # let a = newCompareLine("filea", "emptyfile.txt")
    # let b = newRunFileLine("afile.txt", false, false, false)
    # let dirAndFiles = newDirAndFiles(@[], @[])
    # let expected = runner.OpResultStr[DirAndFiles](kind: okValue, value: dirAndFiles)
    check testMakeDirAndFiles(filename, content, expected)

    # let e = newNameAndContent("afile.txt", "contents of\nthe file\n")
    check testDir(filename, @[])

  test "runFilename do nothing":
    let filename = "testfiles/do-nothing.stf"
    let content = """
id stf file version 0.0.0
"""
    # let message = "File type not supported."
    # let expected = runner.OpResultStr[DirAndFiles](kind: okMessage, message: message)
    # let a = newCompareLine("filea", "emptyfile.txt")
    # let b = newRunFileLine("afile.txt", false, false, false)
    let dirAndFiles = newDirAndFiles(@[], @[])
    let expected = optValue[DirAndFiles](dirAndFiles)
    check testMakeDirAndFiles(filename, content, expected)

    # let e = newNameAndContent("afile.txt", "contents of\nthe file\n")
    check testDir(filename, @[])

  test "runFilename comments":
    let filename = "testfiles/comments.stf"
    let content = """
id stf file version 0.0.0
# This is a do nothing file with comments.
# Comments have # as the first character of
# the line.
"""
    # let a = newCompareLine("filea", "emptyfile.txt")
    # let b = newRunFileLine("afile.txt", false, false, false)
    let dirAndFiles = newDirAndFiles(@[], @[])
    let expected = optValue[DirAndFiles](dirAndFiles)
    check testMakeDirAndFiles(filename, content, expected)

    # let e = newNameAndContent("afile.txt", "contents of\nthe file\n")
    check testDir(filename, @[])

  test "make file":
    let filename = "testfiles/onefile.stf"
    let content = """
id stf file version 0.0.0
# This stf creates a file, that's all.
--- file afile.txt
contents of
the file
--- endfile
"""
    # let a = newCompareLine("filea", "emptyfile.txt")
    let b = newRunFileLine("afile.txt")
    let dirAndFiles = newDirAndFiles(@[], @[b])
    let expected = optValue[DirAndFiles](dirAndFiles)
    check testMakeDirAndFiles(filename, content, expected)

    let e = newNameAndContent("afile.txt", "contents of\nthe file\n")
    check testDir(filename, @[e])

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
    # let a = newCompareLine("afile.txt", "bfile.txt")
    let b = newRunFileLine("afile.txt")
    let c = newRunFileLine("bfile.txt")
    let dirAndFiles = newDirAndFiles(@[], @[b, c])
    let expected = optValue[DirAndFiles](dirAndFiles)
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
    # let a = newCompareLine("filea", "emptyfile.txt")
    let b = newRunFileLine("emptyfile.txt")
    let dirAndFiles = newDirAndFiles(@[], @[b])
    let expected = optValue[DirAndFiles](dirAndFiles)
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
    let expected = optMessage[DirAndFiles](message)
    check testMakeDirAndFiles(filename, content, expected)

    check testDir(filename, @[])

  test "unknown line":
    let filename = "testfiles/unknownline.stf"
    let content = """
id stf file version 0.0.0
# This stf hand an unknown line.
what's this?
"""
    let message = "Unknown line: 'what's this?'."
    let expected = optMessage[DirAndFiles](message)
    check testMakeDirAndFiles(filename, content, expected)
    check testDir(filename, @[])

  # --- file filename [noLastEnding] [command] [nonZeroReturn] ---

  test "noLastEnding":
    let filename = "testfiles/noLastEnding.stf"
    let content = """
id stf file version 0.0.0
# This stf creates a file with no ending newline.
--- file afile.txt noLastEnding
contents of the file
--- endfile
"""
    let r = newRunFileLine("afile.txt", noLastEnding = true)
    let dirAndFiles = newDirAndFiles(@[], @[r])
    let expected = optValue[DirAndFiles](dirAndFiles)
    check testMakeDirAndFiles(filename, content, expected)

    let c = newNameAndContent("afile.txt", "contents of the file")
    check testDir(filename, @[c])

  test "command":
    let filename = "testfiles/command.stf"
    let content = """
id stf file version 0.0.0
# This stf creates a file with a command.
--- file afile.txt noLastEnding command
ls
--- endfile
"""
    let r = newRunFileLine("afile.txt", command = true, noLastEnding = true)
    let dirAndFiles = newDirAndFiles(@[], @[r])
    let expected = optValue[DirAndFiles](dirAndFiles)
    check testMakeDirAndFiles(filename, content, expected)

    let c = newNameAndContent("afile.txt", "ls")
    check testDir(filename, @[c])

  test "command nonZeroReturn":
    let filename = "testfiles/nonZeroReturn.stf"
    let content = """
id stf file version 0.0.0
# This stf creates a file with a command with a nonZeroReturn.
--- file afile.txt noLastEnding command nonZeroReturn
ls
--- endfile
"""
    let r = newRunFileLine("afile.txt", true, true, true)
    let dirAndFiles = newDirAndFiles(@[], @[r])
    let expected = optValue[DirAndFiles](dirAndFiles)
    check testMakeDirAndFiles(filename, content, expected)

    let c = newNameAndContent("afile.txt", "ls")
    check testDir(filename, @[c])

  test "file compare lines":
    let filename = "testfiles/filecomparelines.stf"
    let content = """
id stf file version 0.0.0

------ expected file1.txt == file2.txt ------
------ expected file3.txt == file4.txt ------

"""
    let a = newCompareLine("file1.txt", "file2.txt")
    let b = newCompareLine("file3.txt", "file4.txt")
    let dirAndFiles = newDirAndFiles(@[a, b], @[])
    let expected = optValue[DirAndFiles](dirAndFiles)
    check testMakeDirAndFiles(filename, content, expected)
    check testDir(filename, @[])

  test "help example":
    let filename = "testfiles/helpexample.stf"
    let content = """
id stf file version 0.0.0
# Hello World Example

# Create the script to run.
----- file cmd.sh noLastEnding command -----
../bin/statictea -t=hello.html -s=hello.json >stdout 2>stderr
----- endfile -----------------

# Create the hello.html template file without an ending newline.
--- file hello.html noLastEnding
$$ nextline
$$ hello {name}
--- endfile

--- file hello.json
{"name": "world"}
--- endfile

# Create a file with the expected output.
--- file stdout.expected noLastEnding
hello world
--- endfile

# No standard error output is expected, create an empty file.
--- file stderr.expected
--- endfile

# Compare these files.
--- expected stdout.expected == stdout
--- expected stderr.expected == stderr
"""
    # todo: rename CompareLine CompareLine
    let a = newCompareLine("stdout.expected", "stdout")
    let b = newCompareLine("stderr.expected", "stderr")
    let f1 = newRunFileLine("cmd.sh", command = true, noLastEnding = true)
    let f2 = newRunFileLine("hello.html", noLastEnding = true)
    let f3 = newRunFileLine("hello.json")
    let f4 = newRunFileLine("stdout.expected", noLastEnding = true)
    let f5 = newRunFileLine("stderr.expected")

    let dirAndFiles = newDirAndFiles(@[a, b], @[f1, f2, f3, f4, f5])
    let expected = optValue[DirAndFiles](dirAndFiles)
    check testMakeDirAndFiles(filename, content, expected)
    let cmdSh = """
../bin/statictea -t=hello.html -s=hello.json >stdout 2>stderr"""
    let d1 = newNameAndContent("cmd.sh", cmdSh)

    let helloHtml = """
$$ nextline
$$ hello {name}"""
    let d2 = newNameAndContent("hello.html", helloHtml)

    let helloJson = """
{"name": "world"}
"""
    let d3 = newNameAndContent("hello.json", helloJson)
    let d4 = newNameAndContent("stdout.expected", "hello world")
    let d5 = newNameAndContent("stderr.expected", "")
    check testDir(filename, @[d1, d2, d3, d4, d5])

  test "runCommands":

    let folder = "testfiles"
    let cmdFilename = "cmd.sh"
    let path = joinPath(folder, cmdFilename)
    createFile(path, "echo 'hello there' >t.txt")

    let r = newRunFileLine(cmdFilename, command = true, nonZeroReturn = false)
    let runFileLines = @[r]
    let rcOp = runCommands(folder, runFileLines)

    check rcOp.isValue
    check rcOp.value == 0

    # The current working directory is set to the testfiles folder.
    # t.txt file should appear in the folder.
    let tPath = joinPath(folder, "t.txt")
    check fileExists(tPath)

    discard tryRemoveFile(tPath)
    discard tryRemoveFile(path)

  test "showTabsAndLineEndings":
    check showTabsAndLineEndings("asdf") == "asdf"
    check showTabsAndLineEndings("asdf\n") == "asdf␊"
    check showTabsAndLineEndings("asdf\r\n") == "asdf␍␊"
    check showTabsAndLineEndings("	asdf") == "␉asdf"
    check showTabsAndLineEndings(" 	 asdf") == " ␉ asdf"

  test "showTabsAndLineEndings others":
    check showTabsAndLineEndings("abc\0def") == "abc\x00def"
    check showTabsAndLineEndings("abc\1def") == "abc\x01def"
    check showTabsAndLineEndings("abc\2def") == "abc\x02def"
    check showTabsAndLineEndings("abc\3def") == "abc\x03def"
    check showTabsAndLineEndings("abc\4def") == "abc\x04def"
    check showTabsAndLineEndings("abc\5def") == "abc\x05def"
    check showTabsAndLineEndings("abc\6def") == "abc\x06def"
    check showTabsAndLineEndings("abc\7def") == "abc\x07def"

  test "linesSideBySide empty":
    let content1 = ""
    let content2 = ""
    let expected = "both empty"
    check testLinesSideBySide(content1, content2, expected)

  test "linesSideBySide1":
    let content1 = """
my expected line
"""
    let content2 = """
what I got
"""
    let expected = """
1 expected: my expected line␊
1      got: what I got␊"""
    check testLinesSideBySide(content1, content2, expected)

  test "linesSideBySide2":
    let content1 = """
my expected line
my second line
"""
    let content2 = """
my expected line
what I got
"""
    let expected = """
1     same: my expected line␊
2 expected: my second line␊
2      got: what I got␊"""
    check testLinesSideBySide(content1, content2, expected)

  test "linesSideBySide3":
    let content1 = """
my expected line
middle
my last line
"""
    let content2 = """
my expected line
  the center
my last line
"""
    let expected = """
1     same: my expected line␊
2 expected: middle␊
2      got:   the center␊
3     same: my last line␊"""
    check testLinesSideBySide(content1, content2, expected)


  test "compareFiles":
    check testCompareFilesEqual("test file", "test file")
    check testCompareFilesEqual("", "")
    check testCompareFilesEqual("""
""","""
""")
    check testCompareFilesEqual("""
multi line file
test
123 5
""","""
multi line file
test
123 5
""")

  test "compareFiles different 1":
    let f1 = """
test file
"""
    let f2 = """
hello there
"""
    let expected = """

Difference: f1.txt (expected) != f2.txt (got)
1 expected: test file␊
1      got: hello there␊
"""
    check testCompareFilesDifferent(f1, f2, expected)

  test "compareFiles different 2":
    let f1 = """
test line
different line
"""
    let f2 = """
test line
wow we
"""
    let expected = """

Difference: f1.txt (expected) != f2.txt (got)
1     same: test line␊
2 expected: different line␊
2      got: wow we␊
"""
    check testCompareFilesDifferent(f1, f2, expected)

  test "compareFiles different 3":
    let f1 = """
test line
third line
more
"""
    let f2 = """
test line
something else
more
"""
    let expected = """

Difference: f1.txt (expected) != f2.txt (got)
1     same: test line␊
2 expected: third line␊
2      got: something else␊
3     same: more␊
"""
    check testCompareFilesDifferent(f1, f2, expected)

  test "compareFiles different 4":
    let f1 = ""
    let f2 = """
test line
something else
more
"""
    let expected = """

Difference: f1.txt != f2.txt
            f1.txt is empty
f2.txt───────────────────⤵
test line
something else
more
───────────────────⤴
"""
    check testCompareFilesDifferent(f1, f2, expected)

  test "compareFiles different 5":
    let f1 = """
test line
something else
more
"""
    let f2 = ""
    let expected = """

Difference: f1.txt != f2.txt
            f2.txt is empty
f1.txt───────────────────⤵
test line
something else
more
───────────────────⤴
"""
    check testCompareFilesDifferent(f1, f2, expected)

  test "compareFiles no file":
    let rcOp = compareFiles("f1", "f2")
    check rcOp.isMessage
    check rcOp.message == "cannot open: f1"
