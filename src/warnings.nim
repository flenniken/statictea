## Table of warning messages.

import tpub
import strutils

# Add new warnings to the bottom so the warning numbers never change.
type
  Warning* = enum
    wNoFilename, # w0
    wUnknownSwitch, # w1
    wUnknownArg, # w2
    wOneResultAllowed, # w3
    wExtraPrepostText, # w4
    wOneTemplateAllowed, # w5
    wNoPrepostValue, # w6
    wSkippingExtraPrepost, # w7
    wUnableToOpenLogFile, # w8
    wOneLogAllowed, # w9
    wUnableToWriteLogFile, # w10
    wExceptionMsg, # w11
    wStackTrace, # w12
    wUnexpectedException, # w13
    wInvalidJsonRoot, # w14
    wJsonParseError, # w15
    wFileNotFound, # w16
    wUnableToOpenFile, # w17
    wBigLogFile, # w18

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
      "The root json element must be an object. Skipping file: $1.", # wInvalidJsonRoot
      "Unable to parse the json file. Skipping file: $1.", # wJsonParseError
      "File not found: $1.", # wFileNotFound
      "Unable to open file: $1.", # wUnableToOpenFile
      "The statictea.log file is getting big, delete it or setup log rotation. Size: $1.", # wBigLogFile
    ]

func getWarning*(filename: string, lineNum: int,
    warning: Warning, p1: string = "", p2: string = ""): string =
  ## Return the formatted warning line.
  let pattern = warningsList[warning]
  let warningCode = $ord(warning)
  let message = pattern % [p1, p2]
  result = "$1($2): w$3: $4" % [filename, $lineNum, warningCode, message]
