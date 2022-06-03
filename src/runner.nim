## Standalone command to run Single Test File (stf) files.

import std/strutils
import std/os
import std/osproc
import std/options
import std/parseopt
import std/streams
import std/unicode
import std/strformat
import readlines
import regexes
import opresult

const
  switches = [
    ('h', "help"),
    ('v', "version"),
    ('f', "filename"),
    ('d', "directory"),
    ('l', "leaveTempDir"),
  ]
  runnerId* = "stf file, version 0.1.0"
    ## The first line of the stf file.

type
  RunArgs* = object
    ## RunArgs holds the command line arguments.
    help*: bool
    version*: bool
    leaveTempDir*: bool
    filename*: string
    directory*: string

  Rc* = int
    ## Rc holds a return code where 0 is success.

  RunFileLine* = object
    ## RunFileLine holds the file line options.
    filename*: string
    noLastEnding*: bool
    command*: bool
    nonZeroReturn*: bool

  ExpectedLine* = object
    ## ExpectedLine holds the expected line options.
    gotFilename*: string
    expectedFilename*: string

  LineKind* = enum
    ## The kind of line in a stf file.
    lkRunFileLine,
    lkExpectedLine,
    lkBlockLine,
    lkIdLine,
    lkCommentLine

  AnyLine* = object
    ## Contains the information about one line in a stf file.
    case kind*: LineKind
      of lkRunFileLine:
        runFileLine*: RunFileLine
      of lkExpectedLine:
        expectedLine*: ExpectedLine
      of lkBlockLine:
        blockLine*: string
      of lkIdLine:
        idLine*: string
      of lkCommentLine:
        commentLine*: string

  DirAndFiles* = object
    ## DirAndFiles holds the file and compare lines of the stf file.
    expectedLines*: seq[ExpectedLine]
    runFileLines*: seq[RunFileLine]

  OpResultStr*[T] = OpResult[T, string]
    ## On success return T, otherwise return a message telling what went wrong.

func opValueStr*[T](value: T): OpResultStr[T] =
  ## Return an OpResultStr with a value.
  result = OpResult[T, string](kind: orValue, value: value)

func opMessageStr*[T](message: string): OpResultStr[T] =
  ## Return an OpResultStr with a message why the value cannot be returned.
  result = OpResult[T, string](kind: orMessage, message: message)

func newAnyLineRunFileLine*(runFileLine: RunFileLine): AnyLine =
  ## Create a new AnyLine object for a file line.
  result = AnyLine(kind: lkRunFileLine, runFileLine: runFileLine)

func newAnyLineExpectedLine*(expectedLine: ExpectedLine): AnyLine =
  ## Create a new AnyLine object for a expected line.
  result = AnyLine(kind: lkExpectedLine, expectedLine: expectedLine)

func newAnyLineBlockLine*(blockLine: string): AnyLine =
  ## Create a new AnyLine object for a block line.
  result = AnyLine(kind: lkBlockLine, blockLine: blockLine)

func newAnyLineCommentLine*(commentLine: string): AnyLine =
  ## Create a new AnyLine object for a comment line.
  result = AnyLine(kind: lkCommentLine, commentLine: commentLine)

func newAnyLineIdLine*(idLine: string): AnyLine =
  ## Create a new AnyLine object for a id line.
  result = AnyLine(kind: lkIdLine, idLine: idLine)

func newRunArgs*(help = false, version = false, leaveTempDir = false,
    filename = "", directory = ""): RunArgs =
  ## Create a new RunArgs object.
  result = RunArgs(help: help, version: version,
    leaveTempDir: leaveTempDir, filename: filename, directory: directory)

func newRunFileLine*(filename: string, noLastEnding = false, command = false,
    nonZeroReturn = false): RunFileLine =
  ## Create a new RunFileLine object.
  result = RunFileLine(filename: filename, noLastEnding: noLastEnding,
    command: command, nonZeroReturn: nonZeroReturn)

func newExpectedLine*(gotFilename: string, expectedFilename: string): ExpectedLine =
  ## Create a new ExpectedLine object.
  result = ExpectedLine(gotFilename: gotFilename, expectedFilename: expectedFilename)

