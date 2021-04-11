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

const
  useDocUtils = true
  showHtml = true

# The nimscript module is imported by default. It contains functions
# you can call in your nimble file.
# https://nim-lang.org/0.11.3/nimscript.html

proc get_test_filenames(): seq[string] =
  ## Return the list of the nim files in the tests folder.
  result = @[]
  var list = listFiles("tests")
  for filename in list:
    result.add(lastPathPart(filename))

proc get_source_filenames(): seq[string] =
  ## Return the list of the nim source files in the src folder.
  result = @[]
  var list = listFiles("src")
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

proc doc_module(name: string) =
  let cmd = "nim doc --hints:off -d:test --index:on --out:docs/html/$1.html src/$1.nim" % [name]
  echo cmd
  exec cmd

proc open_in_browser(filename: string) =
  ## Open the given file in a browser if the system has an open
  ## command and the file exists.
  if fileExists(filename):
    exec "(hash open 2>/dev/null && open $1) || echo 'open $1'" % filename

proc getDirName(host: string): string =
  ## Return the host dir name given the nim hostOS name.
  ## Current possible host values: "windows", "macosx", "linux", "netbsd",
  ## "freebsd", "openbsd", "solaris", "aix", "haiku", "standalone".

  if host == "macosx":
    result = "mac"
  elif host == "linux":
    result = "linux"
  elif host == "windows":
    result = "win"
  else:
    assert false, "add a new platform"

proc isPyEnvActive(): bool =
  if system.getEnv("VIRTUAL_ENV", "") == "":
    result = false
  else:
    result = true

# Tasks below

task n, "\tShow available tasks.":
  exec "nimble tasks"

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

task test, "\tRun tests; specify part of test name":
  ## Run one or more tests.  You specify part of the test name and all
  ## tests that match are run. If you don't specify a name, all are
  ## run. Task "t" is faster to run them all.
  let count = system.paramCount()+1
  # The name is either part of a name or "test" when not
  # specified. Test happens to match all test files.
  let name = system.paramStr(count-1)
  let test_filenames = get_test_filenames()
  for filename in test_filenames:
    if name in filename:
      let cmd = get_test_module_cmd(filename)
      echo cmd
      exec cmd

task b, "\tBuild the statictea exe.":
  build_release()

task docs, "\tCreate markdown docs; specify part of source file name.":
  if showHtml and not isPyEnvActive():
    echo "Run the pythonenv task to setup the python environment."
    # The python environment is used to make html files so you can
    # proof the documentation before committing.
    return
  let count = system.paramCount()+1
  # Name is part of a source file name, or "docs" when not specified.
  let name = system.paramStr(count-1)
  let filenames = get_source_filenames()
  for filename in filenames:
    if name in filename or (name == "docs" and filename.endsWith(".nim")):
      var jsonName = changeFileExt(filename, "json")
      var cmd = "nim jsondoc --out:docs/json/$1 src/$2" % [jsonName, filename]
      echo cmd
      echo ""
      exec cmd
      echo ""
      var mdName = changeFileExt(filename, "md")

      # Create a shared.json file for use by the template.
      let sharedJson = """{
"newline": "\n"
}
"""
      writeFile("docs/shared.json", sharedJson)

      cmd = "bin/statictea -s=docs/json/$1 -j=docs/shared.json -t=docs/template.md -r=docs/$2" % [
        jsonName, mdName]
      echo cmd
      exec cmd
      if false: # showHtml:
        var htmlName = changeFileExt(filename, "html")
        var dirName = getDirName(hostOS)
        exec "rm -f docs/html/$1" % htmlName
        exec "env/$1/staticteaenv/bin/rst2html5.py docs/$2 docs/html/$3 | less" % [
          dirName, mdName, htmlName]
        echo cmd
        exec cmd
        open_in_browser(r"docs/html/$1" % htmlName)

