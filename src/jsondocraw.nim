## Generate json data from a nim source file. It's like nim's jsondoc
## command except no html presentation information is in the
## descriptions. The descriptions match the source.

import std/strformat
import std/strutils
import std/strformat
import std/os
import std/tables
import std/osproc
import std/json
import std/re
import std/options
import comparelines
import cmdline
import tempFile

const
  helpText* = """

Create a json file like nim's jsondoc command except the descriptions
do not contain any html presentation information.  This command runs
nim jsondoc command then post processes the data to patch the
descriptions.

Usage:
jsondocraw [-h] srcFilename destFilename

srcFilename -- nim source filename
destFilename -- filename of the json file to create
"""
    ## The help text shown with -h.

  cmlMessages: array[low(CmlMessageId)..high(CmlMessageId), string] = [
    #[_00_]# "Two dashes must be followed by an option name.",
    #[_01_]# "The option '--$1' is not supported.",
    #[_02_]# "The option '$1' requires an argument.",
    #[_03_]# "One dash must be followed by a short option name.",
    #[_04_]# "The short option '-$1' is not supported.",
    #[_05_]# "The option '-$1' needs an argument; use it by itself.",
    #[_06_]# "Duplicate short option: '-$1'.",
    #[_07_]# "Duplicate long option: '--$1'.",
    #[_08_]# "Use the short name '_' instead of '$1' with a bare argument.",
    #[_09_]# "Use an alphanumeric ascii character for a short option name instead of '$1'.",
    #[_10_]# "Missing '$1' argument.",
    #[_11_]# "Extra bare argument.",
    #[_12_]# "One '$1' argument is allowed.",
  ]
    ## Command line parsing errors.

type
  Args* = object
    ## Args holds the source nim filename and the destination
    ## json filename to create.
    help*: bool
    srcFilename*: string
    destJsonFile*: string

  JsonDocRawError = object of OSError

func newArgs*(cmlArgs: CmlArgs): Args =
  ## Create an Args object from a CmlArgs.
  result.help = "help" in cmlArgs
  if "srcFilename" in cmlArgs:
    result.srcFilename = cmlArgs["srcFilename"][0]
  if "destJsonFile" in cmlArgs:
    result.destJsonFile = cmlArgs["destJsonFile"][0]

func getMessage*(message: CmlMessageId, problemArg: string = ""): string =
  ## Return a message from a message id and problem argument.
  result = cmlMessages[message] % [problemArg]

func `$`*(args: Args): string =
  ## Return a string representation of an Args object.
  result.add(fmt"args.help = {args.help}" & "\n")
  result.add(fmt"args.srcFilename = '{args.srcFilename}'" & "\n")
  result.add(fmt"args.destJsonFile = '{args.destJsonFile}'")

proc raiseError(msg: string) =
  raise newException(JsonDocRawError, msg)

proc readOneDesc*(srcLines: seq[string], start: int, finish: int): string =
  ## Return the doc comment found in the given range of line numbers.

  let startIx = start - 1
  var endIx: int
  if finish == -1:
    endIx = srcLines.len - 1
  else:
    endIx = finish - 2

  # Add the discription as a sequence of lines with the leading spaces
  # and ## removed.
  var lines = newSeq[string]()
  var foundDescription = false
  let pattern = re(r"\s*##")
  for line in srcLines[startIx .. endIx]:
    if line.startsWith(pattern):
      let stripped = strip(line, trailing = false)
      if stripped.len > 2:
        let str = stripped[2 .. ^1]
        lines.add(str)
      else:
        lines.add("")
      foundDescription = true
    elif foundDescription:
      break

  # Determine the minimum number of spaces used with the doc comment.
  var minSpaces = 1024
  for line in lines:
    for ix in 0 .. line.len - 1:
      if line[ix] != ' ':
        if ix < minSpaces:
          minSpaces = ix
        break

  # Trim off the minimum leading spaces.
  var trimmedLines = newSeq[string]()
  for line in lines:
    trimmedLines.add(line[minSpaces .. ^1])

  result = trimmedLines.join("")

