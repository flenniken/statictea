# cmdline.nim

Parse the command line.

 Example:
 ~~~
 import cmdline

 # Define the supported options.
 var options = newSeq[CmlOption]()
 options.add(newCmlOption("help", 'h', cmlStopParameter))
 options.add(newCmlOption("log", 'l', cmlOptionalParameter))
 ...

 # Parse the command line.
 let argsOrMessage = cmdline(options, collectParams())
 if argsOrMessage.kind == cmlMessageKind:
   # Display the message.
   echo getMessage(argsOrMessage.messageId,
     argsOrMessage.problemParam)
 else:
   # Optionally post process the resulting arguments.
   let args = newArgs(argsOrMessage.args)
 ~~~~

 For a complete example see the bottom of the file in the isMainModule
 section.

* [cmdline.nim](../src/cmdline.nim) &mdash; Nim source code.
# Index

* type: [CmlArgs](#cmlargs) &mdash; CmlArgs holds the parsed command line arguments in an ordered
dictionary.
* type: [CmlMessageId](#cmlmessageid) &mdash; Possible message IDs returned by cmdline.
* type: [ArgsOrMessageKind](#argsormessagekind) &mdash; The kind of an ArgsOrMessage object, either args or a message.
* type: [ArgsOrMessage](#argsormessage) &mdash; Contains the command line args or a message.
* type: [CmlOptionType](#cmloptiontype) &mdash; The option type.
* [newCmlOption](#newcmloption) &mdash; Create a new CmlOption object.
* [`$`](#) &mdash; Return a string representation of an CmlOption object.
* [`$`](#-1) &mdash; Return a string representation of a ArgsOrMessage object.
* [commandLineEcho](#commandlineecho) &mdash; Show the command line arguments.
* [collectParams](#collectparams) &mdash; Get the command line parameters from the system and return a list.
* [cmdLine](#cmdline) &mdash; Parse the command line parameters.
* [getMessage](#getmessage) &mdash; Return a message from a message id and problem parameter.
* [`$`](#-2) &mdash; Return a string representation of an Args object.

# CmlArgs

CmlArgs holds the parsed command line arguments in an ordered
dictionary. The keys are the supported options found on the
command line and each value is a list of associated arguments.
An option without parameters will have an empty list.

```nim
CmlArgs = OrderedTable[string, seq[string]]
```

# CmlMessageId

Possible message IDs returned by cmdline. The number in the
name is the same as its ord value.  Since the message handling
is left to the caller, it is important for these values to be
stable. New values are added to the end and this is a minor
version change. It is ok to leave unused values in the list and
this is backward compatible. If items are removed or reordered,
that is a major version change.

```nim
CmlMessageId = enum
  cml_00_BareTwoDashes, cml_01_InvalidOption, cml_02_OptionRequiresArg,
  cml_03_BareOneDash, cml_04_InvalidShortOption, cml_05_ShortParamInList,
  cml_06_DupShortOption, cml_07_DupLongOption, cml_08_BareShortName,
  cml_09_AlphaNumericShort, cml_10_MissingArgument, cml_11_TooManyBareArgs,
  cml_12_AlreadyHaveOneArg
```

# ArgsOrMessageKind

The kind of an ArgsOrMessage object, either args or a message.

```nim
ArgsOrMessageKind = enum
  cmlArgsKind, cmlMessageKind
```

# ArgsOrMessage

Contains the command line args or a message.

```nim
ArgsOrMessage = object
  case kind*: ArgsOrMessageKind
  of cmlArgsKind:
      args*: CmlArgs

  of cmlMessageKind:
      messageId*: CmlMessageId
      problemParam*: string


```

# CmlOptionType

The option type.
* cmlParameter0or1 -- option with a parameter, 0 or 1 times.
* cmlNoParameter -- option without a parameter, 0 or 1 times.
* cmlOptionalParameter -- option with an optional parameter, 0
    or 1 times.
* cmlBareParameter -- a parameter without an option, 1 time.
* cmlParameterOnce -- option with a parameter, 1 time.
* cmlParameterMany -- option with a parameter, unlimited
    number of times.
* cmlStopParameter -- option without a parameter, 0 or 1
    times. Stop and return this option by itself.

```nim
CmlOptionType = enum
  cmlParameter0or1, cmlNoParameter, cmlOptionalParameter, cmlBareParameter,
  cmlParameterOnce, cmlParameterMany, cmlStopParameter
```

# newCmlOption

Create a new CmlOption object. For no short option use a dash.

```nim
func newCmlOption(long: string; short: char; optionType: CmlOptionType): CmlOption
```

# `$`

Return a string representation of an CmlOption object.

```nim
func `$`(a: CmlOption): string
```

# `$`

Return a string representation of a ArgsOrMessage object.

```nim
func `$`(a: ArgsOrMessage): string
```

# commandLineEcho

Show the command line arguments.

```nim
proc commandLineEcho()
```

# collectParams

Get the command line parameters from the system and return a list. Don't return the first one which is the app name. This is the list that cmdLine expects.

```nim
proc collectParams(): seq[string]
```

# cmdLine

Parse the command line parameters.  You pass in the list of supported options and the parameters to parse. The arguments found are returned. If there is a problem with the parameters, args contains a message telling the problem. Use collectParams() to generate the parameters.

```nim
func cmdLine(options: openArray[CmlOption]; parameters: openArray[string]): ArgsOrMessage
```

# getMessage

Return a message from a message id and problem parameter.

```nim
func getMessage(message: CmlMessageId; problemParam: string = ""): string
```

# `$`

Return a string representation of an Args object.

```nim
func `$`(a: Args): string
```


---
⦿ Markdown page generated by [StaticTea](https://github.com/flenniken/statictea/) from nim doc comments. ⦿