task docsre, "\tCreate reStructuredtext docs; specify part of source file name.":
  if showHtml and not isPyEnvActive():
    echo "Run the pythonenv task to setup the python environment."
    # The python environment is used to make html files so you can
    # proof the documentation before committing.
    return
  let count = system.paramCount()+1
  # Name is part of a source file name, or "docs" when not specified.
  let name = system.paramStr(count-1)
  let filenames = get_source_filenames()
  for filename in filenames:
    if name in filename or (name == "docs" and filename.endsWith(".nim")):
      var jsonName = changeFileExt(filename, "json")
      var cmd = "nim jsondoc --out:docs/json/$1 src/$2" % [jsonName, filename]
      echo cmd
      echo ""
      exec cmd
      echo ""
      var rstName = changeFileExt(filename, "rst")

      # Add useDocUtils to the shared.json file for use by the template.
      let sharedJson = """{
"useDocUtils": $1,
"newline": "\n"
}
""" % [$useDocUtils]
      writeFile("docs/shared.json", sharedJson)

      cmd = "bin/statictea -s=docs/json/$1 -j=docs/shared.json -t=docs/template.rst -r=docs/$2" % [
        jsonName, rstName]
      echo cmd
      exec cmd
      if showHtml:
        var htmlName = changeFileExt(filename, "html")
        if useDocUtils:
          var dirName = getDirName(hostOS)
          exec "rm -f docs/html/$1" % htmlName
          exec "env/$1/staticteaenv/bin/rst2html5.py docs/$2 docs/html/$3 | less" % [
            dirName, rstName, htmlName]
        else:
          cmd = "nim rst2html --hints:off --out:docs/html/$1 docs/$2" % [htmlName, rstName]
        echo cmd
        exec cmd
        open_in_browser(r"docs/html/$1" % htmlName)

task json, "\tDisplay doc json for a source file.":
  let count = system.paramCount()+1
  let name = system.paramStr(count-1)
  let filenames = get_source_filenames()
  for filename in filenames:
    if name in filename:
      var jsonName = changeFileExt(filename, "json")
      var cmd = "nim jsondoc --out:docs/json/$1 src/$2" % [jsonName, filename]
      echo cmd
      exec cmd
      exec "cat docs/json/$1 | jq | less" % [jsonName]

task tt, "\tCompile and run t.nim":
  let cmd = "nim c -r --gc:orc --hints:off --outdir:bin/tests/ src/t.nim"
  echo cmd
  exec cmd

task tree, "\tShow the project directory tree.":
  exec "tree -I '*.nims|*.bin' | less"

# task args, "\tshow command line arguments":
#   let count = system.paramCount()+1
#   echo "argument count: $1" % $count
#   for i in 0..count-1:
#     echo "$1: $2" % [$i, system.paramStr(i)]


task pythonenv, "Create and activate a python virtual env.":
  # The python environment is used to make html files from the doc
  # commands for proofing it before committing.

  var dirName = getDirName(hostOS)
  let virtualEnv = "env/$1/staticteaenv" % dirName
  if system.dirExists(virtualEnv):
    # Activate the existing virtual environment, if not already
    # active.
    if system.getEnv("VIRTUAL_ENV", "") == "":
      var cmd = "source $1/bin/activate" % [virtualEnv]
      echo "manually run:"
      echo cmd
  else:
    # Create the virtual environment, activate and install necessary
    # packages.
    echo "Creating virtual environment: $1" % [virtualEnv]
    var cmd = "python3 -m venv $1" % [virtualEnv]
    echo cmd
    exec cmd
    cmd = """
source $1/bin/activate; \
pip3 install wheel; \
pip3 install docutils
""" % [virtualEnv]
    echo cmd
    exec cmd

task rst2html5, "Show docutil's rst2html5 help file.":
  if not isPyEnvActive():
    echo "Run pythonenv task first to setup the environment."
  else:
    var dirName = getDirName(hostOS)
    exec "env/$1/staticteaenv/bin/rst2html5.py -h | less" % [dirName]
