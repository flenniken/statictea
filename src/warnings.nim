## Module for handling warnings.

import std/strutils
import messages

# todo: rename "warning" to "messageId".

type
  WarningData* = object
    ## Warning data.
    ## * warning -- the message id
    ## * p1 -- the optional string substituted for the message's $1.
    ## * pos -- the index in the statement where the warning was detected.
    warning*: MessageId
    p1*: string
    pos*: Natural

func getWarningLine*(filename: string, lineNum: int,
    warning: MessageId, p1 = ""): string =
  ## Return a formatted warning line. For example:
  ## @:
  ## @:~~~
  ## @:filename(line): wId: message.
  ## @:~~~~
  let pattern = Messages[warning]
  let warningCode = $ord(warning)
  let message = pattern % [p1]
  result = "$1($2): w$3: $4" % [filename, $lineNum, warningCode, message]

func getWarningLine*(filename: string, lineNum: int,
    warningData: WarningData): string =
  ## Return a formatted warning line. For example:
  ## @:
  ## @:~~~
  ## @:filename(line): wId: message.
  ## @:~~~~
  return getWarningLine(filename, lineNum, warningData)

func newWarningData*(warning: MessageId, p1 = "", pos = 0): WarningData =
  ## Create a WarningData object containing all the warning
  ## information.
  result = WarningData(warning: warning, p1: p1, pos: pos)

func dashIfEmpty(a: string): string =
  if a.len == 0:
    result = "-"
  else:
    result = a

func `$`*(warningData: WarningData): string =
  ## Return a string representation of WarningData.
  ## @:
  ## @:~~~
  ## @:let warning = newWarningData(wUnknownArg, "p1", 5)
  ## @:check $warning == "wUnknownArg(p1):5"
  ## @:~~~~
  result = "$1($2):$3" % [$warningData.warning,
    dashIfEmpty(warningData.p1), $warningData.pos]

func `==`*(w1: WarningData, w2: WarningData): bool =
  ## Return true when the two WarningData objects are equal.
  if w1.warning == w2.warning and w1.p1 == w2.p1 and w1.pos == w2.pos:
    result = true
