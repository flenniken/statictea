# runner.nim

A standalone command to run Single Test File (stf) files.

You use runner for testing command line applications. A stf file
contains the test which the runner executes to determine whether the
test passed.

A stf file contains instructions for creating files, running files and
comparing files and it is designed to look good in a markdown reader.

See the runner help message (get_help) for more information about stf
files, or run the nimble task "runhelp" to show the help text with
glow.


* [runner.nim](../../src/runner.nim) &mdash; Nim source code.
# Index

* const: [runnerId](#runnerid) &mdash; The first line of the stf file.
* type: [RunArgs](#runargs) &mdash; RunArgs holds the command line arguments.
* type: [Rc](#rc) &mdash; Rc holds a return code where 0 is success.
* type: [RunFileLine](#runfileline) &mdash; RunFileLine holds the file line options.
* type: [ExpectedLine](#expectedline) &mdash; ExpectedLine holds the expected line options.
* type: [BlockLineType](#blocklinetype) &mdash; The kind of block line.
* type: [BlockLine](#blockline) &mdash; BlockLine holds a line that starts with tildas or accents.
* type: [LineKind](#linekind) &mdash; The kind of line in a stf file.
* type: [AnyLine](#anyline) &mdash; Contains the information about one line in a stf file.
* type: [DirAndFiles](#dirandfiles) &mdash; DirAndFiles holds the file and compare lines of the stf file.
* [newBlockLine](#newblockline) &mdash; Create a new BlockLine type.
* [newAnyLineRunFileLine](#newanylinerunfileline) &mdash; Create a new AnyLine object for a file line.
* [newAnyLineExpectedLine](#newanylineexpectedline) &mdash; Create a new AnyLine object for a expected line.
* [newAnyLineBlockLine](#newanylineblockline) &mdash; Create a new AnyLine object for a block line.
* [newAnyLineCommentLine](#newanylinecommentline) &mdash; Create a new AnyLine object for a comment line.
* [newAnyLineIdLine](#newanylineidline) &mdash; Create a new AnyLine object for a id line.
* [newRunArgs](#newrunargs) &mdash; Create a new RunArgs object.
* [newRunFileLine](#newrunfileline) &mdash; Create a new RunFileLine object.
* [newExpectedLine](#newexpectedline) &mdash; Create a new ExpectedLine object.
* [newDirAndFiles](#newdirandfiles) &mdash; Create a new DirAndFiles object.
* [`$`](#) &mdash; Return a string representation of a ExpectedLine object.
* [`$`](#-1) &mdash; Return a string representation of a RunFileLine object.
* [writeErr](#writeerr) &mdash; Write a message to stderr.
* [createFolder](#createfolder) &mdash; Create a folder with the given name.
* [deleteFolder](#deletefolder) &mdash; Delete a folder with the given name.
* const: [runnerHelp](#runnerhelp) &mdash; Help for stf runner 
* [parseRunCommandLine](#parseruncommandline) &mdash; Parse the command line arguments.
* [isRunFileLine](#isrunfileline) &mdash; Return true when the line is a file line.
* [isExpectedLine](#isexpectedline) &mdash; Return true when the line is an expected line.
* [parseRunFileLine](#parserunfileline) &mdash; Parse a file command line.
* [parseExpectedLine](#parseexpectedline) &mdash; Parse an expected line.
* [openNewFile](#opennewfile) &mdash; Create a new file in the given folder and return an open File object.
* [getAnyLine](#getanyline) &mdash; Return information about the stf line.
* [makeDirAndFiles](#makedirandfiles) &mdash; Read the stf file and create its temp folder and files.
* [runCommands](#runcommands) &mdash; Run the command files and return 0 when they all returned their expected return code.
* [runStfFilename](#runstffilename) &mdash; Run the stf file and leave the temp dir.

# runnerId

The first line of the stf file.


~~~nim
runnerId = "stf file, version 0.1.0"
~~~

# RunArgs

RunArgs holds the command line arguments.


~~~nim
RunArgs = object
  help*: bool
  version*: bool
  leaveTempDir*: bool
  filename*: string
  directory*: string
~~~

# Rc

Rc holds a return code where 0 is success.


~~~nim
Rc = int
~~~

# RunFileLine

RunFileLine holds the file line options.


~~~nim
RunFileLine = object
  filename*: string
  noLastEnding*: bool
  command*: bool
  nonZeroReturn*: bool
~~~

# ExpectedLine

ExpectedLine holds the expected line options.


~~~nim
ExpectedLine = object
  gotFilename*: string
  expectedFilename*: string
~~~

# BlockLineType

The kind of block line.


~~~nim
BlockLineType = enum
  blTildes, blAccents
~~~

# BlockLine

BlockLine holds a line that starts with tildas or accents.


~~~nim
BlockLine = object
  blockLineType*: BlockLineType
  line*: string
~~~

# LineKind

The kind of line in a stf file.


~~~nim
LineKind = enum
  lkRunFileLine, lkExpectedLine, lkBlockLine, lkIdLine, lkCommentLine
~~~

# AnyLine

Contains the information about one line in a stf file.


~~~nim
AnyLine = object
  case kind*: LineKind
  of lkRunFileLine:
      runFileLine*: RunFileLine

  of lkExpectedLine:
      expectedLine*: ExpectedLine

  of lkBlockLine:
      blockLine*: BlockLine

  of lkIdLine:
      idLine*: string

  of lkCommentLine:
      commentLine*: string
~~~

# DirAndFiles

DirAndFiles holds the file and compare lines of the stf file.


~~~nim
DirAndFiles = object
  expectedLines*: seq[ExpectedLine]
  runFileLines*: seq[RunFileLine]
~~~

# newBlockLine

Create a new BlockLine type.


~~~nim
func newBlockLine(blockLineType: BlockLineType; line: string): BlockLine
~~~

# newAnyLineRunFileLine

Create a new AnyLine object for a file line.


~~~nim
func newAnyLineRunFileLine(runFileLine: RunFileLine): AnyLine
~~~

# newAnyLineExpectedLine

Create a new AnyLine object for a expected line.


~~~nim
func newAnyLineExpectedLine(expectedLine: ExpectedLine): AnyLine
~~~

# newAnyLineBlockLine

Create a new AnyLine object for a block line.


~~~nim
func newAnyLineBlockLine(blockLine: BlockLine): AnyLine
~~~

# newAnyLineCommentLine

Create a new AnyLine object for a comment line.


~~~nim
func newAnyLineCommentLine(commentLine: string): AnyLine
~~~

# newAnyLineIdLine

Create a new AnyLine object for a id line.


~~~nim
func newAnyLineIdLine(idLine: string): AnyLine
~~~

# newRunArgs

Create a new RunArgs object.


~~~nim
func newRunArgs(help = false; version = false; leaveTempDir = false;
                filename = ""; directory = ""): RunArgs
~~~

# newRunFileLine

Create a new RunFileLine object.


~~~nim
func newRunFileLine(filename: string; noLastEnding = false; command = false;
                    nonZeroReturn = false): RunFileLine
~~~

# newExpectedLine

Create a new ExpectedLine object.


~~~nim
func newExpectedLine(gotFilename: string; expectedFilename: string): ExpectedLine
~~~

# newDirAndFiles

Create a new DirAndFiles object.


~~~nim
func newDirAndFiles(expectedLines: seq[ExpectedLine];
                    runFileLines: seq[RunFileLine]): DirAndFiles
~~~

# `$`

Return a string representation of a ExpectedLine object.


~~~nim
func `$`(r: ExpectedLine): string {.raises: [ValueError], tags: [].}
~~~

# `$`

Return a string representation of a RunFileLine object.


~~~nim
func `$`(r: RunFileLine): string {.raises: [ValueError], tags: [].}
~~~

# writeErr

Write a message to stderr.


~~~nim
proc writeErr(message: string) {.raises: [IOError], tags: [WriteIOEffect].}
~~~

# createFolder

Create a folder with the given name. When the folder cannot be
created return a message telling why, else return "".


~~~nim
proc createFolder(folder: string): string {.raises: [],
    tags: [WriteDirEffect, ReadDirEffect].}
~~~

# deleteFolder

Delete a folder with the given name. When the folder cannot be
deleted return a message telling why, else return "".


~~~nim
proc deleteFolder(folder: string): string {.raises: [],
    tags: [WriteDirEffect, ReadDirEffect].}
~~~

# runnerHelp

Help for stf runner


~~~nim
runnerHelp = """# Stf Runner
## Help for stf runner

Run a single test file (stf) or run all stf files in a folder.

The runner reads a stf file, creates multiple small files in a test
folder, runs files then verifies the files contain the correct data.

A stf file is designed to look good in a markdown reader. You can use
the .stf or .stf.md extention.

## Usage

runner [-h] [-v] [-l] [-f=filename] [-d=directory]

* -h --help          Show this help message.
* -v --version       Show the version number.
* -l --leaveTempDir  Leave the temp folder.
* -f --filename      Run the stf file.
* -d --directory     Run the stf files (.stf or .stf.md) in the directory.

## Processing Steps

The stf file runner processes the file tasks in the following order:

* create temp folder
* create files in the temp folder
* runs command type files
* compares files
* removes the temp folder

The temp folder is created in the same folder as the stf file using
the stf name with ".tempdir" append.

Normally the temp folder is removed after running. The -l option
leaves the folder for debugging purposes. If the temp folder exists
when running, it is deleted, then recreated, then deleted when done.

Runner returns 0 when all the tests pass. When running multiple stf
files, it displays each test run and tells how many passed and failed.

## Stf File Format

The Single Test File format is a text file made up of single line
commands.

Command line types:

1. id line
2. file lines
3. file blocks
4. expected lines
5. comment lines

### Id Line

The first line of the stf file identifies it as a stf file and tells
the version. For example:

```
stf file, version 0.1.0
```

### File Line

The file line is used to create a file. It starts with "### File "
followed by the filename then some optional attributes. A line that
starts with "### File" must be a file type line.

The general form of a file line is:

```
### File filename [noLineEnding] [command] [nonZeroReturn]
```

Example file lines:

```
### File server.json
### File cmd.sh command
### File result.expected noLineEnding
### File cmd.sh command nonZeroReturn
### File cmd.sh command nonZeroReturn noLineEnding
```

File Attributes:

* **filename** - the name of the file to create.

The name is required and cannot contain spaces. The file is created in
the temp folder.

* **command** — marks this file to be run.

All files are created before any command runs. The file is run in the
temp folder as the working directory. The commands are run in the
order specified in the file.

* **nonZeroReturn** — the command returns non-zero on success

Normally the runner fails when a command returns a non-zero return
code.  With nonZeroReturn set, it fails when it returns zero.

* **noLineEnding** — create the file without an ending newline.

### File Block Lines

The content of a file is bracketed by markdown code blocks, either
"~~~" or "```".  The block follows a file line. The first block found
is used, so you can have blocks as comments too.  All content up to
the ending code marker go in the file, even lines that look like
commands. You follow the ~~~ with a code name, e.g. javascript, for
syntax highlighting.

### Expected Line

The expected line compares files. You specify two files that should be
equal.  The compares are run after running the commands. You can use
the word "empty" for in place of a filename when you expect the file
to be empty. A line that starts with "### Expected " must be an
expected line.

```
### Expected gotFilename == expectedFilename
```

Examples:

```
### Expected result == result.expected
### Expected t.txt == t.txt.expected
### Expected t.txt == empty
```

### Comments

Comments are all the other lines of the file. So it is hard to make a
syntax error.  The only possible syntax errors are with the id line,
file lines and expected lines.

"""
~~~

# parseRunCommandLine

Parse the command line arguments.


~~~nim
proc parseRunCommandLine(argv: seq[string]): OpResultStr[RunArgs] {.
    raises: [ValueError], tags: [ReadIOEffect].}
~~~

# isRunFileLine

Return true when the line is a file line.


~~~nim
proc isRunFileLine(line: string): bool {.raises: [KeyError], tags: [].}
~~~

# isExpectedLine

Return true when the line is an expected line.


~~~nim
proc isExpectedLine(line: string): bool {.raises: [KeyError], tags: [].}
~~~

# parseRunFileLine

Parse a file command line.


~~~nim
proc parseRunFileLine(line: string): OpResultStr[RunFileLine] {.
    raises: [KeyError, ValueError], tags: [].}
~~~

# parseExpectedLine

Parse an expected line.


~~~nim
proc parseExpectedLine(line: string): OpResultStr[ExpectedLine] {.
    raises: [KeyError, ValueError], tags: [].}
~~~

# openNewFile

Create a new file in the given folder and return an open File
object.


~~~nim
proc openNewFile(folder: string; filename: string): OpResultStr[File] {.
    raises: [ValueError], tags: [ReadDirEffect].}
~~~

# getAnyLine

Return information about the stf line.


~~~nim
proc getAnyLine(line: string): OpResultStr[AnyLine] {.
    raises: [KeyError, ValueError], tags: [].}
~~~

# makeDirAndFiles

Read the stf file and create its temp folder and files. Return the
file lines and expected lines.


~~~nim
proc makeDirAndFiles(filename: string): OpResultStr[DirAndFiles] {.
    raises: [ValueError, Exception, IOError, OSError, KeyError],
    tags: [ReadDirEffect, WriteIOEffect, WriteDirEffect, ReadIOEffect].}
~~~

# runCommands

Run the command files and return 0 when they all returned their
expected return code.


~~~nim
proc runCommands(folder: string; runFileLines: seq[RunFileLine]): int {.
    raises: [OSError, ValueError], tags: [ReadDirEffect, WriteDirEffect,
    ExecIOEffect, ReadIOEffect, RootEffect].}
~~~

# runStfFilename

Run the stf file and leave the temp dir. Return 0 when all the
tests passed.


~~~nim
proc runStfFilename(filename: string): int {.
    raises: [ValueError, Exception, IOError, OSError, KeyError], tags: [
    ReadDirEffect, WriteIOEffect, WriteDirEffect, ReadIOEffect, ExecIOEffect,
    RootEffect].}
~~~


---
⦿ Markdown page generated by [StaticTea](https://github.com/flenniken/statictea/) from nim doc comments. ⦿
