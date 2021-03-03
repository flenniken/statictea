import os
import strutils
include src/version

version       = staticteaVersion
author        = "Steve Flenniken"
description   = "A template processor and language."
license       = "MIT"
srcDir        = "src"
bin           = @["bin/statictea"]

requires "nim >= 1.4.4"

# The nimscript module is imported by default. It contains functions
# you can call in your nimble file.
# https://nim-lang.org/0.11.3/nimscript.html

proc get_test_filenames(): seq[string] =
  ## Return the list of the nim files in the tests folder.
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
  # --gc:orc
  # --hint

  # I turned on gs:orc because "n t" started erroring out. Too many unit tests maybe.
  # [GC] cannot register global variable; too many global variables

  let binName = changeFileExt(filename, "bin")
  var rel: string
  if release:
    rel = "-d:release "
  else:
    rel = ""
  result = "nim c -f --gc:orc --verbosity:0 --hint[Performance]:off --hint[XCannotRaiseY]:off -d:test $1 -r -p:src --out:bin/tmp/$2 tests/$3" % [
    rel, binName, filename]

proc build_release() =
  var cmd = "nim c --gc:orc --hint[Performance]:off --hint[Conf]:off --hint[Link]: off -d:release --out:bin/ src/statictea"
  echo cmd
  exec cmd
  cmd = "strip bin/statictea"
  exec cmd

# Tasks below

task b, "\tBuild the statictea exe.":
  build_release()

task tree, "\tShow the project directory tree.":
  exec "tree -I '*.nims|*.bin' | less"

# task testallslow, "\tRun tests":
#   let test_filenames = get_test_filenames()
#   for filename in test_filenames:
#     if filename == "testall.nim":
#       continue
#     let cmd = get_test_module_cmd(filename)
#     exec cmd

task test, "\tRun one test: test name":
  let count = system.paramCount()+1
  let name = system.paramStr(count-1)
  if name == "showtest":
     echo "Specify part of the test name."
     return
  let test_filenames = get_test_filenames()
  for filename in test_filenames:
    if name in filename:
      let cmd = get_test_module_cmd(filename)
      echo cmd
      exec cmd

proc doc_module(name: string) =
  let cmd = "nim doc --hints:off -d:test --index:on --out:docs/html/$1.html src/$1.nim" % [name]
  echo cmd
  exec cmd

proc open_in_browser(filename: string) =
  ## Open the given file in a browser if the system has an open command.
  exec "(hash open 2>/dev/null && open $1) || echo 'open $1'" % filename

task docs, "\tCreate md doc for a source file.":
  var filename = "readjson.nim"
  var jsonName = "readjson.json"
  var cmd = "nim jsondoc --out:docs/json/$1 src/$2" % [jsonName, filename]
  echo cmd
  exec cmd
  exec "bin/statictea -s=docs/json/$1 -t=docs/template.md -r=docs/readjson.md" % [jsonName]
  exec "less docs/readjson.md"

task json, "\tDisplay json for a source file.":
  var filename = "readjson.nim"
  var jsonName = "readjson.json"
  var cmd = "nim jsondoc --out:docs/json/$1 src/$2" % [jsonName, filename]
  echo cmd
  exec cmd
  exec "cat docs/json/$1 | jq | less" % [jsonName]

task tt, "\tCompile and run t.nim":
  let cmd = "nim c -r --gc:orc --hints:off --outdir:bin/tests/ src/t.nim"
  echo cmd
  exec cmd

task args, "\tshow command line arguments":
  let count = system.paramCount()+1
  echo "argument count: $1" % $count
  for i in 0..count-1:
    echo "$1: $2" % [$i, system.paramStr(i)]

task t, "\tRun all tests at once.":
  # Create a file that includes all the test files.
  exec """
ls -1 tests | grep -v testall | sed 's/\.nim//' |
awk '{printf "include %s\n", $0}' > tests/testall.nim
"""
  let cmd = get_test_module_cmd("testall.nim")
  exec cmd
  exec "rm tests/testall.nim"
  # Make sure it builds with test undefined.
  build_release()
  # Run the command line tests.
  exec "src/test"
