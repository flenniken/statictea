## The warning messages.

import std/strutils
# todo: change include messages to import messages.
import messages

type
  Warning* = MessageId
    ## Warning message id.
  
  WarningData* = object
    ## Warning number and optional extra strings.
    warning*: Warning ## Message id.
    p1*: string         ## Optional warning info.
    p2*: string         ## Optional warning info.

func getWarning*(filename: string, lineNum: int,
    warning: Warning, p1: string = "", p2: string = ""): string =
  ## Return a formatted warning line.
  let pattern = Messages[warning]
  let warningCode = $ord(warning)
  let message = pattern % [p1, p2]
  result = "$1($2): w$3: $4" % [filename, $lineNum, warningCode, message]

proc newWarningData*(warning: Warning, p1: string = "", p2: string = ""): WarningData =
  ## Create a WarningData object containing the warning information.
  result = WarningData(warning: warning, p1: p1, p2: p2)

func dashIfEmpty(a: string): string =
  if a.len == 0:
    result = "-"
  else:
    result = a

func `$`*(warningData: WarningData): string =
  ## Return a string representation of WarningData.
  result = "$1($2, $3)" % [$warningData.warning,
    dashIfEmpty(warningData.p1), dashIfEmpty(warningData.p2)]

func `==`*(w1: WarningData, w2: WarningData): bool =
  ## Return true when the two WarningData are equal.
  if w1.warning == w2.warning and w1.p1 == w2.p1 and w1.p2 == w2.p2:
    result = true
