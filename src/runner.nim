## Standalone command to run Single Test File (stf) files.

import std/strutils
import std/os
import std/osproc
import std/options
import std/parseopt
import std/streams
import readlines
import regexes
when isMainModule:
  import std/os

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

  RcAndMessage* = object
    ## RcAndMessage holds a return code and message.
    rc*: int ## return code, 0 success.
    message*: string ## message. A non-empty message gets displayed.

  RunFileLine* = object
    ## RunFileLine holds the parseRunFileLine result.
    filename*: string
    noLastEnding*: bool
    command*: bool
    nonZeroReturn*: bool

  CompareLine* = object
    ## CompareLine holds the names of two files that are expected to
    ## be equal.
    filename1*: string
    filename2*: string

  DirAndFiles* = object
    ## DirAndFiles holds the result of the makeDirAndFiles
    ## procedure.
    compareLines*: seq[CompareLine]
    runFileLines*: seq[RunFileLine]

  OpResultKind* = enum
    ## The kind of a OpResult object, either a value or message.
    opValue,
    opMessage

  OpResult*[T] = object
    ## Contains either a value or a message string. The default is a
    ## value. It's similar to the Option type but instead of returning
    ## nothing, you return a message that tells why you cannot return
    ## the value.
    case kind*: OpResultKind
      of opValue:
        value*: T
      of opMessage:
        message*: string

func newRunArgs*(help = false, version = false, leaveTempDir = false,
    filename = "", directory = ""): RunArgs =
  ## Create a new RunArgs object.
  result = RunArgs(help: help, version: version,
    leaveTempDir: leaveTempDir, filename: filename, directory: directory)

func newRcAndMessage*(rc: int, message: string): RcAndMessage =
  ## Create a new RcAndMessage object.
  result = RcAndMessage(rc: rc, message: message)

func isMessage*(opResult: OpResult): bool =
  ## Return true when the OpResult is a message.
  if opResult.kind == opMessage:
    result = true

func isValue*(opResult: OpResult): bool =
  ## Return true when the OpResult is a value.
  if opResult.kind == opValue:
    result = true

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
  if opResult.kind == opValue:
    result = "opValue"
  else:
    result = "opMessage"

func `$`*(r: CompareLine): string =
  ## Return a string representation of a CompareLine object.
  result = "expected $1 == $2" % [r.filename1, r.filename2]

func `$`*(r: RunFileLine): string =
  ## Return a string representation of a RunFileLine object.

  var noLastEnding: string
  if r.noLastEnding:
    noLastEnding = "noLastEnding"
  else:
    noLastEnding = ""

  var command: string
  if r.command:
    command = "command"
  else:
    command = ""

  var nonZeroReturn: string
  if r.nonZeroReturn:
    nonZeroReturn = "nonZeroReturn"
  else:
    nonZeroReturn = ""

  result = "file $1 $2 $3 $4" % [r.filename, noLastEnding, command, nonZeroReturn]

proc writeErr*(message: string) =
  ## Write a message to stderr.
  stderr.writeLine(message)

proc writeOut*(message: string) =
  ## Write a message to stdout.
  stdout.writeLine(message)

func stripLineEnding(line: string): string =
  ## Strip line endings from a string.
  result = line.strip(chars={'\n', '\r'}, trailing = true)

proc createFolder*(folder: string): OpResult[RcAndMessage] =
  ## Create a folder with the given name.
  try:
    createDir(folder)
    let rcAndMessage = RcAndMessage(rc: 0, message: "")
    result = OpResult[RcAndMessage](kind: opValue, value: rcAndMessage)
    # echo "Created folder: " & folder
  except OSError:
    let message = "OS error when trying to create the directory: '$1'" % folder
    result = OpResult[RcAndMessage](kind: opMessage, message: message)

proc deleteFolder*(folder: string): OpResult[RcAndMessage] =
  ## Delete a folder with the given name.
  try:
    removeDir(folder)
    let rcAndMessage = RcAndMessage(rc: 0, message: "")
    result = OpResult[RcAndMessage](kind: opValue, value: rcAndMessage)
    # echo "Deleted folder: " & folder
  except OSError:
    # echo "Unable to delete folder: " & folder
    let message = "OS error when trying to remove the directory: '$1'" % folder
    result = OpResult[RcAndMessage](kind: opMessage, message: message)

