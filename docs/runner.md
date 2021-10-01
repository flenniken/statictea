# runner.nim

Standalone command to run Single Test File (stf) files.

* [runner.nim](../src/runner.nim) &mdash; Nim source code.
# Index

* type: [RunArgs](#runargs) &mdash; RunArgs holds the command line arguments.
* type: [RcAndMessage](#rcandmessage) &mdash; RcAndMessage holds a return code and message.
* type: [RunFileLine](#runfileline) &mdash; RunFileLine holds the file line options.
* type: [CompareLine](#compareline) &mdash; CompareLine holds the expected line options.
* type: [DirAndFiles](#dirandfiles) &mdash; DirAndFiles holds the result of the makeDirAndFiles procedure.
* type: [OpResultKind](#opresultkind) &mdash; The kind of OpResult object, either a value or message.
* type: [OpResult](#opresult) &mdash; Contains either a value or a message string.
* [newRunArgs](#newrunargs) &mdash; Create a new RunArgs object.
* [newRcAndMessage](#newrcandmessage) &mdash; Create a new RcAndMessage object.
* [isMessage](#ismessage) &mdash; Return true when the OpResult object contains a message.
* [isValue](#isvalue) &mdash; Return true when the OpResult object contains a value.
* [newRunFileLine](#newrunfileline) &mdash; Create a new RunFileLine object.
* [newCompareLine](#newcompareline) &mdash; Create a new CompareLine object.
* [newDirAndFiles](#newdirandfiles) &mdash; Create a new DirAndFiles object.
* [`$`](#) &mdash; Return a string representation of an OpResult object.
* [`$`](#-1) &mdash; Return a string representation of a CompareLine object.
* [`$`](#-2) &mdash; Return a string representation of a RunFileLine object.
* [writeErr](#writeerr) &mdash; Write a message to stderr.
* [writeOut](#writeout) &mdash; Write a message to stdout.
* [createFolder](#createfolder) &mdash; Create a folder with the given name.
* [deleteFolder](#deletefolder) &mdash; Delete a folder with the given name.
* [parseRunCommandLine](#parseruncommandline) &mdash; Parse the command line arguments.
* [parseRunFileLine](#parserunfileline) &mdash; Parse a file command line.
* [parseExpectedLine](#parseexpectedline) &mdash; Parse an expected line.
* [openNewFile](#opennewfile) &mdash; Create a new file in the given folder and return an open File object.
* [getCmd](#getcmd) &mdash; Return the type of line, either: #, "", id, file, expected or endfile.
* [makeDirAndFiles](#makedirandfiles) &mdash; Read the stf file and create its temp folder and files.
* [runCommand](#runcommand) &mdash; Run a command file and return its return code.
* [runCommands](#runcommands) &mdash; Run the commands.
* [openLineBuffer](#openlinebuffer) &mdash; Open a file for reading lines.
* [showTabsAndLineEndings](#showtabsandlineendings) &mdash; Return a new string with the tab and line endings visible.
* [dup](#dup) &mdash; Duplicate the pattern count times limited to 1024 characters.
* [linesSideBySide](#linessidebyside) &mdash; Show the two sets of lines side by side.
* [compareFiles](#comparefiles) &mdash; Compare two files.
* [compareFileSets](#comparefilesets) &mdash; Compare file sets and return rc=0 when they are all the same.
* [runStfFilename](#runstffilename) &mdash; Run the stf and report the result.
* [runFilename](#runfilename) &mdash; Run the stf and report the result.
* [runFilename](#runfilename-1) &mdash; Run a stf file.
* [runDirectory](#rundirectory) &mdash; Run all the stf files in the specified directory.
* [main](#main) &mdash; Run stf test files.

# RunArgs

RunArgs holds the command line arguments.

```nim
RunArgs = object
  help*: bool
  version*: bool
  leaveTempDir*: bool
  filename*: string
  directory*: string

```

# RcAndMessage

RcAndMessage holds a return code and message.

```nim
RcAndMessage = object
  rc*: int                   ## return code, 0 success.
  message*: string           ## message. A non-empty message gets displayed.

```

# RunFileLine

RunFileLine holds the file line options.

```nim
RunFileLine = object
  filename*: string
  noLastEnding*: bool
  command*: bool
  nonZeroReturn*: bool

```

# CompareLine

CompareLine holds the expected line options.

```nim
CompareLine = object
  filename1*: string
  filename2*: string

```

# DirAndFiles

DirAndFiles holds the result of the makeDirAndFiles procedure.

```nim
DirAndFiles = object
  compareLines*: seq[CompareLine]
  runFileLines*: seq[RunFileLine]

```

# OpResultKind

The kind of OpResult object, either a value or message.

```nim
OpResultKind = enum
  opValue, opMessage
```

# OpResult

Contains either a value or a message string. The default is a value. It's similar to the Option type but instead of returning nothing, you return a message that tells why you cannot return the value.

```nim
OpResult[T] = object
  case kind*: OpResultKind
  of opValue:
      value*: T

  of opMessage:
      message*: string


```

# newRunArgs

Create a new RunArgs object.

```nim
func newRunArgs(help = false; version = false; leaveTempDir = false;
                filename = ""; directory = ""): RunArgs
```

# newRcAndMessage

Create a new RcAndMessage object.

```nim
func newRcAndMessage(rc: int; message: string): RcAndMessage
```

# isMessage

Return true when the OpResult object contains a message.

```nim
func isMessage(opResult: OpResult): bool
```

# isValue

Return true when the OpResult object contains a value.

```nim
func isValue(opResult: OpResult): bool
```

# newRunFileLine

Create a new RunFileLine object.

```nim
func newRunFileLine(filename: string; noLastEnding = false; command = false;
                    nonZeroReturn = false): RunFileLine
```

# newCompareLine

Create a new CompareLine object.

```nim
func newCompareLine(filename1: string; filename2: string): CompareLine
```

# newDirAndFiles

Create a new DirAndFiles object.

```nim
func newDirAndFiles(compareLines: seq[CompareLine];
                    runFileLines: seq[RunFileLine]): DirAndFiles
```

# `$`

Return a string representation of an OpResult object.

```nim
func `$`(opResult: OpResult): string
```

# `$`

Return a string representation of a CompareLine object.

```nim
func `$`(r: CompareLine): string
```

# `$`

Return a string representation of a RunFileLine object.

```nim
func `$`(r: RunFileLine): string
```

# writeErr

Write a message to stderr.

```nim
proc writeErr(message: string)
```

# writeOut

Write a message to stdout.

```nim
proc writeOut(message: string)
```

# createFolder

Create a folder with the given name.

```nim
proc createFolder(folder: string): OpResult[RcAndMessage]
```

# deleteFolder

Delete a folder with the given name.

```nim
proc deleteFolder(folder: string): OpResult[RcAndMessage]
```

# parseRunCommandLine

Parse the command line arguments.

```nim
proc parseRunCommandLine(argv: seq[string]): OpResult[RunArgs]
```

# parseRunFileLine

Parse a file command line.

```nim
proc parseRunFileLine(line: string): OpResult[RunFileLine]
```

# parseExpectedLine

Parse an expected line.

```nim
proc parseExpectedLine(line: string): OpResult[CompareLine]
```

# openNewFile

Create a new file in the given folder and return an open File object.

```nim
proc openNewFile(folder: string; filename: string): OpResult[File]
```

# getCmd

Return the type of line, either: #, "", id, file, expected or endfile.

```nim
proc getCmd(line: string): string
```

# makeDirAndFiles

Read the stf file and create its temp folder and files. Return the file lines and expected lines.

```nim
proc makeDirAndFiles(filename: string): OpResult[DirAndFiles]
```

# runCommand

Run a command file and return its return code.

```nim
proc runCommand(folder: string; filename: string): int
```

# runCommands

Run the commands.

```nim
proc runCommands(folder: string; runFileLines: seq[RunFileLine]): OpResult[
    RcAndMessage]
```

# openLineBuffer

Open a file for reading lines. Return a LineBuffer object.  Close the line buffer stream when done.

```nim
proc openLineBuffer(filename: string): OpResult[LineBuffer]
```

# showTabsAndLineEndings

Return a new string with the tab and line endings visible.

```nim
func showTabsAndLineEndings(str: string): string
```

# dup

Duplicate the pattern count times limited to 1024 characters.

```nim
proc dup(pattern: string; count: Natural): string
```

# linesSideBySide

Show the two sets of lines side by side.

```nim
proc linesSideBySide(expectedContent: string; gotContent: string): string
```

# compareFiles

Compare two files. When they are equal, return rc=0 and message="". When they differ return rc=1 and message where the message shows the differences. On error return an error message.

```nim
proc compareFiles(expectedFilename: string; gotFilename: string): OpResult[
    RcAndMessage]
```

# compareFileSets

Compare file sets and return rc=0 when they are all the same.

```nim
proc compareFileSets(folder: string; compareLines: seq[CompareLine]): OpResult[
    RcAndMessage]
```

# runStfFilename

Run the stf and report the result. Return rc=0 message="" when it passes.

```nim
proc runStfFilename(filename: string): OpResult[RcAndMessage]
```

# runFilename

Run the stf and report the result. Return rc=0 message="" when it passes.

```nim
proc runFilename(filename: string; leaveTempDir: bool): OpResult[RcAndMessage]
```

# runFilename

Run a stf file.

```nim
proc runFilename(args: RunArgs): OpResult[RcAndMessage]
```

# runDirectory

Run all the stf files in the specified directory.

```nim
proc runDirectory(dir: string; leaveTempDir: bool): OpResult[RcAndMessage]
```

# main

Run stf test files. Return a rc and message.

```nim
proc main(argv: seq[string]): OpResult[RcAndMessage]
```


---
⦿ Markdown page generated by [StaticTea](https://github.com/flenniken/statictea/) from nim doc comments. ⦿
