# runner.nim

Standalone command to run Single Test File (stf) files.

* [runner.nim](../src/runner.nim) &mdash; Nim source code.
# Index

* type: [RunArgs](#runargs) &mdash; RunArgs holds the command line arguments.
* type: [Rc](#rc) &mdash; Rc holds a return code where 0 is success.
* type: [RunFileLine](#runfileline) &mdash; RunFileLine holds the file line options.
* type: [CompareLine](#compareline) &mdash; CompareLine holds the expected line options.
* type: [DirAndFiles](#dirandfiles) &mdash; DirAndFiles holds the file and compare lines of the stf file.
* type: [OpResultKind](#opresultkind) &mdash; The kind of OpResult object, either a value or message.
* type: [OpResult](#opresult) &mdash; Contains either a value or a message string.
* [isMessage](#ismessage) &mdash; Return true when the OpResult object contains a message.
* [isValue](#isvalue) &mdash; Return true when the OpResult object contains a value.
* [newRunArgs](#newrunargs) &mdash; Create a new RunArgs object.
* [newRunFileLine](#newrunfileline) &mdash; Create a new RunFileLine object.
* [newCompareLine](#newcompareline) &mdash; Create a new CompareLine object.
* [newDirAndFiles](#newdirandfiles) &mdash; Create a new DirAndFiles object.
* [`$`](#) &mdash; Return a string representation of an OpResult object.
* [`$`](#-1) &mdash; Return a string representation of a CompareLine object.
* [`$`](#-2) &mdash; Return a string representation of a RunFileLine object.
* [writeErr](#writeerr) &mdash; Write a message to stderr.
* [createFolder](#createfolder) &mdash; Create a folder with the given name.
* [deleteFolder](#deletefolder) &mdash; Delete a folder with the given name.
* [parseRunCommandLine](#parseruncommandline) &mdash; Parse the command line arguments.
* [makeBool](#makebool) &mdash; Return false when the string is empty, else return true.
* [parseRunFileLine](#parserunfileline) &mdash; Parse a file command line.
* [parseExpectedLine](#parseexpectedline) &mdash; Parse an expected line.
* [openNewFile](#opennewfile) &mdash; Create a new file in the given folder and return an open File object.
* [getCmd](#getcmd) &mdash; Return the type of line, either: #, "", id, file, expected, endfile or other.
* [makeDirAndFiles](#makedirandfiles) &mdash; Read the stf file and create its temp folder and files.
* [runCommands](#runcommands) &mdash; Run the command files and return 0 when they all returned their expected return code.
* [showTabsAndLineEndings](#showtabsandlineendings) &mdash; Return a new string with the tab and line endings visible.
* [linesSideBySide](#linessidebyside) &mdash; Show the two sets of lines side by side.
* [compareFiles](#comparefiles) &mdash; Compare two files and return the differences.
* [runStfFilename](#runstffilename) &mdash; Run the stf file and leave the temp dir.

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

# Rc

Rc holds a return code where 0 is success.

```nim
Rc = int
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

DirAndFiles holds the file and compare lines of the stf file.

```nim
DirAndFiles = object
  compareLines*: seq[CompareLine]
  runFileLines*: seq[RunFileLine]

```

# OpResultKind

The kind of OpResult object, either a value or message.

```nim
OpResultKind = enum
  okValue, okMessage
```

# OpResult

Contains either a value or a message string. The default is a value. It's similar to the Option type but instead of returning nothing, you return a message that tells why you cannot return the value.

```nim
OpResult[T] = object
  case kind*: OpResultKind
  of okValue:
      value*: T

  of okMessage:
      message*: string


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

# newRunArgs

Create a new RunArgs object.

```nim
func newRunArgs(help = false; version = false; leaveTempDir = false;
                filename = ""; directory = ""): RunArgs
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

# createFolder

Create a folder with the given name. When the folder cannot be created return a message telling why, else return "".

```nim
proc createFolder(folder: string): string
```

# deleteFolder

Delete a folder with the given name. When the folder cannot be deleted return a message telling why, else return "".

```nim
proc deleteFolder(folder: string): string
```

# parseRunCommandLine

Parse the command line arguments.

```nim
proc parseRunCommandLine(argv: seq[string]): OpResult[RunArgs]
```

# makeBool

Return false when the string is empty, else return true.

```nim
func makeBool(item: string): bool
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

Return the type of line, either: #, "", id, file, expected, endfile or other.

```nim
proc getCmd(line: string): string
```

# makeDirAndFiles

Read the stf file and create its temp folder and files. Return the file lines and expected lines.

```nim
proc makeDirAndFiles(filename: string): OpResult[DirAndFiles]
```

# runCommands

Run the command files and return 0 when they all returned their expected return code.

```nim
proc runCommands(folder: string; runFileLines: seq[RunFileLine]): OpResult[Rc]
```

# showTabsAndLineEndings

Return a new string with the tab and line endings visible.

```nim
func showTabsAndLineEndings(str: string): string
```

# linesSideBySide

Show the two sets of lines side by side.

```nim
proc linesSideBySide(expectedContent: string; gotContent: string): string
```

# compareFiles

Compare two files and return the differences. When they are equal return "".

```nim
proc compareFiles(expectedFilename: string; gotFilename: string): OpResult[
    string]
```

# runStfFilename

Run the stf file and leave the temp dir. Return 0 when all the tests passed.

```nim
proc runStfFilename(filename: string): OpResult[Rc]
```


---
⦿ Markdown page generated by [StaticTea](https://github.com/flenniken/statictea/) from nim doc comments. ⦿