func newDirAndFiles*(expectedLines: seq[ExpectedLine],
    runFileLines: seq[RunFileLine]): DirAndFiles =
  ## Create a new DirAndFiles object.
  result = DirAndFiles(expectedLines: expectedLines,
    runFileLines: runFileLines)

func `$`*(r: ExpectedLine): string =
  ## Return a string representation of a ExpectedLine object.
  result = "expected $1 == $2" % [r.gotFilename, r.expectedFilename]

func `$`*(r: RunFileLine): string =
  ## Return a string representation of a RunFileLine object.

  var noLastEnding: string
  if r.noLastEnding:
    noLastEnding = " noLastEnding"

  var command: string
  if r.command:
    command = " command"

  var nonZeroReturn: string
  if r.nonZeroReturn:
    nonZeroReturn = " nonZeroReturn"

  result = fmt"file {r.filename}{noLastEnding}{command}{nonZeroReturn}"

proc writeErr*(message: string) =
  ## Write a message to stderr.
  stderr.writeLine(message)

func stripLineEnding(line: string): string =
  ## Strip line endings from a string.
  result = line.strip(chars={'\n', '\r'}, trailing = true)

proc createFolder*(folder: string): string =
  ## Create a folder with the given name. When the folder cannot be
  ## created return a message telling why, else return "".
  try:
    createDir(folder)
  except:
    result = getCurrentExceptionMsg()

proc deleteFolder*(folder: string): string =
  ## Delete a folder with the given name. When the folder cannot be
  ## deleted return a message telling why, else return "".
  try:
    removeDir(folder)
  except:
    result = getCurrentExceptionMsg()

when not defined(test):
  proc getHelp(): string =
    ## Return the help message and usage text.
    result = """
# Runner

Run a single test file (stf) or run all stf files in a folder.

The runner reads a stf file, creates multiple small files in a test
folder, runs files then verifies the files contain the correct data.

A stf file is designed to look good in a markdown reader. You can use
the .stf or .stf.md extention.

## Usage

runner [-h] [-v] [-l] [-f=filename] [-d=directory]

* -h --help          Show this help message.
* -v --version       Show the version number.
* -l --leaveTempDir  Leave the temp folder.
* -f --filename      Run the stf file.
* -d --directory     Run the stf files (.stf or .stf.md) in the directory.

## Processing Steps

The stf file runner processes the file tasks in the following order:

* create temp folder
* create files in the temp folder
* runs command type files
* compares files
* removes the temp folder

The temp folder is created in the same folder as the stf file using
the stf name with ".tempdir" append.

Normally the temp folder is removed after running. The -l option
leaves the folder for debugging purposes. If the temp folder exists
when running, it is deleted, then recreated, then deleted when done.

Runner returns 0 when all the tests pass. When running multiple stf
files, it displays each test run and tells how many passed and failed.

## Stf File Format

The Single Test File format is a text file made up of single line
commands.

Command line types:

1. id line
2. file lines
3. file blocks
4. expected lines
5. comment lines

### Id Line

The first line of the stf file identifies it as a stf file and tells
the version. For example:

~~~
stf file, version 0.1.0
~~~

### File Line

The file line is used to create a file. It starts with "### File "
followed by the filename then some optional attributes. A line that
starts with "### File" must be a file type line.

The general form of a file line is:

~~~
### File filename [noLineEnding] [command] [nonZeroReturn]
~~~

Example file lines:

~~~
### File server.json
### File cmd.sh command
### File result.expected noLineEnding
### File cmd.sh command nonZeroReturn
### File cmd.sh command nonZeroReturn noLineEnding
~~~

File Attributes:

* **filename** - the name of the file to create.

The name is required and cannot contain spaces. The file is created in
the temp folder.

* **command** — marks this file to be run.

All files are created before any command runs. The file is run in the
temp folder as the working directory. The commands are run in the
order specified in the file.

* **nonZeroReturn** — the command returns non-zero on success

Normally the runner fails when a command returns a non-zero return
code.  With nonZeroReturn set, it fails when it returns zero.

* **noLineEnding** — create the file without an ending newline.

### File Block Lines

The content of a file is bracketed by markdown code blocks, either
"~~~" or "```".  The block follows a file line. The first block found
is used, so you can have blocks as comments too.  All content up to the
ending code marker go in the file, even lines that look like commands.

### Expected Line

The expected line compares files. You specify two files that should be
equal.  The compares are run after running the commands. You can use
the word "empty" for in place of a filename when you expect the file
to be empty. A line that starts with "### Expected " must be an
expected line.

~~~
### Expected gotFilename == expectedFilename
~~~

Examples:

~~~
### Expected result == result.expected
### Expected t.txt == t.txt.expected
### Expected t.txt == empty
~~~

### Comments

Comments are all the other lines of the file. So it is hard to make a
syntax error.  The only possible syntax errors are with the id line,
file lines and expected lines.

"""

