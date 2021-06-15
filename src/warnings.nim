## The warning messages.

import std/strutils

# Add new warnings to the bottom so the warning numbers never change.
type
  WarningData* = object
    ## Warning number and optional extra strings.
    warning*: Warning   ## Warning message id.
    p1*: string         ## Extra warning info.
    p2*: string         ## Extra warning info.

  Warning* = enum
    ## Warning numbers.
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
    wInvalidRepeat,        # w44
    wInvalidPrepost,       # w45
    wMissingCommaParen,    # w46
    wExpectedString,       # w47
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
    wNoTempFile,           # w59
    wExceededMaxLine,      # w60
    wSpaceAfterCommand,    # w61
    wTwoParameters,        # w62
    wNotSameKind,          # w63
    wNotNumberOrString,    # w64
    wTwoOrThreeParameters, # w65
    wTwoOrMoreParameters,  # w66
    wInvalidMaxRepeat,     # w67
    wContentNotSet,        # w68
    wThreeParameters,      # w69
    wExpectedInteger,      # w70
    wAllIntOrFloat,        # w71
    wOverflow,             # w72
    wUnused,               # w73
    wInvalidIndex,         # w74
    wExpectedDictionary,   # w75
    wThreeOrMoreParameters,# w76
    wInvalidMainType,      # w77
    wInvalidCondition,     # w78
    wInvalidVersion,       # w79
    wIntOrStringNumber,    # w80
    wFloatOrStringNumber,  # w81
    wExpectedRoundOption,  # w82
    wOneOrTwoParameters,   # w83
    wMissingNewLineContent, # w84
    wResultFileNotAllowed, # w85
    wUnableToOpenTempFile, # w86
    wUnableToRenameTemp,   # w87
    wNoTemplateName,       # w88
    wInvalidPosition,      # w89
    wEndLessThenStart,     # w90
    wSubstringNotFound,    # w91
    wDupStringTooLong,     # w92
    wPairParameters,       # w93
    wMissingElse,          # w94
    wImmutableVars,        # w95
    wExpected4Parameters,  # w96
    wInvalidLength,        # w97
    wMissingReplacement,   # w98
    wExpectedList,         # w99
    wExpectedSeparator,    # w100
    wReservedNameSpaces,   # w101
    wMissingVarName,       # w102
    wNotDict,              # w103
    wMissingDict,          # w104
    wExpectedSortOrder,    # w105
    wAllNotIntFloatString, # w106
    wIntFloatString,       # w107
    wNotZeroOne,           # w108
    wOneToFourParameters, # w109
    wExpectedSensitivity,  # w110
    wExpectedKey,          # w111
    wDictKeyMissing,       # w112
    wKeyValueKindDiff,     # w113
    wSubListsEmpty,        # w114
    wSubListsDiffTypes,    # w115
    kMaxWarnings,          # w116

