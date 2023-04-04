## Messages IDs and associated strings and routines to get them.

import std/macros
import std/strutils
import std/strformat

type
  MessageLine = object
    num: int
    wEnum: string
    msg: string

proc stopMsg(message: string) =
  ## Stop the compiler at compile time and show a message.
  echo message
  doAssert(false, "Error: invalid line, see details above.")

proc stopLine(ix: int, line: string, msg: string, field = "") =
  ## Stop and show the invalid line.
  let message = fmt"""

message.txt({ix}): {msg}
          field: {field}
     Error line: {line}
"""
  stopMsg(message)

proc readMessages(): seq[MessageLine] =
  ## Read the message.txt file into a list of MessageLines at compile
  ## time.

  let text = slurp("messages.txt")
  let textLines = text.splitLines()
  for ix, line in textLines:
    let fields = line.splitWhitespace(2)
    # Skip comment and blank lines.
    if fields.len == 0 or fields[0].startsWith("#"):
      continue

    var num: int
    var wEnum: string
    var msg: string

    let wNum = fields[0]
    if not wNum.startsWith("w"):
      stopLine(ix, line, "The first column field must start with w.", wNum)
    try:
      num = parseInt(wNum[1 .. ^1])
    except ValueError:
      stopLine(ix, line, "The first column field must be w followed by digits.", wNum)

    if fields.len < 2:
      stopLine(ix, line, "Got an wNum, expected an enum and message.")
    wEnum = fields[1]
    if not wEnum.startsWith("w"):
      stopLine(ix, line, "The second column field enum must start with w.", wEnum)

    if fields.len < 3:
      stopLine(ix, line, "Got wNum and wEnum, expected a message.")
    msg = fields[2]
    if not msg.startsWith("\""):
      stopLine(ix, line, "The third column message must start with \".", msg)
    if not msg.endsWith("\""):
      stopLine(ix, line, "The third column message must end with \".", msg)

    result.add(MessageLine(num: num, wEnum: wEnum, msg: msg))

macro genMsgData() =
  ## Macro that creates enums and an array of the messages at compile
  ## time from the messages.txt file.
  let messageLines = readMessages()

  # Create enums for each message.
  var source = """
type
  MessageId* = enum
    ## Message numbers.
"""
  var expectedNum = 0
  for ix, messageLine in messageLines:
    if messageLine.num != expectedNum:
      let message = fmt"""

Error: Number out of order, got {messageLine.num}, expected {expectedNum}.
 Line: w{messageLine.num} {messageLine.wEnum} {messageLine.msg}
"""
      stopMsg(message)
    source.add(fmt"    {messageLine.wEnum}," & "\n")
    inc(expectedNum)
  source.add("\n")
  # echo source

  # Generate an array of all the messages.
  source.add(fmt"""
const
  Messages*: array[low(MessageId)..high(MessageId), string] = [
""")
  for messageLine in messageLines:
    source.add(fmt"    {messageLine.msg}," & "\n")
  source.add("""
    ]
      ## The message text.
""")
  # echo source
  result = parseStmt(source)

genMsgData()

type
  WarningData* = object
    ## Warning data.
    ## * messageId -- the message id
    ## * p1 -- the optional string substituted for the message's $1.
    ## * pos -- the index in the statement where the warning was detected.
    messageId*: MessageId
    p1*: string
    pos*: Natural

func getWarning*(warning: MessageId, p1 = ""): string =
  ## Return the warning string.
  let pattern = Messages[warning]
  result = pattern % [p1]

func getWarningLine*(filename: string, lineNum: int,
    warning: MessageId, p1 = ""): string =
  ## Return a formatted warning line. For example:
  ##
  ## ~~~
  ## filename(line): wId: message.
  ## ~~~
  let warningCode = $ord(warning)
  result = "$1($2): w$3: $4" % [filename, $lineNum, warningCode, getWarning(warning, p1)]

func getWarningLine*(filename: string, lineNum: int,
    warningData: WarningData): string =
  ## Return a formatted warning line. For example:
  ##
  ## ~~~
  ## filename(line): wId: message.
  ## ~~~
  return getWarningLine(filename, lineNum, warningData)

func newWarningData*(messageId: MessageId, p1 = "", pos = 0): WarningData =
  ## Create a WarningData object containing all the warning
  ## information.
  result = WarningData(messageId: messageId, p1: p1, pos: pos)

func `$`*(warningData: WarningData): string =
  ## Return a string representation of WarningData.
  ##
  ## ~~~nim
  ## let warning = newWarningData(wUnknownArg, "p1", 5)
  ## check $warning == "wUnknownArg(p1):5"
  ## ~~~
  result = """$1 p1="$2" pos=$3""" % [$warningData.messageId,
    warningData.p1, $warningData.pos]

func `==`*(w1: WarningData, w2: WarningData): bool =
  ## Return true when the two WarningData objects are equal.
  if w1.messageId == w2.messageId and w1.p1 == w2.p1 and w1.pos == w2.pos:
    result = true
