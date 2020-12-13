# Package
import os
import strutils

# Include the version number.
include src/version

version       = staticteaVersion
version       = "0.1.0"
author        = "Steve Flenniken"
description   = "A template processor and language."
license       = "MIT"
srcDir        = "src"
bin           = @["statictea"]


# Dependencies

requires "nim >= 1.2.6"

# Code

# The nimscript module is imported by default. It contains functions
# you can call in your nimble file.
# https://nim-lang.org/0.11.3/nimscript.html


proc get_test_filenames(): seq[string] =
  ## Return each nim file in the tests folder.
  result = @[]
  var list = listFiles("tests")
  for filename in list:
    result.add(lastPathPart(filename))


proc get_test_module_cmd(filename: string, release = false): string =
  ## Return the command line to test one module.

  # You can add -f to force a recompile of imported modules, good for
  # testing "imported but not used" warnings.

  # -d, --define:SYMBOL(:VAL)
  #                           define a conditional symbol
  # -f, --forceBuild:on|off   force rebuilding of all modules
  # -p, --path:PATH           add path to search paths
  # -r, --run                 run the compiled program with given arguments

  var rel: string
  if release:
    rel = "-d:release "
  else:
    rel = ""
  result = "nim c -f --verbosity:0 -d:test $2--hints:off -r -p:src --out:bin/tests/$1 tests/$1" % [filename, rel]


# Tasks below

task b, "\tBuild the statictea exe.":
  exec "nimble build"

task r, "\tRun statictea.":
  exec "./statictea"

task tree, "\tShow the project directory tree.":
  exec "tree -I '*.nims' | less"

task testallslow, "\tRun tests":
  let test_filenames = get_test_filenames()
  for filename in test_filenames:
    if filename == "testall.nim":
      continue
    let cmd = get_test_module_cmd(filename)
    exec cmd

task showtests, "Show tests":
  let test_filenames = get_test_filenames()
  for filename in test_filenames:
    echo ""
    echo "$1:" % filename
    let cmd = get_test_module_cmd(filename)
    echo cmd

task showtest, "Show one test: showtest name":
  let count = system.paramCount()+1
  let name = system.paramStr(count-1)
  if name == "showtest":
     echo "Specify part of the test name."
     return
  let test_filenames = get_test_filenames()
  for filename in test_filenames:
    if name in filename:
      echo get_test_module_cmd(filename)

proc doc_module(name: string) =
  let cmd = "nim doc --hints:off -d:test --index:on --out:docs/html/$1.html src/$1.nim" % [name]
  echo cmd
  exec cmd

proc open_in_browser(filename: string) =
  ## Open the given file in a browser if the system has an open command.
  exec "(hash open 2>/dev/null && open $1) || echo 'open $1'" % filename

task docs1, "\tBuild docs for one module.":
  doc_module("loggers")
  open_in_browser("docs/html/loggers.html")

task tt, "\tCompile and run t.nim":
  let cmd = "nim c -r --hints:off --outdir:bin/tests/ src/t.nim"
  echo cmd
  exec cmd

task args, "\tshow command line arguments":
  let count = system.paramCount()+1
  echo "argument count: $1" % $count
  for i in 0..count-1:
    echo "$1: $2" % [$i, system.paramStr(i)]

task hello, "\tSay hello":
  echo "hello there"

task boo, "\tSay boo":
  echo "boo"

task newfile, "\tCreate a new source file and an associated test file: newfile name":
  let count = system.paramCount()+1
  let name = system.paramStr(count-1)
  if name == "newfile":
     echo "Specify the name of the new file without an extension."
     return
  let sourceFilename = "src/$1.nim" % name
  let testFilename = "tests/test_$1.nim" % name

  let sourceFilenameContent = """
## Parse the command line and return the arguments.

import strutils
"""

  let testFilenameContent = """
import unittest
import $1

suite "$1.nim":

  test "$1":
    echo "testing"
""" % name

  let cmd1 = "cp src/version.nim $1" % sourceFilename
  echo cmd1
  exec cmd1

  let cmd2 = "cp tests/test_version.nim $1" % testFilename
  echo cmd2
  exec cmd2

  echo "Created $1" % sourceFilename
  echo "Created $1" % testFilename

  # How do you create a file in a nimble task?
  # var file = open(sourceFilename, fmWrite)
  # file.write(sourceFilenameContent)
  # file.close()

  # var file2 = open(testFilename, fmWrite)
  # file2.write(testFilenameContent)
  # file2.close()

task t, "\tRun all tests":
  exec """
ls -1 tests | grep -v testall | sed 's/\.nim//' |
awk '{printf "include %s\n", $0}' > tests/testall.nim
"""
  let cmd = get_test_module_cmd("testall.nim")
  exec cmd
  exec "rm tests/testall.nim"