func letterToWord(letter: char): OpResultStr[string] =
  ## Convert the one letter switch to its long form.
  for (ch, word) in switches:
    if ch == letter:
      return opValueStr[string](word)
  let message = "Unknown switch: $1" % $letter
  result = opMessageStr[string](message)

proc handleOption(switch: string, word: string, value: string,
    runArgs: var RunArgs): string =
  ## Fill in the RunArgs object with a value from the command line.
  ## Switch is the key from the command line, either a word or a
  ## letter.  Word is the long form of the switch. If the option
  ## cannot be handle, return a message telling why, else return "".

  if word == "filename":
    if value == "":
      return "Missing filename. Use -f=filename"
    else:
      runArgs.filename = value
  elif word == "directory":
    if value == "":
      return "Missing directory name. Use -d=directory"
    else:
      runArgs.directory = value
  elif word == "help":
    runArgs.help = true
  elif word == "version":
    runArgs.version = true
  elif word == "leaveTempDir":
    runArgs.leaveTempDir = true
  else:
    return "Unknown switch."

proc parseRunCommandLine*(argv: seq[string]): OpResultStr[RunArgs] =
  ## Parse the command line arguments.

  var args: RunArgs
  var optParser = initOptParser(argv)

  # Iterate over all arguments passed to the command line.
  for kind, key, value in getopt(optParser):
    case kind
      of CmdLineKind.cmdShortOption:
        for ix in 0..key.len-1:
          let letter = key[ix]
          let wordOp = letterToWord(letter)
          if wordOp.isMessage:
            return opMessageStr[RunArgs](wordOp.message)
          let message = handleOption($letter, wordOp.value, value, args)
          if message != "":
            return opMessageStr[RunArgs](message)

      of CmdLineKind.cmdLongOption:
        let message = handleOption(key, key, value, args)
        if message != "":
          return opMessageStr[RunArgs](message)

      of CmdLineKind.cmdArgument:
        return opMessageStr[RunArgs]("Unknown switch: $1" % [key])

      of CmdLineKind.cmdEnd:
        discard

  result = opValueStr[RunArgs](args)

proc isRunFileLine*(line: string): bool =
  ## Return true when the line is a file line.
  let pattern = r"^### File "
  let matchesO = matchPatternCached(line, pattern, 0, 0)
  result = matchesO.isSome

proc isExpectedLine*(line: string): bool =
  ## Return true when the line is an expected line.
  let pattern = r"^### Expected "
  let matchesO = matchPatternCached(line, pattern, 0, 0)
  result = matchesO.isSome

proc parseRunFileLine*(line: string): OpResultStr[RunFileLine] =
  ## Parse a file command line.

  let pattern = r"^### File ([^\s]+)(.*)$"

  let matchesO = matchPatternCached(line, pattern, 0, 2)
  if not matchesO.isSome:
    return opMessageStr[RunFileLine]("Invalid file line: $1" % [line])

  let (filename, attrs) = matchesO.get2Groups()
  let attributes = attrs.split(" ")

  var noLastEnding, command, nonZeroReturn: bool
  for attr in attributes:
    let attribute = strutils.strip(attr, trailing = true)
    case attribute:
      of "noLastEnding":
        noLastEnding = true
      of "command":
        command = true
      of "nonZeroReturn":
        nonZeroReturn = true
      else:
        discard

  let runFileLine = newRunFileLine(filename, noLastEnding, command, nonZeroReturn)
  result = opValueStr[RunFileLine](runFileLine)

