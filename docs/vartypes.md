# vartypes.nim

StaticTea variable types.

* [vartypes.nim](../src/vartypes.nim) &mdash; Nim source code.
# Index

* const: [variableStartChars](#variablestartchars) &mdash; The characters that make up a variable dotname.
* const: [variableMiddleChars](#variablemiddlechars) &mdash; A variable contains ascii letters, digits, underscores and hypens.
* const: [variableChars](#variablechars) &mdash; A variable contains ascii letters, digits, underscores and hypens.
* const: [startTFVarNumber](#starttfvarnumber) &mdash; A character that starts true, false, a variable or a number.
* type: [VarsDict](#varsdict) &mdash; This is a ref type.
* type: [Mutable](#mutable) &mdash; The mutable state of lists and dictionaries.
* type: [DictType](#dicttype) &mdash; The statictea dictionary type.
* type: [ListType](#listtype) &mdash; The statictea list type.
* type: [Variables](#variables) &mdash; Dictionary holding all statictea variables in multiple distinct logical dictionaries.
* type: [VarsDictOr](#varsdictor) &mdash; A VarsDict object or a warning.
* type: [ValueKind](#valuekind) &mdash; The statictea variable types.
* type: [Value](#value) &mdash; A variable's value reference.
* type: [ValueOr](#valueor) &mdash; A Value object or a warning.
* type: [Statement](#statement) &mdash; Statement object stores the statement text, the line number and its line ending.
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
* type: [ValuePosSi](#valuepossi) &mdash; A value and the position after the value in the statement along with the side effect, if any.
* type: [ValuePosSiOr](#valuepossior) &mdash; A ValuePosSi object or a warning.
* [newSignature](#newsignature) &mdash; Create a Signature object.
* [newSignatureOr](#newsignatureor) &mdash; Create a new SignatureOr with a message.
* [newSignatureOr](#newsignatureor-1) &mdash; Create a new SignatureOr with a message.
* [newSignatureOr](#newsignatureor-2) &mdash; Create a new SignatureOr with a value.
* [newSignatureOr](#newsignatureor-3) &mdash; Create a SignatureOr object.
* [newParam](#newparam) &mdash; Create a new Param object.
* [newVarsDict](#newvarsdict) &mdash; Create a new empty variables dictionary.
* [newVarsDictOr](#newvarsdictor) &mdash; Return a new varsDictOr object containing a warning.
* [newVarsDictOr](#newvarsdictor-1) &mdash; Return a new VarsDict object containing a dictionary.
* [newDictType](#newdicttype) &mdash; 
* [newListType](#newlisttype) &mdash; 
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
* [newStatement](#newstatement) &mdash; Create a new statement.
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
* [newValuePosSi](#newvaluepossi) &mdash; Create a newValuePosSi object.
* [newValuePosSiOr](#newvaluepossior) &mdash; Create a ValuePosSiOr warning.
* [newValuePosSiOr](#newvaluepossior-1) &mdash; Create a ValuePosSiOr warning.
* [`==`](#-8) &mdash; Return true when a equals b.
* [`==`](#-9) &mdash; Return true when a equals b.
* [`!=`](#-10) &mdash; Compare two ValuePosSi objects and return false when equal.
* [`!=`](#-11) &mdash; Compare two ValuePosSiOr objects and return false when equal.
* [newValuePosSiOr](#newvaluepossior-2) &mdash; Create a ValuePosSiOr from a value, pos and exit.
* [newValuePosSiOr](#newvaluepossior-3) &mdash; Create a ValuePosSiOr value from a number or string.
* [newValuePosSiOr](#newvaluepossior-4) &mdash; Create a ValuePosSiOr from a ValuePosSi.
* [codeToParamType](#codetoparamtype) &mdash; Convert a parameter code letter to a ParamType.
* [strToParamType](#strtoparamtype) &mdash; Return the parameter type for the given string, e.
* [shortName](#shortname) &mdash; Return a short name based on the given index value.
* [newSignatureO](#newsignatureo) &mdash; Return a new signature for the function name and signature code.

# variableStartChars

The characters that make up a variable dotname.  A variable starts with an ascii letter.

```nim
variableStartChars: set[char] =
```

# variableMiddleChars

A variable contains ascii letters, digits, underscores and hypens.

```nim
variableMiddleChars: set[char] =
```

# variableChars

A variable contains ascii letters, digits, underscores and hypens. Variables are connected with dots to make a dot name.

```nim
variableChars: set[char] =
```

# startTFVarNumber

A character that starts true, false, a variable or a number.

```nim
startTFVarNumber: set[char] =
```

# VarsDict

This is a ref type. Create a new VarsDict with newVarsDict procedure.

```nim
VarsDict = OrderedTableRef[string, Value]
```

# Mutable

The mutable state of lists and dictionaries.
* immutable -- you cannot change it
* append -- you can append to the end
* full -- you can change everything

```nim
Mutable
```

# DictType

The statictea dictionary type.

* dict -- an ordered dictionary.
* mutable -- whether you can append to the dictionary or not.

```nim
DictType = object
  dict*: VarsDict
  mutable*: Mutable

```

# ListType

The statictea list type.

* list -- a list of values.
* mutable -- whether you can append to the dictionary or not.

```nim
ListType = object
  list*: seq[Value]
  mutable*: Mutable

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
* vkString -- string of UTF-8 characters
* vkInt -- 64 bit signed integer
* vkFloat -- 64 bit floating point number
* vkDict -- hash table mapping strings to any value
* vkList -- a list of values of any type
* vkBool -- true or false
* vkFunc -- reference to a function

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

# Statement

Statement object stores the statement text, the line number and its line ending.

* text -- a line containing a statement without the line ending
* lineNum -- line number in the file where the statement starts (the first line is 1)
statement starts.
* ending -- the line ending, either linefeed (\n) or carriage return and linefeed (\r\n).

```nim
Statement = object
  text*: string
  lineNum*: Natural
  ending*: string

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
* ptString -- string parameter type
* ptInt -- integer
* ptFloat -- floating point number
* ptDict -- dictionary
* ptList -- list
* ptBool -- boolean
* ptFunc -- function pointer
* ptAny -- any parameter type

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
* params -- a list of the function parameter names and types
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

* builtIn -- true for the built-in functions, false for user functions
* signature -- the function signature
* docComment -- the function document comment
* filename -- the filename where the function is defined either the code file or functions.nim
* lineNum -- the line number where the function definition starts
* numLines -- the number of lines to define the function
* statements -- a list of the function statements for user functions
* functionPtr -- pointer to the function for built-in functions

```nim
FunctionSpec = object
  builtIn*: bool
  signature*: Signature
  docComment*: string
  filename*: string
  lineNum*: Natural
  numLines*: Natural
  statements*: seq[Statement]
  functionPtr*: FunctionPtr

```

# FunResultKind

The kind of a FunResult object, either a value or warning.
* frValue -- a value
* frWarning -- a warning message

```nim
FunResultKind = enum
  frValue, frWarning
```

# FunResult

Contains the result of calling a function, either a value or a warning.

The parameter field is the index of the problem argument or
-1 to point at the function itself.

```nim
FunResult = object
  case kind*: FunResultKind
  of frValue:
      value*: Value

  of frWarning:
      parameter*: int
      warningData*: WarningData


```

# SideEffect

The kind of side effect for a statement.

* seNone -- no side effect, the normal case
* seReturn -- the return function; stop the command and
either skip the replacement block or stop iterating.
* seLogMessage -- the log function; write a message to the log file
* seBareIfIgnore -- the bare IF function was false, ignore the statement

```nim
SideEffect = enum
  seNone = "none", seReturn = "return", seLogMessage = "log",
  seBareIfIgnore = "bareIfIgnore"
```

# ValuePosSi

A value and the position after the value in the statement along with the side effect, if any. The position includes the trailing whitespace.  For the example statement below, the value 567 starts at index 6 and ends at position 10.

~~~
0123456789 123456789
var = 567 # test
      ^ start
          ^ end position
~~~

```nim
ValuePosSi = object
  value*: Value
  pos*: Natural
  sideEffect*: SideEffect

```

# ValuePosSiOr

A ValuePosSi object or a warning.

```nim
ValuePosSiOr = OpResultWarn[ValuePosSi]
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

# newDictType



```nim
func newDictType(varsDict: VarsDict; mutable = Mutable.immutable): DictType
```

# newListType



```nim
func newListType(valueList: seq[Value]; mutable = Mutable.immutable): ListType
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
proc newValue(valueList: seq[Value]; mutable = Mutable.immutable): Value
```

# newValue

Create a dictionary value from a VarsDict.

```nim
proc newValue(varsDict: VarsDict; mutable = Mutable.immutable): Value
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
~~~

```nim
proc newValue[T](list: openArray[T]; mutable = Mutable.immutable): Value
```

# newValue

New dict value from an array of pairs where the pairs are the
same type which may be Value type.

~~~
 let dictValue = newValue([("a", 1), ("b", 2), ("c", 3)])
 let dictValue = newValue([("a", 1.1), ("b", 2.2), ("c", 3.3)])
 let dictValue = newValue([("a", newValue(1.1)), ("b", newValue("a"))])
~~~

```nim
proc newValue[T](dictPairs: openArray[(string, T)]; mutable = Mutable.immutable): Value
```

# newFunc

Create a new func which is a FunctionSpec.

```nim
func newFunc(builtIn: bool; signature: Signature; docComment: string;
             filename: string; lineNum: Natural; numLines: Natural;
             statements: seq[Statement]; functionPtr: FunctionPtr): FunctionSpec
```

# newValue

Create a new func value.

```nim
func newValue(function: FunctionSpec): Value
```

# newEmptyListValue

Return an empty list value.

```nim
proc newEmptyListValue(mutable = Mutable.immutable): Value
```

# newEmptyDictValue

Create a dictionary value from a VarsDict.

```nim
proc newEmptyDictValue(mutable = Mutable.immutable): Value
```

# `==`

Return true when two variables are equal.

```nim
proc `==`(a: Value; b: Value): bool
```

# newStatement

Create a new statement.

```nim
func newStatement(text: string; lineNum: Natural = 1; ending = "\n"): Statement
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
func newFunResultWarn(warning: MessageId; parameter: int = 0; p1: string = "";
                      pos = 0): FunResult
```

# newFunResultWarn

Return a new FunResult object containing a warning created from a WarningData object.

```nim
func newFunResultWarn(warningData: WarningData; parameter: int = 0): FunResult
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

# newValuePosSi

Create a newValuePosSi object.

```nim
proc newValuePosSi(value: Value; pos: Natural; sideEffect: SideEffect = seNone): ValuePosSi
```

# newValuePosSiOr

Create a ValuePosSiOr warning.

```nim
func newValuePosSiOr(warning: MessageId; p1 = ""; pos = 0): ValuePosSiOr
```

# newValuePosSiOr

Create a ValuePosSiOr warning.

```nim
func newValuePosSiOr(warningData: WarningData): ValuePosSiOr
```

# `==`

Return true when a equals b.

```nim
proc `==`(a: ValuePosSi; b: ValuePosSi): bool
```

# `==`

Return true when a equals b.

```nim
proc `==`(a: ValuePosSiOr; b: ValuePosSiOr): bool
```

# `!=`

Compare two ValuePosSi objects and return false when equal.

```nim
proc `!=`(a: ValuePosSi; b: ValuePosSi): bool
```

# `!=`

Compare two ValuePosSiOr objects and return false when equal.

```nim
proc `!=`(a: ValuePosSiOr; b: ValuePosSiOr): bool
```

# newValuePosSiOr

Create a ValuePosSiOr from a value, pos and exit.

```nim
func newValuePosSiOr(value: Value; pos: Natural; sideEffect: SideEffect = seNone): ValuePosSiOr
```

# newValuePosSiOr

Create a ValuePosSiOr value from a number or string.

```nim
proc newValuePosSiOr(number: int | int64 | float64 | string; pos: Natural): ValuePosSiOr
```

# newValuePosSiOr

Create a ValuePosSiOr from a ValuePosSi.

```nim
func newValuePosSiOr(val: ValuePosSi): ValuePosSiOr
```

# codeToParamType

Convert a parameter code letter to a ParamType.

```nim
func codeToParamType(code: ParamCode): ParamType
```

# strToParamType

Return the parameter type for the given string, e.g. "int" to ptInt.

```nim
func strToParamType(str: string): ParamType
```

# shortName

Return a short name based on the given index value. Return a for 0, b for 1, etc.  It returns names a, b, c, ..., z then repeats a0, b0, c0,....

```nim
proc shortName(index: Natural): string
```

# newSignatureO

Return a new signature for the function name and signature code. The parameter names come from the shortName function for letters a through z in order. The last letter in the code is the function's return type.

Example:

~~~
var signatureO = newSignatureO("myname", "ifss")
echo $signatureO.get()
=>
myname(a: int, b: float, c: string) string
~~~

```nim
func newSignatureO(functionName: string; signatureCode: string): Option[
    Signature]
```


---
⦿ Markdown page generated by [StaticTea](https://github.com/flenniken/statictea/) from nim doc comments. ⦿
