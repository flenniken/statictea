## Private module for experimenting.

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
  ## Read the message.txt file into a list of MessageLines.

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
  Messages*: array[0..{messageLines.len-1}, string] = [
""")
  for messageLine in messageLines:
    source.add(fmt"    {messageLine.msg}," & "\n")
  source.add("    ]\n")
  # echo source
  result = parseStmt(source)

genMsgData()

echo fmt"There are {Messages.len} messages with enums from {MessageId.low}({ord(MessageId.low)}) to {MessageId.high}({ord(MessageId.high)})"
echo fmt"{wSuccess}: {Messages[0]}"
