## Standalone command to run Single Test File (stf) files.

import std/strutils
import std/os
import std/osproc
import std/options
import std/parseopt
import std/streams
import std/unicode
import std/strformat
when isMainModule:
  import std/os
import readlines
import regexes

const
  switches = [
    ('h', "help"),
    ('v', "version"),
    ('f', "filename"),
    ('d', "directory"),
    ('l', "leaveTempDir"),
  ]
  runnerId = "id stf file version 0.0.0"
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

  CompareLine* = object
    ## CompareLine holds the expected line options.
    filename1*: string
    filename2*: string

  DirAndFiles* = object
    ## DirAndFiles holds the file and compare lines of the stf file.
    compareLines*: seq[CompareLine]
    runFileLines*: seq[RunFileLine]

  OpResultKind* = enum
    ## The kind of OpResult object, either a value or message.
    okValue,
    okMessage

  OpResult*[T] = object
    ## Contains either a value or a message string. The default is a
    ## value. It's similar to the Option type but instead of returning
    ## nothing, you return a message that tells why you cannot return
    ## the value.
    case kind*: OpResultKind
      of okValue:
        value*: T
      of okMessage:
        message*: string

func isMessage*(opResult: OpResult): bool =
  ## Return true when the OpResult object contains a message.
  if opResult.kind == okMessage:
    result = true

func isValue*(opResult: OpResult): bool =
  ## Return true when the OpResult object contains a value.
  if opResult.kind == okValue:
    result = true

func opValue[T](value: T): OpResult[T] =
  ## Create an OpResult value object.
  return OpResult[T](kind: okValue, value: value)

func opMessage[T](message: string): OpResult[T] =
  ## Create an OpResult message object.
  return OpResult[T](kind: okMessage, message: message)

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

func newCompareLine*(filename1: string, filename2: string): CompareLine =
  ## Create a new CompareLine object.
  result = CompareLine(filename1: filename1, filename2: filename2)

func newDirAndFiles*(compareLines: seq[CompareLine],
    runFileLines: seq[RunFileLine]): DirAndFiles =
  ## Create a new DirAndFiles object.
  result = DirAndFiles(compareLines: compareLines,
    runFileLines: runFileLines)

func `$`*(opResult: OpResult): string =
  ## Return a string representation of an OpResult object.
  if opResult.kind == okValue:
    result = "okValue: $1" % $opResult.value
  else:
    result = "okMessage: $1" % opResult.message

func `$`*(r: CompareLine): string =
  ## Return a string representation of a CompareLine object.
  result = "expected $1 == $2" % [r.filename1, r.filename2]

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

# proc writeOut*(message: string) =
#   ## Write a message to stdout.
#   stdout.writeLine(message)

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
folder, runs commands then verifies the correct output.

## Usage

runner [-h] [-v] [-l] [-f=filename] [-d=directory]

* -h --help          Show this help message.
* -v --version       Show the version number.
* -l --leaveTempDir  Leave the temp folder.
* -f --filename      Run the stf file.
* -d --directory     Run the stf files in the directory.

## Processing Order

The stf file processing order:

* temp folder created
* files created in the tempdir
* commands run
* files compared
* temp folder removed

The temp folder is created in the same folder as the stf using the stf
name with ".tempdir" append.

Normally the temp folder is removed after running, the -l option
leaves it. If the temp folder exists, it is deleted then recreated.

Runner returns 0 when all the tests pass. When running multiple it
displays each test run and tells how many passed and failed.

## Stf File Format

The Single Test File format is a text file made up of single line
commands:

1. id
2. comment and blank lines
3. file
4. endfile
5. expected

You can add spaces, tabs and dashes at the beginning and end of the
command lines, except the id and comment lines.

### Id Command

The first line of the stf file identifies it as a stf file.  The id
ends with the version number. Here is the id:

~~~
id stf file version 0.0.0
~~~

### Comment Command

Comments start with # as the first character of the line. Blank lines
are ignored.

### File Command

The file command is used to create a file. It begins with “file”
followed by the filename then some optional attributes.  The general
form is:

~~~
file filename [noLineEnding] [command] [nonZeroReturn]
~~~

File Options:

* *filename* - the name of the file to create.

