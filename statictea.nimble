import std/os
import std/strutils
import std/json
import std/nre
import std/strformat
include src/version
include src/dot

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
  ## Return the basename of the nim files in the tests folder.
  result = @[]
  var list = listFiles("tests")
  for filename in list:
    result.add(lastPathPart(filename))

proc get_source_filenames(path: bool = false, noExt: bool = false): seq[string] =
  ## Return the basename of the nim source files in the src folder.
  let excludeFilenames = ["t.nim", "dot.nim"]
  result = @[]
  var list = listFiles("src")
  for filename in list:
    if filename.endsWith(".nim") and not (lastPathPart(filename) in excludeFilenames):
      var name = filename
      if noExt:
        name = name[0 .. ^5]
      if not path:
        name = lastPathPart(name)
      result.add(name)

proc get_test_module_cmd(filename: string, release = false): string =
  ## Return the command line to test the given nim file.

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
  let part1 = "nim c -f --gc:orc --verbosity:0 --hint[Performance]:off "
  let part2 = "--hint[XCannotRaiseY]:off -d:test "
  let part3 = "$1 -r -p:src --out:bin/$2 tests/$3" % [rel, binName, filename]
  result = part1 & part2 & part3

proc build_release() =
  ## Build the release version of statictea.
  var cmd = "nim c --gc:orc --hint[Performance]:off --hint[Conf]:off --hint[Link]: off -d:release --out:bin/ src/statictea"
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

  # Collect the doc comments at the beginning of the file.
  var lines = newSeq[string]()
  for line in text.splitLines():
    if line.startsWith("##"):
      lines.add(line[2 .. ^1])
    else:
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
  ## Escape json string.
  result = escapeJsonUnquoted(str)

proc indexJson(): string =
  ## Generate json for the doc comment index of all the source files.

  let filenames = get_source_filenames(path = true)

  # Extract the source module descriptions.
  var descriptions = newSeq[string]()
  for filename in filenames:
    descriptions.add(readModuleDescription(filename))

  # Generate the index json.
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
  ## Create a dependency dot file from statictea.nim and everything it
  ## references. Run "man dot" for information about the dot format
  ## and formatting options.

  # See the following example which has links on each node.
  # https://graphviz.org/Gallery/directed/go-package.html

  exec "nim --hints:off genDepend src/statictea.nim"
  echo "Generated src/statictea.dot"
  rmFile("src/statictea.png")
  rmFile("statictea.deps")

  # Create a dictionary of all the source filenames.
  let sourceNames = get_source_filenames(noExt = true)
  var sourceNamesDict = initTable[string, int]()
  for name in sourceNames:
    sourceNamesDict[name] = 0

  # Read the dot file into a sequence of left and right values.
  let dotFilename = "src/statictea.dot"
  let dependencies = readDotFile(dotFilename)

  # Count the number of modules the source file imports.
  for dependency in dependencies:
    let left = dependency.left
    if left in sourceNamesDict and dependency.right in sourceNamesDict:
      var count = sourceNamesDict[left] + 1
      sourceNamesDict[left] = count

  # Create a new dot file without the nim runtime modules.
  var dotText = "digraph statictea {\n"
  # Add color the node's background and link them to their docs.
  # https://www.graphviz.org/doc/info/colors.html
  for name in sourceNames:
    let url = "URL=\"$1.md\"" % name
    let tooltip = "tooltip=\"$1.md\"" % name
    var extra: string
    var allNodes = "fontsize=24"
    if sourceNamesDict[name] > 0:
      extra = "fillcolor=bisque3, style=filled"
    else:
      extra = "shape=doubleoctagon, fillcolor=aquamarine, style=filled"
    var attrs: string
    if name == "statictea":
      attrs = fmt"{name} [{allNodes}, shape=invhouse, {extra}, {url}, {tooltip}];" & "\n"
    else:
      attrs = fmt"{name} [{allNodes}, {extra}, {url}, {tooltip}];" & "\n"
    dotText.add(attrs)
  # Generate the connections between the nodes.
  for dependency in dependencies:
    if dependency.left in sourceNamesDict and dependency.right in sourceNamesDict:
      dotText.add("$1 -> \"$2\";\n" % [dependency.left, dependency.right])
  dotText.add("}\n")

  # Create an svg file from the new dot file.
  let dotDotFilename = "src/dot.dot"
  writeFile(dotDotFilename, dotText)
  echo "Generated $1" % dotDotFilename
  exec "dot -Tsvg src/dot.dot -o docs/staticteadep.svg"
  echo "Generated docs/staticteadep.svg"

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
  build_release()
  # Run the command line tests.
  exec "src/test"

