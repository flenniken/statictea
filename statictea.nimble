import std/os
import std/strutils
import std/json
import std/nre
import std/strformat
import std/sets
include src/version
include src/dot

version       = staticteaVersion
author        = "Steve Flenniken"
description   = "A template processor and language."
license       = "MIT"
srcDir        = "src"
bin           = @["bin/statictea"]

requires "nim >= 1.4.8"

# The nimscript module is imported by default. It contains functions
# you can call in your nimble file.
# https://nim-lang.org/0.11.3/nimscript.html

proc exit() =
  exec "exit 1"

proc get_test_filenames(): seq[string] =
  ## Return the basename of the nim files in the tests folder.
  result = @[]
  var list = listFiles("tests")
  for filename in list:
    result.add(lastPathPart(filename))

proc get_dir_filenames(folder: string, extension: string, path: bool = false,
    noExt: bool = false, excludeFilenames: seq[string] = @[]): seq[string] =
  ## Return the basename of the source files in the given folder that
  ## end with the given extension.  You have the option to include the
  ## path or file extension and whether to exclude some files.
  result = @[]
  var list = listFiles(folder)
  for filename in list:
    if filename.endsWith(extension) and not (lastPathPart(filename) in excludeFilenames):
      var name = filename
      if noExt:
        name = name[0 .. ^5]
      if not path:
        name = lastPathPart(name)
      result.add(name)

proc get_source_filenames(path: bool = false, noExt: bool = false): seq[string] =
  ## Return the basename of the nim source files in the src
  ## folder excluding a few.
  let excludeFilenames = @["t.nim", "dot.nim", "runner.nim"]
  result = get_dir_filenames("src", ".nim", path = path, noExt = noExt,
    excludeFilenames = excludeFilenames)

proc get_testfile_filenames(): seq[string] =
  ## Return the basename of the stf source files in the testfiles
  ## folder.
  result = get_dir_filenames("testfiles", ".stf", path = true)

proc get_test_module_cmd(filename: string, release = false): string =
  ## Return the command line to test the given nim file.

  #[

  c

    Compile the code.

  -f, --forceBuild:on|off

    Force rebuilding of all imported modules.  This is good for
    testing "imported but not used" warnings because they only appear
    the first time.

  --gc:orc

    I turned on gs:orc because "n t" started erroring out. Too many unit
    tests maybe. The error message was :"[GC] cannot register global
    variable; too many global variables"

  --verbosity:0|1|2|3

    set Nim's verbosity level (1 is default)  --verbosity:0

  --hint[Performance]:off

    Turn off Performance hint messages.

  --hint[XCannotRaiseY]:off

    Turn off XCannotRaiseY hint messages.

  -d:release

    Compile for release.  It is off when running tests.

  -d:test

    Define the "test" symbol.  All test code is wrapped in sections
    marked with "when defined(test):"

  -r, --run

    Run the compiled program with given arguments
    The -r compiles for release.  It is off when running tests.

  -p:src

    The commands are run from the statictea folder.  The nim non-test source code
    is in the src folder which is specified by -p:src so the imports can be found.

  --out:bin/test_testfile.bin

    The compiled test files go in the bin folder and their extension there is "bin".

  tests/test_testfile.nim

    The nim test files are in the tests folder.

  ]#

  let binName = changeFileExt(filename, "bin")
  var rel: string
  if release:
    rel = "-d:release "
  else:
    rel = ""

  let part1 = "nim c --gc:orc --verbosity:0 --hint[Performance]:off "
  let part2 = "--hint[XCannotRaiseY]:off -d:test "
  let part3 = "$1 -r -p:src --out:bin/$2 tests/$3" % [rel, binName, filename]

  result = part1 & part2 & part3

proc buildRelease() =
  ## Build the release version of statictea.
  let part1 = "nim c --gc:orc --hint[Performance]:off "
  let part2 = "--hint[Conf]:off --hint[Link]: off -d:release "
  let part3 = "--out:bin/ src/statictea"
  var cmd = part1 & part2 & part3
  echo cmd
  exec cmd
  cmd = "strip bin/statictea"
  exec cmd

