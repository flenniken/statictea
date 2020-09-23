## Table of warning messages.

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
    wUnableToWriteLogFile,
    wExceptionMsg,
    wStackTrace,
    wUnexpectedException,

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
      "Unable to write to the log file: '$1'.", # wUnableToWriteLogFile
      "Exception: '$1'.", # wExceptionMsg
      "Stack trace: '$1'.", # wStackTrace
      "Unexpected exception: '$1'.", # wUnexpectedException
    ]

func getWarning*(filename: string, lineNum: int,
    warning: Warning, p1: string = "", p2: string = ""): string =
  ## Return the formatted warning line.
  let pattern = warningsList[warning]
  let message = pattern % [p1, p2]
  let messageNum = ord(warning)
  result = "$1($2): w$3: $4" % [filename, $lineNum, $messageNum, message]
