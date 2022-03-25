## Module for handling warnings.

import std/strutils
import messages

type
  Warning* = MessageId
    ## Warning message id.

  WarningData* = object
    ## Warning data.
    warning*: Warning ## Message id.
    p1*: string ## Optional extra warning string.
    pos*: Natural ## Position in the statement.

func getWarningLine*(filename: string, lineNum: int,
    warning: Warning, p1 = ""): string =
  ## Return a formatted warning line.
  let pattern = Messages[warning]
  let warningCode = $ord(warning)
  let message = pattern % [p1]
  result = "$1($2): w$3: $4" % [filename, $lineNum, warningCode, message]

func getWarningLine*(filename: string, lineNum: int,
    warningData: WarningData): string =
  ## Return a formatted warning line.
  return getWarningLine(filename, lineNum, warningData)

proc newWarningData*(warning: Warning, p1 = "", pos = 0): WarningData =
  ## Create a WarningData object containing the warning information.
  result = WarningData(warning: warning, p1: p1, pos: pos)

func dashIfEmpty(a: string): string =
  if a.len == 0:
    result = "-"
  else:
    result = a

func `$`*(warningData: WarningData): string =
  ## Return a string representation of WarningData.
  result = "$1($2):$3" % [$warningData.warning,
    dashIfEmpty(warningData.p1), $warningData.pos]

func `==`*(w1: WarningData, w2: WarningData): bool =
  ## Return true when the two WarningData are equal.
  if w1.warning == w2.warning and w1.p1 == w2.p1 and w1.pos == w2.pos:
    result = true