proc getDirName(host: string): string =
  ## Return a directory name corresponding to the given nim hostOS
  ## name.  The name is good for storing host specific files, for
  ## example in the bin and env folders.  Current possible host
  ## values: "windows", "macosx", "linux", "netbsd", "freebsd",
  ## "openbsd", "solaris", "aix", "haiku", "standalone".

  if host == "macosx":
    result = "mac"
  elif host == "linux":
    result = "linux"
  elif host == "windows":
    result = "win"
  else:
    assert false, "add a new platform"

proc readModuleDescription(filename: string): string =
  ## Return the module doc comment at the top of the file.
  let text = slurp(filename)

  # Collect the doc comments at the beginning of the file. Read
  # the first block of lines starting with ##.
  var foundDescription = false
  var lines = newSeq[string]()
  for line in text.splitLines():
    if line.startsWith("##"):
      lines.add(line[2 .. ^1])
      foundDescription = true
    elif foundDescription:
      break

  # Determine the minimum number of spaces used with the doc comment.
  var minSpaces = 1024
  for line in lines:
    for ix in 0 .. line.len - 1:
      if line[ix] != ' ':
        if ix < minSpaces:
          minSpaces = ix
        break

  # Trim off the minimum leading spaces.
  var trimmedLines = newSeq[string]()
  for line in lines:
    # trimmedLines.add($minSpaces & ":" & line)
    trimmedLines.add(line[minSpaces .. ^1])

  result = trimmedLines.join("\n")

proc jsonQuote(str: string): string =
  ## Escape the specified json string.
  result = escapeJsonUnquoted(str)

proc fileIndexJson(filenames: seq[string]): string =
  ## Generate a json string containing the name of all the files and
  ## their doc comment descriptions.

  # Extract the source module descriptions from all the files.
  var descriptions = newSeq[string]()
  for filename in filenames:
    descriptions.add(readModuleDescription(filename))

  # Generate the index json with a filename and description.
  var modules = newSeq[string]()
  for ix, filename in filenames:
    modules.add("""
  {
    "filename": "$1",
    "description": "$2"
  }""" % [filename, jsonQuote(descriptions[ix])])

  result = """
{
  "modules": [
$1
  ]
}
""" % [join(modules, ",\n")]

proc sourceIndexJson(): string =
  ## Generate json for the doc comment index of all the source files.
  let filenames = get_source_filenames(path = true)
  result = fileIndexJson(filenames)

proc testfilesIndexJson(): string =
  ## Generate json for the doc comment index of all the stf test files.
  let filenames = get_testfile_filenames()
  result = fileIndexJson(filenames)

proc insertFile(filename: string, startLine: string, endLine: string,
                sectionFilename: string) =
  ## Insert sectionFilename into filename replacing the existing
  ## section of the file marked with start and end lines.
  let mainText = slurp(filename)
  let sectionText = slurp(sectionFilename)

  # We use a finite state machine. When in the start state we output
  # filename lines. When the startLine is found, we insert the section
  # file. Then we transition to the skip state where we skip lines
  # until the endline is found. Then we transition to the end state
  # and output the rest of the filename lines.

  type
    State = enum
      ## Finite state machine states.
      start, skip, finish

  var foundStartLine = false
  var state = State.start
  var lines = newSeq[string]()
  for line in mainText.splitLines():
    if state == State.start:
      lines.add(line)
      if line == startLine:
        foundStartLine = true
        for insertLine in sectionText.splitLines():
          lines.add(insertLine)
        state = State.skip
    elif state == State.skip:
      if line == endLine:
        lines.add(line)
        state = State.finish
    elif state == State.finish:
      lines.add(line)
  if not foundStartLine:
    echo "did not find start line"
  else:
    writeFile(filename, lines.join("\n"))

proc readDotFile*(dotFilename: string): seq[Dependency] =
  ## Read a dot file and return a sequence of left and right
  ## values. Skip the first and last line.
  let text = slurp(dotFilename)
  for line in text.splitLines():
    let dependencyO = parseDotLine(line)
    if dependencyO.isSome():
      result.add(dependencyO.get())

