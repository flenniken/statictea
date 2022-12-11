# messages.nim

Messages IDs and associated strings and routines to get them

* [messages.nim](../src/messages.nim) &mdash; Nim source code.
# Index

* type: [MessageId](#messageid) &mdash; Message numbers.
* const: [Messages](#messages) &mdash; The message text.
* type: [WarningData](#warningdata) &mdash; Warning data.
* [getWarning](#getwarning) &mdash; Return the warning string.
* [getWarningLine](#getwarningline) &mdash; Return a formatted warning line.
* [getWarningLine](#getwarningline-1) &mdash; Return a formatted warning line.
* [newWarningData](#newwarningdata) &mdash; Create a WarningData object containing all the warning information.
* [`$`](#) &mdash; Return a string representation of WarningData.
* [`==`](#-1) &mdash; Return true when the two WarningData objects are equal.

# MessageId

Message numbers.

```nim
MessageId = enum
  wSuccess,                 ## w0
  wUnknownSwitch,           ## w1
  wUnknownArg,              ## w2
  wOneResultAllowed,        ## w3
  wExtraPrepostText,        ## w4
  wOneTemplateAllowed,      ## w5
  wNoPrepostValue,          ## w6
  wSkippingExtraPrepost,    ## w7
  wUnableToOpenLogFile,     ## w8
  wOneLogAllowed,           ## w9
  wUnableToWriteLogFile,    ## w10
  wExceptionMsg,            ## w11
  wStackTrace,              ## w12
  wUnexpectedException,     ## w13
  wInvalidJsonRoot,         ## w14
  wJsonParseError,          ## w15
  wFileNotFound,            ## w16
  wUnableToOpenFile,        ## w17
  wBigLogFile,              ## w18
  wCannotOpenStd,           ## w19
  wNotACommand,             ## w20
  wCmdLineTooLong,          ## w21
  wNoCommand,               ## w22
  wNoPostfix,               ## w23
  wNoContinuationLine,      ## w24
  wSkippingTextAfterNum,    ## w25
  wNotNumber,               ## w26
  wNumberOverFlow,          ## w27
  wNotEnoughMemoryForLB,    ## w28
  wMissingStatementVar,     ## w29
  wNotString,               ## w30
  wTextAfterValue,          ## w31
  wInvalidUtf8,             ## w32
  wInvalidRightHandSide,    ## w33
  wInvalidVariable,         ## w34
  wInvalidNameSpace,        ## w35
  wVariableMissing,         ## w36
  wStatementError,          ## w37
  wReadOnlyDictionary,      ## w38
  wReadOnlyTeaVar,          ## w39
  wInvalidTeaVar,           ## w40
  wInvalidOutputValue,      ## w41
  wInvalidMaxCount,         ## w42
  wInvalidTeaContent,       ## w43
  wInvalidRepeat,           ## w44
  wInvalidPrepost,          ## w45
  wMissingCommaParen,       ## w46
  wExpectedString,          ## w47
  wInvalidStatement,        ## w48
  wOneParameter,            ## w49
  wStringListDict,          ## w50
  wInvalidFunction,         ## w51
  wGetTakes2or3Params,      ## w52
  wExpectedIntFor2,         ## w53
  wMissingListItem,         ## w54
  wExpectedStringFor2,      ## w55
  wMissingDictItem,         ## w56
  wExpectedListOrDict,      ## w57
  wMissingReplacementVar,   ## w58
  wNoTempFile,              ## w59
  wExceededMaxLine,         ## w60
  wSpaceAfterCommand,       ## w61
  wTwoParameters,           ## w62
  wNotSameKind,             ## w63
  wNotNumberOrString,       ## w64
  wTwoOrThreeParameters,    ## w65
  wTwoOrMoreParameters,     ## w66
  wInvalidMaxRepeat,        ## w67
  wContentNotSet,           ## w68
  wTwoOrThreeParams,        ## w69
  wExpectedInteger,         ## w70
  wAllIntOrFloat,           ## w71
  wOverflow,                ## w72
  wUnused,                  ## w73
  wInvalidIndex,            ## w74
  wExpectedDictionary,      ## w75
  wThreeOrMoreParameters,   ## w76
  wInvalidMainType,         ## w77
  wInvalidCondition,        ## w78
  wInvalidVersion,          ## w79
  wIntOrStringNumber,       ## w80
  wFloatOrStringNumber,     ## w81
  wExpectedRoundOption,     ## w82
  wOneOrTwoParameters,      ## w83
  wMissingNewLineContent,   ## w84
  wResultFileNotAllowed,    ## w85
  wUnableToOpenTempFile,    ## w86
  wUnableToRenameTemp,      ## w87
  wNoTemplateName,          ## w88
  wInvalidPosition,         ## w89
  wEndLessThenStart,        ## w90
  wSubstringNotFound,       ## w91
  wDupStringTooLong,        ## w92
  wPairParameters,          ## w93
  wMissingElse,             ## w94
  wImmutableVars,           ## w95
  wExpected4Parameters,     ## w96
  wInvalidLength,           ## w97
  wMissingReplacement,      ## w98
  wExpectedList,            ## w99
  wExpectedSeparator,       ## w100
  wReservedNameSpaces,      ## w101
  wMissingVarName,          ## w102
  wNotDict,                 ## w103
  wMissingDict,             ## w104
  wExpectedSortOrder,       ## w105
  wAllNotIntFloatString,    ## w106
  wIntFloatString,          ## w107
  wNotZeroOne,              ## w108
  wOneToFourParameters,     ## w109
  wExpectedSensitivity,     ## w110
  wExpectedKey,             ## w111
  wDictKeyMissing,          ## w112
  wKeyValueKindDiff,        ## w113
  wSubListsEmpty,           ## w114
  wSubListsDiffTypes,       ## w115
  wMaxWarnings,             ## w116
  wInvalidSignature,        ## w117
  wInvalidParmType,         ## w118
  wNotEnoughArgs,           ## w119
  wWrongType,               ## w120
  wNoVarargArgs,            ## w121
  wNotEnoughVarargs,        ## w122
  wTooManyArgs,             ## w123
  wAtLeast4Parameters,      ## w124
  wExpectedNumberString,    ## w125
  wCaseTypeMismatch,        ## w126
  wNotEvenCases,            ## w127
  wNotAllStrings,           ## w128
  wTeaVariableExists,       ## w129
  wAppendToList,            ## w130
  wAppendToTeaVar,          ## w131
  wDuplicateVar,            ## w132
  wNoFilename,              ## w133
  wFourHexDigits,           ## w134
  wNotMatchingSurrogate,    ## w135
  wMissingSurrogatePair,    ## w136
  wNotPopular,              ## w137
  wControlNotEscaped,       ## w138
  wNoEndingQuote,           ## w139
  wLowSurrogateFirst,       ## w140
  wPairedSurrogate,         ## w141
  wReplaceMany,             ## w142
  wJoinListString,          ## w143
  wBareEndblock,            ## w144
  wBareContinue,            ## w145
  wInvalidLowSurrogate,     ## w146
  wCodePointTooBig,         ## w147
  wInvalidUtf8ByteSeq,      ## w148
  wUtf8Surrogate,           ## w149
  wEndPosTooSmall,          ## w150
  wEndPosTooBig,            ## w151
  wStartPosTooBig,          ## w152
  wLengthTooBig,            ## w153
  wStartPosTooSmall,        ## w154
  wDictRequiresEven,        ## w155
  wDictStringKey,           ## w156
  wCmlBareTwoDashes,        ## w157
  wCmlInvalidOption,        ## w158
  wCmlOptionRequiresArg,    ## w159
  wCmlBareOneDash,          ## w160
  wCmlInvalidShortOption,   ## w161
  wCmlShortParamInList,     ## w162
  wCmlDupShortOption,       ## w163
  wCmlDupLongOption,        ## w164
  wCmlBareShortName,        ## w165
  wCmlAlphaNumericShort,    ## w166
  wCmlMissingParameter,     ## w167
  wCmdTooManyBareArgs,      ## w168
  wCmlAlreadyHaveOneArg,    ## w169
  wMissingCommaBracket,     ## w170
  wUserMessage,             ## w171
  wMissingDictIndex,        ## w172
  wMaxDepthExceeded,        ## w173
  wSameAsTemplate,          ## w174
  wSameAsResult,            ## w175
  wResultWithUpdate,        ## w176
  wSkipOrStop,              ## w177
  wUpdateReadonly,          ## w178
  wNotEnoughArgsOpt,        ## w179
  wTooManyArgsOpt,          ## w180
  wNegativeLength,          ## w181
  wReadOnlyCodeVars,        ## w182
  wNoPlusSignLine,          ## w183
  wIncompleteMultiline,     ## w184
  wTripleAtEnd,             ## w185
  wNoGlobalInCodeFile,      ## w186
  wUseStop,                 ## w187
  wMissingEndingTriple,     ## w188
  wInvalidStringType,       ## w189
  wInvalidVarNameStart,     ## w190
  wInvalidVarName,          ## w191
  wNoEndingBracket,         ## w192
  wExpectedBool,            ## w193
  wAssignTrueFalse,         ## w194
  wTwoArguments,            ## w195
  wNotBoolOperator,         ## w196
  wMissingCondRightParen,   ## w197
  wNotCompareOperator,      ## w198
  wBoolOperatorLeft,        ## w199
  wCompareOperator,         ## w200
  wCompareOperatorSame,     ## w201
  wNeedPrecedence,          ## w202
  wNoMatchingParen,         ## w203
  wReadOnlyFunctions,       ## w204
  wNotInL,                  ## w205
  wNotFunction,             ## w206
  wNoneMatchedFirst,        ## w207
  wNotEnoughCharacters,     ## w208
  wNoMatchingBracket,       ## w209
  wInvalidCharacter,        ## w210
  wInvalidFirstArgChar,     ## w211
  wAssignmentIf,            ## w212
  wBareIfTwoArguments,      ## w213
  wExpectedDotname,         ## w214
  wInvalidDotname,          ## w215
  wInvalidReplSyntax,       ## w216
  wIndexNotListOrDict,      ## w217
  wIndexNotInt,             ## w218
  wInvalidIndexRange,       ## w219
  wKeyNotString,            ## w220
  wMissingKey,              ## w221
  wMissingRightBracket,     ## w222
  wUnableCreateStream,      ## w223
  wNotInF,                  ## w224
  wDefineFunction,          ## w225
  wMissingLeftAndOpr,       ## w226
  wExpectedSignature         ## w227
```

# Messages

The message text.

```nim
Messages: array[low(MessageId) .. high(MessageId), string] = ["Success.", ## The message text.
## wSuccess
    "",                     ## wUnknownSwitch
    "Unknown argument: $1.", ## wUnknownArg
    "",                     ## wOneResultAllowed
    "",                     ## wExtraPrepostText
    "",                     ## wOneTemplateAllowed
    "",                     ## wNoPrepostValue
    "Skipping extra prepost text: $1.", ## wSkippingExtraPrepost
    "Unable to open log file: \'$1\'.", ## wUnableToOpenLogFile
    "",                     ## wOneLogAllowed
    "Unable to write to the log file: \'$1\'.", ## wUnableToWriteLogFile
    "Exception: \'$1\'.",   ## wExceptionMsg
    "Stack trace: \'$1\'.", ## wStackTrace
    "Unexpected exception: \'$1\'.", ## wUnexpectedException
    "The root json element must be an object (dictionary).", ## wInvalidJsonRoot
    "Unable to parse the JSON.", ## wJsonParseError
    "File not found: $1.",  ## wFileNotFound
    "Unable to open file: $1.", ## wUnableToOpenFile
    "The log file is over 1 GB.", ## wBigLogFile
    "Unable to open standard input: $1.", ## wCannotOpenStd
    "",                     ## wNotACommand
    "",                     ## wCmdLineTooLong
    "No command found at column $1, treating it as a non-command line.", ## wNoCommand
    """The matching closing comment postfix was not found, expected: "$1".""", ## wNoPostfix
    "",                     ## wNoContinuationLine
    "",                     ## wSkippingTextAfterNum
    "Invalid number.",      ## wNotNumber
    "The number is too big or too small.", ## wNumberOverFlow
    "Not enough memory for the line buffer.", ## wNotEnoughMemoryForLB
    "Statement does not start with a variable name.", ## wMissingStatementVar
    "",                     ## wNotString
    "Unused text at the end of the statement.", ## wTextAfterValue
    "",                     ## wInvalidUtf8
    "Expected a string, number, variable, list or condition.", ## wInvalidRightHandSide
    "Missing operator, = or &=.", ## wInvalidVariable
    "",                     ## wInvalidNameSpace
    "The variable \'$1\' does not exist.", ## wVariableMissing
    "",                     ## wStatementError
    "You cannot overwrite the server variables.", ## wReadOnlyDictionary
    "You cannot change the t.$1 tea variable.", ## wReadOnlyTeaVar
    "Invalid tea variable: $1.", ## wInvalidTeaVar
    """Invalid t.output value, use: "result", "stdout", "stderr", "log", or "skip".""", ## wInvalidOutputValue
    "MaxLines must be an integer greater than 1.", ## wInvalidMaxCount
    "You must assign t.content a string.", ## wInvalidTeaContent
    "The variable t.repeat must be an integer between 0 and t.maxRepeat.", ## wInvalidRepeat
    "Invalid prepost: $1.", ## wInvalidPrepost
    "Expected comma or right parentheses.", ## wMissingCommaParen
    "Expected a string.",   ## wExpectedString
    "",                     ## wInvalidStatement
    "",                     ## wOneParameter
    "",                     ## wStringListDict
    "The function does not exist: $1.", ## wInvalidFunction
    "",                     ## wGetTakes2or3Params
    "",                     ## wExpectedIntFor2
    "The list index $1 is out of range.", ## wMissingListItem
    "",                     ## wExpectedStringFor2
    "The dictionary does not have an item with key $1.", ## wMissingDictItem
    "",                     ## wExpectedListOrDict
    "The replacement variable doesn\'t exist: $1.", ## wMissingReplacementVar
    "Unable to create a temporary file.", ## wNoTempFile
    "Read t.maxLines replacement block lines without finding the endblock.", ## wExceededMaxLine
    "No space after the command.", ## wSpaceAfterCommand
    "",                     ## wTwoParameters
    "The two arguments are not the same type.", ## wNotSameKind
    "",                     ## wNotNumberOrString
    "",                     ## wTwoOrThreeParameters
    "",                     ## wTwoOrMoreParameters
    "The maxRepeat value must be greater than or equal to t.repeat.", ## wInvalidMaxRepeat
    "The t.content variable is not set for the replace command, treating it like the block command.", ## wContentNotSet
    "",                     ## wTwoOrThreeParams
    "The argument must be an integer.", ## wExpectedInteger
    "",                     ## wAllIntOrFloat
    "Overflow or underflow.", ## wOverflow
    "The argument must be a string.", ## wExpectedString
    "",                     ## wInvalidIndex
    "",                     ## wExpectedDictionary
    "",                     ## wThreeOrMoreParameters
    "",                     ## wInvalidMainType
    "",                     ## wInvalidCondition
    "Invalid StaticTea version string.", ## wInvalidVersion
    "",                     ## wIntOrStringNumber
    "",                     ## wFloatOrStringNumber
    "Expected round, floor, ceiling or truncate.", ## wExpectedRoundOption
    "",                     ## wOneOrTwoParameters
    "",                     ## wMissingNewLineContent
    "The update option overwrites the template, no result file allowed.", ## wResultFileNotAllowed
    "Unable to open temporary file.", ## wUnableToOpenTempFile
    "Unable to rename temporary file over template file.", ## wUnableToRenameTemp
    "No template name. Use -h for help.", ## wNoTemplateName
    "Invalid position: got $1.", ## wInvalidPosition
    "",                     ## wEndLessThenStart
    "The substring was not found and no default argument.", ## wSubstringNotFound
    "The resulting duplicated string must be under 1024 characters, got: $1.", ## wDupStringTooLong
    "Specify arguments in pairs.", ## wPairParameters
    "None of the case conditions match and no else case.", ## wMissingElse
    "You cannot assign to an existing variable.", ## wImmutableVars
    "",                     ## wExpected4Parameters
    "Invalid length: $1.",  ## wInvalidLength
    "",                     ## wMissingReplacement
    "",                     ## wExpectedList
    "Expected / or \\.",    ## wExpectedSeparator
    "The variables f, h - k, m - r, u are reserved variable names.", ## wReservedNameSpaces
    "",                     ## wMissingVarName
    "Name, $1, is not a dictionary.", ## wNotDict
    "",                     ## wMissingDict
    "Expected the sort order, \'ascending\' or \'descending\'.", ## wExpectedSortOrder
    "",                     ## wAllNotIntFloatString
    "",                     ## wIntFloatString
    "The argument must be 0 or 1.", ## wNotZeroOne
    "",                     ## wOneToFourParameters
    "Expected sensitive or unsensitive.", ## wExpectedSensitivity
    "",                     ## wExpectedKey
    "A dictionary is missing the sort key.", ## wDictKeyMissing
    "The sort key values are different types.", ## wKeyValueKindDiff
    "A sublist is empty.",  ## wSubListsEmpty
    "The first item in the sublists are different types.", ## wSubListsDiffTypes
    "You reached the maximum number of warnings, suppressing the rest.", ## wMaxWarnings
    "",                     ## wInvalidSignature
    "",                     ## wInvalidParmType
    "Not enough arguments, expected $1.", ## wNotEnoughArgs
    "Wrong argument type, expected $1.", ## wWrongType
    "",                     ## wNoVarargArgs
    "",                     ## wNotEnoughVarargs
    "The function requires $1 arguments.", ## wTooManyArgs
    "",                     ## wAtLeast4Parameters
    "Expected number string.", ## wExpectedNumberString
    "A case condition is not the same type as the main condition.", ## wCaseTypeMismatch
    "Expected an even number of cases, got $1 list items.", ## wNotEvenCases
    "The list values must be all strings.", ## wNotAllStrings
    "You cannot reassign a variable.", ## wTeaVariableExists
    "You can only append to a list, got $1.", ## wAppendToList
    "You cannot append to a tea variable.", ## wAppendToTeaVar
    "Duplicate json variable \'$1\' skipped.", ## wDuplicateVar
    "No $1 filename.",      ## wNoFilename
    "A \\u must be followed by 4 hex digits.", ## wFourHexDigits
    "",                     ## wNotMatchingSurrogate
    "Missing the low surrogate.", ## wMissingSurrogatePair
    """A slash must be followed by one letter from: nr"t\bf/.""", ## wNotPopular
    "Controls characters must be escaped.", ## wControlNotEscaped
    "No ending double quote.", ## wNoEndingQuote
    "You cannot use a low surrogate by itself or first in a pair.", ## wLowSurrogateFirst
    "",                     ## wPairedSurrogate
    "The replaceMany function failed.", ## wReplaceMany
    "The join list items must be strings.", ## wJoinListString
    "The endblock command does not have a matching block command.", ## wBareEndblock
    "The continue command is not part of a command.", ## wBareContinue
    "Invalid low surrogate.", ## wInvalidLowSurrogate
    "Unicode code point over the limit of 10FFFF.", ## wCodePointTooBig
    "Invalid UTF-8 byte sequence at position $1.", ## wInvalidUtf8ByteSeq
    "Unicode surrogate code points are invalid in UTF-8 strings.", ## wUtf8Surrogate
    "",                     ## wEndPosTooSmall
    "",                     ## wEndPosTooBig
    "The start position is greater then the number of characters in the string.", ## wStartPosTooBig
    "The length is greater then the possible number of characters in the slice.", ## wLengthTooBig
    "The start position is less than 0.", ## wStartPosTooSmall
    "Dictionaries require an even number of list items.", ## wDictRequiresEven
    "The dictionary keys must be strings.", ## wDictStringKey
    "Two dashes must be followed by an option name.", ## wCmlBareTwoDashes
    "The option \'--$1\' is not supported.", ## wCmlInvalidOption
    "The option \'$1\' requires an argument.", ## wCmlOptionRequiresArg
    "One dash must be followed by a short option name.", ## wCmlBareOneDash
    "The short option \'-$1\' is not supported.", ## wCmlInvalidShortOption
    "The option \'-$1\' needs an argument; use it by itself.", ## wCmlShortParamInList
    "Duplicate short option: \'-$1\'.", ## wCmlDupShortOption
    "Duplicate long option: \'--$1\'.", ## wCmlDupLongOption
    "Use the short name \'_\' instead of \'$1\' with a bare argument.", ## wCmlBareShortName
    "Use an alphanumeric ascii character for a short option name instead of \'$1\'.", ## wCmlAlphaNumericShort
    "Missing \'$1\' argument.", ## wCmlMissingArgument
    "Extra bare argument.", ## wCmdTooManyBareArgs
    "One \'$1\' argument is allowed.", ## wCmlAlreadyHaveOneArg
    "Missing comma or right bracket.", ## wMissingCommaBracket
    "$1",                   ## wUserMessage
    "",                     ## wMissingDictIndex
    "The maximum JSON depth of $1 was exceeded.", ## wMaxDepthExceeded
    "The template and $1 files are the same.", ## wSameAsTemplate
    "The result and $1 files are the same.", ## wSameAsResult
    "The result file is used with the update option.", ## wResultWithUpdate
    "Expected \'skip\' or \'stop\' for the return function value.", ## wSkipOrStop
    "Cannot update the readonly template.", ## wUpdateReadonly
    "The function requires at least $1 arguments.", ## wNotEnoughArgsOpt
    "The function requires at most $1 arguments.", ## wTooManyArgsOpt
    "The length must be a positive number.", ## wNegativeLength
    "You can only change code variables in code files.", ## wReadOnlyCodeVars
    "Out of lines looking for the plus sign line.", ## wNoPlusSignLine
    "Out of lines looking for the multiline string.", ## wIncompleteMultiline
    "Triple quotes must always end the line.", ## wTripleAtEnd
    "You cannot assign to the g namespace in a code file.", ## wNoGlobalInCodeFile
    "Use \'...return(\"stop\")...\' in a code file.", ## wUseStop
    "Missing the ending triple quotes.", ## wMissingEndingTriple
    "Invalid string type, expected rb, json or dn.", ## wInvalidStringType
    "Invalid variable name; names start with an ascii letter.", ## wInvalidVarNameStart
    "Invalid variable name; names contain letters, digits or underscores.", ## wInvalidVarName
    "No ending bracket.",   ## wNoEndingBracket
    "The argument must be a bool value, got $1.", ## wExpectedBool
    "You cannot assign true or false.", ## wAssignTrueFalse
    "Expected two arguments.", ## wTwoArguments
    "Expected a boolean operator, and, or, ==, !=, <, >, <=, >=.", ## wNotBoolOperator
    "The condition expression\'s closing right parentheses was not found.", ## wMissingCondRightParen
    "Expected a compare operator, ==, !=, <, >, <=, >=.", ## wNotCompareOperator
    "A boolean operator’s left value must be a bool.", ## wBoolOperatorLeft
    "A comparison operator’s values must be numbers or strings of the same type.", ## wCompareOperator
    "The comparison operator’s right value must be the same type as the left value.", ## wCompareOperatorSame
    "When mixing \'and\'s and \'or\'s you need to specify the precedence with parentheses.", ## wNeedPrecedence
    "No matching end right parentheses.", ## wNoMatchingParen
    "You cannot assign to the functions dictionary.", ## wReadOnlyFunctions
    "The variable \'$1\' isn\'t in the l dictionary.", ## wNotInL
    "You cannot call the variable because it\'s not a function or a list of functions.", ## wNotFunction
    "None of the $1 functions matched the first argument.", ## wNoneMatchedFirst
    "Ran out of characters before finishing the statement.", ## wNotEnoughCharacters
    "No matching end right bracket.", ## wNoMatchingBracket
    "Invalid character.",   ## wInvalidCharacter
    "Invalid first character of the argument.", ## wInvalidFirstArgChar
    "An if with an assignment takes three arguments.", ## wAssignmentIf
    "An if without an assignment takes two arguments.", ## wBareIfTwoArguments
    "Expected a variable or a dot name.", ## wExpectedDotname
    "Invalid variable or dot name.", ## wInvalidDotname
    "Invalid REPL command syntax.", ## wInvalidReplSyntax
    "The container variable must be a list or dictionary got $1.", ## wIndexNotListOrDict
    "The index variable must be an integer.", ## wIndexNotInt
    "The index value $1 is out of range.", ## wInvalidIndexRange
    "The key variable must be an string.", ## wKeyNotString
    "The key doesn\'t exist in the dictionary.", ## wMissingKey
    "Missing right bracket.", ## wMissingRightBracket
    "Unable to create a stream object.", ## wUnableCreateStream
    "The variable \'$1\' isn\'t in the f dictionary.", ## wNotInF
    "Define a function in a code file and not nested.", ## wDefineFunction
    "Missing left hand side and operator, e.g. a = len(b) not len(b).", ## wMissingLeftAndOpr
    "Expected signature string."]
```

# WarningData

Warning data.<ul class="simple"><li>warning -- the message id</li>
<li>p1 -- the optional string substituted for the message's $1.</li>
<li>pos -- the index in the statement where the warning was detected.</li>
</ul>


```nim
WarningData = object
  messageId*: MessageId
  p1*: string
  pos*: Natural

```

# getWarning

Return the warning string.

```nim
func getWarning(warning: MessageId; p1 = ""): string
```

# getWarningLine

Return a formatted warning line. For example:

~~~
filename(line): wId: message.
~~~~

```nim
func getWarningLine(filename: string; lineNum: int; warning: MessageId; p1 = ""): string
```

# getWarningLine

Return a formatted warning line. For example:

~~~
filename(line): wId: message.
~~~~

```nim
func getWarningLine(filename: string; lineNum: int; warningData: WarningData): string
```

# newWarningData

Create a WarningData object containing all the warning information.

```nim
func newWarningData(messageId: MessageId; p1 = ""; pos = 0): WarningData
```

# `$`

Return a string representation of WarningData.

~~~
let warning = newWarningData(wUnknownArg, "p1", 5)
check $warning == "wUnknownArg(p1):5"
~~~~

```nim
func `$`(warningData: WarningData): string
```

# `==`

Return true when the two WarningData objects are equal.

```nim
func `==`(w1: WarningData; w2: WarningData): bool
```


---
⦿ Markdown page generated by [StaticTea](https://github.com/flenniken/statictea/) from nim doc comments. ⦿
