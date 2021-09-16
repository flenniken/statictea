## Run a stf (single test file) file.

import std/strutils
import std/os
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
    rc*: int
    message*: string

  RunFileLine* = object
    ## RunFileLine holds the parseRunFileLine result.
    filename*: string
    noLastEnding*: bool
    command*: bool
    nonZeroReturn*: bool

  RunExpectedLine* = object
    ## RunExpectedLine holds the names of two files that are expected to
    ## be equal.
    filename1*: string
    filename2*: string

  DirAndFiles* = object
    ## DirAndFiles holds the result of the makeDirAndFiles
    ## procedure.
    runExpectedLines*: seq[RunExpectedLine]
    runFileLines*: seq[RunFileLine]

  OpResultKind* = enum
    ## The kind of a OpResult object, either a value or message.
    opValue,
    opMessage

  OpResult*[T] = object
    ## Contains either a value or a message string. The default is a
    ## value.
    case kind*: OpResultKind
      of opValue:
        value*: T
      of opMessage:
        message*: string

func newRunArgs*(help = false, version = false, leaveTempDir = false,
    filename = "", directory = ""): RunArgs =
  result = RunArgs(help: help, version: version,
    leaveTempDir: leaveTempDir, filename: filename, directory: directory)

func newRcAndMessage*(rc: int, message: string): RcAndMessage =
  result = RcAndMessage(rc: rc, message: message)

func isMessage*(opResult: OpResult): bool =
  if opResult.kind == opMessage:
    result = true

func isValue*(opResult: OpResult): bool =
  if opResult.kind == opValue:
    result = true

func newRunFileLine*(filename: string, noLastEnding: bool, command:
    bool, nonZeroReturn: bool): RunFileLine =
  result = RunFileLine(filename: filename, noLastEnding: noLastEnding,
    command: command, nonZeroReturn: nonZeroReturn)

func newRunExpectedLine*(filename1: string, filename2: string): RunExpectedLine =
  result = RunExpectedLine(filename1: filename1, filename2: filename2)

func newDirAndFiles*(runExpectedLines: seq[RunExpectedLine],
    runFileLines: seq[RunFileLine]): DirAndFiles =
  result = DirAndFiles(runExpectedLines: runExpectedLines,
    runFileLines: runFileLines)

func `$`*(r: RunExpectedLine): string =
  ## Return a string representation of a RunExpectedLine.

  result = "expected $1 == $2" % [r.filename1, r.filename2]

func `$`*(r: RunFileLine): string =
  ## Return a string representation of a RunFileLine.

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
  result = """
Run a test specified by a stf test file or run all the stf test files
contained in a folder.

The stf test file contains instructions for creating files needed to
preform the test. It creates the temp files in a temp folder next to the
test file. After creating the files it runs one of them to preform the
test. Then it compares files to see whether the test passed or not.

runner [-h] [-v] [-f=filename] [-d=directory]


There are four types of command lines in an stf file.  Elements on a
command line can use multiple spaces or tabs to separate commonents
and commands can use any number of dashes at the beginning and end of
the line.  The stf command lines are:

* id
* file
* endfile
* expected

# Id Line

The id line is the first line of the file and identifies it as a stf
file and tells its version. The leading and trailing spaces and dashes
are optional. Example line:

--- id stf file version 0.0.0 ---

# File and Endfile Lines

The file and endfile lines bracket the lines used for a new file. You
specify the name of the file, whether to use line ending on the last
line, whether this file is a test script to run and whether the test
script returns 0 or non-zero return code. Example:

--- file filename [noLastEnding] [command] [nonZeroReturn] ---
The file lines go here.
The file lines go here.
The file lines go here.
--- endfile

* filename -- the name of the file to create. You cannot use spaces in
  the name.
* noLastEnding -- create the file with a newline on the last line.
* command -- this file is the test script to run.
* nonZeroReturn -- used with "command" and tells whether the script is
  expected to return a non-zero return code value.

# expected line

The "expected" line tells which files should be compared after running
the test script. Example:

--- expected filename1 == filename2

# comment line

You can add comments. Comment lines start with # as the first
character of the line.  Blank lines are ignored except in file blocks.

# Example

The following example stf file instructs the runner to create the
files : cmd.sh, hello.html, hello.json, stdout-expected and
stderr-expected then it runs cmd.sh looking for a 0 return code. Then
it compares the files "stdout" with "stdout.expected" and "stderr"
with "stderr.expected".

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

# todo: allow a space instead of an equal sign on the command line. "-f filename"

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
  if item != "":
    result = true
  else:
    result = false

proc parseRunFileLine*(line: string): OpResult[RunFileLine] =
  ## The optional elements must be specified in order.
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

proc parseRunExpectedLine*(line: string): OpResult[RunExpectedLine] =
  #----------expected stdout.expected == stdout
  let pattern = r"^[- ]*expected[ ]+([^\s]+)[ ]*==[ ]*([^\s]+)[-\s]*$"
  let matchesO = matchPatternCached(line, pattern, 0)
  if not matchesO.isSome:
    return OpResult[RunExpectedLine](kind: opMessage,
      message: "Invalid expected line: $1" % [line])

  let matches = matchesO.get()
  let (filename1, filename2) = matches.get2Groups()
  let expectedEqual = newRunExpectedLine(filename1, filename2)
  return OpResult[RunExpectedLine](kind: opValue, value: expectedEqual)

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
  ## Return the type of line.
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

  var runExpectedLines = newSeq[RunExpectedLine]()
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
    let message = "The temp dir already exists. Delete it and try again. '$1'" % tempDirName
    return OpResult[DirAndFiles](kind: opMessage, message: message)
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
      let expectedEqualOp = parseRunExpectedLine(line)
      if expectedEqualOp.isMessage:
        return OpResult[DirAndFiles](kind: opMessage,
          message: expectedEqualOp.message)
      runExpectedLines.add(expectedEqualOp.value)
    else:
      let message = "Unknown line: '$1'." % stripLineEnding(line)
      return OpResult[DirAndFiles](kind: opMessage, message: message)

  let dirAndFiles = newDirAndFiles(runExpectedLines, runFileLines)
  result = OpResult[DirAndFiles](kind: opValue, value: dirAndFiles)

proc runDirectory*(dir: string): OpResult[RcAndMessage] =
  result = OpResult[RcAndMessage](kind: opMessage,
    message: "runDirectory: not implemented")

proc runFilename*(args: RunArgs): OpResult[RcAndMessage] =
  let dirAndFilesOp = makeDirAndFiles(args.filename)
  if dirAndFilesOp.isMessage:
    result = OpResult[RcAndMessage](kind: opMessage,
      message: dirAndFilesOp.message)

  # Remove the temp folder unless leave is specified.
  if not args.leaveTempDir:
    if fileExists(args.filename):
      discard deleteFolder(args.filename & ".tempdir")

proc runDirectory(args: RunArgs): OpResult[RcAndMessage] =
  result = runDirectory(args.directory)

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
  ## Run statictea tests files. Return a rc and message.

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
    writeErr(rcAndMessageOp.message)
    quit(QuitFailure)
  else:
    let rcAndMessage = rcAndMessageOp.value
    if rcAndMessage.message != "":
      writeErr(rcAndMessage.message)
    quit(rcAndMessage.rc)