proc createDependencyGraph() =
  ## Create a dependency dot file from statictea.nim modules showing
  ## the module import dependencies.

  # Run "man dot" for information about the dot format
  # and formatting options.

  # Introduction to the dot language.
  # https://en.wikipedia.org/wiki/DOT_(graph_description_language)

  # See the following example which has links on each node.
  # https://graphviz.org/Gallery/directed/go-package.html

  # Add color the node's background and link them to their docs.
  # https://www.graphviz.org/doc/info/colors.html

  let dotFilename = "src/statictea.dot"
  exec "nim --hints:off genDepend src/statictea.nim"
  echo fmt"Generated {dotFilename}"
  rmFile("src/statictea.png")
  rmFile("statictea.deps")

  # Create a dictionary of all the source filenames.
  let sourceNames = get_source_filenames(noExt = true)
  var sourceNamesDict = initTable[string, int]()
  for name in sourceNames:
    sourceNamesDict[name] = 0

  # Read the dot file into a sequence of left and right values.
  let dependencies = readDotFile(dotFilename)

  # Count the number of modules the source file imports.
  for dependency in dependencies:
    let left = dependency.left
    if left in sourceNamesDict and dependency.right in sourceNamesDict:
      var count = sourceNamesDict[left] + 1
      sourceNamesDict[left] = count

  # Create a new dot file without the nim runtime modules. Format the
  # nodes and edges.
  var dotText = """digraph statictea {
  ratio=.5;
  size="10";
"""
  # size="14,8";

  for name in sourceNames:
    let url = fmt"""URL="{name}.md""""
    let tooltip = fmt"""tooltip="{name}.md""""
    var extra: string
    var allNodes = "fontsize=24;"
    if sourceNamesDict[name] > 0:
      # tree trunk
      extra = "fillcolor=palegoldenrod, style=filled"
    else:
      # tree leaves
      extra = "shape=doubleoctagon, fillcolor=palegreen, style=filled"
    var attrs: string
    if name == "statictea":
      attrs = fmt"{name} [{allNodes} shape=invhouse, {extra}, {url}, {tooltip}];" & "\n"
    else:
      attrs = fmt"{name} [{allNodes} {extra}, {url}, {tooltip}];" & "\n"
    dotText.add(attrs)
  # Generate the connections between the nodes.
  for dependency in dependencies:
    if dependency.left in sourceNamesDict and dependency.right in sourceNamesDict:
      dotText.add(fmt"""{dependency.left} -> "{dependency.right}";""" & "\n")
  dotText.add("}\n")

  # Create an svg file from the new dot file.
  let dotDotFilename = "src/dot.dot"
  writeFile(dotDotFilename, dotText)
  echo "Generated $1" % dotDotFilename
  exec "dot -Tsvg src/dot.dot -o docs/staticteadep.svg"
  echo "Generated docs/staticteadep.svg"

proc createDependencyGraph2() =
  ## Create a dependency dot file from the StaticTea source. Show the
  ## the nim system modules on the left and the StaticTea modules on
  ## the right.

  # Create a dot file of all the import dependencies.
  let dotFilename = "src/statictea.dot"
  exec "nim --hints:off genDepend src/statictea.nim"
  echo fmt"Generated {dotFilename}"
  rmFile("src/statictea.png")
  rmFile("statictea.deps")

  # Create a hash set of all the statictea source filenames.
  var sourceNamesSet = toHashSet(get_source_filenames(noExt = true))

  # Read the dot file into a sequence of left and right values.
  let dotDepends = readDotFile(dotFilename)

  # Switch the dependencies so the nim system modules are on the left
  # and the statictea modules are on the right.
  var dependencies: seq[Dependency]
  for dependency in dotDepends:
    let left = dependency.right
    let right = dependency.left
    if not (left in sourceNamesSet) and (right in sourceNamesSet):
      dependencies.add(newDependency(left, right))

  # Count the number of modules the left module references.
  var nameCount = initTable[string, int]()
  for dependency in dependencies:
    let left = dependency.left
    var count: int
    if left in nameCount:
      count = nameCount[left] + 1
    else:
      count = 1
    nameCount[left] = count

  # Create a dot file with formatting.
  var dotText = """digraph statictea {
  rankdir=LR;
  ranksep="4";
"""
  for dependency in dependencies:
    let left = dependency.left
    var nodetAttrs: string
    var lineAttrs: string
    if nameCount[left] == 1:
      # tree leaves
      nodetAttrs = "shape=doubleoctagon, fillcolor=palegreen, style=filled"
    elif nameCount[left] == 2:
      nodetAttrs = "color=red;"
      lineAttrs = "color=red;"
    let attrs = fmt"{left} [fontsize=24; {nodetAttrs}];" & "\n"
    dotText.add(attrs)
    dotText.add("$1 -> \"$2\" [$3];\n" % [dependency.left, dependency.right, lineAttrs])
    # dotText.add(fmt"""{dependency.left} -> "{dependency.right}" [{lineAttrs}];""" & "\n")
  dotText.add("}\n")

  # Create an svg file from the new dot file.
  let src_dot2_dot = "src/dot2.dot"
  writeFile(src_dot2_dot, dotText)
  echo fmt"Generated {src_dot2_dot}"
  let staticteadep2_svg = "docs/staticteadep2.svg"
  exec fmt"dot -Tsvg {src_dot2_dot} -o {staticteadep2_svg}"
  echo fmt"Generated {staticteadep2_svg}"

