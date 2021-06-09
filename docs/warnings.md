[StaticTea Modules](/)

# warnings.nim

The warning messages.

# Index

* type: [WarningData](#user-content-a0) &mdash; Warning number and optional extra strings.
* type: [Warning](#user-content-a1) &mdash; Warning numbers.
* [getWarning](#user-content-a2) &mdash; Return a formatted warning line.
* [newWarningData](#user-content-a3) &mdash; Create a WarningData object containing the warning information.
* [`$`](#user-content-a4) &mdash; Return a string representation of WarningData.
* [`==`](#user-content-a5) &mdash; Return true when the two WarningData are equal.

# <a id="a0"></a>WarningData

Warning number and optional extra strings.

```nim
WarningData = object
  warning*: Warning          ## Warning message id.
  p1*: string                ## Extra warning info.
  p2*: string                ## Extra warning info.

```


# <a id="a1"></a>Warning

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
  wDictKeyMissing, wKeyValueKindDiff, wSubListsEmpty, wSubListsDiffTypes
```


# <a id="a2"></a>getWarning

Return a formatted warning line.

```nim
func getWarning(filename: string; lineNum: int; warning: Warning;
                p1: string = ""; p2: string = ""): string
```


# <a id="a3"></a>newWarningData

Create a WarningData object containing the warning information.

```nim
proc newWarningData(warning: Warning; p1: string = ""; p2: string = ""): WarningData
```


# <a id="a4"></a>`$`

Return a string representation of WarningData.

```nim
func `$`(warningData: WarningData): string
```


# <a id="a5"></a>`==`

Return true when the two WarningData are equal.

```nim
func `==`(w1: WarningData; w2: WarningData): bool
```



---
⦿ StaticTea markdown template for nim doc comments. ⦿
