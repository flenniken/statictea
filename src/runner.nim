## Run a statictea combined test file.

import std/strutils
import std/os
import std/options
import std/parseopt
import std/streams
import readlines
when isMainModule:
  import std/os

const
  switches = [
    ('h', "help"),
    ('v', "version"),
    ('f', "filename"),
    ('d', "directory"),
  ]
  staticteaTestFile = "statictea test file 0.0.0"

type
  Args* = object
    ## Args holds the command line arguments.
    help*: bool
    version*: bool
    filename*: string
    directory*: string

  RcAndMessage* = object
    ## RcAndMessage holds a return code and message.
    rc*: int
    message*: string

  FileLine* = object
    ## FileLine holds the parseFileLine result.
    filename*: string
    noLastLine*: bool

  ExpectedLine* = object
    ## FileLine holds the parseExpectedLine result.
    expectedName*: string
    gotName*: string

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

func isMessage*(opResult: OpResult): bool =
  if opResult.kind == opMessage:
    result = true

func isValue*(opResult: OpResult): bool =
  if opResult.kind == opValue:
    result = true

# func newOpResultMessage*[T](message: string): OpResult =
#   ## Return a new OpResult object containing a message.
#   result = OpResult(kind: opMessage, message: message)

# func newOpResultValue*[T](value: T): OpResult =
#   ## Return a new OpResult object containing a value.
#   result = OpResult(kind: opValue, value: T)

func newFileLine*(filename: string, noLastLine: bool): FileLine =
  result = FileLine(filename: filename, noLastLine: noLastLine)

func newExpectedLine*(expectedName: string, gotName: string): ExpectedLine =
  result = ExpectedLine(expectedName: expectedName, gotName: gotName)

proc writeErr*(message: string) =
  ## Write a message to stderr.
  stderr.writeLine(message)

proc writeOut*(message: string) =
  ## Write a message to stdout.
  stdout.writeLine(message)

proc createFolder*(folder: string): OpResult[RcAndMessage] =
  ## Create a folder with the given name.
  try:
    createDir(folder)
    let rcAndMessage = RcAndMessage(rc: 0, message: "")
    result = OpResult[RcAndMessage](kind: opValue, value: rcAndMessage)
  except OSError:
    let message = "OS error when trying to create the directory: $1" % folder
    result = OpResult[RcAndMessage](kind: opMessage, message: message)