const
    # The list of warnings. Add new messages to the bottom and do not
    # reorder the messages.
    warningsList*: array[low(Warning)..high(Warning), string] = [
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
      "No command found at column $1, treating it as a non-command line.", # wNoCommand
      """The matching closing comment postfix was not found, expected: "$1".""", # wNoPostfix
      "Missing the continuation command, abandoning the previous command.", # wNoContinuationLine
      "Ignoring extra text after the number.", # wSkippingTextAfterNum
      "Invalid number.", # wNotNumber
      "The number is too big or too small.", # wNumberOverFlow
      "Not enough memory for the line buffer.", # wNotEnoughMemoryForLB
      "Statement does not start with a variable name.", # wMissingStatementVar
      "Invalid string.", # wNotString
      "Unused text at the end of the statement. Missing semicolon?", # wTextAfterValue
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
      "Invalid count. It must be a positive integer.", # wInvalidMaxCount
      "Invalid t.content, it must be a string.", # wInvalidTeaContent
      "Invalid t.repeat, it must be an integer >= 0 and <= t.maxRepeat.", # wInvalidRepeat
      "Invalid prepost: $1.", # wInvalidPrepost
      "Expected comma or right parentheses.", # wMissingCommaParen
      "Expected a string.", # wExpectedString
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
      "The replacement variable doesn't exist: $1$2.", # wMissingReplacementVar
      "Unable to create a temporary file.", # wNoTempFile
      "Reached the maximum replacement block line count without finding the endblock.", # wExceededMaxLine
      "No space after the command.", # wSpaceAfterCommand
      "The function takes two parameters.", # wTwoParameters
      "The two parameters are not the same type.", # wNotSameKind
      "The parameters must be numbers or strings.", # wNotNumberOrString
      "The function takes two or three parameters.", # wTwoOrThreeParameters
      "The function takes two or more parameters.", # wTwoOrMoreParameters
      "The t.maxRepeat variable must be an integer >= t.repeat.", # wInvalidMaxRepeat
      "The t.content variable is not set for the replace command, treating it like the block command.", # wContentNotSet
      "Expected three parameters.", # wThreeParameters
      "The parameter must be an integer.", # wExpectedInteger
      "The parameters must be all integers or all floats.", # wAllIntOrFloat
      "Overflow or underflow.", # wOverflow
      "The parameter must be a string.", # wExpectedString
      "Index values must greater than or equal to 0, got: $1.", # wInvalidIndex
      "The parameter must be a dictionary.", # wExpectedDictionary
      "The function takes at least 3 parameters.", # wThreeOrMoreParameters
      "The main condition type must an int or string.", # wInvalidMainType
      "The case condition must be an int or string.", # wInvalidCondition
      "Invalid StaticTea version string.", # wInvalidVersion
      "Expected int or int number string.", # wIntOrStringNumber
      "Expected a float or float number string.", # wFloatOrStringNumber
      "Expected round, floor, ceiling or truncate.", # wExpectedRoundOption
      "The function takes one or two parameters.", # wOneOrTwoParameters
      "The t.content does not end with a newline, adding one.", # wMissingNewLineContent
      "The update option overwrites the template, no result file allowed.", # wResultFileNotAllowed
      "Unable to open temporary file.", # wUnableToOpenTempFile
      "Unable to rename temporary file over template file.", # wUnableToRenameTemp
      "No template name. Use -h for help.", # wNoTemplateName
      "Invalid position: got $1.", # wInvalidPosition
      "The end position is less that the start position.", # wEndLessThenStart
      "The substring was not found and no default parameter.", # wSubstringNotFound
      "The resulting duplicated string must be under 1024 characters, got: $1.", # wDupStringTooLong
      "Specify parameters in pairs.", # wPairParameters
      "None of the case conditions match and no else case.", # wMissingElse
      "Variable already exists, assign to a new variable.", # wImmutableVars
      "Expected four parameters.", # wExpected4Parameters
      "Invalid length: $1.", # wInvalidLength
      "Invalid number of parameters, the pattern and replacement come in pairs.", # wMissingReplacement
      "Expected a list.", # wExpectedList
      "Expected / or \\.", # wExpectedSeparator
      "The variables f, g, h, l, s and t are reserved variable names.", # wReservedNameSpaces
      "Name, $1, doesn't exist in the parent dictionary.", # wMissingVarName
      "Name, $1, is not a dictionary.", # wNotDict
      "The dictionary $1 doesn't exist.", # wMissingDict
      "Expected the sort order, 'ascending' or 'descending'.", # wExpectedSortOrder
      "The list values must be all ints, all floats or all strings.", # wAllNotIntFloatString
      "The values must be integers, floats or strings.", # wIntFloatString
      "The parameter must be 0 or 1.", # wNotZeroOne
      "The function takes one to four parameters.", # wOneToFourParameters
      "Expected the sensitive or unsensitive.", # wExpectedSensitivity
      "Expected the dictionary sort key.", # wExpectedKey
      "A dictionary is missing the sort key.", # wDictKeyMissing
      "The sort key values are different types.", # wKeyValueKindDiff
      "A sublist is empty.", # wSubListsEmpty
      "The first item in the sublists are different types.", # wSubListsDiffTypes
      "Reached the maximum number of warnings, suppressing the rest.", #kMaxWarnings
    ]

func getWarning*(filename: string, lineNum: int,
    warning: Warning, p1: string = "", p2: string = ""): string =
  ## Return a formatted warning line.
  let pattern = warningsList[warning]
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