The file is created in the temp folder. No spaces in the name.

* *command* — marks this file to be run.

All files are created before the commands run. The file is run in the
temp folder as the working directory. The commands are run in the
order specified in the file.

* *nonZeroReturn* — non-zero return code.

Normally the runner fails when a command returns a non-zero return
code.  With nonZeroReturn set, it fails when it returns zero.

* *noLineEnding* — create the file without an ending newline.

### Endfile Command

The endfile command line follows a file line and it brackets the lines
of the file to be created. All these lines go in the file, even ones
that look like commands.

### Expected Command

The expected line compares files. You specify two files that should be
equal.  The compares are run after running the commands.

~~~
expected filename1 == filename2
~~~

## Example Stf File

The following example stf file instructs the runner to create the
files cmd.sh, hello.html, hello.json, stdout-expected and
stderr-expected.  It then runs cmd.sh looking for a 0 return
code. Then it compares the output files with their expected output.

~~~
id stf file version 0.0.0
# Hello World Example

# Create the cmd.sh script.
--- file cmd.sh command
../bin/statictea -t=hello.html -s=hello.json >stdout 2>stderr
--- endfile

# Create hello.html without an ending newline.
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

# No standard error output is expected.
--- file stderr.expected
--- endfile

# Compare these files are equal.
--- expected stdout.expected == stdout
--- expected stderr.expected == stderr
~~~
"""

func letterToWord(letter: char): OpResult[string] =
  ## Convert the one letter switch to its long form.
  for (ch, word) in switches:
    if ch == letter:
      return opValue[string](word)
  let message = "Unknown switch: $1" % $letter
  result = opMessage[string](message)

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

proc parseRunCommandLine*(argv: seq[string]): OpResult[RunArgs] =
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
            return opMessage[RunArgs](wordOp.message)
          let message = handleOption($letter, wordOp.value, value, args)
          if message != "":
            return opMessage[RunArgs](message)

      of CmdLineKind.cmdLongOption:
        let message = handleOption(key, key, value, args)
        if message != "":
          return opMessage[RunArgs](message)

      of CmdLineKind.cmdArgument:
        return opMessage[RunArgs]("Unknown switch: $1" % [key])

      of CmdLineKind.cmdEnd:
        discard

  result = opValue[RunArgs](args)

func makeBool*(item: string): bool =
  ## Return false when the string is empty, else return true.
  if item == "":
    result = false
  else:
    result = true

proc parseRunFileLine*(line: string): OpResult[RunFileLine] =
  ## Parse a file command line.
  # todo: The optional elements must be specified in order.
  # --- file hello.html noLastEnding command nonZeroReturn
  let pattern = r"^[-\s]*file[-\s]+([^-\s]+)(?:[-\s]+(noLastEnding)){0,1}(?:[-\s]+(command)){0,1}(?:[-\s]+(nonZeroReturn)){0,1}[-\s]*$"

  let matchesO = matchPatternCached(line, pattern, 0)
  if not matchesO.isSome:
    return opMessage[RunFileLine]("Invalid file line: $1" % [line])

  let matches = matchesO.get()
  let groups = matches.getGroups(4)
  let filename = groups[0]
  let noLastEnding = makeBool(groups[1])
  let command = makeBool(groups[2])
  let nonZeroReturn = makeBool(groups[3])

  let fileLine = newRunFileLine(filename, noLastEnding, command, nonZeroReturn)
  result = opValue[RunFileLine](fileLine)

proc parseExpectedLine*(line: string): OpResult[CompareLine] =
  ## Parse an expected line.
  #--- expected stdout.expected == stdout
  let pattern = r"^[-\s]*expected[-\s]+([^-\s]+)[-\s]*==[-\s]*([^-\s]+)[-\s]*$"
  let matchesO = matchPatternCached(line, pattern, 0)
  if not matchesO.isSome:
    return opMessage[CompareLine]("Invalid expected line: $1" % [line])

  let matches = matchesO.get()
  let (filename1, filename2) = matches.get2Groups()
  let expectedEqual = newCompareLine(filename1, filename2)
  result = opValue[CompareLine](expectedEqual)

proc openNewFile*(folder: string, filename: string): OpResult[File] =
  ## Create a new file in the given folder and return an open File
  ## object.

  var path = joinPath(folder, filename)
  if fileExists(path):
    return opMessage[File]("File already exists: $1" % [path])

  var file: File
  if not open(file, path, fmWrite):
    let message = "Unable to create the file: $1" % [path]
    return opMessage[File](message)

  result = opValue[File](file)

proc getCmd*(line: string): string =
  ## Return the type of line, either: #, "", id, file, expected,
  ## endfile or other.
  if line.startswith("#"):
    result = "#"
  # todo ignore pure whitespace lines.
  elif line == "\n":
    result = ""
  elif line == "\r\n":
    result = ""
  else:
    let pattern = r"^[- ]*(id|file|expected|endfile)"
    let matchesO = matchPatternCached(line, pattern, 0)
    if not matchesO.isSome:
      result = "other"
    else:
      let matches = matchesO.get()
      result = matches.getGroup()

proc createSectionFile(lb: var LineBuffer, folder: string,
    runFileLine: RunFileLine): string =
  ## Create a file from lines in the stf file starting at the current
  ## position until the endfile line is found.  Return a message when
  ## the file cannot be created, else return "".

  # Open a new file in the given folder.
  let filename = runFileLine.filename
  let noLastEnding = runFileLine.noLastEnding
  var fileOp = openNewFile(folder, filename)
  if fileOp.isMessage:
    return fileOp.message
  var file = fileOp.value

  # Write lines until the next endfile is found.
  var line: string
  var previousLine: string
  var firstLine = true
  while true:
    line = readlines.readline(lb)
    if line == "":
      # The end file was missing. Close and delete the new file.
      file.close()
      let path = joinPath(folder, filename)
      discard tryRemoveFile(path)
      return "The endfile line was missing."
    let cmd = getCmd(line)
    if cmd == "endfile":
      break # Done

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

proc makeDirAndFiles*(filename: string): OpResult[DirAndFiles] =
  ## Read the stf file and create its temp folder and files. Return the
  ## file lines and expected lines.

  var compareLines = newSeq[CompareLine]()
  var runFileLines = newSeq[RunFileLine]()

  # Make sure the file exists.
  if not fileExists(filename):
    return opMessage[DirAndFiles]("File not found: '$1'." % [filename])

  # Open the file for reading.
  let stream = newFileStream(filename, fmRead)
  if stream == nil:
    return opMessage[DirAndFiles]("Unable to open file: '$1'." % [filename])
  defer:
    stream.close()

  # Create a temp folder next to the stf file. Remove it first if it
  # already exists.
  let tempDirName = filename & ".tempdir"
  if dirExists(tempDirName):
    removeDir(tempDirName)
  let message = createFolder(tempDirName)
  if message != "":
    return opMessage[DirAndFiles](message)

  # Allocate a buffer for reading lines.
  var lineBufferO = newLineBuffer(stream, filename = filename)
  if not lineBufferO.isSome():
    return opMessage[DirAndFiles]("Unable to allocate a line buffer.")
  var lb = lineBufferO.get()

  # Check the file type is supported. The first line contains the type
  # and version number.
  var line = readlines.readline(lb)
  if line == "":
    return opMessage[DirAndFiles]("Empty file: '$1'." % filename)
  if not line.startsWith(runnerId):
    let message = """Invalid stf file first line:
