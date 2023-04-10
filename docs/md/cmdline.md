# cmdline.nim

Parse the command line.

Example:

~~~nim
import cmdline

# Define the supported options.
var supportedOptions = newSeq[CmlOption]()
supportedOptions.add(newCmlOption("help", 'h', cmlStopArgument))
supportedOptions.add(newCmlOption("log", 'l', cmlOptionalArgument))
...

# Parse the command line.
let argsOrMessage = cmdline(supportedOptions, collectArgs())
if argsOrMessage.kind == cmlMessageKind:
  # Display the message.
  echo getMessage(argsOrMessage.messageId,
    argsOrMessage.problemArg)
else:
  # Optionally post process the resulting arguments.
  let args = newArgs(argsOrMessage.args)
~~~

For a complete example see the bottom of the file in the isMainModule
section.


* [cmdline.nim](../src/cmdline.nim) &mdash; Nim source code.
# Index

* type: [CmlArgs](#cmlargs) &mdash; CmlArgs holds the parsed command line arguments in an ordered dictionary.
* type: [CmlMessageId](#cmlmessageid) &mdash; Possible message IDs returned by cmdline.
* type: [ArgsOrMessageKind](#argsormessagekind) &mdash; The kind of an ArgsOrMessage object, either args or a message.
* type: [ArgsOrMessage](#argsormessage) &mdash; Contains the command line args or a message.
* type: [CmlOptionType](#cmloptiontype) &mdash; The option type.
* type: [CmlOption](#cmloption) &mdash; An CmlOption holds its type, long name and short name.
* [newCmlOption](#newcmloption) &mdash; Create a new CmlOption object.
* [newArgsOrMessage](#newargsormessage) &mdash; Create a new ArgsOrMessage object containing arguments.
* [newArgsOrMessage](#newargsormessage-1) &mdash; Create a new ArgsOrMessage object containing a message id and optionally the problem argument.
* [`$`](#) &mdash; Return a string representation of an CmlOption object.
* [`$`](#-1) &mdash; Return a string representation of a ArgsOrMessage object.
* [commandLineEcho](#commandlineecho) &mdash; Show the command line arguments.
* [collectArgs](#collectargs) &mdash; Get the command line arguments from the system and return a list.
* [cmdLine](#cmdline) &mdash; Parse the command line arguments.
* const: [cmlMessages](#cmlmessages) &mdash; Messages used by this module.
* [getMessage](#getmessage) &mdash; Return a message from a message id and problem argument.
* [`$`](#-2) &mdash; Return a string representation of an Args object.

# CmlArgs

CmlArgs holds the parsed command line arguments in an ordered
dictionary. The keys are the supported options found on the
command line and each value is a list of associated arguments.
An option without arguments will have an empty list.


~~~nim
CmlArgs = OrderedTable[string, seq[string]]
~~~

# CmlMessageId

Possible message IDs returned by cmdline. The number in the
name is the same as its ord value.  Since the message handling
is left to the caller, it is important for these values to be
stable. New values are added to the end and this is a minor
version change. It is ok to leave unused values in the list and
this is backward compatible. If items are removed or reordered,
that is a major version change.


~~~nim
CmlMessageId = enum
  cml_00_BareTwoDashes, cml_01_InvalidOption, cml_02_OptionRequiresArg,
  cml_03_BareOneDash, cml_04_InvalidShortOption, cml_05_ShortArgInList,
  cml_06_DupShortOption, cml_07_DupLongOption, cml_08_BareShortName,
  cml_09_AlphaNumericShort, cml_10_MissingArgument, cml_11_TooManyBareArgs,
  cml_12_AlreadyHaveOneArg
~~~

# ArgsOrMessageKind

The kind of an ArgsOrMessage object, either args or a message.


~~~nim
ArgsOrMessageKind = enum
  cmlArgsKind, cmlMessageKind
~~~

# ArgsOrMessage

Contains the command line args or a message.


~~~nim
ArgsOrMessage = object
  case kind*: ArgsOrMessageKind
  of cmlArgsKind:
      args*: CmlArgs

  of cmlMessageKind:
      messageId*: CmlMessageId
      problemArg*: string
~~~

# CmlOptionType

The option type.

* cmlArgument0or1 — option with an argument, 0 or 1 times.
* cmlNoArgument — option without an argument, 0 or 1 times.
* cmlOptionalArgument — option with an optional argument, 0
or 1 times.
* cmlBareArgument — an argument without an option, 1 time.
* cmlArgumentOnce — option with an argument, 1 time.
* cmlArgumentMany — option with an argument, unlimited number
of times.
* cmlStopArgument — option without an argument, 0 or 1
times. Stop and return this option by itself.
* cmlNoOptions — when no arguments specified. No messages for
any required options.


~~~nim
CmlOptionType = enum
  cmlArgument0or1, cmlNoArgument, cmlOptionalArgument, cmlBareArgument,
  cmlArgumentOnce, cmlArgumentMany, cmlStopArgument, cmlNoOptions
~~~

# CmlOption

An CmlOption holds its type, long name and short name.


~~~nim
CmlOption = object
  optionType: CmlOptionType
  long: string
  short: char
~~~

# newCmlOption

Create a new CmlOption object. For no short option use a dash.


~~~nim
func newCmlOption(long: string; short: char; optionType: CmlOptionType): CmlOption
~~~

# newArgsOrMessage

Create a new ArgsOrMessage object containing arguments.


~~~nim
func newArgsOrMessage(args: CmlArgs): ArgsOrMessage
~~~

# newArgsOrMessage

Create a new ArgsOrMessage object containing a message id and
optionally the problem argument.


~~~nim
func newArgsOrMessage(messageId: CmlMessageId; problemArg = ""): ArgsOrMessage
~~~

# `$`

Return a string representation of an CmlOption object.


~~~nim
func `$`(a: CmlOption): string {.raises: [ValueError], tags: [].}
~~~

# `$`

Return a string representation of a ArgsOrMessage object.


~~~nim
func `$`(a: ArgsOrMessage): string {.raises: [ValueError], tags: [].}
~~~

# commandLineEcho

Show the command line arguments.


~~~nim
proc commandLineEcho() {.raises: [ValueError], tags: [ReadIOEffect].}
~~~

# collectArgs

Get the command line arguments from the system and return a
list. Don't return the first one which is the app name. This is
the list that cmdLine expects.


~~~nim
proc collectArgs(): seq[string] {.raises: [], tags: [ReadIOEffect].}
~~~

# cmdLine

Parse the command line arguments.  You pass in the list of
supported options and the arguments to parse. The arguments found
are returned. If there is a problem with the arguments, args
contains a message telling the problem. Use collectArgs() to
generate the arguments. Parse uses "arg value" not "arg=value".


~~~nim
func cmdLine(supportedOptions: openArray[CmlOption];
             arguments: openArray[string]): ArgsOrMessage {.raises: [KeyError],
    tags: [].}
~~~

# cmlMessages

Messages used by this module.


~~~nim
cmlMessages: array[low(CmlMessageId) .. high(CmlMessageId), string] = [
    "Two dashes must be followed by an option name.",
    "The option \'--$1\' is not supported.",
    "The option \'$1\' requires an argument.",
    "One dash must be followed by a short option name.",
    "The short option \'-$1\' is not supported.",
    "The option \'-$1\' needs an argument; use it by itself.",
    "Duplicate short option: \'-$1\'.", "Duplicate long option: \'--$1\'.",
    "Use the short name \'_\' instead of \'$1\' with a bare argument.", "Use an alphanumeric ascii character for a short option name instead of \'$1\'.",
    "Missing \'$1\' argument.", "Extra bare argument.",
    "One \'$1\' argument is allowed."]
~~~

# getMessage

Return a message from a message id and problem argument.


~~~nim
func getMessage(message: CmlMessageId; problemArg: string = ""): string {.
    raises: [ValueError], tags: [].}
~~~

# `$`

Return a string representation of an Args object.


~~~nim
func `$`(a: Args): string {.raises: [ValueError], tags: [].}
~~~


---
⦿ Markdown page generated by [StaticTea](https://github.com/flenniken/statictea/) from nim doc comments. ⦿