proc parseExpectedLine*(line: string): OpResultStr[ExpectedLine] =
  ## Parse an expected line.
  # # Expected stdout.expected == stdout
  let pattern = r"^### Expected ([^\s]+) == ([^\s]+)[\s]*$"

  let matchesO = matchPatternCached(line, pattern, 0, 2)
  if not matchesO.isSome:
    return opMessageStr[ExpectedLine]("Invalid expected line: $1" % [line])

  let (gotFilename, expectedFilename) = matchesO.get2Groups()
  let expectedEqual = newExpectedLine(gotFilename, expectedFilename)
  result = opValueStr[ExpectedLine](expectedEqual)

proc openNewFile*(folder: string, filename: string): OpResultStr[File] =
  ## Create a new file in the given folder and return an open File
  ## object.

  var path = joinPath(folder, filename)
  if fileExists(path):
    return opMessageStr[File]("File already exists: $1" % [path])

  var file: File
  if not open(file, path, fmWrite):
    let message = "Unable to create the file: $1" % [path]
    return opMessageStr[File](message)

  result = opValueStr[File](file)

proc getAnyLine*(line: string): OpResultStr[AnyLine] =
  ## Return information about the stf line.

  if line == runnerId:
    return opValueStr(AnyLine(kind: lkIdLine, idLine: line))

  if line.startsWith("~~~")  or line.startsWith("```"):
    return opValueStr(AnyLine(kind: lkBlockLine, blockLine: line))

  if isRunFileLine(line):
    let runFileLineOp = parseRunFileLine(line)
    if runFileLineOp.isValue:
      return opValueStr(newAnyLineRunFileLine(runFileLineOp.value))
    else:
      return opMessageStr[AnyLine](runFileLineOp.message)

  if isExpectedLine(line):
    let expectedEqualOp = parseExpectedLine(line)
    if expectedEqualOp.isValue:
      return opValueStr(AnyLine(kind: lkExpectedLine, expectedLine: expectedEqualOp.value))
    else:
      return opMessageStr[AnyLine](expectedEqualOp.message)

  result = opValueStr(AnyLine(kind: lkCommentLine, commentLine: line))

proc createSectionFile(lb: var LineBuffer, folder: string,
    runFileLine: RunFileLine): string =
  ## Create a file from lines in the stf file. Read starting at the
  ## current position until the start block line is found, then read
  ## the file lines until the matching end block is found.  Return a
  ## message when the file cannot be created, else return "".

  # Open a new file in the given folder.
  let filename = runFileLine.filename
  let noLastEnding = runFileLine.noLastEnding
  var fileOp = openNewFile(folder, filename)
  if fileOp.isMessage:
    return fileOp.message
  var file = fileOp.value

  # Look for the starting block line.
  var line: string
  var blockLine: string
  var lineNum = 0
  while true:
    line = readlines.readline(lb)
    if line == "":
      # The start block was missing. Close and delete the new file.
      file.close()
      let path = joinPath(folder, filename)
      discard tryRemoveFile(path)
      return "The start block line was missing."
    inc(lineNum)
    let anyLineOr = getAnyLine(line)
    if anyLineOr.isMessage:
      return fmt"{lineNum}: {anyLineOr.message}"
    let anyLine = anyLineOr.value
    if anyLine.kind == lkBlockLine:
      blockLine = anyLine.blockLine
      break

  # Write lines until the next endblock line is found.
  var previousLine: string
  var firstLine = true
  while true:
    line = readlines.readline(lb)
    if line == "":
      # The end block was missing. Close and delete the new file.
      file.close()
      let path = joinPath(folder, filename)
      discard tryRemoveFile(path)
      return "The end block line was missing."
    let anyLineOr = getAnyLine(line)
    if anyLineOr.isMessage:
      return fmt"{lineNum}: {anyLineOr.message}"
    let anyLine = anyLineOr.value
    if anyLine.kind == lkBlockLine and anyLine.blockLine == blockLine:
      break

    # Write the previous line to the file.
    if not firstLine:
      file.write(previousLine)
    previousLine = line
    firstLine = false

  # Write the last line.
  if noLastEnding:
    previousLine = previousLine.stripLineEnding()
  file.write(previousLine)

  # Close the new file.
  file.close()