proc getHelp(): string =
  ## Return the help message and usage text.
  result = """
Run a single test file (stf) or run all stf files in a folder.

The runner reads a stf file, creates multiple small files in a test
folder, runs commands then verifies the correct output.

# Usage

runner [-h] [-v] [-l] [-f=filename] [-d=directory]

-h --help          Show this help message.
-v --version       Show the version number.
-l --leaveTempDir  Leave the temp folder.
-f --filename      Run the stf file.
-d --directory     Run the stf files in the directory.

The stf file processing order:

* temp folder created with the name of the stf file with “. tempdir”
  appended
* files created in the tempdir
* commands run and the return codes checked
* file compares run
* temp folder removed

Runner returns 0 when all the tests pass. When running multiple it
displays each test run and tells how many passed and failed.

Normally the temp folder is removed after running, the -l option
leaves it. If the temp folder exists, it is deleted then recreated.

# Stf File Format

The Single Test File format is a text file made up of five
single line commands.

1. comment and blank lines
2. file
3. endfile
4. expected
5. id

You can add spaces, tabs and dashes at the beginning and end of the
command lines, except the id and comment lines.

# Comment Command

Comments start with # as the first character of the line. Blank lines
are ignored.

# File Command

The file command is used to create a file. It begins with “file”
followed by the filename then some optional attributes.  The general
form is:

~~~
file filename [noLineEnding] [command] [nonZeroReturn]
~~~

* filename - the name of the file to create. It is created in them temp
  folder named after the stf file with “.tempdir” appended. No spaces
  in the name.

* command — the file is run. All files are created before running
  commands. The working directory is the temp folder where all the
  files are.  The commands are run in the order specified in the file.

* noLineEnding — the file is created without an ending newline.

* nonZeroReturn — the command is expected to return a non-zero return
  code when run.

# Endfile Command

The endfile command line follows a file line and it brackets the lines
of the file to be created. All these lines go in the file, even ones
that look like commands.

# Expected Command

The expected line compares files. You specify two files that should be
equal.  The compares are run after running the commands.

~~~
expected filename1 == filename2
~~~

# Id Command

The first line of the stf file identifies it as a stf file.  The id
ends with the version number.

~~~
id stf file version 0.0.0
~~~

# Example Stf File

The following example stf file instructs the runner to create the
files : cmd.sh, hello.html, hello.json, stdout-expected and
stderr-expected.  It then runs cmd.sh looking for a 0 return code. Then
it compares the files "stdout" with "stdout.expected" and "stderr"
with "stderr.expected".

~~~
id stf file version 0.0.0
# Hello World Example

# Create the cmd.sh script.
----- file cmd.sh command -----
../bin/statictea -t=hello.html -s=hello.json >stdout 2>stderr
----- endfile -----

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

# Compare these files are equal.
--- expected stdout.expected == stdout
--- expected stderr.expected == stderr
~~~
"""

func letterToWord(letter: char): OpResult[string] =
  for tup in switches:
    if tup[0] == letter:
      return OpResult[string](kind: opValue, value: tup[1])
  let message = "Unknown switch: $1" % $letter
  result = OpResult[string](kind: opMessage, message: message)

# todo: make an object for the return value.
proc handleWord(switch: string, word: string, value: string,
    help: var bool, version: var bool, leaveTempDir: var bool, filename: var string,
    directory: var string): OpResult[string] =
  ## Handle one switch and return its value.  Switch is the key from
  ## the command line, either a word or a letter.  Word is the long
  ## form of the switch.

  if word == "filename":
    if value == "":
      return OpResult[string](kind: opMessage,
        message: "Missing filename. Use -f=filename")
    else:
      filename = value
  elif word == "directory":
    if value == "":
      return OpResult[string](kind: opMessage,
        message: "Missing directory name. Use -d=directory")
    else:
      directory = value
  elif word == "help":
    help = true
  elif word == "version":
    version = true
  elif word == "leaveTempDir":
    leaveTempDir = true
  else:
    return OpResult[string](kind: opMessage, message: "Unknown switch.")

