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
import std/algorithm
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

If nim's jsondoc command crashes, replace the problem characters and
try again. You can also use an alternate document comment #$ as a
workaround. For example:

proc myRoutine(a: int): string =
  ## required simple line
  #$ alternate doc comment used instead
  #$ of the first line.
  result = $a
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


proc collectDescription(nimPattern: bool, srcLines: seq[string], start: int, finish: int): seq[string] =
  ## Collect the description lines between the start and finish line
  ## numbers.
  let startIx = start - 1
  var endIx: int
  if finish == -1:
    endIx = srcLines.len - 1
  else:
    endIx = finish - 2
  if endIx >= srcLines.len:
    return

  var pattern: string
  if nimPattern:
    pattern = r"\s*##"
  else:
    pattern = r"\s*#\$"
  let rePattern = re(pattern)

  var foundNimDesc = false
  for line in srcLines[startIx .. endIx]:
    if line.startsWith(rePattern):
      # Strip the leading space and the two comment characters.
      let stripped = strip(line, trailing = false)
      result.add(stripped[2 .. ^1])
      foundNimDesc = true
    elif foundNimDesc:
      break

proc trimDescLines(descLines: seq[string]): string =
  ## If the description lines start with a blank column, trim it off.
  ## Return the description as one string.

  # Check for a blank first column.
  var blankFirstColumn = true
  for line in descLines:
    if line.len > 0:
      let ch = line[0]
      if ch != '\n' and ch != '\r' and ch != ' ':
        blankFirstColumn = false

  if not blankFirstColumn:
    return descLines.join("")

  # Trim off one leading blank column.
  var trimmedLines = newSeq[string]()
  for line in descLines:
    if line.len > 0 and line[0] == ' ':
      trimmedLines.add(line[1 .. ^1])
    else:
      trimmedLines.add(line)
  result = trimmedLines.join("")

proc readOneDesc*(srcLines: seq[string], start: int, finish: int): string =
  ## Return the doc comment found in the given range of line
  ## numbers. Look for #$ first then, if not found, look for ##.

  if start > srcLines.len:
    return
  var descLines = collectDescription(nimPattern=false, srcLines, start, finish)
  if descLines.len == 0:
    descLines = collectDescription(nimPattern=true, srcLines, start, finish)
  result = trimDescLines(descLines)

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
  sort(lineNums)

  # Read all the descriptions from the source file and return a
  # mapping from line number to description.
  let text = readFile(args.srcFilename)
  let lineNumToDesc = readDescriptions(text, lineNums)

  # Patch the jsonObj with descriptions from the source file.  When
  # one not found, use the original.
  let newModuleDescription = lineNumToDesc["1"]
  if newModuleDescription != "":
    jsonObj["moduleDescription"] = newJString(newModuleDescription)
  for entry in jsonObj["entries"]:
    let newDesc = lineNumToDesc[$entry["line"]]
    if newDesc != "":
      entry["description"] = newJString(newDesc)

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
