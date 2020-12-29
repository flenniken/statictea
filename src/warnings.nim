## Table of warning messages.

import tpub
import strutils

# Add new warnings to the bottom so the warning numbers never change.
type
  Warning* = enum
    wNoFilename,           # w0
    wUnknownSwitch,        # w1
    wUnknownArg,           # w2
    wOneResultAllowed,     # w3
    wExtraPrepostText,     # w4
    wOneTemplateAllowed,   # w5
    wNoPrepostValue,       # w6
    wSkippingExtraPrepost, # w7
    wUnableToOpenLogFile,  # w8
    wOneLogAllowed,        # w9
    wUnableToWriteLogFile, # w10
    wExceptionMsg,         # w11
    wStackTrace,           # w12
    wUnexpectedException,  # w13
    wInvalidJsonRoot,      # w14
    wJsonParseError,       # w15
    wFileNotFound,         # w16
    wUnableToOpenFile,     # w17
    wBigLogFile,           # w18
    wCannotOpenStd,        # w19
    wNotACommand,          # w20
    wCmdLineTooLong,       # w21
    wNoCommand,            # w22
    wNoPostfix,            # w23
    wNoContinuationLine,   # w24
    wSkippingTextAfterNum, # w25
    wNotNumber,            # w26
    wNumberOverFlow,       # w27
    wNotEnoughMemoryForLB, # w28
    wMissingStatementVar,  # w29
    wNotString,            # w30
    wTextAfterValue,       # w31
    wInvalidUtf8,          # w32
    wInvalidRightHandSide, # w33
    wInvalidVariable,      # w34
    wInvalidNameSpace,     # w35
    wVariableMissing,      # w36
    wStatementError,       # w37
    wReadOnlyDictionary,   # w38
    wReadOnlyTeaVar,       # w39
    wInvalidTeaVar,        # w40
    wInvalidOutputValue,   # w41
    wInvalidMaxCount,      # w42
    wInvalidTeaContent,    # w43
    wInvalidMaxRepeat,     # w44
    wInvalidPrepost,       # w45
    wMissingCommaParen,    # w46
    wExpectedStrings,      # w47
    wInvalidStatement,     # w48
    wOneParameter,         # w49
    wStringListDict,       # w50
    wInvalidFunction,      # w51
    wGetTakes2or3Params,   # w52
    wExpectedIntFor2,      # w53
    wMissingListItem,      # w54
    wExpectedStringFor2,   # w55
    wMissingDictItem,      # w56
    wExpectedListOrDict,   # w57
    wMissingReplacementVar, # w58

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
      "One template file allowed on the command line, skipping: $1.", # wOneTemplateAllowed
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
      "Setup log rotation for $1 which has $2 bytes.", # wBigLogFile
      "Unable to open standard device: $1.", # wCannotOpenStd
      "No command specified on the line, treating it as a comment.", # wNotACommand
      "Command line too long.", # wCmdLineTooLong
      "No command found at column $1, skipping line.", # wNoCommand
      """The matching closing comment postfix was not found, expected: "$1".""", # wNoPostfix
      "Missing the continuation line, abandoning the command.", # wNoContinuationLine
      "Ignoring extra text after the number.", # wSkippingTextAfterNum
      "Invalid number.", # wNotNumber
      "The number is too big or too small.", # wNumberOverFlow
      "Not enough memory for the line buffer.", # wNotEnoughMemoryForLB
      "Statement does not start with a variable name.", # wMissingStatementVar
      "Invalid string.", # wNotString
      "Unused text at the end of the statement.", # wTextAfterValue
      "Invalid UTF-8 byte in the string.", # wInvalidUtf8
      "Expected a string, number, variable or function.", # wInvalidRightHandSide
      "Invalid variable or missing equal sign.", # wInvalidVariable
      "The variable namespace '$1' does not exist.", # wInvalidNameSpace
      "The variable '$1' does not exist.", # wVariableMissing
      "The statement starting at column $1 has an error.", # wStatementError
      "You cannot overwrite the server or shared variables.", # wReadOnlyDictionary
      "You cannot change the $1 tea variable.", # wReadOnlyTeaVar
      "Invalid tea variable: $1.", # wInvalidTeaVar
      """Invalid t.output value, use: "result", "stderr", "log", or "skip".""", # wInvalidOutputValue
      "Invalid max count, it must be an integer >= 0.", # wInvalidMaxCount
      "Invalid t.content, it must be a string.", # wInvalidTeaContent
      "Invalid t.repeat, it must be an integer >= 0 and <= t.maxRepeat.", # wInvalidMaxRepeat
      "Invalid prepost: $1.", # wInvalidPrepost
      "Expected comma or right parentheses.", # wMissingCommaParen
      "Concat parameter $1 is not a string.", # wExpectedStrings
      "Invalid statement, skipping it.", # wInvalidStatement
      "Expected one parameter.", # wOneParameter
      "Len takes a string, list or dict parameter.", # wStringListDict
      "Not a function: $1.", # wInvalidFunction
      "The get function takes 2 or 3 parameters.", # wGetTakes2or3Params
      "Expected an int for the second parameter, got $1.", # wExpectedIntFor2
      "The list index $1 out of range.", # wMissingListItem
      "Expected a string for the second parameter, got $1.", # wExpectedStringFor2
      "The dictionary does not have an item with key $1.", # wMissingDictItem
      "Expected a list or dictionary as the first parameter.", # wExpectedListOrDict
      "The replacement variable doesn't exist: $1.", # wMissingReplacementVar
    ]

func getWarning*(filename: string, lineNum: int,
    warning: Warning, p1: string = "", p2: string = ""): string =
  ## Return the formatted warning line.
  let pattern = warningsList[warning]
  let warningCode = $ord(warning)
  let message = pattern % [p1, p2]
  result = "$1($2): w$3: $4" % [filename, $lineNum, warningCode, message]