proc parseRunCommandLine*(argv: seq[string]): OpResult[RunArgs] =
  ## Return the command line arguments or a message when there is a
  ## problem.

  var args: RunArgs
  var help: bool = false
  var version: bool = false
  var leaveTempDir: bool = false
  var filename: string
  var directory: string

  var optParser = initOptParser(argv)

  # Iterate over all arguments passed to the command line.
  for kind, key, value in getopt(optParser):
    case kind
      of CmdLineKind.cmdShortOption:
        for ix in 0..key.len-1:
          let letter = key[ix]
          let wordOp = letterToWord(letter)
          if wordOp.isMessage:
            return OpResult[RunArgs](kind: opMessage, message: wordOp.message)
          let messageOp = handleWord($letter, wordOp.value, value,
            help, version, leaveTempDir, filename, directory)
          if messageOp.isMessage:
            return OpResult[RunArgs](kind: opMessage, message: messageOp.message)

      of CmdLineKind.cmdLongOption:
        let messageOp = handleWord(key, key, value, help, version, leaveTempDir,
          filename, directory)
        if messageOp.isMessage:
          return OpResult[RunArgs](kind: opMessage, message: messageOp.message)

      of CmdLineKind.cmdArgument:
        return OpResult[RunArgs](kind: opMessage,
          message: "Unknown switch: $1" % [key])

      of CmdLineKind.cmdEnd:
        discard

  args.help = help
  args.version = version
  args.filename = filename
  args.directory = directory
  args.leaveTempDir = leaveTempDir

  result = OpResult[RunArgs](kind: opValue, value: args)

func makeBool(item: string): bool =
  ## Return true when the string is not empty, else return false.
  if item != "":
    result = true
  else:
    result = false

proc parseRunFileLine*(line: string): OpResult[RunFileLine] =
  ## Parse a file command line.
  # The optional elements must be specified in order.
  #----------file hello.html [noLastEnding] [command] [nonZeroReturn]
  let pattern = r"^[- ]*file[ ]+([^\s]+)(?:[ ]+(noLastEnding)){0,1}(?:[ ]+(command)){0,1}(?:[ ]+(nonZeroReturn)){0,1}[-\s]*$"

  let matchesO = matchPatternCached(line, pattern, 0)
  if not matchesO.isSome:
    return OpResult[RunFileLine](kind: opMessage,
      message: "Invalid file line: $1" % [line])

  let matches = matchesO.get()
  let groups = matches.getGroups(4)
  let filename = groups[0]
  let noLastEnding = makeBool(groups[1])
  let command = makeBool(groups[2])
  let nonZeroReturn = makeBool(groups[3])

  let fileLine = newRunFileLine(filename, noLastEnding, command, nonZeroReturn)
  return OpResult[RunFileLine](kind: opValue, value: fileLine)

proc parseCompareLine*(line: string): OpResult[CompareLine] =
  ## Parse an expected line.
  #----------expected stdout.expected == stdout
  let pattern = r"^[- ]*expected[ ]+([^\s]+)[ ]*==[ ]*([^\s]+)[-\s]*$"
  let matchesO = matchPatternCached(line, pattern, 0)
  if not matchesO.isSome:
    return OpResult[CompareLine](kind: opMessage,
      message: "Invalid expected line: $1" % [line])

  let matches = matchesO.get()
  let (filename1, filename2) = matches.get2Groups()
  let expectedEqual = newCompareLine(filename1, filename2)
  return OpResult[CompareLine](kind: opValue, value: expectedEqual)

proc openNewFile*(folder: string, filename: string): OpResult[File] =
  ## Create a new file in the given folder and return an open File
  ## object.

  var path = joinPath(folder, filename)
  if fileExists(path):
    return OpResult[File](kind: opMessage,
      message: "File already exists: $1" % [path])

  var file: File
  if not open(file, path, fmWrite):
    let message = "Unable to create the file: $1" % [path]
    return OpResult[File](kind: opMessage, message: message)

  result = OpResult[File](kind: opValue, value: file)

proc getCmd*(line: string): string =
  ## Return the type of line, either: #, "", id, file, expected or
  ## endfile.
  if line.startswith("#"):
    result = "#"
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
    runFileLine: RunFileLine): OpResult[RcAndMessage] =
  ## Create a file in the given folder by reading lines in the line buffer until
  ## "endfile" is found.

  # Create a file in the given folder.
  let filename = runFileLine.filename
  let noLastEnding = runFileLine.noLastEnding

  var fileOp = openNewFile(folder, filename)
  if fileOp.isMessage:
    return OpResult[RcAndMessage](kind: opMessage, message: fileOp.message)
  var file = fileOp.value

  # Write lines until the next endfile is found.
  var line: string
  var previousLine: string
  var firstLine = true
  while true:
    line = readlines.readline(lb)
    if line == "":
      file.close()
      let path = joinPath(folder, filename)
      discard tryRemoveFile(path)
      return OpResult[RcAndMessage](kind: opMessage,
        message: "The endfile line was missing.")
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

  file.close()
  let rcAndMessage = RcAndMessage(rc: 0, message: "")
  result = OpResult[RcAndMessage](kind: opValue, value: rcAndMessage)

