## Messages IDs and associated strings.

# Add new messages to the bottom and do not reorder, delete or reuse
# the messages so the existing message numbers never change.  Create
# new ids for each error so different parts of the code are
# independent.

type
  MessageId* = enum
    ## Message numbers.
    wSuccess,              ## w0
    wUnknownSwitch,        ## w1
    wUnknownArg,           ## w2
    wOneResultAllowed,     ## w3
    wExtraPrepostText,     ## w4
    wOneTemplateAllowed,   ## w5
    wNoPrepostValue,       ## w6
    wSkippingExtraPrepost, ## w7
    wUnableToOpenLogFile,  ## w8
    wOneLogAllowed,        ## w9
    wUnableToWriteLogFile, ## w10
    wExceptionMsg,         ## w11
    wStackTrace,           ## w12
    wUnexpectedException,  ## w13
    wInvalidJsonRoot,      ## w14
    wJsonParseError,       ## w15
    wFileNotFound,         ## w16
    wUnableToOpenFile,     ## w17
    wBigLogFile,           ## w18
    wCannotOpenStd,        ## w19
    wNotACommand,          ## w20
    wCmdLineTooLong,       ## w21
    wNoCommand,            ## w22
    wNoPostfix,            ## w23
    wNoContinuationLine,   ## w24
    wSkippingTextAfterNum, ## w25
    wNotNumber,            ## w26
    wNumberOverFlow,       ## w27
    wNotEnoughMemoryForLB, ## w28
    wMissingStatementVar,  ## w29
    wNotString,            ## w30
    wTextAfterValue,       ## w31
    wInvalidUtf8,          ## w32
    wInvalidRightHandSide, ## w33
    wInvalidVariable,      ## w34
    wInvalidNameSpace,     ## w35
    wVariableMissing,      ## w36
    wStatementError,       ## w37
    wReadOnlyDictionary,   ## w38
    wReadOnlyTeaVar,       ## w39
    wInvalidTeaVar,        ## w40
    wInvalidOutputValue,   ## w41
    wInvalidMaxCount,      ## w42
    wInvalidTeaContent,    ## w43
    wInvalidRepeat,        ## w44
    wInvalidPrepost,       ## w45
    wMissingCommaParen,    ## w46
    wExpectedString,       ## w47
    wInvalidStatement,     ## w48
    wOneParameter,         ## w49
    wStringListDict,       ## w50
    wInvalidFunction,      ## w51
    wGetTakes2or3Params,   ## w52
    wExpectedIntFor2,      ## w53
    wMissingListItem,      ## w54
    wExpectedStringFor2,   ## w55
    wMissingDictItem,      ## w56
    wExpectedListOrDict,   ## w57
    wMissingReplacementVar, ## w58
    wNoTempFile,           ## w59
    wExceededMaxLine,      ## w60
    wSpaceAfterCommand,    ## w61
    wTwoParameters,        ## w62
    wNotSameKind,          ## w63
    wNotNumberOrString,    ## w64
    wTwoOrThreeParameters, ## w65
    wTwoOrMoreParameters,  ## w66
    wInvalidMaxRepeat,     ## w67
    wContentNotSet,        ## w68
    wThreeParameters,      ## w69
    wExpectedInteger,      ## w70
    wAllIntOrFloat,        ## w71
    wOverflow,             ## w72
    wUnused,               ## w73
    wInvalidIndex,         ## w74
    wExpectedDictionary,   ## w75
    wThreeOrMoreParameters,## w76
    wInvalidMainType,      ## w77
    wInvalidCondition,     ## w78
    wInvalidVersion,       ## w79
    wIntOrStringNumber,    ## w80
    wFloatOrStringNumber,  ## w81
    wExpectedRoundOption,  ## w82
    wOneOrTwoParameters,   ## w83
    wMissingNewLineContent, ## w84
    wResultFileNotAllowed, ## w85
    wUnableToOpenTempFile, ## w86
    wUnableToRenameTemp,   ## w87
    wNoTemplateName,       ## w88
    wInvalidPosition,      ## w89
    wEndLessThenStart,     ## w90
    wSubstringNotFound,    ## w91
    wDupStringTooLong,     ## w92
    wPairParameters,       ## w93
    wMissingElse,          ## w94
    wImmutableVars,        ## w95
    wExpected4Parameters,  ## w96
    wInvalidLength,        ## w97
    wMissingReplacement,   ## w98
    wExpectedList,         ## w99
    wExpectedSeparator,    ## w100
    wReservedNameSpaces,   ## w101
    wMissingVarName,       ## w102
    wNotDict,              ## w103
    wMissingDict,          ## w104
    wExpectedSortOrder,    ## w105
    wAllNotIntFloatString, ## w106
    wIntFloatString,       ## w107
    wNotZeroOne,           ## w108
    wOneToFourParameters,  ## w109
    wExpectedSensitivity,  ## w110
    wExpectedKey,          ## w111
    wDictKeyMissing,       ## w112
    wKeyValueKindDiff,     ## w113
    wSubListsEmpty,        ## w114
    wSubListsDiffTypes,    ## w115
    kMaxWarnings,          ## w116
    kInvalidSignature,     ## w117
    kInvalidParamType,     ## w118
    kNotEnoughArgs,        ## w119
    kWrongType,            ## w120
    kNoVarargArgs,         ## w121
    kNotEnoughVarargs,     ## w122
    kTooManyArgs,          ## w123
    wAtLeast4Parameters,   ## w124
    wExpectedNumberString, ## w125
    wCaseTypeMismatch,     ## w126
    wNotEvenCases,         ## w127
    wNotAllStrings,        ## w128
    wTeaVariableExists,    ## w129
    wAppendToList,         ## w130
    wAppendToTeaVar,       ## w131
    wDuplicateVar,         ## w132
    wNoFilename,           ## w133
    wFourHexDigits,        ## w134
    wNotMatchingSurrogate, ## w135
    wMissingSurrogatePair, ## w136
    wNotPopular,           ## w137
    wControlNotEscaped,    ## w138
    wNoEndingQuote,        ## w139
    wLowSurrogateFirst,    ## w140
    wPairedSurrogate,      ## w141
    wReplaceMany,          ## w142
    wJoinListString,       ## w143
    wBareEndblock,         ## w144
    wBareContinue,         ## w145
    wInvalidLowSurrogate,  ## w146
    wCodePointTooBig,      ## w147