expected: $1
     got: $2""" % [runnerId, line]
    return opMessage[DirAndFiles](message)

  while true:
    # Read a line from the stf file.
    line = readlines.readline(lb)
    if line == "":
      break # No more lines.
    let cmd = getCmd(line)
    case cmd
    of "#", "":
      discard
    of "file":
      # Create a new file.
      let fileLineOp = parseRunFileLine(line)
      if fileLineOp.isMessage:
        return opMessage[DirAndFiles](fileLineOp.message)
      let fileLine = fileLineOp.value
      runFileLines.add(fileLine)
      let message = createSectionFile(lb, tempDirName, fileLine)
      if message != "":
        return opMessage[DirAndFiles](message)

    of "expected":
      # Remember the expected filenames to compare.
      let expectedEqualOp = parseExpectedLine(line)
      if expectedEqualOp.isMessage:
        return opMessage[DirAndFiles](expectedEqualOp.message)
      compareLines.add(expectedEqualOp.value)
    else:
      let message = "Unknown line: '$1'." % stripLineEnding(line)
      return opMessage[DirAndFiles](message)

  let dirAndFiles = newDirAndFiles(compareLines, runFileLines)
  result = opValue[DirAndFiles](dirAndFiles)

proc runCommands*(folder: string, runFileLines: seq[RunFileLine]):
    OpResult[Rc] =
  ## Run the command files and return 0 when they all returned their
  ## expected return code.

  # Set the working directory to the folder.
  assert(dirExists(folder))
  let oldDir = getCurrentDir()
  setCurrentDir(folder)

  var rc = 0

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
          let message = "$1 generated an unexpected return code of 0." %
            runFileLine.filename
          return opMessage[Rc](message)
      elif cmdRc != 0:
        let message =  "$1 generated a non-zero return code." %
          runFileLine.filename
        return opMessage[Rc](message)

  setCurrentDir(oldDir)

  result = opValue[Rc](rc)

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

proc linesSideBySide*(expectedContent: string, gotContent: string): string =
  ## Show the two sets of lines side by side.

  if expectedContent == "" and gotContent == "":
     return "both empty"

  let expected = splitNewLines(expectedContent)
  let got = splitNewLines(gotContent)

  var show = showTabsAndLineEndings

  var lines: seq[string]
  for ix in countUp(0, max(expected.len, got.len)-1):
    var eLine = ""
    if ix < expected.len:
      eLine = $expected[ix]

    var gLine = ""
    if ix < got.len:
      gLine = $got[ix]

    var lineNum = $(ix+1)
    if eLine == gLine:
      # lines.add("$1     same: $2" % [dup(" ", lineNum.len), show(eLine)])
      lines.add("$1     same: $2" % [$lineNum, show(eLine)])
    else:
      lines.add("$1 expected: $2" % [lineNum, show(eLine)])
      lines.add("$1      got: $2" % [lineNum, show(gLine)])

  result = lines.join("\n")

proc readFileContent(filename: string): OpResult[string] =
  ## Read the file and return the content as a string.
  try:
    let content = readFile(filename)
    result = opValue[string](content)
  except:
    result = opMessage[string](getCurrentExceptionMsg())

proc compareFiles*(expectedFilename: string, gotFilename: string): OpResult[string] =
  ## Compare two files and return the differences. When they are equal
  ## return "".

  # Read the "expected" file.
  let expectedContentOp = readFileContent(expectedFilename)
  if expectedContentOp.isMessage:
    return opMessage[string](expectedContentOp.message)
  let expectedContent = expectedContentOp.value

  # Read the "got" file.
  let gotContentOp = readFileContent(gotFilename)
  if gotContentOp.isMessage:
    return opMessage[string](gotContentOp.message)
  let gotContent = gotContentOp.value

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
  if expectedContent != gotContent:
    let (_, expBasename) = splitPath(expectedFilename)
    let (_, gotBasename) = splitPath(gotFilename)

    if expectedContent == "" or gotContent == "":
      if expectedContent == "":
        message = """