proc makeDirAndFiles*(filename: string): OpResult[DirAndFiles] =
  ## Read the stf file and create its temp folder and files. Return the
  ## file lines and expected lines.

  var compareLines = newSeq[CompareLine]()
  var runFileLines = newSeq[RunFileLine]()

  if not fileExists(filename):
    return OpResult[DirAndFiles](kind: opMessage,
      message: "File not found: '$1'." % [filename])

  # Open the file for reading.
  let stream = newFileStream(filename, fmRead)
  if stream == nil:
    return OpResult[DirAndFiles](kind: opMessage,
      message: "Unable to open file: '$1'." % [filename])
  defer:
    stream.close()

  # Create a temp folder next to the file.
  let tempDirName = filename & ".tempdir"
  if dirExists(tempDirName):
    removeDir(tempDirName)

  let rcAndMessageOp = createFolder(tempDirName)
  if rcAndMessageOp.isMessage:
    return OpResult[DirAndFiles](kind: opMessage, message: rcAndMessageOp.message)

  # Allocate a buffer for reading lines.
  var lineBufferO = newLineBuffer(stream, filename = filename)
  if not lineBufferO.isSome():
    return OpResult[DirAndFiles](kind: opMessage,
      message: "Unable to allocate a line buffer.")
  var lb = lineBufferO.get()

  # Check the file type is supported. The first line contains the type
  # and version number.
  var line = readlines.readline(lb)
  if line == "":
    return OpResult[DirAndFiles](kind: opMessage,
      message: "Empty file: '$1'." % filename)
  if not line.startsWith(runnerId):
    let message = """Invalid stf file first line:
expected: $1
     got: $2""" % [runnerId, line]
    return OpResult[DirAndFiles](kind: opMessage, message: message)

  while true:
    # Read a line if we don't already have it.
    line = readlines.readline(lb)
    if line == "":
      break # No more lines.
    let cmd = getCmd(line)
    case cmd
    of "#", "":
      discard
    of "file":
      let fileLineOp = parseRunFileLine(line)
      if fileLineOp.isMessage:
        return OpResult[DirAndFiles](kind: opMessage,
          message: fileLineOp.message)
      let fileLine = fileLineOp.value
      runFileLines.add(fileLine)
      let rcAndMessage = createSectionFile(lb, tempDirName, fileLine)
      if rcAndMessage.isMessage:
        return OpResult[DirAndFiles](kind: opMessage,
          message: rcAndMessage.message)

    of "expected":
      # Remember the expected filenames to compare.
      let expectedEqualOp = parseCompareLine(line)
      if expectedEqualOp.isMessage:
        return OpResult[DirAndFiles](kind: opMessage,
          message: expectedEqualOp.message)
      compareLines.add(expectedEqualOp.value)
    else:
      let message = "Unknown line: '$1'." % stripLineEnding(line)
      return OpResult[DirAndFiles](kind: opMessage, message: message)

  let dirAndFiles = newDirAndFiles(compareLines, runFileLines)
  result = OpResult[DirAndFiles](kind: opValue, value: dirAndFiles)

proc runCommand*(folder: string, filename: string): int =
  ## Run a command file and return its return code.

  let oldDir = getCurrentDir()

  # Set the working directory to the folder.
  assert(dirExists(folder))
  setCurrentDir(folder)

  # Make the file executable.
  setFilePermissions(filename, {fpUserExec, fpUserRead, fpUserWrite})

  # Run the file and return the return code.
  result = execCmd(filename)

  setCurrentDir(oldDir)