proc echoGrip() =
  echo """

The grip app is good for viewing github markdown locally.
  grip --quiet readme.org &
  http://localhost:6419/docs/index.md
  http://localhost:6419/testfiles/readme.md

"""

proc taskDocsIx() =
  ## Create the index json file.

  echo "Create index json."
  var jsonFilename = "docs/index.json"
  var json = sourceIndexJson()
  writeFile(jsonFilename, json)

  # Process the index template and create the index.md file.
  echo "Create the index.md file"
  var cmd = "bin/statictea -s=$1 -t=templates/nimModuleIndex.md -r=docs/index.md" %
    [jsonFilename]
  exec cmd

  rmFile(jsonFilename)
  echo "Generated docs/index.md"
  # echoGrip()

proc taskTestfilesReadme() =
  ## Create a testfiles folder readme containing an index to the stf
  ## test files.

  echo "Create a json file with the name of all the stf tests an their description."
  var jsonFilename = "testfiles.index.json"
  var json = testfilesIndexJson()
  writeFile(jsonFilename, json)

  # Process the index template and create the index.md file.
  echo "Create the testfiles/readme.md file"
  var cmd = "bin/statictea -s=$1 -t=templates/testfiles.md -r=testfiles/readme.md" %
    [jsonFilename]
  exec cmd

  rmFile(jsonFilename)
  echo "Generated testfiles/readme.md"
  echoGrip()

proc myFileNewer(a: string, b: string): bool =
  ## Return true when file a is newer than file b.
  # result = getLastModificationTime(a) > getLastModificationTime(b)
  for filename in [a, b]:
    if not fileExists(filename):
      echo "file doesn't exist: " & filename
      return false

  let cmd = "echo $(($(date -r " & a & " +%s)-$(date -r " & b & " +%s)))"
  # echo cmd
  let diffStr = staticExec(cmd)
  let diff = parseInt(diffStr)
  if diff < 0:
    result = true
  else:
    result = false

proc taskDocs(namePart: string) =
  ## Create one or more markdown docs; specify part of source filename.":
  let filenames = get_source_filenames()
  for filename in filenames:
    # Name is part of a source file name, or "docs" when not specified.
    if namePart in filename or namePart == "docs":
      var mdName = "docs/$1" % [changeFileExt(filename, "md")]

      if myFileNewer("src/" & filename, mdName):
        echo "Skipping unchanged $1." % filename
        continue

      # Create json doc comments from the source file.
      var jsonName = "docs/$1" % [changeFileExt(filename, "json")]
      var cmd = "nim --hint[Conf]:off --hint[SuccessX]:off jsondoc --out:$1 src/$2" % [jsonName, filename]
      echo "Create $1 from nim json doc comments." % [jsonName]
      exec cmd
      echo ""

      # Create a shared.json file for use by the template.
      let sharedJson = """{"newline": "\n"}"""
      let sharedFilename = "docs/shared.json"
      writeFile(sharedFilename, sharedJson)

      # Create markdown from the json comments using a statictea template.
      echo "Generate $1" % [mdName]
      let part1 = "bin/statictea -j=docs/shared.json -t=templates/nimModule.md "
      let part2 = "-s=$1 -r=$2" % [jsonName, mdName]
      exec part1 & part2

      # Remove the temporary files.
      rmFile(sharedFilename)
      echo "Remove $1" % [jsonName]
      rmFile(jsonName)

  echoGrip()