proc makeDirAndFiles*(filename: string): OpResultStr[DirAndFiles] =
  ## Read the stf file and create its temp folder and files. Return the
  ## file lines and expected lines.

  var expectedLines = newSeq[ExpectedLine]()
  var runFileLines = newSeq[RunFileLine]()

  # Make sure the file exists.
  if not fileExists(filename):
    return opMessageStr[DirAndFiles]("File not found: '$1'." % [filename])

  # Open the file for reading.
  let stream = newFileStream(filename, fmRead)
  if stream == nil:
    return opMessageStr[DirAndFiles]("Unable to open file: '$1'." % [filename])
  defer:
    stream.close()

  # Create a temp folder next to the stf file. Remove it first if it
  # already exists.
  let tempDirName = filename & ".tempdir"
  if dirExists(tempDirName):
    removeDir(tempDirName)
  let message = createFolder(tempDirName)
  if message != "":
    return opMessageStr[DirAndFiles](message)

  # Allocate a buffer for reading lines.
  var lineBufferO = newLineBuffer(stream, filename = filename)
  if not lineBufferO.isSome():
    return opMessageStr[DirAndFiles]("Unable to allocate a line buffer.")
  var lb = lineBufferO.get()

  # Check the file type is supported. The first line contains the type
  # and version number.
  var line = readlines.readline(lb)
  if line == "":
    return opMessageStr[DirAndFiles]("Empty file: '$1'." % filename)
  if not line.startsWith(runnerId):
    let message = """Invalid stf file first line:
     got: $1
expected: $2""" % [line, runnerId]
    return opMessageStr[DirAndFiles](message)

  while true:
    # Read a line from the stf file.
    line = readlines.readline(lb)
    if line == "":
      break # No more lines.
    let anyLineOr = getAnyLine(line)
    if anyLineOr.isMessage:
      return opMessageStr[DirAndFiles](anyLineOr.message)
    let anyLine = anyLineOr.value
    case anyLine.kind
    of lkRunFileLine:
      # Create a new file.
      let runFileLine = anyLine.runFileLine
      runFileLines.add(runFileLine)
      let message = createSectionFile(lb, tempDirName, runFileLine)
      if message != "":
        return opMessageStr[DirAndFiles](message)
    of lkExpectedLine:
      # Remember the expected filenames to compare.
      expectedLines.add(anyLine.expectedLine)
    else:
      discard

  if runFileLines.len == 0:
    return opMessageStr[DirAndFiles]("No files run.")

  # if expectedLines.len == 0:
  #   return opMessageStr[DirAndFiles]("No expected lines.")

  let dirAndFiles = newDirAndFiles(expectedLines, runFileLines)
  result = opValueStr[DirAndFiles](dirAndFiles)

proc runCommands*(folder: string, runFileLines: seq[RunFileLine]):
    int =
  ## Run the command files and return 0 when they all returned their
  ## expected return code.

  # Set the working directory to the folder.
  assert(dirExists(folder))
  let oldDir = getCurrentDir()
  setCurrentDir(folder)

  # Run each command file.
  for runFileLine in runFileLines:
    if runFileLine.command:
      # Make the file executable.
      setFilePermissions(runFileLine.filename, {fpUserExec, fpUserRead, fpUserWrite})

      # Run the file and return the return code.
      let localFile = "./" & runFileLine.filename
      let cmdRc = execCmd(localFile)

      # Check the return code.
      if runFileLine.nonZeroReturn:
        if cmdRc == 0:
          echo "$1 generated an unexpected return code of 0." %
            runFileLine.filename
          result = 1
      elif cmdRc != 0:
        echo "$1 generated a non-zero return code." %
          runFileLine.filename
        result = 1

  setCurrentDir(oldDir)

func showTabsAndLineEndings*(str: string): string =
  ## Return a new string with the tab and line endings visible.

  var visibleRunes = newSeq[Rune]()
  for rune in runes(str):
    var num = uint(rune)
    # Show a special glyph for tab, carrage return and line feed.
    if num == 9 or num == 10 or num == 13:
      num = 0x00002400 + num
    visibleRunes.add(Rune(num))
  result = $visibleRunes