proc runCommands*(folder: string, runFileLines: seq[RunFileLine]):
    OpResult[RcAndMessage] =
  ## Run the commands.

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

      if runFileLine.nonZeroReturn:
        if cmdRc == 0:
          echo "$1 generated an unexpected return code of 0." % runFileLine.filename
          echo ""
          rc = 1
      elif cmdRc != 0:
        echo "$1 generated a non-zero return code." %
          runFileLine.filename
        echo ""
        rc = 1

  setCurrentDir(oldDir)

  let rcAndMessage = RcAndMessage(rc: rc, message: "")
  result = OpResult[RcAndMessage](kind: opValue, value: rcAndMessage)

proc openLineBuffer*(filename: string): OpResult[LineBuffer] =
  ## Open a file for reading lines. Return a LineBuffer object.  Close
  ## the line buffer stream when done.

  # Open the file for reading.
  let stream = newFileStream(filename, fmRead)
  if stream == nil:
    return OpResult[LineBuffer](kind: opMessage,
      message: "Unable to open file: '$1'." % [filename])

  # Allocate a buffer for reading lines.
  var lbO = newLineBuffer(stream, filename = filename)
  if not lbO.isSome():
    stream.close()
    return OpResult[LineBuffer](kind: opMessage,
      message: "Unable to allocate a line buffer.")

  result = OpResult[LineBuffer](kind: opValue, value: lbO.get())

proc compareFiles*(filename1: string, filename2: string): OpResult[RcAndMessage] =
  ## Compare two files. When they are equal, return rc=0 and
  ## message="". When they differ return rc=1 and message = the first
  ## line difference. On error return an error message.

  let op1 = openLineBuffer(filename1)
  if op1.isMessage:
    return OpResult[RcAndMessage](kind: opMessage,
      message: op1.message)
  var lb1 = op1.value
  defer:
    if lb1.getStream() != nil:
      lb1.getStream().close()

  let op2 = openLineBuffer(filename2)
  if op2.isMessage:
    return OpResult[RcAndMessage](kind: opMessage,
      message: op2.message)
  var lb2 = op2.value
  defer:
    if lb2.getStream() != nil:
      lb2.getStream().close()

  var rc = 0
  var message = ""
  if filename1 != filename2:
    while true:
      var line1 = readlines.readline(lb1)
      var line2 = readlines.readline(lb2)
      if line1 != line2:
        # The two files are different.
        let (_, f1) = splitPath(filename1)
        let (_, f2) = splitPath(filename2)
        rc = 1
        let width = max(f1.len, f2.len)
        message = """
Files differ on line $1:
$2: ($3)
$4: ($5)""" % [$(lb1.getLineNum()), align(f1, width), line1.stripLineEnding(), align(f2, width), line2.stripLineEnding()] & "\n"
        break;

      if line1 == "":
        break # done

  let rcAndMessage = RcAndMessage(rc: rc, message: message)
  result = OpResult[RcAndMessage](kind: opValue, value: rcAndMessage)

proc compareFileSets*(folder: string, compareLines: seq[CompareLine]):
    OpResult[RcAndMessage] =
  ## Compare file sets and return rc=0 when they are all the same.

  var rc = 0
  for compareLine in compareLines:
    var path1 = joinPath(folder, compareLine.filename1)
    var path2 = joinPath(folder, compareLine.filename2)

    # Compare the two files.
    let rcAndMessageOp = compareFiles(path1, path2)

    if rcAndMessageOp.isMessage:
      # Show the error.
     echo rcAndMessageOp.message
     rc = 1
    else:
      let rcAndMessage = rcAndMessageOp.value
      if rcAndMessage.rc != 0:
        # Show this first different line.
        echo rcAndMessage.message
        rc = 1

  let rcAndMessage = RcAndMessage(rc: rc, message: "")
  result = OpResult[RcAndMessage](kind: opValue, value: rcAndMessage)

proc runStfFilename*(filename: string): OpResult[RcAndMessage] =
  ## Run the stf and report the result. Return rc=0 message="" when it
  ## passes.

  # Create the temp folder and files inside it.
  let dirAndFilesOp = makeDirAndFiles(filename)
  if dirAndFilesOp.isMessage:
    return OpResult[RcAndMessage](kind: opMessage,
      message: dirAndFilesOp.message)
  let dirAndFiles = dirAndFilesOp.value

  let folder = filename & ".tempdir"

  # Run the command files.
  var rcAndMessageOp = runCommands(folder, dirAndFiles.runFileLines)
  if rcAndMessageOp.isMessage:
    return rcAndMessageOp
  result = rcAndMessageOp

  # Compare the files.
  rcAndMessageOp = compareFileSets(folder, dirAndFiles.compareLines)
  if rcAndMessageOp.isMessage:
    return rcAndMessageOp
  var rcAndMessage = rcAndMessageOp.value
  if rcAndMessage.rc != 0:
    result = rcAndMessageOp

