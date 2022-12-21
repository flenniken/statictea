# vartypes.nim

StaticTea variable types.

* [vartypes.nim](../src/vartypes.nim) &mdash; Nim source code.
# Index

* type: [VarsDict](#varsdict) &mdash; The statictea dictionary type.
* type: [Variables](#variables) &mdash; Dictionary holding all statictea variables in multiple distinct logical dictionaries.
* type: [VarsDictOr](#varsdictor) &mdash; A VarsDict object or a warning.
* type: [ValueKind](#valuekind) &mdash; The statictea variable types.
* type: [Value](#value) &mdash; A variable's value reference.
* type: [ValueOr](#valueor) &mdash; A Value object or a warning.
* type: [FunctionPtr](#functionptr) &mdash; Signature of a statictea built in function.
* type: [ParamCode](#paramcode) &mdash; Parameter type, one character of "ifsldpa" corresponding to int, float, string, list, dict, func, any.
* type: [ParamType](#paramtype) &mdash; The statictea parameter types.
* type: [Param](#param) &mdash; Holds attributes for one parameter.
* type: [Signature](#signature) &mdash; Holds the function signature.
* type: [SignatureOr](#signatureor) &mdash; A signature or message.
* type: [FunctionSpec](#functionspec) &mdash; Holds the function details.
* type: [FunResultKind](#funresultkind) &mdash; The kind of a FunResult object, either a value or warning.
* type: [FunResult](#funresult) &mdash; Contains the result of calling a function, either a value or a warning.
* type: [SideEffect](#sideeffect) &mdash; The kind of side effect for a statement.
* type: [ValueAndPos](#valueandpos) &mdash; A value and the position after the value in the statement along with the side effect, if any.
* type: [ValueAndPosOr](#valueandposor) &mdash; A ValueAndPos object or a warning.
* [newSignature](#newsignature) &mdash; Create a Signature object.
* [newSignatureOr](#newsignatureor) &mdash; Create a new SignatureOr with a message.
* [newSignatureOr](#newsignatureor-1) &mdash; Create a new SignatureOr with a message.
* [newSignatureOr](#newsignatureor-2) &mdash; Create a new SignatureOr with a value.
* [newSignatureOr](#newsignatureor-3) &mdash; Create a SignatureOr object.
* [newParam](#newparam) &mdash; Create a new Param object.
* [newVarsDict](#newvarsdict) &mdash; Create a new empty variables dictionary.
* [newVarsDictOr](#newvarsdictor) &mdash; Return a new varsDictOr object containing a warning.
* [newVarsDictOr](#newvarsdictor-1) &mdash; Return a new VarsDict object containing a dictionary.
* [newValue](#newvalue) &mdash; Create a string value.
* [newValue](#newvalue-1) &mdash; Create an integer value.
* [newValue](#newvalue-2) &mdash; Create a bool value.
* [newValue](#newvalue-3) &mdash; Create a float value.
* [newValue](#newvalue-4) &mdash; Create a list value.
* [newValue](#newvalue-5) &mdash; Create a dictionary value from a VarsDict.
* [newValue](#newvalue-6) &mdash; New value from an existing value.
* [newValue](#newvalue-7) &mdash; New list value from an array of items of the same kind.
* [newValue](#newvalue-8) &mdash; New dict value from an array of pairs where the pairs are the
same type which may be Value type.
* [newFunc](#newfunc) &mdash; Create a new func which is a FunctionSpec.
* [newValue](#newvalue-9) &mdash; Create a new func value.
* [newEmptyListValue](#newemptylistvalue) &mdash; Return an empty list value.
* [newEmptyDictValue](#newemptydictvalue) &mdash; Create a dictionary value from a VarsDict.
* [`==`](#) &mdash; Return true when two variables are equal.
* [`$`](#-1) &mdash; Return a string representation of a signature.
* [`$`](#-2) &mdash; Return a string representation of a function.
* [jsonStringRepr](#jsonstringrepr) &mdash; Return the JSON string representation.
* [dictToString](#dicttostring) &mdash; Return a string representation of a dict Value in JSON format.
* [listToString](#listtostring) &mdash; Return a string representation of a list variable in JSON format.
* [valueToString](#valuetostring) &mdash; Return a string representation of a variable in JSON format.
* [valueToStringRB](#valuetostringrb) &mdash; Return the string representation of the variable for use in the replacement blocks.
* [`$`](#-3) &mdash; Return a string representation of a Value.
* [`$`](#-4) &mdash; Return a string representation of a VarsDict.
* [dotNameRep](#dotnamerep) &mdash; Return a dot name string representation of a dictionary.
* [newValueOr](#newvalueor) &mdash; Create a new ValueOr containing a warning.
* [newValueOr](#newvalueor-1) &mdash; Create a new ValueOr containing a warning.
* [newValueOr](#newvalueor-2) &mdash; Create a new ValueOr containing a value.
* [newFunResultWarn](#newfunresultwarn) &mdash; Return a new FunResult object containing a warning.
* [newFunResultWarn](#newfunresultwarn-1) &mdash; Return a new FunResult object containing a warning created from a WarningData object.
* [newFunResult](#newfunresult) &mdash; Return a new FunResult object containing a value.
* [`==`](#-5) &mdash; Compare two FunResult objects and return true when equal.
* [`!=`](#-6) &mdash; Compare two FunResult objects and return false when equal.
* [`$`](#-7) &mdash; Return a string representation of a FunResult object.
* [newValueAndPos](#newvalueandpos) &mdash; Create a newValueAndPos object.
* [newValueAndPosOr](#newvalueandposor) &mdash; Create a ValueAndPosOr warning.
* [newValueAndPosOr](#newvalueandposor-1) &mdash; Create a ValueAndPosOr warning.
* [`==`](#-8) &mdash; Return true when a equals b.
* [`!=`](#-9) &mdash; Compare two ValueAndPosOr objects and return false when equal.
* [newValueAndPosOr](#newvalueandposor-2) &mdash; Create a ValueAndPosOr from a value, pos and exit.
* [newValueAndPosOr](#newvalueandposor-3) &mdash; Create a ValueAndPosOr value from a number or string.
* [newValueAndPosOr](#newvalueandposor-4) &mdash; Create a ValueAndPosOr from a ValueAndPos.
* [codeToParamType](#codetoparamtype) &mdash; 
* [strToParamType](#strtoparamtype) &mdash; Return the parameter type for the given string.
* [shortName](#shortname) &mdash; Return a short name based on the given index value.
* [newSignatureO](#newsignatureo) &mdash; Return a new signature for the function name and signature code.

# VarsDict

The statictea dictionary type. This is a ref type. Create a new
VarsDict with newVarsDict procedure.

```nim
VarsDict = OrderedTableRef[string, Value]
```

# Variables

Dictionary holding all statictea variables in multiple distinct logical dictionaries.

```nim
Variables = VarsDict
```

# VarsDictOr

A VarsDict object or a warning.

```nim
VarsDictOr = OpResultWarn[VarsDict]
```

# ValueKind

The statictea variable types.

```nim
ValueKind = enum
  vkString = "string", vkInt = "int", vkFloat = "float", vkDict = "dict",
  vkList = "list", vkBool = "bool", vkFunc = "func"
```

# Value

A variable's value reference.

```nim
Value = ref ValueObj
```

# ValueOr

A Value object or a warning.

```nim
ValueOr = OpResultWarn[Value]
```

# FunctionPtr

Signature of a statictea built in function. It takes any number of values and returns a value or a warning message.

```nim
FunctionPtr = proc (variables: Variables; parameters: seq[Value]): FunResult
```

# ParamCode

Parameter type, one character of "ifsldpa" corresponding to int, float, string, list, dict, func, any.

```nim
ParamCode = char
```

# ParamType

The statictea parameter types. The same as the variable types ValueKind with an extra for "any".

```nim
ParamType = enum
  ptString = "string", ptInt = "int", ptFloat = "float", ptDict = "dict",
  ptList = "list", ptBool = "bool", ptFunc = "func", ptAny = "any"
```

# Param

Holds attributes for one parameter.
* name -- the parameter name
* paramType -- the parameter type

```nim
Param = object
  name*: string
  paramType*: ParamType

```

# Signature

Holds the function signature.
* optional -- true when the last parameter is optional
* name -- the function name
* params -- the function parameters name and type
* returnType -- the function return type

```nim
Signature = object
  optional*: bool
  name*: string
  params*: seq[Param]
  returnType*: ParamType

```

# SignatureOr

A signature or message.

```nim
SignatureOr = OpResultWarn[Signature]
```

# FunctionSpec

Holds the function details.

builtIn -- true for the built-in functions, false for user functions
signature -- the function signature
docComments -- the function document comments
filename -- the filename where the function is defined either the code file or runFunctions.nim
lineNum -- the line number where the function definition starts
numLines -- the number of lines to define the function
statementLines -- a list of the function statements for user functions
functionPtr -- pointer to the function for built-in functions

```nim
FunctionSpec = object
  builtIn*: bool
  signature*: Signature
  docComments*: seq[string]
  filename*: string
  lineNum*: Natural
  numLines*: Natural
  statementLines*: seq[string]
  functionPtr*: FunctionPtr

```

# FunResultKind

The kind of a FunResult object, either a value or warning.

```nim
FunResultKind = enum
  frValue, frWarning
```

# FunResult

Contains the result of calling a function, either a value or a warning.

```nim
FunResult = object
  case kind*: FunResultKind
  of frValue:
      value*: Value          ## Return value of the function.
    
  of frWarning:
      parameter*: Natural    ## Index of problem parameter.
      warningData*: WarningData


```

# SideEffect

The kind of side effect for a statement.

* seNone -- no side effect, the normal case
* seReturn -- a return side effect, either stop or skip. stop
the command or skip the replacement block iteration.
* seLogMessage -- the log function specified to write a message to the log file

```nim
SideEffect = enum
  seNone, seReturn, seLogMessage
```

# ValueAndPos

A value and the position after the value in the statement along with the side effect, if any. The position includes the trailing whitespace.  For the example statement below, the value 567 starts at index 6 and ends at position 10.

~~~
0123456789
var = 567 # test
      ^ start
          ^ end position
~~~~

Exit is set true by the return function to exit a command.

```nim
ValueAndPos = object
  value*: Value
  pos*: Natural
  sideEffect*: SideEffect

```

# ValueAndPosOr

A ValueAndPos object or a warning.

```nim
ValueAndPosOr = OpResultWarn[ValueAndPos]
```

# newSignature

Create a Signature object.

```nim
proc newSignature(optional: bool; name: string; params: seq[Param];
                  returnType: ParamType): Signature
```

# newSignatureOr

Create a new SignatureOr with a message.

```nim
func newSignatureOr(warning: MessageId; p1 = ""; pos = 0): SignatureOr
```

# newSignatureOr

Create a new SignatureOr with a message.

```nim
func newSignatureOr(warningData: WarningData): SignatureOr
```

# newSignatureOr

Create a new SignatureOr with a value.

```nim
func newSignatureOr(signature: Signature): SignatureOr
```

# newSignatureOr

Create a SignatureOr object.

```nim
proc newSignatureOr(optional: bool; name: string; params: seq[Param];
                    returnType: ParamType): SignatureOr
```

# newParam

Create a new Param object.

```nim
func newParam(name: string; paramType: ParamType): Param
```

# newVarsDict

Create a new empty variables dictionary. VarsDict is a ref type.

```nim
proc newVarsDict(): VarsDict
```

# newVarsDictOr

Return a new varsDictOr object containing a warning.

```nim
func newVarsDictOr(warning: MessageId; p1: string = ""; pos = 0): VarsDictOr
```

# newVarsDictOr

Return a new VarsDict object containing a dictionary.

```nim
func newVarsDictOr(varsDict: VarsDict): VarsDictOr
```

# newValue

Create a string value.

```nim
proc newValue(str: string): Value
```

# newValue

Create an integer value.

```nim
proc newValue(num: int | int64): Value
```

# newValue

Create a bool value.

```nim
proc newValue(a: bool): Value
```

# newValue

Create a float value.

```nim
proc newValue(num: float): Value
```

# newValue

Create a list value.

```nim
proc newValue(valueList: seq[Value]): Value
```

# newValue

Create a dictionary value from a VarsDict.

```nim
proc newValue(varsDict: VarsDict): Value
```

# newValue

New value from an existing value. Since values are ref types, the
new value is an alias to the same value.

```nim
proc newValue(value: Value): Value
```

# newValue

New list value from an array of items of the same kind.

~~~
let listValue = newValue([1, 2, 3])
let listValue = newValue(["a", "b", "c"])
let listValue = newValue([newValue(1), newValue("b")])
~~~~

```nim
proc newValue[T](list: openArray[T]): Value
```

# newValue

New dict value from an array of pairs where the pairs are the
same type which may be Value type.

~~~
 let dictValue = newValue([("a", 1), ("b", 2), ("c", 3)])
 let dictValue = newValue([("a", 1.1), ("b", 2.2), ("c", 3.3)])
 let dictValue = newValue([("a", newValue(1.1)), ("b", newValue("a"))])
~~~~

```nim
proc newValue[T](dictPairs: openArray[(string, T)]): Value
```

# newFunc

Create a new func which is a FunctionSpec.

```nim
func newFunc(builtIn: bool; signature: Signature; docComments: seq[string];
             filename: string; lineNum: Natural; numLines: Natural;
             statementLines: seq[string]; functionPtr: FunctionPtr): FunctionSpec
```

# newValue

Create a new func value.

```nim
func newValue(function: FunctionSpec): Value
```

# newEmptyListValue

Return an empty list value.

```nim
proc newEmptyListValue(): Value
```

# newEmptyDictValue

Create a dictionary value from a VarsDict.

```nim
proc newEmptyDictValue(): Value
```

# `==`

Return true when two variables are equal.

```nim
proc `==`(a: Value; b: Value): bool
```

# `$`

Return a string representation of a signature.

```nim
func `$`(signature: Signature): string
```

# `$`

Return a string representation of a function.

```nim
func `$`(function: FunctionSpec): string
```

# jsonStringRepr

Return the JSON string representation. It is assumed the string is a valid UTF-8 encoded string.

```nim
proc jsonStringRepr(str: string): string
```

# dictToString

Return a string representation of a dict Value in JSON format.

```nim
func dictToString(value: Value): string
```

# listToString

Return a string representation of a list variable in JSON format.

```nim
func listToString(value: Value): string
```

# valueToString

Return a string representation of a variable in JSON format.

```nim
func valueToString(value: Value): string
```

# valueToStringRB

Return the string representation of the variable for use in the replacement blocks.

```nim
func valueToStringRB(value: Value): string
```

# `$`

Return a string representation of a Value.

```nim
func `$`(value: Value): string
```

# `$`

Return a string representation of a VarsDict.

```nim
proc `$`(varsDict: VarsDict): string
```

# dotNameRep

Return a dot name string representation of a dictionary. The top variables tells whether the dict is the variables dictionary.

```nim
func dotNameRep(dict: VarsDict; leftSide: string = ""; top = false): string
```

# newValueOr

Create a new ValueOr containing a warning.

```nim
func newValueOr(warning: MessageId; p1 = ""; pos = 0): ValueOr
```

# newValueOr

Create a new ValueOr containing a warning.

```nim
func newValueOr(warningData: WarningData): ValueOr
```

# newValueOr

Create a new ValueOr containing a value.

```nim
func newValueOr(value: Value): ValueOr
```

# newFunResultWarn

Return a new FunResult object containing a warning. It takes a message id, the index of the problem parameter, and the optional string that goes with the warning.

```nim
func newFunResultWarn(warning: MessageId; parameter: Natural = 0;
                      p1: string = ""; pos = 0): FunResult
```

# newFunResultWarn

Return a new FunResult object containing a warning created from a WarningData object.

```nim
func newFunResultWarn(warningData: WarningData; parameter: Natural = 0): FunResult
```

# newFunResult

Return a new FunResult object containing a value.

```nim
func newFunResult(value: Value): FunResult
```

# `==`

Compare two FunResult objects and return true when equal.

```nim
func `==`(r1: FunResult; r2: FunResult): bool
```

# `!=`

Compare two FunResult objects and return false when equal.

```nim
proc `!=`(a: FunResult; b: FunResult): bool
```

# `$`

Return a string representation of a FunResult object.

```nim
func `$`(funResult: FunResult): string
```

# newValueAndPos

Create a newValueAndPos object.

```nim
proc newValueAndPos(value: Value; pos: Natural; sideEffect: SideEffect = seNone): ValueAndPos
```

# newValueAndPosOr

Create a ValueAndPosOr warning.

```nim
func newValueAndPosOr(warning: MessageId; p1 = ""; pos = 0): ValueAndPosOr
```

# newValueAndPosOr

Create a ValueAndPosOr warning.

```nim
func newValueAndPosOr(warningData: WarningData): ValueAndPosOr
```

# `==`

Return true when a equals b.

```nim
proc `==`(a: ValueAndPosOr; b: ValueAndPosOr): bool
```

# `!=`

Compare two ValueAndPosOr objects and return false when equal.

```nim
proc `!=`(a: ValueAndPosOr; b: ValueAndPosOr): bool
```

# newValueAndPosOr

Create a ValueAndPosOr from a value, pos and exit.

```nim
func newValueAndPosOr(value: Value; pos: Natural;
                      sideEffect: SideEffect = seNone): ValueAndPosOr
```

# newValueAndPosOr

Create a ValueAndPosOr value from a number or string.

```nim
proc newValueAndPosOr(number: int | int64 | float64 | string; pos: Natural): ValueAndPosOr
```

# newValueAndPosOr

Create a ValueAndPosOr from a ValueAndPos.

```nim
func newValueAndPosOr(val: ValueAndPos): ValueAndPosOr
```

# codeToParamType



```nim
func codeToParamType(code: ParamCode): ParamType
```

# strToParamType

Return the parameter type for the given string.

```nim
func strToParamType(str: string): ParamType
```

# shortName

Return a short name based on the given index value. Return a for 0, b for 1, etc.  It returns names a, b, c, ..., z then repeats a0, b0, c0,....

```nim
proc shortName(index: Natural): string
```

# newSignatureO

Return a new signature for the function name and signature code.

```nim
func newSignatureO(functionName: string; signatureCode: string): Option[
    Signature]
```


---
⦿ Markdown page generated by [StaticTea](https://github.com/flenniken/statictea/) from nim doc comments. ⦿