proc getHelp(): string =
  result = """

Run a StaticTea combined test file or run all test files in a
directory.

runner [-h] [-v] [-f filename] [-d directory]

The test runner runs test files in a folder.  Each file describes
multiple files that make up a test.  The runner creates the files in a
temp folder then runs a command line using those files. It then
compare the output to the expected output.

The runner creates files with an ending newline unless you specify
noLastEnding.

The line endings are preserved.

The following test file instructs the runner to create two files,
hello.html and hello.json then run a statictea command with them. Then
it compares standard out with the expected output

~~~
statictea test runner 0.0.0
# Hello World Example
----------file: hello.html (noLastEnding)
$$ nextline
$$ hello {name}
----------file: hello.json
{"name": "world"}
----------file: stdout.expected (noLastEnding)
hello world
----------file: stderr.expected
----------command line
../bin/statictea -s=hello.json -t=hello.html >stdout 2>stderr
----------expected: stdout.expected == stdout
----------expected: stderr.expected == stderr
----------return code: 0
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
    help: var bool, version: var bool, filename: var string,
    directory: var string): OpResult[string] =

  ## Handle one switch and return its value.  Switch is the key from
  ## the command line, either a word or a letter.  Word is the long
  ## form of the switch.

  if word == "filename":
    if value == "":
      return OpResult[string](kind: opMessage, message: "Missing filename. Use -f=filename")
    else:
      filename = value
  elif word == "directory":
    if value == "":
      return OpResult[string](kind: opMessage, message: "Missing directory name. Use -d=directory")
    else:
      directory = value
  elif word == "help":
    help = true
  elif word == "version":
    version = true
  else:
    return OpResult[string](kind: opMessage, message: "Unknown switch.")

proc parseRunnerCommandLine*(argv: seq[string]): OpResult[Args] =
  ## Return the command line arguments or a message when there is a
  ## problem.

  var args: Args
  var help: bool = false
  var version: bool = false
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
            return OpResult[Args](kind: opMessage, message: wordOp.message)
          let messageOp = handleWord($letter, wordOp.value, value,
            help, version, filename, directory)
          if messageOp.isMessage:
            return OpResult[Args](kind: opMessage, message: messageOp.message)

      of CmdLineKind.cmdLongOption:
        let messageOp = handleWord(key, key, value, help, version,
                   filename, directory)
        if messageOp.isMessage:
          return OpResult[Args](kind: opMessage, message: messageOp.message)

      of CmdLineKind.cmdArgument:
        return OpResult[Args](kind: opMessage, message: "Unknown switch: $1" % [key])

      of CmdLineKind.cmdEnd:
        discard

  args.help = help
  args.version = version
  args.filename = filename
  args.directory = directory

  result = OpResult[Args](kind: opValue, value: args)

proc parseFileLine(line: string): OpResult[FileLine] =
  return OpResult[FileLine](kind: opMessage, message: "not implemented")
  # var filename = ""
  # var noLastLine = false
  # result = some(newFileLine(filename, noLastLine))
  # result = some(newExpectedLine(expectedName, gotName))

proc parseExpectedLine(line: string): OpResult[ExpectedLine] =
  return OpResult[ExpectedLine](kind: opMessage, message: "not implemented")
  # var expectedName = ""
  # var gotName = ""
  # result = some(newExpectedLine(expectedName, gotName))

proc openNewFile*(folder: string, filename: string): OpResult[File] =
  ## Create a new file in the given folder and return an open File
  ## object.

  var path = joinPath(folder, filename)
  if fileExists(path):
    return OpResult[File](kind: opMessage, message: "File already exists: $1" % [path])

  var file: File
  if not open(file, path, fmWrite):
    let message = "Unable to create the file: $1" % [path]
    return OpResult[File](kind: opMessage, message: message)

  result = OpResult[File](kind: opValue, value: file)

proc createSectionFile(lb: var LineBuffer, folder: string, filename: string,
                noLastLine: bool): OpResult[string] =
  ## Create a file in the given folder by reading lines in the line buffer until
  ## "----------" is found or the end of the file. Return the last
  ## line.

  var fileOp = openNewFile(folder, filename)
  if fileOp.isMessage:
    return OpResult[string](kind: opMessage, message: fileOp.message)
  var file = fileOp.value
  defer:
    file.close()

  var line: string
  while true:
    line = readlines.readline(lb)
    if line == "":
      break # No more lines.
    if line.startsWith("----------"):
      break # Done
    # Write the line to the file.
    file.write(line)

  result = OpResult[string](kind: opValue, value: line)

proc runFilename(filename: string): OpResult[RcAndMessage] =
  ## Run a test file and return 0 when successful, else return a message.

  if not fileExists(filename):
    return OpResult[RcAndMessage](kind: opMessage, message: "File not found: $1" % [filename])

  # Open the file for reading.
  let stream = newFileStream(filename, fmRead)
  if stream == nil:
    return OpResult[RcAndMessage](kind: opMessage, message: "Unable to open file: $1" % [filename])
  defer:
    stream.close()

  # Create a temp folder next to the file.
  let tempDirName = filename & ".tempdir"
  if dirExists(tempDirName):
    let message = "The temp dir already exists. Delete it and try again. $1" % tempDirName
    return OpResult[RcAndMessage](kind: opMessage, message: message)
  let rcAndMessageOp = createFolder(tempDirName)
  if rcAndMessageOp.isMessage:
    return rcAndMessageOp

  # Allocate a buffer for reading lines.
  var lineBufferO = newLineBuffer(stream, filename = filename)
  if not lineBufferO.isSome():
    return OpResult[RcAndMessage](kind: opMessage, message: "Unable to allocate a line buffer.")
  var lb = lineBufferO.get()

  # Check the file type is supported. The first line contains the type
  # and version number.
  var line = readlines.readline(lb)
  if line == "":
    return OpResult[RcAndMessage](kind: opMessage, message: "Emtpy file: $1" % filename)

  if not line.startsWith(staticteaTestFile):
    let message = """File type not supported.