proc runFilename*(filename: string, leaveTempDir: bool): OpResult[RcAndMessage] =
  ## Run the stf and report the result. Return rc=0 message="" when it
  ## passes.

  result = runStfFilename(filename)
  if not result.isMessage:
    # Remove the temp folder unless leave is specified.
    let tempDir = filename & ".tempdir"
    if leaveTempDir:
      echo "Leaving temp dir: " & tempDir
    else:
      if fileExists(filename):
        discard deleteFolder(tempDir)

proc runFilename*(args: RunArgs): OpResult[RcAndMessage] =
  ## Run a stf file.
  result = runFilename(args.filename, args.leaveTempDir)

proc runDirectory*(dir: string, leaveTempDir: bool): OpResult[RcAndMessage] =
  ## Run all the stf files in the specified directory.

  if not dirExists(dir):
    let message = "The dir does not exist: " & dir
    return OpResult[RcAndMessage](kind: opMessage,
      message: message)

  var count = 0
  var passedCount = 0
  var rc = 0
  for kind, path in walkDir(dir):
    if path.endsWith(".stf"):
      let (_, basename) = splitPath(path)
      echo "Running: " & basename
      let rcAndMessageOp = runFilename(path, leaveTempDir)
      if rcAndMessageOp.isMessage:
        return rcAndMessageOp
      if rcAndMessageOp.value.rc == 0:
        inc(passedCount)
      else:
        rc = 1
      inc(count)

  let message = "$1 passed, $2 failed\n" % [
    $passedCount, $(count - passedCount)]
  let rcAndMessage = RcAndMessage(rc: rc, message: message)
  result = OpResult[RcAndMessage](kind: opValue, value: rcAndMessage)

proc runDirectory(args: RunArgs): OpResult[RcAndMessage] =
  ## Run all stf files in a directory.
  result = runDirectory(args.directory, args.leaveTempDir)

proc processRunArgs(args: RunArgs): OpResult[RcAndMessage] =
  ## Process the arguments and return a return code or message.

  if args.help:
    let rcAndMessage = RcAndMessage(rc: 0, message: getHelp())
    result = OpResult[RcAndMessage](kind: opValue, value: rcAndMessage)
  elif args.version:
    let rcAndMessage = RcAndMessage(rc: 0, message: runnerId)
    result = OpResult[RcAndMessage](kind: opValue, value: rcAndMessage)
  elif args.filename != "":
    result = runFilename(args)
  elif args.directory != "":
    result = runDirectory(args)
  else:
    let rcAndMessage = RcAndMessage(rc: 0,
      message: "Missing argments, use -h for help.")
    result = OpResult[RcAndMessage](kind: opValue, value: rcAndMessage)

proc main*(argv: seq[string]): OpResult[RcAndMessage] =
  ## Run stf test files. Return a rc and message.

  # Setup control-c monitoring so ctrl-c stops the program.
  proc controlCHandler() {.noconv.} =
    quit 0
  setControlCHook(controlCHandler)

  try:
    # Parse the command line options.
    let argsOp = parseRunCommandLine(argv)
    if argsOp.isMessage:
      return OpResult[RcAndMessage](kind: opMessage,
        message: argsOp.message)
    let args = argsOp.value

    # Run.
    result = processRunArgs(args)
  except:
    var message = "Unexpected exception: $1" % [getCurrentExceptionMsg()]
    # The stack trace is only available in the debug builds.
    when not defined(release):
      message = message & "\n" & getCurrentException().getStackTrace()
    result = OpResult[RcAndMessage](kind: opMessage, message: message)

when isMainModule:
  let rcAndMessageOp = main(commandLineParams())
  if rcAndMessageOp.isMessage:
    # Error path. Write the message to stderr.
    writeErr(rcAndMessageOp.message)
    quit(QuitFailure)
  else:
    # Success path. Display non-empty messages and set the return
    # code.
    let rcAndMessage = rcAndMessageOp.value
    if rcAndMessage.message != "":
      writeOut(rcAndMessage.message)
    quit(rcAndMessage.rc)