Difference: $1 != $2
            $1 is empty
$2$3$4$5
""" % [expBasename, gotBasename, topBorder, gotContent, bottomBorder]

      else:

        message = """

Difference: $1 != $2
            $2 is empty
$1$3$4$5
""" % [expBasename, gotBasename, topBorder, expectedContent, bottomBorder]

    else:
      message = """

Difference: $1 (expected) != $2 (got)
$3
""" % [expBasename, gotBasename, linesSideBySide(expectedContent, gotContent)]

  return OpResult[string](kind: okValue, value: message)

proc compareFileSets(folder: string, compareLines: seq[CompareLine]):
    OpResult[Rc] =
  ## Compare multiple pairs of files and show the differences. When
  ## they are all the same return 0.

  var rc = 0
  for compareLine in compareLines:
    var path1 = joinPath(folder, compareLine.filename1)
    var path2 = joinPath(folder, compareLine.filename2)

    # Compare the two files.
    let stringOp = compareFiles(path1, path2)

    if stringOp.isMessage:
      # Show the error.
      echo stringOp.message
      rc = 1
    else:
      # Show the differences, if any.
      let differences = stringOp.value
      if differences != "":
        echo differences
        rc = 1

  result = OpResult[Rc](kind: okValue, value: rc)

proc runStfFilename*(filename: string): OpResult[Rc] =
  ## Run the stf file and leave the temp dir. Return 0 when all the
  ## tests passed.

  # Create the temp folder and files inside it.
  let dirAndFilesOp = makeDirAndFiles(filename)
  if dirAndFilesOp.isMessage:
    return opMessage[Rc](dirAndFilesOp.message)
  let dirAndFiles = dirAndFilesOp.value

  let folder = filename & ".tempdir"

  # Run the command files.
  var rcOp = runCommands(folder, dirAndFiles.runFileLines)
  if rcOp.isMessage:
    return rcOp
  result = rcOp

  # Compare the files.
  rcOp = compareFileSets(folder, dirAndFiles.compareLines)
  if rcOp.isMessage:
    return rcOp
  if rcOp.value != 0:
    result = rcOp

when not defined(test):

  proc runFilename(filename: string, leaveTempDir: bool): OpResult[Rc] =
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

  proc runFilename(args: RunArgs): OpResult[Rc] =
    ## Run a stf file specified by a RunArgs object. Return 0 when it
    ## passes.
    result = runFilename(args.filename, args.leaveTempDir)

  proc runDirectory(dir: string, leaveTempDir: bool): OpResult[Rc] =
    ## Run all the stf files in the specified directory. Return 0 when
    ## they all pass. Show progess and count of passed and failed.

    if not dirExists(dir):
      let message = "The dir does not exist: " & dir
      return opMessage[Rc](message)

    var count = 0
    var passedCount = 0
    var rc = 0
    for kind, path in walkDir(dir):
      if path.endsWith(".stf"):
        let (_, basename) = splitPath(path)
        echo "Running: " & basename
        let rcOp = runFilename(path, leaveTempDir)
        if rcOp.isMessage:
          return rcOp
        if rcOp.value == 0:
          inc(passedCount)
        else:
          rc = 1
        inc(count)

    if count == passedCount:
      echo "All $1 tests passed!" % $passedCount
    else:
      echo "$1 passed, $2 failed\n" % [
        $passedCount, $(count - passedCount)]
    result = OpResult[Rc](kind: okValue, value: rc)

  proc runDirectory(args: RunArgs): OpResult[Rc] =
    ## Run all stf files in a directory. Return 0 when all pass.
    result = runDirectory(args.directory, args.leaveTempDir)

  proc processRunArgs(args: RunArgs): OpResult[Rc] =
    ## Run what was specified on the command line. Return 0 when
    ## successful.

    if args.help:
      echo getHelp()
      result = OpResult[Rc](kind: okValue, value: 0)
    elif args.version:
      echo runnerId
      result = OpResult[Rc](kind: okValue, value: 0)
    elif args.filename != "":
      result = runFilename(args)
    elif args.directory != "":
      result = runDirectory(args)
    else:
      echo "Missing argments, use -h for help."
      result = OpResult[Rc](kind: okValue, value: 1)

  proc main(argv: seq[string]): OpResult[Rc] =
    ## Run stf test files. Return 0 when successful.

    # Setup control-c monitoring so ctrl-c stops the program.
    proc controlCHandler() {.noconv.} =
      quit 0
    setControlCHook(controlCHandler)

    try:
      # Parse the command line options.
      let argsOp = parseRunCommandLine(argv)
      if argsOp.isMessage:
        return opMessage[Rc](argsOp.message)
      let args = argsOp.value

      # Run.
      result = processRunArgs(args)
    except:
      var message = "Unexpected exception: $1" % [getCurrentExceptionMsg()]
      # The stack trace is only available in the debug builds.
      when not defined(release):
        message = message & "\n" & getCurrentException().getStackTrace()
      result = opMessage[Rc](message)

when isMainModule:
  let rcOp = main(commandLineParams())
  if rcOp.isMessage:
    # Error path. Write the message to stderr.
    writeErr(rcOp.message)
    quit(QuitFailure)
  else:
    # Return the return code.
    quit(rcOp.value)