task test, "\tRun tests; specify part of test filename.":
  ## Run one or more tests.  You specify part of the test filename and all
  ## files that match are run. If you don't specify a name, all are
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

task docs, "\tCreate markdown docs; specify part of source filename.":
  let count = system.paramCount()+1
  let name = system.paramStr(count-1)
  let filenames = get_source_filenames()
  for filename in filenames:
    # Name is part of a source file name, or "docs" when not specified.
    if name in filename or name == "docs":
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
      var mdName = "docs/$1" % [changeFileExt(filename, "md")]
      echo "Generate $1" % [mdName]
      let part1 = "bin/statictea -j=docs/shared.json -t=templates/nimModule.md "
      let part2 = "-s=$1 -r=$2" % [jsonName, mdName]
      exec part1 & part2

      # Remove the temporary files.
      rmFile(sharedFilename)
      echo "Remove $1" % [jsonName]
      rmFile(jsonName)

  echo """
The grip app is good for viewing gitlab markdown.
  grip --quiet docs/index.md &
  http://localhost:6419/index.md
"""

task json, "\tDisplay nim's doc json for a source file; specify part of name.":
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
  # The jq command is good for viewing the output.
  # n json | jq | less

task jsonix, "\tDisplay the module index json for the source files.":
  var json = indexJson()
  # writeFile("docs/index.json", json)
  for line in json.splitLines():
    echo line

task docsix, "\tGenerate the nim module index to the source files.":

  # Create the index json file.
  echo "Create index json."
  var jsonFilename = "docs/index.json"
  var json = indexJson()
  writeFile(jsonFilename, json)

  # Process the index template and create the index.md file.
  echo "Create the index.md file"
  var cmd = "bin/statictea -s=$1 -t=templates/nimModuleIndex.md -r=docs/index.md" %
    [jsonFilename]
  exec cmd

  rmFile(jsonFilename)
  echo "Generated docs/index.md"
  echo """
The grip app is good for viewing gitlab markdown.
  grip --quiet docs/index.md &
  http://localhost:6419/index.md
"""

task readmefun, "Create readme function section.":
  let count = system.paramCount()+1

  echo "Export nim runFunctions json doc comments..."
  let filename = "runFunction.nim"
  var jsonName = joinPath("docs", changeFileExt(filename, "json"))
  var cmd = "nim --hint[Conf]:off --hint[SuccessX]:off jsondoc --out:$1 src/$2" %
    [jsonName, filename]
  exec cmd
  echo "Generated $1" % [jsonName]

  # Create a shared.json file for use by the template.
  let sharedJson = """{"newline": "\n"}"""
  let sharedFilename = "docs/shared.json"
  writeFile(sharedFilename, sharedJson)

  echo "Generate readme function section from template..."
  let templateName = joinPath("templates", "readmeFuncSection.org")
  let sectionFile = joinPath("docs", "readmeFuncs.org")
  cmd = "bin/statictea -l -s=$1 -j=docs/shared.json -t=$2 -r=$3" %
     [jsonName, templateName, sectionFile]
  # echo cmd
  exec cmd

  rmFile(sharedFilename)
  rmFile(jsonName)

  insertFile("readme.org", "# Dynamic Content Begins",
    "# Dynamic Content Ends", sectionFile)

  echo "Generated sectionFile: " & sectionFile
  # rmFile(sectionFile)

  echo "Updated readme.org"

task tt, "\tCompile and run t.nim.":
  let cmd = "nim c -r --gc:orc --hints:off --outdir:bin/tests/ src/t.nim"
  echo cmd
  exec cmd

task tree, "\tShow the project directory tree.":
  exec "tree -I '*.nims|*.bin' | less"

task args, "\tshow command line arguments":
  let count = system.paramCount()+1
  for i in 0..count-1:
    echo "$1: $2" % [$(i+1), system.paramStr(i)]

task dot, "\tCreate the dependency graph of the StaticTea source.":
  createDependencyGraph()
  # exec "open -a Firefox http://localhost:6419/staticteadep.svg"
  echo "View the svg file in your browser:"
  echo "http://localhost:6419/staticteadep.svg"
