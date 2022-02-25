# cmdline.nim

Parse the command line.

* [cmdline.nim](../src/cmdline.nim) &mdash; Nim source code.
# Index

* type: [MessageId](#messageid) &mdash; Posssible message numbers returned by cmdline.
* type: [ArgsOrMessageIdKind](#argsormessageidkind) &mdash; The kind of an ArgsOrMessageId object, either args or a message id.
* type: [Args](#args) &mdash; Args holds the parsed command line arguments in an ordered dictionary.
* type: [ArgsOrMessageId](#argsormessageid) &mdash; Contains the command line args or a message id.
* type: [OptionType](#optiontype) &mdash; OptionType tells whether the option has an associated parameter or not and whether it is a bare parameter.
* [newOption](#newoption) &mdash; Return a new Option object.
* [`$`](#) &mdash; Return a string representation of an Option object.
* [`$`](#-1) &mdash; Return a string representation of a ArgsOrMessageId object.
* [commandLineEcho](#commandlineecho) &mdash; Show the command line arguments.
* [collectParams](#collectparams) &mdash; Get the command line parameters from the system and return a list.
* [cmdLine](#cmdline) &mdash; Parse the command line options.

# MessageId

Posssible message numbers returned by cmdline.

```nim
MessageId = enum
  clmBareTwoDashes,         ## Two dashes must be followed by an option name.
  clmInvalidOption,         ## "--{optionName}" is not an option.
  clmMissingRequiredParameter, ## Missing
```

# ArgsOrMessageIdKind

The kind of an ArgsOrMessageId object, either args or a message id.

```nim
ArgsOrMessageIdKind = enum
  clArgs, clMessageId
```

# Args

Args holds the parsed command line arguments in an ordered dictionary. The keys are the supported options found on the command line and each value is a list of associated parameters. The bare parameters use key "_bare". An option without parameters will have an empty list.

```nim
Args = OrderedTable[string, seq[string]]
```

# ArgsOrMessageId

Contains the command line args or a message id.

```nim
ArgsOrMessageId = object
  case kind*: ArgsOrMessageIdKind
  of clArgs:
      args*: Args

  of clMessageId:
      messageId*: MessageId
      problemParam*: string


```

# OptionType

OptionType tells whether the option has an associated parameter or not and whether it is a bare parameter.

```nim
OptionType = enum
  clParameter,              ## option with a parameter
  clNoParameter,            ## option without a parameter
  clOptionalParameter,      ## option with an optional parameter
  clBareParameter            ## bare parameter. Use '_' for the short name.
```

# newOption

Return a new Option object.

```nim
func newOption(long: string; short: char; optionType: OptionType): Option
```

# `$`

Return a string representation of an Option object.

```nim
func `$`(a: Option): string
```

# `$`

Return a string representation of a ArgsOrMessageId object.

```nim
func `$`(a: ArgsOrMessageId): string
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

Parse the command line options.  You pass in the dictionary of options supported. The arguments are returned or a message telling why args cannot be returned. Use collectParams() to generate parameters.

```nim
func cmdLine(options: openArray[Option]; parameters: openArray[string]): ArgsOrMessageId
```


---
⦿ Markdown page generated by [StaticTea](https://github.com/flenniken/statictea/) from nim doc comments. ⦿