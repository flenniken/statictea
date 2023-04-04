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


* [runner.nim](../src/runner.nim) &mdash; Nim source code.
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
* [parseRunCommandLine](#parseruncommandline) &mdash; Parse the command line arguments.
* [isRunFileLine](#isrunfileline) &mdash; Return true when the line is a file line.
* [isExpectedLine](#isexpectedline) &mdash; Return true when the line is an expected line.
* [parseRunFileLine](#parserunfileline) &mdash; Parse a file command line.
* [parseExpectedLine](#parseexpectedline) &mdash; Parse an expected line.
* [openNewFile](#opennewfile) &mdash; Create a new file in the given folder and return an open File
object.
* [getAnyLine](#getanyline) &mdash; Return information about the stf line.
* [makeDirAndFiles](#makedirandfiles) &mdash; Read the stf file and create its temp folder and files.
* [runCommands](#runcommands) &mdash; Run the command files and return 0 when they all returned their
expected return code.
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
