## Generate json data from a nim source file.

import std/strformat
import std/strutils
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
Create a json file like Nim's jsondoc command except the descriptions
match the source. This command runs Nim's jsondoc command then post
processes the data to patch the descriptions.

The jsondocraw command exists because Nim’s jsondoc command assumes
the doc comment is formatted as reStructuredText (RST) and it converts
the RST to HTML for the JSON description.

The jsondocraw command reads the description's line number in the JSON
file then reads the source file to extract the raw doc comment.

When you use markdown or some other format for your doc comments, you
are likely to specify something that causes the RST parser to fail and
no JSON is produced. When this happens you can specify an alternate doc
comment prefix as a workaround, "#$ " instead of "## ".

The leading ## is required for nim's jsondoc to record it in the
json.

proc sample*() =
  ##
  #$ alternate doc comment
  #$ when needed
  echo "tea"

Usage:
  jsondocraw [-h] [-v] srcFilename destFilename

  -h --help — show this message
  -v --version — show the version number

  srcFilename — nim source filename
  destFilename — filename of the json file to create
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
    ## Args holds the arguments specified on the command line.
    ##
    ## * help — help or -h was specified
    ## * noOptions — no options or arguments specified
    ## * version — version or -v was specified
    ## * srcFilename — nim source filename
    ## * destJsonFile — name of the JSON file to create
    help*: bool
    noOptions*: bool
    version*: bool
    srcFilename*: string
    destJsonFile*: string

  JsonDocRawError = object of OSError

func newArgs*(cmlArgs: CmlArgs): Args =
  ## Create an Args object from a CmlArgs.
  result.help = "help" in cmlArgs
  result.noOptions = "noOptions" in cmlArgs
  result.version = "version" in cmlArgs
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
  ## Return the doc comment found in the given range of line
  ## numbers. The srcLines contain the line endings.

  # Get the start and ending indexes.
  let startIx = start - 1
  var endIx: int
  if finish == -1:
    endIx = srcLines.len - 1
  else:
    endIx = finish - 2
  if startIx < 0 or startIx > endIx:
    return
  if endIx >= srcLines.len:
    return

  # Create the description from the set of lines that start with ## or
  # #$. Remove the leading characters.
  let rePattern = re(r" *#(?:#|\$)")
  var foundNimDesc = false
  for line in srcLines[startIx .. endIx]:
    if line.startsWith(rePattern):
      # Strip the leading spaces.
      let stripped = strip(line, leading = true, trailing = false)

      # Remove the leading ## or #$ and one following character (not
      # newline) if it exists.

      if stripped.len == 2:
        # ##
        break
      elif stripped.len == 3:
        # ##_
        # ##a
        # ##n
        if stripped[2] == '\n':
          result.add('\n')
        else:
          break
      elif stripped.len > 3:
        # 0123
        # ## asdf\n
        # ## a
        # ## n
        # ##an
        # ##rn
        # ##asdf\n
        result.add(stripped[3 .. ^1])
      foundNimDesc = true
    elif foundNimDesc:
      break
  strip(result, trailing=false, chars = {'\n', '\r'})

proc readDescriptions*(text: string, lineNums: seq[int]): OrderedTable[string, string] =
  ## Read all the descriptions in the file specified by the starting
  ## line numbers. Return a dictionary mapping the line number to its
  ## description.
  # Split the lines and keep the line endings.
  let srcLines = text.splitNewLines()

  # Create the maximum line range for each description.
  var ranges = newSeq[tuple[start: int, finish: int]]()
  var start = 1
  var finish: int
  for lineNum in lineNums:
    finish = lineNum
    ranges.add( (start, finish) )
    start = finish
  ranges.add( (start, -1) )

  for r in ranges:
    result[$r.start] = readOneDesc(srcLines, r.start, r.finish)

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
  # not found, use the original.
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
    if args.help or args.noOptions:
      echo helpText
    elif args.version:
      echo "0.0.1"
    else:
      removePresentation(args)

  proc main(argv: seq[string]): int =
    ## Run jsondocraw

    # Parse the command line options.
    var options = newSeq[CmlOption]()
    options.add(newCmlOption("help", 'h', cmlStopArgument))
    options.add(newCmlOption("noOptions", '_', cmlNoOptions))
    options.add(newCmlOption("version", 'v', cmlStopArgument))
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
