# variables.nim

Procedures for working with statictea variables.

There is one dictionary to hold the logically separate dictionaries,
g, h, s, t etc which makes passing them around easier.

The language allows local variables to be specified without the l
prefix and it allows functions to be specified without the f prefix.


* [variables.nim](../src/variables.nim) &mdash; Nim source code.
# Index

* const: [outputValues](#outputvalues) &mdash; Where the replacement block's output goes.
* type: [Operator](#operator) &mdash; The statement operator types.
* type: [VariableData](#variabledata) &mdash; The VariableData object holds the variable name, operator,
and value which is the result of running a statement.
* type: [VariableDataOr](#variabledataor) &mdash; A VariableData object or a warning.
* type: [NoPrefixDict](#noprefixdict) &mdash; The variable letter prefix to use when it's missing.
* [newVariableDataOr](#newvariabledataor) &mdash; Create an object containing a warning.
* [newVariableDataOr](#newvariabledataor-1) &mdash; Create an object containing a warning.
* [newVariableDataOr](#newvariabledataor-2) &mdash; Create an object containing a VariableData object.
* [`$`](#) &mdash; Return a string representation of VariableData.
* [startVariables](#startvariables) &mdash; Create an empty variables object in its initial state.
* [getTeaVarIntDefault](#getteavarintdefault) &mdash; Return the int value of one of the tea dictionary integer items.
* [getTeaVarStringDefault](#getteavarstringdefault) &mdash; Return the string value of one of the tea dictionary string items.
* [resetVariables](#resetvariables) &mdash; Clear the local variables and reset the tea variables for running a command.
* [assignVariable](#assignvariable) &mdash; Assign the variable the given value if possible, else return a warning.
* [assignVariable](#assignvariable-1) &mdash; Assign the variable the given value if possible, else return a warning.
* [getVariable](#getvariable) &mdash; Look up the variable and return its value when found, else return a warning.

# outputValues

Where the replacement block's output goes.
* result -- output goes to the result file
* stdout -- output goes to the standard output stream
* stdout -- output goes to the standard error stream
* log -- output goes to the log file
* skip -- output goes to the bit bucket

~~~nim
outputValues = ["result", "stdout", "stderr", "log", "skip"]
~~~

# Operator

The statement operator types.

* opIgnore -- ignore the statement, e.g. comment or blank statement.
* opAppendDict (=) -- append the value to the dictionary
* opAppendList ($=) -- append the value to the list
* opReturn -- stop or skip the current replacement iteration
* opLog -- log a message

~~~nim
Operator = enum
  opIgnore = "ignore", opEqual = "=", opAppendList = "&=", opReturn = "return",
  opLog = "log"
~~~

# VariableData

The VariableData object holds the variable name, operator,
and value which is the result of running a statement.

* dotNameStr -- the variable dot name tells which dictionary contains
the variable, i.e.: l.d.a
* operator -- the statement's operator; what to do with the variable and value.
* value -- the variable's value

~~~nim
VariableData = object
  dotNameStr*: string
  operator*: Operator
  value*: Value
~~~

# VariableDataOr

A VariableData object or a warning.

~~~nim
VariableDataOr = OpResultWarn[VariableData]
~~~

# NoPrefixDict

The variable letter prefix to use when it's missing.

* npLocal -- use the local (l) dictionary
* npBuiltIn -- use the built in function (f) dictionary

~~~nim
NoPrefixDict = enum
  npLocal, npBuiltIn
~~~

# newVariableDataOr

Create an object containing a warning.

~~~nim
func newVariableDataOr(warning: MessageId; p1 = ""; pos = 0): VariableDataOr
~~~

# newVariableDataOr

Create an object containing a warning.

~~~nim
func newVariableDataOr(warningData: WarningData): VariableDataOr
~~~

# newVariableDataOr

Create an object containing a VariableData object.

~~~nim
func newVariableDataOr(dotNameStr: string; operator: Operator; value: Value): VariableDataOr
~~~

# `$`

Return a string representation of VariableData.

~~~nim
func `$`(v: VariableData): string {.raises: [ValueError, Exception],
                                    tags: [RootEffect].}
~~~

# startVariables

Create an empty variables object in its initial state.

~~~nim
func startVariables(server: VarsDict = nil; args: VarsDict = nil;
                    funcs: VarsDict = nil; userFuncs: VarsDict = nil): Variables
~~~

# getTeaVarIntDefault

Return the int value of one of the tea dictionary integer items. If the value does not exist, return its default value.

~~~nim
func getTeaVarIntDefault(variables: Variables; varName: string): int64 {.
    raises: [KeyError], tags: [].}
~~~

# getTeaVarStringDefault

Return the string value of one of the tea dictionary string items. If the value does not exist, return its default value.

~~~nim
func getTeaVarStringDefault(variables: Variables; varName: string): string {.
    raises: [KeyError], tags: [].}
~~~

# resetVariables

Clear the local variables and reset the tea variables for running a command.

~~~nim
proc resetVariables(variables: var Variables) {.raises: [KeyError], tags: [].}
~~~

# assignVariable

Assign the variable the given value if possible, else return a warning.

~~~nim
proc assignVariable(variables: var Variables; dotNameStr: string; value: Value;
                    operator = opEqual): Option[WarningData] {.
    raises: [KeyError, ValueError], tags: [].}
~~~

# assignVariable

Assign the variable the given value if possible, else return a warning.

~~~nim
proc assignVariable(variables: var Variables; variableData: VariableData): Option[
    WarningData] {.raises: [KeyError, ValueError], tags: [].}
~~~

# getVariable

Look up the variable and return its value when found, else return a warning. When no prefix is specified, look in the noPrefixDict dictionary.

~~~nim
proc getVariable(variables: Variables; dotNameStr: string;
                 noPrefixDict: NoPrefixDict): ValueOr {.raises: [KeyError],
    tags: [].}
~~~


---
⦿ Markdown page generated by [StaticTea](https://github.com/flenniken/statictea/) from nim doc comments. ⦿
