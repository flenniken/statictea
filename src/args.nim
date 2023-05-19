## Types for handling command line arguments.

import std/strformat
import messages
import opresult
import tables

type
  Prepost* = object
    ## Prepost holds one prefix and its associated postfix.
    prefix*: string
    postfix*: string

  PrepostTable* = OrderedTable[string, string]
    ## The prefix postfix pairs stored in an ordered dictionary
    ## mapping the prefix to the postfix.

  Args* = object
    ## Args holds all the command line arguments.
    help*: bool
    version*: bool
    update*: bool
    log*: bool
    repl*: bool
    serverList*: seq[string]
    codeList*: seq[string]
    prepostList*: seq[Prepost]
    templateFilename*: string
    resultFilename*: string
    logFilename*: string

  ArgsOr* = OpResultWarn[Args]
    ## The args or a warning.

proc makeUserPrepostTable*(prepostList: seq[Prepost]): PrepostTable =
  ## Return the user's ordered table that maps prefixes to
  ## postfixes. This is used when the user specifies prefixes on the
  ## command line and it does not contain any defaults.
  assert prepostList.len > 0
  result = initOrderedTable[string, string]()
  for prepost in prepostList:
    # The prefix and postfix values have been validated by the command line
    # processing procedure parsePrepost.
    assert prepost.prefix != ""
    result[prepost.prefix] = prepost.postfix

func newArgsOr*(warningData: WarningData):
     ArgsOr =
  ## Return a new ArgsOr object containing a warning.
  result = opMessageW[Args](warningData)

func newArgsOr*(warning: MessageId, p1: string = "", pos = 0):
     ArgsOr =
  ## Return a new ArgsOr object containing a warning.
  let warningData = newWarningData(warning, p1, pos)
  result = opMessageW[Args](warningData)

func newArgsOr*(args: Args): ArgsOr =
  ## Return a new ArgsOr object containing args.
  result = opValueW[Args](args)

func newPrepost*(prefix: string, postfix: string): Prepost =
  ## Create a new prepost object from the prefix and postfix.
  result = Prepost(prefix: prefix, postfix: postfix)

func toString(list: openArray[string]): string =
  ## Return the string representation of an array of strings.
  result = "["
  for i, item in list:
    if i > 0:
      result.add(", ")
    result.add(fmt""""{item}"""")
  result.add("]")

func `$`*(p: Prepost): string =
  ## Return the Prepost string representation.
  result = fmt""""{p.prefix},{p.postfix}""""

func toString(list: openArray[Prepost]): string =
  ## Return the Prepost list string representation.
  result = "["
  for i, prepost in list:
    if i > 0:
      result.add(", ")
    result.add($prepost)
  result.add("]")

func `$`*(args: Args): string =
  ## Return the Args string representation.
  result.add(fmt"""
args.help = {args.help}
args.version = {args.version}
args.update = {args.update}
args.log = {args.log}
args.repl = {args.repl}
args.logFilename = "{args.logFilename}"
args.resultFilename = "{args.resultFilename}"
args.serverList = {toString(args.serverList)}
args.codeList = {toString(args.codeList)}
args.templateFilename = "{args.templateFilename}"
args.prepostList = {toString(args.prepostList)}""")

func `$`*(prepostList: seq[Prepost]): string =
  ## Return the seq[Prepost] string representation.
  var first = true
  for pp in prepostList:
    if not first:
      result.add(", ")
    first = false
    result.add(fmt"({pp.prefix}, {pp.postfix})")

const
  predefinedPrepost*: array[8, Prepost] = [
    newPrepost("$$", ""),
    newPrepost("<!--$", "-->"),
    newPrepost("#$", ""),
    newPrepost(";$", ""),
    newPrepost("//$", ""),
    newPrepost("/*$", "*/"),
    newPrepost("&lt;!--$", "--&gt;"),
    newPrepost("# $", "")
  ]
    ## The predefined prefixes and postfixes.

proc makeDefaultPrepostTable*(): PrepostTable =
  ## Return the default ordered table that maps prefixes to postfixes.
  result = initOrderedTable[string, string]()
  for prepost in predefinedPrepost:
    assert prepost.prefix != ""
    result[prepost.prefix] = prepost.postfix

proc getPrepostTable*(args: Args): PrepostTable =
  ## Get the the prepost settings from the user or use the default
  ## ones.

  # Get the prepost table, either the user specified one or the
  # default one. The defaults are not used when the user specifies
  # them, so that they have complete control over the preposts used.
  if args.prepostList.len > 0:
    # The prepostList has been validated already.
    result = makeUserPrepostTable(args.prepostList)
  else:
    result = makeDefaultPrepostTable()