when false:
  proc dup(pattern: string, count: Natural): string =
    ## Duplicate the pattern count times. Return "" when the result
    ## would be longer than 1024 characters.
    if count < 1:
      return
    let length = count * pattern.len
    if length > 1024:
      return
    result = newStringOfCap(length)
    for ix in countUp(1, int(count)):
      result.add(pattern)

proc linesSideBySide*(gotContent: string, expectedContent: string): string =
  ## Show the two sets of lines side by side.

  if gotContent == "" and expectedContent == "":
     return "both empty"

  let got = splitNewLines(gotContent)
  let expected = splitNewLines(expectedContent)

  var show = showTabsAndLineEndings

  var lines: seq[string]
  for ix in countUp(0, max(got.len, expected.len)-1):
    var gLine = ""
    if ix < got.len:
      gLine = $got[ix]

    var eLine = ""
    if ix < expected.len:
      eLine = $expected[ix]

    var lineNum = $(ix+1)
    if eLine == gLine:
      # lines.add("$1     same: $2" % [dup(" ", lineNum.len), show(eLine)])
      lines.add("$1     same: $2" % [$lineNum, show(eLine)])
    else:
      lines.add("$1      got: $2" % [lineNum, show(gLine)])
      lines.add("$1 expected: $2" % [lineNum, show(eLine)])

  result = lines.join("\n")

proc readFileContent(filename: string): OpResultStr[string] =
  ## Read the file and return the content as a string.
  try:
    let content = readFile(filename)
    result = opValueStr[string](content)
  except:
    result = opMessageStr[string](getCurrentExceptionMsg())

proc compareFiles*(gotFilename: string, expectedFilename: string): OpResultStr[string] =
  ## Compare two files and return the differences. When they are equal
  ## return "".

  let (_, gotBasename) = splitPath(gotFilename)
  let (_, expBasename) = splitPath(expectedFilename)

  # Read the "got" file.
  var gotContent: string
  if gotBasename == "empty":
    gotContent = ""
  else:
    let gotContentOp = readFileContent(gotFilename)
    if gotContentOp.isMessage:
      return opMessageStr[string]("Error: " & gotContentOp.message)
    gotContent = gotContentOp.value

  # Read the "expected" file.
  var expectedContent: string
  if expBasename == "empty":
    expectedContent = ""
  else:
    let expectedContentOp = readFileContent(expectedFilename)
    if expectedContentOp.isMessage:
      return opMessageStr[string]("Error: " & expectedContentOp.message)
    expectedContent = expectedContentOp.value

  #  ⤶ ⤷ ⤴ ⤵
  # ⬉ ⬈ ⬊ ⬋
  let topBorder    = "───────────────────⤵\n"
  let bottomBorder = "───────────────────⤴"


# Difference: result.expected != result.txt
#             result.expected is empty
# result.txt───────────────────⤵
# Log the replacement block.
# Log the replacement block containing a variable.
# Log the replacement block two times.
# Log the nextline replacement block.
# Log the replace command's replacement block.
# ───────────────────⤴


  # If the files are different, show the differences.
  var message: string
  if gotContent != expectedContent:
    let (_, gotBasename) = splitPath(gotFilename)
    let (_, expBasename) = splitPath(expectedFilename)

    if gotContent == "" or expectedContent == "":
      if gotContent == "":
        message = """

Difference: $1 != $2
            $1 is empty
$2$3$4$5
""" % [gotBasename, expBasename, topBorder, expectedContent, bottomBorder]

      else:

        message = """

Difference: $1 != $2
            $2 is empty
$1$3$4$5
""" % [gotBasename, expBasename, topBorder, gotContent, bottomBorder]

    else:
      message = """

Difference: $1 (got) != $2 (expected)
$3
""" % [gotBasename, expBasename, linesSideBySide(gotContent, expectedContent)]

  return opValueStr[string](message)