proc taskReadMeFun() =
  ## Create the readme function section from the runFunctions.nim
  ## file.

  let filename = "runFunction.nim"
  var jsonName = joinPath("docs", changeFileExt(filename, "json"))
  var cmd = "nim --hint[Conf]:off --hint[SuccessX]:off jsondoc --out:$1 src/$2" %
    [jsonName, filename]
  exec cmd
  echo ""
  echo "Exported runFunctions.nim json doc comments: $1" % [jsonName]

  # Create a shared.json file for use by the template.
  let sharedJson = """{"newline": "\n"}"""
  let sharedFilename = "docs/shared.json"
  writeFile(sharedFilename, sharedJson)

  # Create the readme function section org file.
  let templateName = joinPath("templates", "readmeFuncSection.org")
  let sectionFile = joinPath("docs", "readmeFuncs.org")
  cmd = "bin/statictea -l -s=$1 -j=docs/shared.json -t=$2 -r=$3" %
     [jsonName, templateName, sectionFile]
  # echo cmd
  exec cmd
  echo "Generated readme function section file: " & sectionFile

  rmFile(sharedFilename)
  rmFile(jsonName)

  # Insert the function section into the readme.
  insertFile("readme.org", "# Dynamic Content Begins",
    "# Dynamic Content Ends", sectionFile)
  echo "Merged function section into readme.org."

  # rmFile(sectionFile)

proc buildRunner() =
  let part1 = "nim c --gc:orc --hint[Performance]:off "
  let part2 = "--hint[Conf]:off --hint[Link]: off -d:release "
  let part3 = "--out:bin/ src/runner"
  var cmd = part1 & part2 & part3
  echo cmd
  exec cmd
  cmd = "strip bin/runner"
  exec cmd

proc runRunnerFolder() =
  ## Run the stf files in the testfiles folder.

  let cmd = "export statictea='../../bin/statictea'; bin/runner -d=testfiles"
  echo cmd
  let result = staticExec cmd
  echo result

proc get_stf_filenames(): seq[string] =
  ## Return the basename of the stf files in the testfiles folder.
  result = @[]
  var list = listFiles("testfiles")
  for filename in list:
    if filename.endsWith(".stf") and not filename.startsWith(".#"):
      result.add(lastPathPart(filename))

proc runRunStf() =
  # Get the name of the stf to run.
  let count = system.paramCount()+1
  var name = system.paramStr(count-1)

  let stf_filenames = get_stf_filenames()
  var failed = false
  for filename in stf_filenames:
    if name == "rt" or name.toLower in filename.toLower:
      # Run a stf file.
      let cmd = """
export statictea='../../bin/statictea'; bin/runner -f=testfiles/$1""" % filename
      if name == "rt":
        echo filename
      else:
        echo cmd
      let result = staticExec cmd
      if result != "":
        failed = true
        echo result
  if failed:
    echo "failed"
  else:
    echo "success"

proc runRunStfMain() =
  try:
    runRunStf()
  except:
    echo ""
    discard

proc sameBytes(a: string, b: string): bool =
  ## Return true when the two files contain the same bytes.
  let aBytes = slurp(a)
  let bBytes = slurp(b)
  if aBytes == bBytes:
    result = true


proc checkUtf8DecoderEcho() =
  ## Check whether there is a new version of utf8decoder.nim in the
  ## utftests repo. Return 0 when up-to-date.
  
  let utf8testsFolder = "../utf8tests"
  let utf8decoder = "../utf8tests/src/utf8decoder.nim"
  let localUtf8decoder = "src/utf8decoder.nim"
  if not dirExists(utf8testsFolder):
    # Ignore when the repo is missing.
    # echo "no utf8tests repo"
    return
  if not fileExists(utf8decoder):
    echo "utf8decoder.nim isn't in utftests repo anymore."
    return
  if not sameBytes(utf8decoder, localUtf8decoder):
    echo "Update utf8decoder.nim"
    echo fmt"cp {utf8decoder} {localUtf8decoder}"
    echo "Use ^^ to copy."
  else:
    echo "utf8decoder is up-to-date"

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
  rmFile("tests/testall.nim")

  # Make sure it builds with test undefined.
  buildRelease()

  # Build runner.
  buildRunner()

  # Run the stf tests.
  runRunnerFolder()

  # Make sure utf8decoder is up-to-date.
  checkUtf8DecoderEcho()