expected: $1
got: $2
""" % [staticteaTestFile, line]
    return OpResult[RcAndMessage](kind: opMessage, message: message)

  var haveLine = false
  while true:
    if not haveLine:
      line = lb.readline()
    if line == "":
      break # No more lines.
    if line.startsWith("#"):
      continue
    if line.startsWith("----------file:"):
      let fileLineOp = parseFileLine(line)
      if fileLineOp.isMessage:
        return OpResult[RcAndMessage](kind: opMessage, message: fileLineOp.message)
      let fileLine = fileLineOp.value
      let lastLineOp = createSectionFile(lb, tempDirName, fileLine.filename, fileLine.noLastLine)
      if lastLineOp.isMessage:
        return OpResult[RcAndMessage](kind: opMessage, message: lastLineOp.message)
      line = lastLineOp.value
      haveLine = false
      continue

    if line.startsWith("----------expected:"):
      # Remember the expected filenames to compare.
      let expectedLineOp = parseExpectedLine(line)
      if expectedLineOp.isMessage:
        return OpResult[RcAndMessage](kind: opMessage, message: expectedLineOp.message)
      writeOut("expected")
    if line.startsWith("----------command line"):
      # Remember the command line
      writeOut("command line")
    if line.startsWith("----------return code"):
      writeOut("return code")

  ## Run the command
  writeOut("run command")

  ## Compare expected filenames
  writeOut("compare files")

  ## Remove the temp folder.
  removeDir(tempDirName)
  let rcAndMessage = RcAndMessage(rc: 0, message: "")
  result = OpResult[RcAndMessage](kind: opValue, value: rcAndMessage)

proc runDirectory(dir: string): OpResult[RcAndMessage] =
  result = OpResult[RcAndMessage](kind: opMessage, message: "runDirectory: not implemented")

proc runFilename(args: Args): OpResult[RcAndMessage] =
  result = runFilename(args.filename)

proc runDirectory(args: Args): OpResult[RcAndMessage] =
  result = runDirectory(args.directory)

proc processArgs(args: Args): OpResult[RcAndMessage] =
  ## Process the arguments and return a return code or message.

  if args.help:
    let rcAndMessage = RcAndMessage(rc: 0, message: getHelp())
    result = OpResult[RcAndMessage](kind: opValue, value: rcAndMessage)
  elif args.version:
    let rcAndMessage = RcAndMessage(rc: 0, message: staticteaTestFile)
    result = OpResult[RcAndMessage](kind: opValue, value: rcAndMessage)
  elif args.filename != "":
    result = runFilename(args)
  elif args.directory != "":
    result = runDirectory(args)
  else:
    let rcAndMessage = RcAndMessage(rc: 0, message: "Missing argments, use -h for help.")
    result = OpResult[RcAndMessage](kind: opValue, value: rcAndMessage)

proc main*(argv: seq[string]): OpResult[RcAndMessage] =
  ## Run statictea tests files. Return a rc and message.

  # Parse the command line options.
  let argsOp = parseRunnerCommandLine(argv)
  if not argsOp.isMessage:
    return OpResult[RcAndMessage](kind: opMessage, message: argsOp.message)
  let args = argsOp.value

  # Setup control-c monitoring so ctrl-c stops the program.
  proc controlCHandler() {.noconv.} =
    quit 0
  setControlCHook(controlCHandler)

  try:
    result = processArgs(args)
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
