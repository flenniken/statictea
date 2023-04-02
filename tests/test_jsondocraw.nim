import std/os
import std/unittest
import std/tables
import std/strformat
import cmdline
import jsondocraw
import sharedtestcode
import comparelines

suite "jsondocraw.nim":

  test "test me":
    check 1 == 1

  test "newArgs":
    var cmlArgs: CmlArgs
    cmlArgs["srcFilename"] = @["src/readjson.nim"]
    cmlArgs["destJsonFile"] = @["src/readjson.nim"]
    let args = newArgs(cmlArgs)
    let expected = """
args.help = false
args.srcFilename = 'src/readjson.nim'
args.destJsonFile = 'src/readjson.nim'"""
    check gotExpected($args, expected)

  test "getMessage":
    let got = jsondocraw.getMessage(cml_02_OptionRequiresArg, "testme")
    let expected = "The option 'testme' requires an argument."
    check gotExpected(got, expected)

  test "readOneDesc one":
    let sourceCode = """
## Parse the command line.
import std/os
import std/tables
import std/strutils
"""
    let expected = """
Parse the command line.
"""
    let srcLines = splitNewLines(sourceCode)
    let got = readOneDesc(srcLines, 1, 4)
    check gotExpected(got, expected)

  test "readOneDesc 2":
    let sourceCode = """
  ## line one
  ## line two
"""
    let expected = """
line one
line two
"""
    let srcLines = splitNewLines(sourceCode)
    let got = readOneDesc(srcLines, 1, 3)
    check gotExpected(got, expected)

  test "readOneDesc 3":
    let sourceCode = """
  ##   line one
  ##    line two
  ##  line three
"""
    let expected = """
 line one
  line two
line three
"""
    let srcLines = splitNewLines(sourceCode)
    let got = readOneDesc(srcLines, 1, 4)
    check gotExpected(got, expected)

  test "readOneDesc 3":
    let sourceCode = """
  ##   line one
  ##    line two
  ##  line three
"""
    let expected = """
line one
"""
    let srcLines = splitNewLines(sourceCode)
    let got = readOneDesc(srcLines, 1, 2)
    check gotExpected(got, expected)

  test "readOneDesc cmdline":
    let sourceCode = """
import std/os
import std/tables
import std/strutils

type
  CmlArgs* = OrderedTable[string, seq[string]]
    ## CmlArgs holds the parsed command line arguments in an ordered
    ## dictionary. The keys are the supported options found on the
    ## command line and each value is a list of associated arguments.
    ## An option without arguments will have an empty list.

  CmlMessageId* = enum
    ## Possible message IDs returned by cmdline. The number in the
    ## name is the same as its ord value.  Since the message handling
    ## is left to the caller, it is important for these values to be
    ## stable. New values are added to the end and this is a minor
    ## version change. It is ok to leave unused values in the list and
    ## this is backward compatible. If items are removed or reordered,
    ## that is a major version change.
    cml_00_BareTwoDashes,
    cml_01_InvalidOption,
    cml_02_OptionRequiresArg,
    cml_03_BareOneDash,
"""
    let expected = """
CmlArgs holds the parsed command line arguments in an ordered
dictionary. The keys are the supported options found on the
command line and each value is a list of associated arguments.
An option without arguments will have an empty list.
"""
    let srcLines = splitNewLines(sourceCode)
    let got = readOneDesc(srcLines, 6, 12)
    check gotExpected(got, expected)

  test "readDescriptions":
    let text = """
  ArgsOrMessageKind* = enum
    ## The kind of an ArgsOrMessage object, either args or a message.
    cmlArgsKind,
    cmlMessageKind

  ArgsOrMessage* = object
    ## Contains the command line args or a message.
    case kind*: ArgsOrMessageKind
    of cmlArgsKind:
      args*: CmlArgs
    of cmlMessageKind:
      messageId*: CmlMessageId
      problemArg*: string

  CmlOptionType* = enum
    ## The option type.
    ##
    ## * cmlArgument0or1 -- option with an argument, 0 or 1 times.
    ## * cmlNoArgument -- option without an argument, 0 or 1 times.
    ## * cmlOptionalArgument -- option with an optional argument, 0
    ##     or 1 times.
    ## * cmlBareArgument -- an argument without an option, 1 time.
    ## * cmlArgumentOnce -- option with an argument, 1 time.
    ## * cmlArgumentMany -- option with an argument, unlimited
    ##     number of times.
    ## * cmlStopArgument -- option without an argument, 0 or 1
    ##     times. Stop and return this option by itself.
    cmlArgument0or1
    cmlNoArgument
    cmlOptionalArgument
    cmlBareArgument
    cmlArgumentOnce
    cmlArgumentMany
    cmlStopArgument

  CmlOption* = object
    ## An CmlOption holds its type, long name and short name.
    optionType: CmlOptionType
    long: string
    short: char
"""
    let lineNums = @[1, 6, 15, 36]
    let mapping = readDescriptions(text, lineNums)
    var got = ""
    for k, v in mapping.pairs():
      got.add(fmt"{k}: {v}")
    # echo got
    let expected = """
1: The kind of an ArgsOrMessage object, either args or a message.
6: Contains the command line args or a message.
15:  The option type.

 * cmlArgument0or1 -- option with an argument, 0 or 1 times.
 * cmlNoArgument -- option without an argument, 0 or 1 times.
 * cmlOptionalArgument -- option with an optional argument, 0
     or 1 times.
 * cmlBareArgument -- an argument without an option, 1 time.
 * cmlArgumentOnce -- option with an argument, 1 time.
 * cmlArgumentMany -- option with an argument, unlimited
     number of times.
 * cmlStopArgument -- option without an argument, 0 or 1
     times. Stop and return this option by itself.
36: An CmlOption holds its type, long name and short name.
"""
    if got != expected:
      echo linesSideBySide(got, expected)
      fail

  test "removePresentation":
    var cmlArgs: CmlArgs
    cmlArgs["srcFilename"] = @["src/cmdline.nim"]
    cmlArgs["destJsonFile"] = @["docs/cmdline.json"]
    let args = newArgs(cmlArgs)

    check fileExists(args.srcFilename)
    discard tryRemoveFile(args.destJsonFile)

    removePresentation(args)

    check fileExists(args.srcFilename)
    check fileExists(args.destJsonFile)

    discard tryRemoveFile(args.destJsonFile)