proc readDescriptions*(text: string, lineNums: seq[int]): OrderedTable[string, string] =
  ## Read all the descriptions in the text specified by the line
  ## numbers. Return a dictionary mapping the line number to its
  ## description.
  let srcLines = text.splitNewLines()

  # Create the line range for each description.
  var ranges = newSeq[tuple[start: int, finish: int]]()
  var start = 1
  var finish: int
  for lineNum in lineNums:
    finish = lineNum
    ranges.add( (start, finish) )
    start = finish
  ranges.add( (start, -1) )

  # for r in ranges:
  #   echo $r

  for r in ranges:
    let desc = readOneDesc(srcLines, r.start, r.finish)
    result[$r.start] = desc

  # let jsonFilename = joinPath("docs", changeFileExt(basename, "json"))

proc removePresentation*(args: Args) =
  ## Create a json file without presentation formatting in the
  ## descriptions.  Pass in a source filename and the name of the json
  ## file to create.

  if not fileExists(args.srcFilename):
    raiseError("source file doesn't exist")

  let tempFileO = openTempFile()
  if not isSome(tempFileO):
    raiseError("unable to create a temp file")
  let tempFile = tempFileO.get()
  let origJsonFilename = tempFile.filename
  defer: discard tryRemoveFile(origJsonFilename)

  # Remove the destination if it exists before creating it.
  discard tryRemoveFile(args.destJsonFile)

  # Run nim's jsondoc to create a json file in the temp dir.
  let cmd = fmt"nim --hints:off jsondoc --out:{origJsonFilename} {args.srcFilename}"
  let (stdouterr, rc) = execCmdEx(cmd)
  if rc != 0 or not fileExists(origJsonFilename):
    echo cmd
    echo stdouterr
    raiseError("error creating the json file")

  # Read the json file.
  let jsonObj = parseFile(origJsonFilename)

  # Create a list of line numbers one associated with each
  # description.  The first one is the module's description.
  var lineNums = newSeq[int]()
  for entry in jsonObj["entries"]:
    lineNums.add(entry["line"].getInt())

  # Read all the descriptions from the source file and return a
  # mapping from line number to description.
  let text = readFile(args.srcFilename)
  let lineToDesc = readDescriptions(text, lineNums)

  # Patch the jsonObj replacing all the descriptions.
  jsonObj["moduleDescription"] = newJString(lineToDesc["1"])
  for entry in jsonObj["entries"]:
    let desc = newJString(lineToDesc[$entry["line"]])
    entry["description"] = desc

  # Write to a new json file.
  writeFile(args.destJsonFile, pretty(jsonObj))

when isMainModule:
  proc run(args: Args): int =
    if args.help:
      echo helpText
    else:
      removePresentation(args)

  proc main(argv: seq[string]): int =
    ## Run jsondocraw

    # Parse the command line options.
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("help", 'h', cmlStopArgument))
    options.add(newCmlOption("srcFilename", '_', cmlBareArgument))
    options.add(newCmlOption("destJsonFile", '_', cmlBareArgument))
    let argsOrMessage = cmdline(options, collectArgs())
    if argsOrMessage.kind == cmlMessageKind:
      # Display the message.
      echo getMessage(argsOrMessage.messageId, argsOrMessage.problemArg)
      return 1
    let args = newArgs(argsOrMessage.args)

    # Setup control-c monitoring so ctrl-c stops the program.
    proc controlCHandler() {.noconv.} =
      quit 0
    setControlCHook(controlCHandler)

    result = 1
    try:
      result = run(args)
    except JsonDocRawError as ex:
      echo ex.msg
    except:
      let msg = getCurrentExceptionMsg()
      echo fmt"Unexpected exception: '{msg}'."

  let rc = main(commandLineParams())
  quit(if rc == 0: QuitSuccess else: QuitFailure)