const
  Messages*: array[low(MessageId)..high(MessageId), string] = [
    "Success.", ## wSuccess
    "Unknown switch: $1.", ## wUnknownSwitch
    "Unknown argument: $1.", ## wUnknownArg
    "One result file allowed, skipping: '$1'.", ## wOneResultAllowed
    "Skipping extra prepost text: $1.", ## wExtraPrepostText
    "One template file allowed on the command line, skipping: $1.", ## wOneTemplateAllowed
    "No prepost value. Use $1=\"...\".", ## wNoPrepostValue
    "Skipping extra prepost text: $1.", ## wSkippingExtraPrepost
    "Unable to open log file: '$1'.", ## wUnableToOpenLogFile
    "One log file allowed, skipping: '$1'.", ## wOneLogAllowed
    "Unable to write to the log file: '$1'.", ## wUnableToWriteLogFile
    "Exception: '$1'.", ## wExceptionMsg
    "Stack trace: '$1'.", ## wStackTrace
    "Unexpected exception: '$1'.", ## wUnexpectedException
    "The root json element must be an object. Skipping file: $1.", ## wInvalidJsonRoot
    "Unable to parse the json file. Skipping file: $1.", ## wJsonParseError
    "File not found: $1.", ## wFileNotFound
    "Unable to open file: $1.", ## wUnableToOpenFile
    "Setup log rotation for $1 which has $2 bytes.", ## wBigLogFile
    "Unable to open standard device: $1.", ## wCannotOpenStd
    "No command specified on the line, treating it as a comment.", ## wNotACommand
    "Command line too long.", ## wCmdLineTooLong
    "No command found at column $1, treating it as a non-command line.", ## wNoCommand
    """The matching closing comment postfix was not found, expected: "$1".""", ## wNoPostfix
    "Missing the continuation command, abandoning the previous command.", ## wNoContinuationLine
    "Ignoring extra text after the number.", ## wSkippingTextAfterNum
    "Invalid number.", ## wNotNumber
    "The number is too big or too small.", ## wNumberOverFlow
    "Not enough memory for the line buffer.", ## wNotEnoughMemoryForLB
    "Statement does not start with a variable name.", ## wMissingStatementVar
    "Invalid string.", ## wNotString
    "Unused text at the end of the statement.", ## wTextAfterValue
    "Invalid UTF-8 byte in the string.", ## wInvalidUtf8
    "Expected a string, number, variable or function.", ## wInvalidRightHandSide
    "Invalid variable or missing equal sign.", ## wInvalidVariable
    "The variable namespace '$1' does not exist.", ## wInvalidNameSpace
    "The variable '$1' does not exist.", ## wVariableMissing
    "The statement starting at column $1 has an error.", ## wStatementError
    "You cannot overwrite the server or shared variables.", ## wReadOnlyDictionary
    "You cannot change the t.$1 tea variable.", ## wReadOnlyTeaVar
    "Invalid tea variable: $1.", ## wInvalidTeaVar
    """Invalid t.output value, use: "result", "stdout", "stderr", "log", or "skip".""", ## wInvalidOutputValue
    "MaxLines must be an integer greater than 1.", ## wInvalidMaxCount
    "You must assign t.content a string.", ## wInvalidTeaContent
    "The variable t.repeat must be an integer between 0 and t.maxRepeat.", ## wInvalidRepeat
    "Invalid prepost: $1.", ## wInvalidPrepost
    "Expected comma or right parentheses.", ## wMissingCommaParen
    "Expected a string.", ## wExpectedString
    "Invalid statement, skipping it.", ## wInvalidStatement
    "Expected one parameter.", ## wOneParameter
    "Len takes a string, list or dict parameter.", ## wStringListDict
    "The function does not exist: $1.", ## wInvalidFunction
    "The get function takes 2 or 3 parameters.", ## wGetTakes2or3Params
    "Expected an int for the second parameter, got $1.", ## wExpectedIntFor2
    "The list index $1 out of range.", ## wMissingListItem
    "Expected a string for the second parameter, got $1.", ## wExpectedStringFor2
    "The dictionary does not have an item with key $1.", ## wMissingDictItem
    "Expected a list or dictionary as the first parameter.", ## wExpectedListOrDict
    "The replacement variable doesn't exist: $1$2.", ## wMissingReplacementVar
    "Unable to create a temporary file.", ## wNoTempFile
    "Read t.maxLines replacement block lines without finding the endblock.", ## wExceededMaxLine
    "No space after the command.", ## wSpaceAfterCommand
    "The function takes two parameters.", ## wTwoParameters
    "The two parameters are not the same type.", ## wNotSameKind
    "The parameters must be numbers or strings.", ## wNotNumberOrString
    "The function takes two or three parameters.", ## wTwoOrThreeParameters
    "The function takes two or more parameters.", ## wTwoOrMoreParameters
    "The maxRepeat value must be greater than or equal to t.repeat.", ## wInvalidMaxRepeat
    "The t.content variable is not set for the replace command, treating it like the block command.", ## wContentNotSet
    "Expected three parameters.", ## wThreeParameters
    "The parameter must be an integer.", ## wExpectedInteger
    "The parameters must be all integers or all floats.", ## wAllIntOrFloat
    "Overflow or underflow.", ## wOverflow
    "The parameter must be a string.", ## wExpectedString
    "Index values must greater than or equal to 0, got: $1.", ## wInvalidIndex
    "The parameter must be a dictionary.", ## wExpectedDictionary
    "The function takes at least 3 parameters.", ## wThreeOrMoreParameters
    "The main condition type must an int or string.", ## wInvalidMainType
    "The case condition must be an int or string.", ## wInvalidCondition
    "Invalid StaticTea version string.", ## wInvalidVersion
    "Expected int or int number string.", ## wIntOrStringNumber
    "Expected a float or float number string.", ## wFloatOrStringNumber
    "Expected round, floor, ceiling or truncate.", ## wExpectedRoundOption
    "The function takes one or two parameters.", ## wOneOrTwoParameters
    "The t.content does not end with a newline, adding one.", ## wMissingNewLineContent
    "The update option overwrites the template, no result file allowed.", ## wResultFileNotAllowed
    "Unable to open temporary file.", ## wUnableToOpenTempFile
    "Unable to rename temporary file over template file.", ## wUnableToRenameTemp
    "No template name. Use -h for help.", ## wNoTemplateName
    "Invalid position: got $1.", ## wInvalidPosition
    "The end position is less that the start position.", ## wEndLessThenStart
    "The substring was not found and no default parameter.", ## wSubstringNotFound
    "The resulting duplicated string must be under 1024 characters, got: $1.", ## wDupStringTooLong
    "Specify parameters in pairs.", ## wPairParameters
    "None of the case conditions match and no else case.", ## wMissingElse
    "You cannot assign to an existing variable.", ## wImmutableVars
    "Expected four parameters.", ## wExpected4Parameters
    "Invalid length: $1.", ## wInvalidLength
    "Invalid number of parameters, the pattern and replacement come in pairs.", ## wMissingReplacement
    "Expected a list.", ## wExpectedList
    "Expected / or \\.", ## wExpectedSeparator
    "The variables f, g, h, l, s and t are reserved variable names.", ## wReservedNameSpaces
    "Name, $1, doesn't exist in the parent dictionary.", ## wMissingVarName
    "Name, $1, is not a dictionary.", ## wNotDict
    "The dictionary $1 doesn't exist.", ## wMissingDict
    "Expected the sort order, 'ascending' or 'descending'.", ## wExpectedSortOrder
    "The list values must be all ints, all floats or all strings.", ## wAllNotIntFloatString
    "The values must be integers, floats or strings.", ## wIntFloatString
    "The parameter must be 0 or 1.", ## wNotZeroOne
    "The function takes one to four parameters.", ## wOneToFourParameters
    "Expected the sensitive or unsensitive.", ## wExpectedSensitivity
    "Expected the dictionary sort key.", ## wExpectedKey
    "A dictionary is missing the sort key.", ## wDictKeyMissing
    "The sort key values are different types.", ## wKeyValueKindDiff
    "A sublist is empty.", ## wSubListsEmpty
    "The first item in the sublists are different types.", ## wSubListsDiffTypes
    "You reached the maximum number of warnings, suppressing the rest.", ## kMaxWarnings
    "Invalid signature string.", ## kInvalidSignature
    "Invalid parameter type.", ## kInvalidParamType
    "Not enough parameters, expected $1 got $2.", ## kNotEnoughArgs
    "Wrong parameter type, expected $1 got $2.", ## kWrongType
    "The required vararg parameter has no arguments.", ## kNoVarargArgs
    "Missing vararg parameter, expected groups of 2 got 1.", ## kNotEnoughVarargs
    "Too many arguments, expected at most $1 got $2.", ## kTooManyArgs
    "Expected at least four parameters.", ## wAtLeast4Parameters
    "Expected number string.", ## wExpectedNumberString
    "A case condition is not the same type as the main condition.", ## wCaseTypeMismatch
    "Expected an even number of cases, got $1 list items.", ## wNotEvenCases
    "The list values must be all strings.", ## wNotAllStrings
    "You cannot reassign a variable.", ## wTeaVariableExists
    "You can only append to a list, got $1.", ## wAppendToList
    "You cannot append to a tea variable.", ## wAppendToTeaVar
    "Duplicate json variable '$1' skipped.", ## wDuplicateVar
    "No $1 filename. Use $2=filename.", ## wNoFilename
    "A \\u must be followed by 4 hex digits.", ## wFourHexDigits
    "The second value is not a matching surrogate pair.", ## wNotMatchingSurrogate
    "Missing the low surrogate.", ## wMissingSurrogatePair
    """A slash must be followed by one letter from: nr"t\bf/.""", ## wNotPopular
    "Controls characters must be escaped.", ## wControlNotEscaped
    "No ending double quote.", ## wNoEndingQuote
    "You cannot use a low surrogate by itself or first in a pair.", ## wLowSurrogateFirst
    "Invalid paired surrogate.", ## wPairedSurrogate
    "The replaceMany function failed.", ## wReplaceMany
    "The join list items must be strings.", ## wJoinListString
    "The endblock command does not have a matching block command.", ## wBareEndblock
    "The continue command is not part of a command.", ## wBareContinue
    "Invalid low surrogate.", ## wInvalidLowSurrogate
    "Unicode code point over the limit of 10FFFF.", ## wCodePointTooBig
    ]
    ## The message text.
