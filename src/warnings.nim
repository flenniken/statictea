## Handle warning messages.

import streams
import tpub
import strutils

type
  Warning* = enum
    wNoFilename,
    wUnknownSwitch,
    wUnknownArg,
    wOneResultAllowed,
    wExtraPrepostText,
    wOneTemplateAllowed,
    wNoPrepostValue,
    wSkippingExtraPrepost,
    wUnableToOpenLogFile,
    wOneLogAllowed,

tpubType:
  const
    # The list of warnings. Add new messages to the bottom and do not
    # reorder the messages.
    warningsList: array[low(Warning)..high(Warning), string] = [
      "No $1 filename. Use $2=filename.", # wNoFilename
      "Unknown switch: $1.", # wUnknownSwitch
      "Unknown argument: $1.", # wUnknownArg
      "One result file allowed, skipping: '$1'.", # wOneResultAllowed
      "Skipping extra prepost text: $1.", # wExtraPrepostText
      "One template file allowed, skipping: $1.", # wOneTemplateAllowed
      "No prepost value. Use $1=\"...\".", # wNoPrepostValue
      "Skipping extra prepost text: $1.", # wSkippingExtraPrepost
      "Unable to open log file: '$1'.", # wUnableToOpenLogFile
      "One log file allowed, skipping: '$1'.", # wOneLogAllowed
    ]

func getWarning(filename: string, lineNum: int,
    warning: Warning, p1: string = "", p2: string = ""): string {.tpub.} =

  let pattern = warningsList[warning]
  let message = pattern % [p1, p2]
  let messageNum = ord(warning)
  result = "$1($2): w$3: $4" % [filename, $lineNum, $messageNum, message]


proc warning*(outStream: Stream, filename: string = "", lineNum: int=0,
    warning: Warning, p1: string = "", p2: string = "") =

  let fullLine = getWarning(filename, lineNum, warning, p1, p2)
  outStream.writeLine(fullLine)
