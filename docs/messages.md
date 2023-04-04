# messages.nim

Messages IDs and associated strings and routines to get them.


* [messages.nim](../src/messages.nim) &mdash; Nim source code.
# Index

* type: [MessageId](#messageid) &mdash; 
* const: [Messages](#messages) &mdash; 
* type: [WarningData](#warningdata) &mdash; Warning data.
* [getWarning](#getwarning) &mdash; Return the warning string.
* [getWarningLine](#getwarningline) &mdash; Return a formatted warning line.
* [getWarningLine](#getwarningline-1) &mdash; Return a formatted warning line.
* [newWarningData](#newwarningdata) &mdash; Create a WarningData object containing all the warning
information.
* [`$`](#) &mdash; Return a string representation of WarningData.
* [`==`](#-1) &mdash; 

# MessageId



~~~nim
MessageId = enum
  wSuccess, wUnknownSwitch, wUnknownArg, wOneResultAllowed, wExtraPrepostText,
  wOneTemplateAllowed, wNoPrepostValue, wSkippingExtraPrepost,
  wUnableToOpenLogFile, wOneLogAllowed, wUnableToWriteLogFile, wExceptionMsg,
  wStackTrace, wUnexpectedException, wInvalidJsonRoot, wJsonParseError,
  wFileNotFound, wUnableToOpenFile, wBigLogFile, wCannotOpenStd, wNotACommand,
  wCmdLineTooLong, wNoCommand, wNoPostfix, wNoContinuationLine,
  wSkippingTextAfterNum, wNotNumber, wNumberOverFlow, wNotEnoughMemoryForLB,
  wMissingStatementVar, wNotString, wTextAfterValue, wInvalidUtf8,
  wInvalidRightHandSide, wInvalidVariable, wInvalidNameSpace, wVariableMissing,
  wStatementError, wReadOnlyDictionary, wReadOnlyTeaVar, wInvalidTeaVar,
  wInvalidOutputValue, wInvalidMaxCount, wInvalidTeaContent, wInvalidRepeat,
  wInvalidPrepost, wMissingCommaParen, wExpectedString, wInvalidStatement,
  wOneParameter, wStringListDict, wInvalidFunction, wGetTakes2or3Params,
  wExpectedIntFor2, wMissingListItem, wExpectedStringFor2, wMissingDictItem,
  wExpectedListOrDict, wMissingReplacementVar, wNoTempFile, wExceededMaxLine,
  wSpaceAfterCommand, wTwoParameters, wNotSameKind, wNotNumberOrString,
  wTwoOrThreeParameters, wTwoOrMoreParameters, wInvalidMaxRepeat,
  wContentNotSet, wTwoOrThreeParams, wExpectedInteger, wAllIntOrFloat,
  wOverflow, wUnused, wInvalidIndex, wExpectedDictionary,
  wThreeOrMoreParameters, wInvalidMainType, wInvalidCondition, wInvalidVersion,
  wIntOrStringNumber, wFloatOrStringNumber, wExpectedRoundOption,
  wOneOrTwoParameters, wMissingNewLineContent, wResultFileNotAllowed,
  wUnableToOpenTempFile, wUnableToRenameTemp, wNoTemplateName, wInvalidPosition,
  wEndLessThenStart, wSubstringNotFound, wDupStringTooLong, wPairParameters,
  wMissingElse, wImmutableVars, wExpected4Parameters, wInvalidLength,
  wMissingReplacement, wExpectedList, wExpectedSeparator, wReservedNameSpaces,
  wMissingVarName, wNotDict, wMissingDict, wExpectedSortOrder,
  wAllNotIntFloatString, wIntFloatString, wNotZeroOne, wOneToFourParameters,
  wExpectedSensitivity, wExpectedKey, wDictKeyMissing, wKeyValueKindDiff,
  wSubListsEmpty, wSubListsDiffTypes, wMaxWarnings, wInvalidSignature,
  wInvalidParmType, wNotEnoughArgs, wWrongType, wNoVarargArgs,
  wNotEnoughVarargs, wTooManyArgs, wAtLeast4Parameters, wExpectedNumberString,
  wCaseTypeMismatch, wNotEvenCases, wNotAllStrings, wTeaVariableExists,
  wAppendToList, wAppendToTeaVar, wDuplicateVar, wNoFilename, wFourHexDigits,
  wNotMatchingSurrogate, wMissingSurrogatePair, wNotPopular, wControlNotEscaped,
  wNoEndingQuote, wLowSurrogateFirst, wPairedSurrogate, wReplaceMany,
  wJoinListString, wBareEndblock, wBareContinue, wInvalidLowSurrogate,
  wCodePointTooBig, wInvalidUtf8ByteSeq, wUtf8Surrogate, wEndPosTooSmall,
  wEndPosTooBig, wStartPosTooBig, wLengthTooBig, wStartPosTooSmall,
  wDictRequiresEven, wDictStringKey, wCmlBareTwoDashes, wCmlInvalidOption,
  wCmlOptionRequiresArg, wCmlBareOneDash, wCmlInvalidShortOption,
  wCmlShortParamInList, wCmlDupShortOption, wCmlDupLongOption,
  wCmlBareShortName, wCmlAlphaNumericShort, wCmlMissingArgument,
  wCmdTooManyBareArgs, wCmlAlreadyHaveOneArg, wMissingCommaBracket,
  wUserMessage, wMissingDictIndex, wMaxDepthExceeded, wSameAsTemplate,
  wSameAsResult, wResultWithUpdate, wSkipOrStop, wUpdateReadonly,
  wNotEnoughArgsOpt, wTooManyArgsOpt, wNegativeLength, wReadOnlyCodeVars,
  wNoPlusSignLine, wIncompleteMultiline, wTripleAtEnd, wNoGlobalInCodeFile,
  wUseStop, wMissingEndingTriple, wInvalidStringType, wInvalidVarNameStart,
  wInvalidVarName, wNoEndingBracket, wExpectedBool, wAssignTrueFalse,
  wTwoArguments, wNotBoolOperator, wMissingCondRightParen, wNotCompareOperator,
  wBoolOperatorLeft, wCompareOperator, wCompareOperatorSame, wNeedPrecedence,
  wNoMatchingParen, wReadOnlyFunctions, wNotInL, wNotFunction,
  wNoneMatchedFirst, wNotEnoughCharacters, wNoMatchingBracket,
  wInvalidCharacter, wInvalidFirstArgChar, wAssignmentIf, wBareIfTwoArguments,
  wExpectedDotname, wInvalidDotname, wInvalidReplSyntax, wIndexNotListOrDict,
  wIndexNotInt, wInvalidIndexRange, wKeyNotString, wMissingKey,
  wMissingRightBracket, wUnableCreateStream, wNotInF, wDefineFunction,
  wMissingLeftAndOpr, wExpectedSignature, wFunctionName, wMissingLeftParen,
  wParameterName, wMissingColon, wExpectedParamType, wExpectedReturnType,
  wUnusedSignatureText, wMissingSignature, wNotLastOptional,
  wReturnTypeRequired, wMissingDocComment, wMissingStatements,
  wNoReturnStatement, wLeftHandBracket, wUserFunctionWarning, wWrongReturnType,
  wCallbackReturn, wCallbackStr, wExpectedListArg, wExceptionFunctionArg,
  wCallbackReturnType, wCallbackNumParams, wCallbackIntParam, wExpectedVariable,
  wMissingStateVar, wCallbackListParam, wStateRequired, wReturnArgument,
  wVarStartsWithLetter, wVarContainsChars, wVarEndsWith, wVarMaximumLength,
  wNotFuncVariable, wImmutableDict, wImmutableList, wNewListInDict,
  wInvalidIndexValue, wNotVariableName, wNotIndexString, wTwoParamIfArg,
  wInvalidAnchorType, wUserFunction, wInvalidHtmlPlace, wNotDictVariable,
  wSpecifyF, wNotListVariable, wVarNameNotDotName
~~~

# Messages



~~~nim
Messages: array[low(MessageId) .. high(MessageId), string] = ["Success.", "",
    "Unknown argument: $1.", "", "", "", "", "Skipping extra prepost text: $1.",
    "Unable to open log file: \'$1\'.", "",
    "Unable to write to the log file: \'$1\'.", "Exception: \'$1\'.",
    "Stack trace: \'$1\'.", "Unexpected exception: \'$1\'.",
    "The root json element must be an object (dictionary).",
    "Unable to parse the JSON.", "File not found: $1.",
    "Unable to open file: $1.", "The log file is over 1 GB.",
    "Unable to open standard input: $1.", "", "",
    "No command found at column $1, treating it as a non-command line.",
    "The matching closing comment postfix was not found expected: \'$1\'.", "",
    "", "Invalid number.", "The number is too big or too small.",
    "Not enough memory for the line buffer.",
    "Statement does not start with a variable name.", "",
    "Unused text at the end of the statement.", "",
    "Expected a string, number, variable, list or condition.",
    "Missing operator, = or &=.", "", "The variable \'$1\' does not exist.", "",
    "You cannot overwrite the server variables.",
    "You cannot change the t.$1 tea variable.", "Invalid tea variable: $1.", """Invalid t.output value, use: "result", "stdout", "stderr", "log", or "skip".""",
    "MaxLines must be an integer greater than 1.",
    "You must assign t.content a string.",
    "The variable t.repeat must be an integer between 0 and t.maxRepeat.",
    "Invalid prepost: $1.", "Expected comma or right parentheses.",
    "Expected a string.", "", "", "", "The function does not exist: $1.", "",
    "", "The list index $1 is out of range.", "",
    "The dictionary does not have an item with key $1.", "",
    "The replacement variable doesn\'t exist: $1.",
    "Unable to create a temporary file.",
    "Read t.maxLines replacement block lines without finding the endblock.",
    "No space after the command.", "",
    "The two arguments are not the same type.", "", "", "",
    "The maxRepeat value must be greater than or equal to t.repeat.", "The t.content variable is not set for the replace command, treating it like the block command.",
    "", "The argument must be an integer.", "", "Overflow or underflow.",
    "The argument must be a string.", "", "", "", "", "",
    "Invalid StaticTea version string.", "", "",
    "Expected round, floor, ceiling or truncate.", "", "",
    "The update option overwrites the template, no result file allowed.",
    "Unable to open temporary file.",
    "Unable to rename temporary file over template file.",
    "No template name. Use -h for help.", "Invalid position: got $1.", "",
    "The substring was not found and no default argument.",
    "The resulting duplicated string must be under 1024 characters, got: $1.",
    "Specify arguments in pairs.",
    "None of the case conditions match and no else case.",
    "You cannot assign to an existing variable.", "", "Invalid length: $1.", "",
    "", "Expected / or \\.",
    "The variables h - k, m - r are reserved variable names.", "",
    "Name is not a dictionary.", "",
    "Expected the sort order, \'ascending\' or \'descending\'.", "", "",
    "The argument must be 0 or 1.", "", "Expected sensitive or unsensitive.",
    "", "A dictionary is missing the sort key.",
    "The sort key values are different types.", "A sublist is empty.",
    "The first item in the sublists are different types.",
    "You reached the maximum number of warnings, suppressing the rest.", "", "",
    "Not enough arguments, expected $1.", "Wrong argument type, expected $1.",
    "", "", "The function requires $1 arguments.", "",
    "Expected number string.",
    "A case condition is not the same type as the main condition.",
    "Expected an even number of cases, got $1 list items.",
    "The list values must be all strings.", "You cannot reassign a variable.",
    "You can only append to a list, got $1.",
    "You cannot append to a tea variable.",
    "Duplicate json variable \'$1\' skipped.", "No $1 filename.",
    "A \\u must be followed by 4 hex digits.", "", "Missing the low surrogate.",
    """A slash must be followed by one letter from: bfnru"/\.""",
    "Controls characters must be escaped.", "No ending double quote.",
    "You cannot use a low surrogate by itself or first in a pair.", "",
    "The replaceMany function failed.", "The join list items must be strings.",
    "The endblock command does not have a matching block command.",
    "The continue command is not part of a command.", "Invalid low surrogate.",
    "Unicode code point over the limit of 10FFFF.",
    "Invalid UTF-8 byte sequence at position $1.",
    "Unicode surrogate code points are invalid in UTF-8 strings.", "", "", "The start position is greater then the number of characters in the string.", "The length is greater then the possible number of characters in the slice.",
    "The start position is less than 0.",
    "Dictionaries require an even number of list items.",
    "The dictionary keys must be strings.",
    "Two dashes must be followed by an option name.",
    "The option \'--$1\' is not supported.",
    "The option \'$1\' requires an argument.",
    "One dash must be followed by a short option name.",
    "The short option \'-$1\' is not supported.",
    "The option \'-$1\' needs an argument; use it by itself.",
    "Duplicate short option: \'-$1\'.", "Duplicate long option: \'--$1\'.",
    "Use the short name \'_\' instead of \'$1\' with a bare argument.", "Use an alphanumeric ascii character for a short option name instead of \'$1\'.",
    "Missing \'$1\' argument.", "Extra bare argument.",
    "One \'$1\' argument is allowed.", "Missing comma or right bracket.", "$1",
    "", "The maximum JSON depth of $1 was exceeded.",
    "The template and $1 files are the same.",
    "The result and $1 files are the same.",
    "The result file is used with the update option.",
    "Expected \'skip\' or \'stop\' for the return function value.",
    "Cannot update the readonly template.",
    "The function requires at least $1 arguments.",
    "The function requires at most $1 arguments.",
    "The length must be a positive number.",
    "You can only change code variables (o dictionary) in code files.",
    "Out of lines looking for the plus sign line.",
    "Out of lines looking for the multiline string.", "A multiline string\'s leading and ending triple quotes must end the line.",
    "You can only change global variables (g dictionary) in template files.",
    "Use \'...return(\"stop\")...\' in a code file.",
    "Missing the ending triple quotes.",
    "Invalid string type, expected rb, json or dn.",
    "Invalid variable name; names start with an ascii letter.",
    "Invalid variable name; names contain letters, digits or underscores.",
    "No ending bracket.", "The argument must be a bool value, got $1.",
    "You cannot assign true or false.", "Expected two arguments.",
    "Expected a boolean operator, and, or, ==, !=, <, >, <=, >=.",
    "The condition expression\'s closing right parentheses was not found.",
    "Expected a compare operator, ==, !=, <, >, <=, >=.",
    "A boolean operator’s left value must be a bool.", "A comparison operator’s values must be numbers or strings of the same type.", "The comparison operator’s right value must be the same type as the left value.", "When mixing \'and\'s and \'or\'s you need to specify the precedence with parentheses.",
    "No matching end right parentheses.",
    "You cannot assign to the functions dictionary.",
    "The variable \'$1\' isn\'t in the l dictionary.", "You cannot call the variable because it\'s not a function or a list of functions.",
    "None of the $1 functions matched the first argument.",
    "Ran out of characters before finishing the statement.",
    "No matching end right bracket.", "Invalid character.",
    "Invalid first character of the argument.", "",
    "A bare IF without an assignment takes two arguments.",
    "Expected a variable or a dot name.",
    "Expected variable name not function call.",
    "Invalid REPL command syntax, unexpected text.",
    "The container variable must be a list or dictionary got $1.",
    "The index variable must be an integer.",
    "The index value $1 is out of range.",
    "The key variable must be an string.",
    "The key doesn\'t exist in the dictionary.", "Missing right bracket.",
    "Unable to create a stream object.",
    "The variable \'$1\' isn\'t in the f dictionary.",
    "Define a function in a code file and not nested.",
    "Missing left hand side and operator, e.g. a = len(b) not len(b).",
    "Expected signature string.", "Expected a function name.",
    "Expected a left parentheses for the signature.",
    "Expected a parameter name.", "Expected a colon.", "Expected a parameter type: bool, int, float, string, dict, list, func or any.",
    "Invalid return type.", "Unused extra text at the end of the signature.",
    "Missing the function signature string.",
    "Only the last parameter can be optional.", "The return type is required.",
    "Missing required doc comment.",
    "Out of lines; No statements for the function.",
    "Out of lines; missing the function\'s return statement.",
    "You cannot use bracket notation to change a variable.",
    "The user function generated a warning.", "Wrong return type, got $1.", "Expected the func variable\'s return value to be a list with a string and a value.", "Expected the func variable\'s return string to be \'stop\', \'skip\' or \'add\'.",
    "Expected list argument, got $1.", "Expected a func variable, got $1.",
    "Expected the func variable\'s return type to be a bool, got: $1.",
    "Expected the func variable has 3 or 4 parameters but it has 1.",
    "Expected the func variable\'s first parameter to be an int, got $1.",
    "Expected a variable.", "The listLoop state argument exists but the callback doesn\'t have a state parameter.",
    "", "The func variable has a required state parameter but it is being not passed to it.", "Invalid return; use a bare return in a user function or use it in a bare if statement.",
    "A variable starts with an ascii letter.",
    "A variable contains ascii letters, digits, underscores and hypens.",
    "A variable name ends with an ascii letter or digit.",
    "A variable and dot name are limited to 64 characters.",
    "The variable is not a function variable.",
    "You cannot assign to an immutable dictionary.",
    "You cannot append to an immutable list.",
    "You cannot create a new list element in the immutable dictionary.",
    "The index value must be a variable name or literal string.",
    "The index variable value is not a valid variable name.",
    "The index value is not a string.",
    "A two parameter IF function cannot be used as an argument.",
    "Invalid anchor type, expected html or github.",
    "You can only assign a user function variable to the u dictionary.",
    """Invalid html place, expected "body", or "attribute".""",
    "The variable is not a dictionary.", "Specify f or a function variable.",
    "The variable is not a list.", "Expected a variable name without dots."]
~~~

# WarningData

Warning data.
* messageId -- the message id
* p1 -- the optional string substituted for the message's $1.
* pos -- the index in the statement where the warning was detected.


~~~nim
WarningData = object
  messageId*: MessageId
  p1*: string
  pos*: Natural
~~~

# getWarning

Return the warning string.


~~~nim
func getWarning(warning: MessageId; p1 = ""): string {.raises: [ValueError],
    tags: [].}
~~~

# getWarningLine

Return a formatted warning line. For example:

~~~
filename(line): wId: message.
~~~


~~~nim
func getWarningLine(filename: string; lineNum: int; warning: MessageId; p1 = ""): string {.
    raises: [ValueError], tags: [].}
~~~

# getWarningLine

Return a formatted warning line. For example:

~~~
filename(line): wId: message.
~~~


~~~nim
func getWarningLine(filename: string; lineNum: int; warningData: WarningData): string
~~~

# newWarningData

Create a WarningData object containing all the warning
information.


~~~nim
func newWarningData(messageId: MessageId; p1 = ""; pos = 0): WarningData
~~~

# `$`

Return a string representation of WarningData.

~~~nim
let warning = newWarningData(wUnknownArg, "p1", 5)
check $warning == "wUnknownArg(p1):5"
~~~


~~~nim
func `$`(warningData: WarningData): string {.raises: [ValueError], tags: [].}
~~~

# `==`



~~~nim
func `==`(w1: WarningData; w2: WarningData): bool
~~~


---
⦿ Markdown page generated by [StaticTea](https://github.com/flenniken/statictea/) from nim doc comments. ⦿