proc compareFileSets(folder: string, expectedLines: seq[ExpectedLine]):
    int =
  ## Compare multiple pairs of files and show the differences. When
  ## they are all the same return 0.

  for expectedLine in expectedLines:
    var gotPath = joinPath(folder, expectedLine.gotFilename)
    var expectedPath = joinPath(folder, expectedLine.expectedFilename)

    # Compare the two files.
    let stringOp = compareFiles(gotPath, expectedPath)

    if stringOp.isMessage:
      # Show the error.
      echo stringOp.message
      result = 1
    else:
      # Show the differences, if any.
      let differences = stringOp.value
      if differences != "":
        echo differences
        result = 1

proc runStfFilename*(filename: string): int =
  ## Run the stf file and leave the temp dir. Return 0 when all the
  ## tests passed.

  # Create the temp folder and files inside it.
  let dirAndFilesOp = makeDirAndFiles(filename)
  if dirAndFilesOp.isMessage:
    echo dirAndFilesOp.message
    return 1
  let dirAndFiles = dirAndFilesOp.value

  let folder = filename & ".tempdir"

  # Run the command files.
  result = runCommands(folder, dirAndFiles.runFileLines)
  if result != 0:
    return result

  # Compare the files.
  result = compareFileSets(folder, dirAndFiles.expectedLines)

when not defined(test):

  proc runFilename(filename: string, leaveTempDir: bool): int =
    ## Run the stf file and optionally leave the temp dir. Return 0 when
    ## all the tests pass.

    result = runStfFilename(filename)

    # Remove the temp folder unless leave is specified.
    let tempDir = filename & ".tempdir"
    if leaveTempDir:
      echo "Leaving temp dir: " & tempDir
    else:
      if fileExists(filename):
        discard deleteFolder(tempDir)

  proc runFilenameMain(args: RunArgs): int =
    ## Run a stf file specified by a RunArgs object. Return 0 when it
    ## passes.
    result = runFilename(args.filename, args.leaveTempDir)

  proc runDirectory(dir: string, leaveTempDir: bool): int =
    ## Run all the stf files in the specified directory. Return 0 when
    ## they all pass. Show progess and count of passed and failed.

    if not dirExists(dir):
      echo "The dir does not exist: " & dir
      return 1

    var failedTests: seq[string]
    var count = 0
    var passedCount = 0
    for kind, path in walkDir(dir):
      if path.endsWith(".stf") or ".stf." in path:
        let (_, basename) = splitPath(path)
        echo "Running: " & basename

        let runRc = runFilename(path, leaveTempDir)
        if runRc == 0:
          inc(passedCount)
        else:
          failedTests.add(path)
          result = 1
        inc(count)

    if count == passedCount:
      echo "All $1 tests passed!" % $passedCount
    else:
      echo "$1 Passed, $2 Failed\n" % [
        $passedCount, $(count - passedCount)]
      for failedTest in failedTests:
        echo failedTest

  proc runDirectoryMain(args: RunArgs): int =
    ## Run all stf files in a directory. Return 0 when all pass.
    result = runDirectory(args.directory, args.leaveTempDir)

  proc processRunArgs(args: RunArgs): int =
    ## Run what was specified on the command line. Return 0 when
    ## successful.

    if args.help:
      echo getHelp()
    elif args.version:
      echo runnerId
    elif args.filename != "":
      result = runFilenameMain(args)
    elif args.directory != "":
      result = runDirectoryMain(args)
    else:
      echo "Missing argments, use -h for help."
      result = 1

  proc main(argv: seq[string]): int =
    ## Run stf test files. Return 0 when all the tests pass and 1 when
    ## one or more fail.

    # Setup control-c monitoring so ctrl-c stops the program.
    proc controlCHandler() {.noconv.} =
      quit 0
    setControlCHook(controlCHandler)

    try:
      # Parse the command line options.
      let argsOp = parseRunCommandLine(argv)
      if argsOp.isMessage:
        return 1
      let args = argsOp.value
      result = processRunArgs(args)
    except:
      echo "Unexpected exception: $1" % [getCurrentExceptionMsg()]
      # The stack trace is only available in the debug builds.
      when not defined(release):
        echo message & "\n" & getCurrentException().getStackTrace()
      result = 1

when isMainModule:
  let rc = main(commandLineParams())
  if rc == 0:
    quit(QuitSuccess)
  else:
    quit(QuitFailure)
