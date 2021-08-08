# warnings.nim

The warning messages.

* [warnings.nim](../src/warnings.nim) &mdash; Nim source code.
# Index

* type: [WarningData](#warningdata) &mdash; Warning number and optional extra strings.
* type: [Warning](#warning) &mdash; Warning numbers.
* const: [warningsList](#warningslist) &mdash; 
* [getWarning](#getwarning) &mdash; Return a formatted warning line.
* [newWarningData](#newwarningdata) &mdash; Create a WarningData object containing the warning information.
* [`$`](#) &mdash; Return a string representation of WarningData.
* [`==`](#-1) &mdash; Return true when the two WarningData are equal.

# WarningData

Warning number and optional extra strings.

```nim
WarningData = object
  warning*: Warning          ## Warning message id.
  p1*: string                ## Optional warning info.
  p2*: string                ## Optional warning info.

```

# Warning

Warning numbers.

```nim
Warning = enum
  wNoFilename, wUnknownSwitch, wUnknownArg, wOneResultAllowed,
  wExtraPrepostText, wOneTemplateAllowed, wNoPrepostValue,
  wSkippingExtraPrepost, wUnableToOpenLogFile, wOneLogAllowed,
  wUnableToWriteLogFile, wExceptionMsg, wStackTrace, wUnexpectedException,
  wInvalidJsonRoot, wJsonParseError, wFileNotFound, wUnableToOpenFile,
  wBigLogFile, wCannotOpenStd, wNotACommand, wCmdLineTooLong, wNoCommand,
  wNoPostfix, wNoContinuationLine, wSkippingTextAfterNum, wNotNumber,
  wNumberOverFlow, wNotEnoughMemoryForLB, wMissingStatementVar, wNotString,
  wTextAfterValue, wInvalidUtf8, wInvalidRightHandSide, wInvalidVariable,
  wInvalidNameSpace, wVariableMissing, wStatementError, wReadOnlyDictionary,
  wReadOnlyTeaVar, wInvalidTeaVar, wInvalidOutputValue, wInvalidMaxCount,
  wInvalidTeaContent, wInvalidRepeat, wInvalidPrepost, wMissingCommaParen,
  wExpectedString, wInvalidStatement, wOneParameter, wStringListDict,
  wInvalidFunction, wGetTakes2or3Params, wExpectedIntFor2, wMissingListItem,
  wExpectedStringFor2, wMissingDictItem, wExpectedListOrDict,
  wMissingReplacementVar, wNoTempFile, wExceededMaxLine, wSpaceAfterCommand,
  wTwoParameters, wNotSameKind, wNotNumberOrString, wTwoOrThreeParameters,
  wTwoOrMoreParameters, wInvalidMaxRepeat, wContentNotSet, wThreeParameters,
  wExpectedInteger, wAllIntOrFloat, wOverflow, wUnused, wInvalidIndex,
  wExpectedDictionary, wThreeOrMoreParameters, wInvalidMainType,
  wInvalidCondition, wInvalidVersion, wIntOrStringNumber, wFloatOrStringNumber,
  wExpectedRoundOption, wOneOrTwoParameters, wMissingNewLineContent,
  wResultFileNotAllowed, wUnableToOpenTempFile, wUnableToRenameTemp,
  wNoTemplateName, wInvalidPosition, wEndLessThenStart, wSubstringNotFound,
  wDupStringTooLong, wPairParameters, wMissingElse, wImmutableVars,
  wExpected4Parameters, wInvalidLength, wMissingReplacement, wExpectedList,
  wExpectedSeparator, wReservedNameSpaces, wMissingVarName, wNotDict,
  wMissingDict, wExpectedSortOrder, wAllNotIntFloatString, wIntFloatString,
  wNotZeroOne, wOneToFourParameters, wExpectedSensitivity, wExpectedKey,
  wDictKeyMissing, wKeyValueKindDiff, wSubListsEmpty, wSubListsDiffTypes,
  kMaxWarnings, kInvalidSignature, kInvalidParamType, kNotEnoughArgs,
  kWrongType, kNoVarargArgs, kNotEnoughVarargs, kTooManyArgs,
  wAtLeast4Parameters, wExpectedNumberString, wCaseTypeMismatch, wNotEvenCases,
  wNotAllStrings, wTeaVariableExists, wAppendToList, wAppendToTeaVar
```

# warningsList



```nim
warningsList: array[low(Warning) .. high(Warning), string] = [
    "No $1 filename. Use $2=filename.", "Unknown switch: $1.",
    "Unknown argument: $1.", "One result file allowed, skipping: \'$1\'.",
    "Skipping extra prepost text: $1.",
    "One template file allowed on the command line, skipping: $1.",
    "No prepost value. Use $1=\"...\".", "Skipping extra prepost text: $1.",
    "Unable to open log file: \'$1\'.",
    "One log file allowed, skipping: \'$1\'.",
    "Unable to write to the log file: \'$1\'.", "Exception: \'$1\'.",
    "Stack trace: \'$1\'.", "Unexpected exception: \'$1\'.",
    "The root json element must be an object. Skipping file: $1.",
    "Unable to parse the json file. Skipping file: $1.", "File not found: $1.",
    "Unable to open file: $1.", "Setup log rotation for $1 which has $2 bytes.",
    "Unable to open standard device: $1.",
    "No command specified on the line, treating it as a comment.",
    "Command line too long.",
    "No command found at column $1, treating it as a non-command line.",
    """The matching closing comment postfix was not found, expected: "$1".""",
    "Missing the continuation command, abandoning the previous command.",
    "Ignoring extra text after the number.", "Invalid number.",
    "The number is too big or too small.",
    "Not enough memory for the line buffer.",
    "Statement does not start with a variable name.", "Invalid string.",
    "Unused text at the end of the statement. Missing semicolon?",
    "Invalid UTF-8 byte in the string.",
    "Expected a string, number, variable or function.",
    "Invalid variable or missing equal sign.",
    "The variable namespace \'$1\' does not exist.",
    "The variable \'$1\' does not exist.",
    "The statement starting at column $1 has an error.",
    "You cannot overwrite the server or shared variables.",
    "You cannot change the $1 tea variable.", "Invalid tea variable: $1.",
    """Invalid t.output value, use: "result", "stderr", "log", or "skip".""",
    "Invalid count. It must be a positive integer.",
    "Invalid t.content, it must be a string.",
    "Invalid t.repeat, it must be an integer >= 0 and <= t.maxRepeat.",
    "Invalid prepost: $1.", "Expected comma or right parentheses.",
    "Expected a string.", "Invalid statement, skipping it.",
    "Expected one parameter.", "Len takes a string, list or dict parameter.",
    "The function does not exist: $1.",
    "The get function takes 2 or 3 parameters.",
    "Expected an int for the second parameter, got $1.",
    "The list index $1 out of range.",
    "Expected a string for the second parameter, got $1.",
    "The dictionary does not have an item with key $1.",
    "Expected a list or dictionary as the first parameter.",
    "The replacement variable doesn\'t exist: $1$2.",
    "Unable to create a temporary file.", "Reached the maximum replacement block line count without finding the endblock.",
    "No space after the command.", "The function takes two parameters.",
    "The two parameters are not the same type.",
    "The parameters must be numbers or strings.",
    "The function takes two or three parameters.",
    "The function takes two or more parameters.",
    "The t.maxRepeat variable must be an integer >= t.repeat.", "The t.content variable is not set for the replace command, treating it like the block command.",
    "Expected three parameters.", "The parameter must be an integer.",
    "The parameters must be all integers or all floats.",
    "Overflow or underflow.", "The parameter must be a string.",
    "Index values must greater than or equal to 0, got: $1.",
    "The parameter must be a dictionary.",
    "The function takes at least 3 parameters.",
    "The main condition type must an int or string.",
    "The case condition must be an int or string.",
    "Invalid StaticTea version string.", "Expected int or int number string.",
    "Expected a float or float number string.",
    "Expected round, floor, ceiling or truncate.",
    "The function takes one or two parameters.",
    "The t.content does not end with a newline, adding one.",
    "The update option overwrites the template, no result file allowed.",
    "Unable to open temporary file.",
    "Unable to rename temporary file over template file.",
    "No template name. Use -h for help.", "Invalid position: got $1.",
    "The end position is less that the start position.",
    "The substring was not found and no default parameter.",
    "The resulting duplicated string must be under 1024 characters, got: $1.",
    "Specify parameters in pairs.",
    "None of the case conditions match and no else case.",
    "You cannot assign to an existing variable.", "Expected four parameters.",
    "Invalid length: $1.",
    "Invalid number of parameters, the pattern and replacement come in pairs.",
    "Expected a list.", "Expected / or \\.",
    "The variables f, g, h, l, s and t are reserved variable names.",
    "Name, $1, doesn\'t exist in the parent dictionary.",
    "Name, $1, is not a dictionary.", "The dictionary $1 doesn\'t exist.",
    "Expected the sort order, \'ascending\' or \'descending\'.",
    "The list values must be all ints, all floats or all strings.",
    "The values must be integers, floats or strings.",
    "The parameter must be 0 or 1.",
    "The function takes one to four parameters.",
    "Expected the sensitive or unsensitive.",
    "Expected the dictionary sort key.",
    "A dictionary is missing the sort key.",
    "The sort key values are different types.", "A sublist is empty.",
    "The first item in the sublists are different types.",
    "Reached the maximum number of warnings, suppressing the rest.",
    "Invalid signature string.", "Invalid parameter type.",
    "Not enough parameters, expected $1 got $2.",
    "Wrong parameter type, expected $1 got $2.",
    "The required vararg parameter has no arguments.",
    "Missing vararg parameter, expected groups of 2 got 1.",
    "Too many arguments, expected at most
```

# getWarning

Return a formatted warning line.

```nim
func getWarning(filename: string; lineNum: int; warning: Warning;
                p1: string = ""; p2: string = ""): string
```

# newWarningData

Create a WarningData object containing the warning information.

```nim
proc newWarningData(warning: Warning; p1: string = ""; p2: string = ""): WarningData
```

# `$`

Return a string representation of WarningData.

```nim
func `$`(warningData: WarningData): string
```

# `==`

Return true when the two WarningData are equal.

```nim
func `==`(w1: WarningData; w2: WarningData): bool
```


---
⦿ Markdown page generated by [StaticTea](https://github.com/flenniken/statictea/) from nim doc comments. ⦿
