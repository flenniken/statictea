# Package
import os

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

task b, "Build the statictea exe.":
  exec "nimble build"

task r, "Run statictea.":
  exec "./statictea"

task tree, "Show the project directory tree.":
  exec "tree -I '*.nims' | less"

task t, "Run tests":
  let test_filenames = get_test_filenames()
  for filename in test_filenames:
    let cmd = get_test_module_cmd(filename)
    exec cmd

task showTests, "Show tests":
  let test_filenames = get_test_filenames()
  for filename in test_filenames:
    echo ""
    echo "$1:" % filename
    let cmd = get_test_module_cmd(filename)
    echo cmd

proc doc_module(name: string) =
  let cmd = "nim doc --hints:off -d:test --index:on --out:docs/html/$1.html src/$1.nim" % [name]
  echo cmd
  exec cmd

proc open_in_browser(filename: string) =
  ## Open the given file in a browser if the system has an open command.
  exec "(hash open 2>/dev/null && open $1) || echo 'open $1'" % filename

task docs1, "Build docs for one module.":
  doc_module("loggers")
  open_in_browser("docs/html/loggers.html")

task tt, "Compile and run t.nim":
  let cmd = "nim c -r --hints:off --outdir:bin/tests/ src/t.nim"
  echo cmd
  exec cmd

task args, "show command line arguments":
  let count = system.paramCount()+1
  echo "argument count: $1" % $count
  for i in 0..count-1:
    echo "$1: $2" % [$i, system.paramStr(i)]

task hello, "Say hello":
  echo "hello there"

task boo, "Say boo":
  echo "boo"