task test, "\tRun one or more tests; specify part of test filename.":
  ## Run one or more tests.  You specify part of the test filename and
  ## all files that match case insensitive are run. If you don't
  ## specify a name, all are run. Task "t" is faster to run them all.
  let count = system.paramCount()+1
  # The name is either part of a name or "test" when not
  # specified. Test happens to match all test files.
  let name = system.paramStr(count-1)
  let test_filenames = get_test_filenames()
  for filename in test_filenames:
    if name.toLower in filename.toLower:
      if filename == "testall.nim":
        continue
      let cmd = get_test_module_cmd(filename)
      echo cmd
      exec cmd

task b, "\tBuild the statictea exe.":
  buildRelease()

task docsall, "\tCreate all the docs, docsix, docs, readmefun, dot.":
  taskDocsIx()
  taskDocs("")
  taskReadMeFun()
  createDependencyGraph()
  createDependencyGraph2()


task docs, "\tCreate one or more markdown docs; specify part of source filename.":
  let count = system.paramCount()+1
  let namePart = system.paramStr(count-1)
  taskDocs(namePart)

task docsix, "\tCreate markdown docs index.":
  taskDocsIx()

task json, "\tDisplay one or more source file's json doc comments; specify part of name.":
  let count = system.paramCount()+1
  let name = system.paramStr(count-1)
  let filenames = get_source_filenames()
  for filename in filenames:
    if name in filename:
      var jsonName = joinPath("docs", changeFileExt(filename, "json"))
      var cmd = "nim --hints:off jsondoc --out:$1 src/$2" % [jsonName, filename]
      # echo cmd
      exec cmd
      let text = slurp(jsonName)
      for line in text.splitLines():
        echo line
      break
  echo ""
  echo "The jq command is good for viewing the output."
  echo "n json name | jq | less"

task jsonix, "\tDisplay markdown docs index json.":
  var json = sourceIndexJson()
  # writeFile("docs/index.json", json)
  for line in json.splitLines():
    echo line

task testfilesix, "\tDisplay markdown testfiles index json.":
  var json = testfilesIndexJson()
  for line in json.splitLines():
    echo line

task readmefun, "Create the readme function section.":
  taskReadMeFun()

task dot, "\tCreate a dependency graph of the StaticTea source.":
  createDependencyGraph()

  echoGrip()
  echo """

View the svg file in your browser:
  http://localhost:6419/staticteadep.svg
"""

task dot2, "\tCreate a dependency graph of the system modules used by StaticTea.":
  createDependencyGraph2()

  echoGrip()
  echo """
View the svg file in your browser:
  http://localhost:6419/staticteadep2.svg
"""

task tt, "\tCompile and run t.nim.":
  let cmd = "nim c -r --gc:orc --hints:off --outdir:bin/tests/ src/t.nim"
  echo cmd
  exec cmd

task tree, "\tShow the project directory tree.":
  exec "tree -I '*.nims|*.bin' | less"

task args, "\tShow command line arguments.":
  let count = system.paramCount()+1
  for i in 0..count-1:
    echo "$1: $2" % [$(i+1), system.paramStr(i)]

task br, "\tBuild the stf test runner.":
  buildRunner()

task rt, "\tRun one or more stf tests in testfiles; specify part of the name.":
  runRunStfMain()

task stf, "\tList stf tests with newest last.":
  exec """ls -1tr testfiles/*.stf | xargs grep "##" | cut -c 11- | sed 's/:## / -- /'"""

task testfilesreadme, "\tCreate testfiles readme.md.":
  taskTestfilesReadme()

task newstf, "\tCreate new stf as a starting point for a new test.":
  let count = system.paramCount()+1
  var name = system.paramStr(count-1)
  if name == "newstf":
    echo "Specify a name for a new stf test in the testfiles folder."
  else:
    var (_, basename) = splitPath(name)
    if not basename.endsWith(".stf"):
      basename = basename & ".stf"
    var filename = joinPath("testfiles", basename)
    if fileExists(filename):
      echo "File already exists: $1" % filename
    else:
      let cmd = "cp testfiles/template.stf $1" % filename
      echo cmd
      exec cmd

task runhelp, "\tShow the runner help text with glow.":
  exec "bin/runner -h | glow -"

task helpme, "\tShow the statictea help text.":
  exec "bin/statictea -h | less"
