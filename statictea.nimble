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

requires "nim >= 1.4.2"

# The nimscript module is imported by default. It contains functions
# you can call in your nimble file.
# https://nim-lang.org/0.11.3/nimscript.html

proc exit() =
  exec "exit 1"

proc get_test_filenames(): seq[string] =
  ## Return the basename of the nim files in the tests folder.
  result = @[]
  let exclude = ["testall1.nim", "testall2.nim"]
  var list = listFiles("tests")
  for filename in list:
    let basename = lastPathPart(filename)
    if not (basename in exclude):
      result.add(basename)

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
  let excludeFilenames = @["t.nim", "dot.nim", "sharedtestcode.nim"]
  result = get_dir_filenames("src", ".nim", path = path, noExt = noExt,
    excludeFilenames = excludeFilenames)

proc get_testfile_filenames(): seq[string] =
  ## Return the basename of the stf source files in the testfiles
  ## folder.
  result = get_dir_filenames("testfiles", ".stf.md", path = true)

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

    I turned on gs:orc because "n t" started erroring out. Too many
    unit tests maybe. The error message was :"[GC] cannot register
    global variable; too many global variables".  I turned it off
    because "writing to nil" error when building "n test runfun".  I
    got rid of "n t" because it was crashing the compiler too often.

  --verbosity:0|1|2|3

    set Nim's verbosity level (1 is default)  --verbosity:0

  --hint[Performance]:off

    Turn off Performance hint messages.

  --hint[XCannotRaiseY]:off

    Turn off XCannotRaiseY hint messages.

  --hint[Name]:off

    Turn off hints like:
      Hint: 'funReadJson_sa' should be: 'funReadJsonSa'

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

  let part1 = "nim c --verbosity:0 --hint[Performance]:off "
  let part2 = "--hint[XCannotRaiseY]:off --hint[Name]:off -d:test "
  let part3 = "$1 -r -p:src --out:bin/$2 tests/$3" % [rel, binName, filename]

  result = part1 & part2 & part3

proc buildRelease() =
  ## Build the release version of statictea.
  let part1 = "nim c --hint[Performance]:off "
  let part2 = "--hint[Conf]:off --hint[Name]:off --hint[Link]:off -d:release "
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
    if line.startsWith("##") and line.len > 2:
      lines.add(line[2 .. line.len - 1])
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

proc readModuleDescriptionMd(filename: string): string =
  ## Return the module doc comment at the top of the file for markdown
  ## files.
  let text = slurp(filename)

  # Collect the doc comments at the beginning of the file. Read the
  # first block of lines starting with a letter to the first blank
  # line.

  var foundDescription = false
  var descriptionLines = newSeq[string]()
  let fileLines = text.splitLines()
  for line in fileLines[1 .. fileLines.len-1]:   # Skip the first line.
    if foundDescription:
      if line == "":
        break
      descriptionLines.add(line)
    elif line != "" and isAlphaNumeric(line[0]):
      foundDescription = true
      descriptionLines.add(line)

  result = descriptionLines.join("\n")

proc jsonQuote(str: string): string =
  ## Escape the specified json string.
  result = escapeJsonUnquoted(str)

proc fileIndexJson(filenames: seq[string], descriptions: seq[string]): string =
  ## Generate a json string containing the name of all the files and
  ## their doc comment descriptions.

  if filenames.len != descriptions.len:
    echo "Error: the number of filenames and their descriptions do not match."
    return

  # Generate the index json with a filename and description.
  result = """
{
  "modules": ["""

  for ix, filename in filenames:
    if ix == 0:
      result.add("\n")
    else:
      result.add(",\n")
    result.add("""
  {
    "filename": "$1",
    "description": "$2"
  }""" % [filename, jsonQuote(descriptions[ix])])

  result.add("""

  ]
}
""")

proc sourceIndexJson(): string =
  ## Generate json for the doc comment index of all the source files.
  let filenames = get_source_filenames(path = true)

  # Extract the source module descriptions from all the files.
  var descriptions = newSeq[string]()
  for filename in filenames:
    descriptions.add(readModuleDescription(filename))

  result = fileIndexJson(filenames, descriptions)

proc testfilesIndexJson(): string =
  ## Generate json for the doc comment index of all the stf test files.
  let filenames = get_testfile_filenames()

  # Extract the source module descriptions from all the files.
  var descriptions = newSeq[string]()
  for filename in filenames:
    descriptions.add(readModuleDescriptionMd(filename))

  result = fileIndexJson(filenames, descriptions)

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

  # Create a dictionary of all the source filenames and how many
  # imports each has.
  let sourceNames = get_source_filenames(noExt = true)
  var sourceNamesDict = initTable[string, int]()
  for name in sourceNames:
    sourceNamesDict[name] = 0

  # echo "sourceNamesDict keys:"
  # for name, _ in pairs(sourceNamesDict):
  #   echo fmt"name: {name}"

  # Read the dot file into a sequence of left and right values.
  let dependencies = readDotFile(dotFilename)

  # Count the number of modules the source file imports.
  for dependency in dependencies:
    # echo fmt"dependency: {dependency}"
    let left = dependency.left
    if sourceNamesDict.contains(left) and sourceNamesDict.contains(dependency.right):
      var count = sourceNamesDict[left] + 1
      sourceNamesDict[left] = count

  # echo "module import-count"
  # for key, value in pairs(sourceNamesDict):
  #   echo fmt"{key}: {value}"

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
    let count = sourceNamesDict[name]
    if count == 0:
      # tree leaves
      extra = "shape=doubleoctagon, fillcolor=palegreen, style=filled"
    elif count == 1:
      extra = "fillcolor=palegoldenrod, style=filled"
      # extra = "color=red"
    else:
      # tree trunk
      extra = "fillcolor=palegoldenrod, style=filled"
    var attrs: string
    if name == "statictea":
      attrs = fmt"{name} [{allNodes} shape=invhouse, {extra}, {url}, {tooltip}];" & "\n"
    else:
      attrs = fmt"{name} [{allNodes} {extra}, {url}, {tooltip}];" & "\n"
    dotText.add(attrs)

  # Generate the connections between the nodes.
  for dependency in dependencies:
    if dependency.left in sourceNamesDict and dependency.right in sourceNamesDict:
      if sourceNamesDict[dependency.left] == 1:
        dotText.add(
          fmt"""{dependency.left} -> "{dependency.right}"[color=red];""" & "\n")
      else:
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
      if left.startsWith("std/"):
        # Remove "std/" from the nim module names.
        # 1.6.2
        dependencies.add(newDependency(left[4 .. ^1], right))
      else:
        # 1.4.2
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
    dotText.add("$1 -> \"$2\" [$3];\n" % [left, dependency.right, lineAttrs])
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
  var cmd = "bin/statictea -s $1 -t templates/nimModuleIndex.md -r docs/index.md" %
    [jsonFilename]
  exec cmd

  rmFile(jsonFilename)
  echo "Generated docs/index.md"
  # echoGrip()

proc taskTestfilesReadme() =
  ## Create a testfiles folder readme containing an index to the stf
  ## test files.

  echo "Create a json file with the name of all the stf tests and their descriptions."
  var jsonFilename = "testfiles.index.json"
  var json = testfilesIndexJson()
  writeFile(jsonFilename, json)

  # Process the index template and create the index.md file.
  echo "Create the testfiles/readme.md file"
  var cmd = "bin/statictea -s $1 -t templates/testfiles.md -r testfiles/readme.md" %
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

proc taskDocs(namePart: string, forceRebuild = false) =
  ## Create one or more markdown docs; specify part of source filename.":
  let filenames = get_source_filenames()
  for filename in filenames:
    # Name is part of a source file name, or "docs" when not specified.
    if namePart.toLower in filename.toLower or namePart == "docs":
      var mdName = "docs/$1" % [changeFileExt(filename, "md")]

      if not forceRebuild and myFileNewer("src/" & filename, mdName):
        echo "Skipping unchanged $1." % filename
        continue

      # Create json doc comments from the source file.
      var jsonName = "docs/$1" % [changeFileExt(filename, "json")]
      let hintsOff = "--hint[Conf]:off --hint[SuccessX]:off --hint[Name]:off"
      var cmd = "nim $1 jsondoc --out:$2 src/$3" % [hintsOff, jsonName, filename]
      echo "Create $1 from nim json doc comments." % [jsonName]
      exec cmd
      echo ""

      # Create markdown from the json comments using a statictea template.
      echo "Generate $1" % [mdName]
      let part1 = "bin/statictea -t templates/nimModule.md "
      let part2 = "-s $1 -r $2" % [jsonName, mdName]
      cmd = part1 & part2
      echo cmd
      let output = staticExec(cmd)
      if len(output) > 0:
        echo output
        exec fmt"rm {mdName}"

      # Remove the temporary files.
      rmFile(jsonName)

  echoGrip()

proc taskReadMeFun() =
  ## Create the readme function section from the runFunctions.nim
  ## file.

  let filename = "runFunction.nim"
  var jsonName = joinPath("docs", changeFileExt(filename, "json"))
  let hintsOff = "--hint[Conf]:off --hint[SuccessX]:off --hint[Name]:off"
  var cmd = "nim $1 jsondoc --out:$2 src/$3" %
    [hintsOff, jsonName, filename]
  exec cmd
  echo ""
  echo "Exported runFunctions.nim json doc comments to $1" % [jsonName]

  # Create the readme function section org file.
  let templateName = joinPath("templates", "readmeFuncSection.org")
  let sectionFile = joinPath("docs", "readmeFuncs.org")
  cmd = "bin/statictea -l -s $1 -t $2 -r $3" %
     [jsonName, templateName, sectionFile]
  echo cmd
  exec cmd
  echo "Generated readme function section file " & sectionFile

  # rmFile(jsonName)

  # Insert the function section into the readme.
  insertFile("readme.org", "# Dynamic Content Begins",
    "# Dynamic Content Ends", sectionFile)
  echo "Merged function section into readme.org."

  # rmFile(sectionFile)

proc buildRunner() =
  let part1 = "nim c --hint[Performance]:off "
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
  # echo cmd
  let (result, rc) = gorgeEx(cmd)
  echo result
  if rc != 0:
    echo "stf test failure"
    raise newException(IOError, "stf failure")

proc get_stf_filenames(): seq[string] =
  ## Return the basename of the stf files in the testfiles folder.
  result = @[]
  var list = listFiles("testfiles")
  for filename in list:
    if ".stf" in filename and not filename.startsWith(".#"):
      result.add(lastPathPart(filename))

proc runRunStf() =
  # Get the name of the stf to run.
  let count = system.paramCount()+1
  var name = system.paramStr(count-1)

  # When the name is "rt" that means no name was specified.  Run the
  # whole directory using the -d option.
  if name == "rt":
    let cmd = "export statictea='../../bin/statictea'; bin/runner -d=testfiles"
    let result = staticExec cmd
    echo result
    return

  let stf_filenames = get_stf_filenames()
  var failed = false
  var foundTest = false
  var numberRan = 0
  var lastCmd: string
  for filename in stf_filenames:
    if name == "rt" or name.toLower in filename.toLower:
      # Run a stf file.
      foundTest = true
      let cmd = """
export statictea='../../bin/statictea'; bin/runner -f=testfiles/$1""" % filename
      echo "Running: " & filename
      let result = staticExec cmd
      lastCmd = cmd
      inc(numberRan)
      if result != "":
        failed = true
        echo result
  if not foundTest:
    echo "test not found: " & name
  elif not failed:
    echo "Success"
  # Show the command when running just one test that fails.
  if numberRan == 1 and failed:
    echo ""
    echo "command line used:"
    echo lastCmd

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

  if len(aBytes) != len(bBytes):
    return false

  for ix, aByte in aBytes:
    var bByte = bBytes[ix]
    if aByte != bByte:
      return false

  result = true


proc checkUtf8DecoderEcho() =
  ## Check whether there is a new version of utf8decoder.nim in the
  ## utftests repo. Return 0 when up-to-date.

  let utf8testsFolder = "../utf8tests"

  const remoteRelativeFiles = ["src/utf8decoder.nim", "tests/test_utf8decoder.nim"]
  const localFiles = ["src/utf8decoder.nim", "tests/test_utf8decoder.nim"]
  assert len(remoteRelativeFiles) == len(localFiles)

  if not dirExists(utf8testsFolder):
    # Ignore when the repo is missing.
    # echo fmt"missing: {utf8testsFolder}"
    return
  var different = false
  for ix, remoteRelative in remoteRelativeFiles:
    let remoteFile = joinPath(utf8testsFolder, remoteRelative)
    let localFile = localFiles[ix]
    if not fileExists(remoteFile):
      echo fmt"{remoteFile} isn't in utftests repo anymore."
      return
    if not sameBytes(remoteFile, localFile):
      echo fmt"diff {remoteFile} {localFile}"
      echo fmt"cp {remoteFile} {localFile}"
      different = true
    # else:
    #   echo fmt"diff {remoteFile} {localFile}"

  if different:
    echo "Use ^^ to update the local copy."

proc otherTests() =
  # Make sure it builds with test undefined.
  buildRelease()

  # Build runner.
  buildRunner()

  # Run the stf tests.
  runRunnerFolder()

  # Make sure utf8decoder is up-to-date.
  checkUtf8DecoderEcho()

proc runUnitTests(name = "") =
  ## Run one or more tests.  You specify part of the test filename and
  ## all files that match case insensitive are run. If you don't
  ## specify a name, all are run.
  let test_filenames = get_test_filenames()
  for filename in test_filenames:
    if name.toLower in filename.toLower:
      if filename == "testall.nim":
        continue
      let cmd = get_test_module_cmd(filename)
      echo cmd
      exec cmd

# Tasks below

task n, "\tShow available tasks.":
  exec "nimble tasks"

task test, "\tRun one or more tests; specify part of test filename.":
  let count = system.paramCount()+1
  let name = system.paramStr(count-1)
  runUnitTests(name)

task other, "\tRun other tests and build tests.":
  otherTests()

task b, "\tBuild the statictea exe.":
  buildRelease()

task docsall, "\tCreate all the docs, docsix, docs, readmefun, dot.":
  taskDocsIx()
  taskDocs("")
  taskReadMeFun()
  taskTestfilesReadme()
  createDependencyGraph()
  createDependencyGraph2()

task docs, "\tCreate one or more markdown docs; specify part of source filename.":
  let count = system.paramCount()+1
  var namePart = system.paramStr(count-1)
  var forceRebuild = false
  if namePart == "force":
    forceRebuild = true
    namePart = system.paramStr(count-2)
  taskDocs(namePart, forceRebuild)

task docsix, "\tCreate markdown docs index.":
  taskDocsIx()

task json, "\tDisplay one or more source file's json doc comments; specify part of name.":
  let count = system.paramCount()+1
  let name = system.paramStr(count-1)
  let filenames = get_source_filenames()
  for filename in filenames:
    if name.toLower in filename.toLower:
      var jsonName = joinPath("docs", changeFileExt(filename, "json"))
      var cmd = "nim --hints:off jsondoc --out:$1 src/$2" % [jsonName, filename]
      # echo cmd
      exec cmd
      let text = slurp(jsonName)
      for line in text.splitLines():
        echo line
      break
  # echo ""
  # echo "The jq command is good for viewing the output."
  # echo "n json name | jq | less"

task jsonix, "\tDisplay markdown docs index json.":
  var json = sourceIndexJson()
  # writeFile("docs/index.json", json)
  for line in json.splitLines():
    echo line

task stfix, "\tDisplay markdown testfiles index json.":
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
  http://localhost:6419/docs/staticteadep.svg
"""

task dot2, "\tCreate a dependency graph of the system modules used by StaticTea.":
  createDependencyGraph2()

  echoGrip()
  echo """
View the svg file in your browser:
  http://localhost:6419/docs/staticteadep2.svg
"""

task tt, "\tCompile and run t.nim.":
  let cmd = "nim c -r --hints:off --outdir:bin/tests/ src/t.nim"
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

# task stf, "\tList stf tests with newest last.":
#   exec """ls -1tr testfiles/*.stf | xargs grep "##" | cut -c 11- | sed 's/:## / -- /'"""

task stfrm, "\tCreate testfiles readme.md.":
  taskTestfilesReadme()

task newstf, "\tCreate new stf as a starting point for a new test.":
  let count = system.paramCount()+1
  var name = system.paramStr(count-1)
  if name == "newstf":
    echo "Specify a name for a new stf test file."
  else:
    var (_, basename) = splitPath(name)
    if "." in basename:
      echo "Specify a name without an extension."
    else:
      var filename = joinPath("testfiles", basename & ".stf.md")
      if fileExists(filename):
        echo "File already exists: $1" % filename
      else:
        let cmd = "cp testfiles/template.stf.md $1" % filename
        echo cmd
        exec cmd

task runhelp, "\tShow the runner help text with glow.":
  exec "bin/runner -h | glow -"

task helpme, "\tShow the statictea help text.":
  exec "bin/statictea -h | less"

task remote, "\tCheck whether the remote code needs updating.":
  checkUtf8DecoderEcho()

task cmdline, "\tBuild cmdline.":
  let part1 = "nim c --hint[Performance]:off "
  let part2 = "--hint[Conf]:off --hint[Link]: off -d:release "
  let part3 = "--out:bin/ src/cmdline"
  var cmd = part1 & part2 & part3
  echo cmd
  exec cmd
  echo "Run bin/cmdline"

task release, "\tRun tests and update docs.":
  runUnitTests()
  otherTests()
  taskDocsIx()
  taskDocs("")
  taskReadMeFun()
  taskTestfilesReadme()
  createDependencyGraph()
  createDependencyGraph2()

const
  image = "statictea-image"
  container = "statictea-container"

task drun, "\tRun a statictea debian docker build env.":
  let statusCmd = fmt"docker inspect {image} 2>/dev/null | grep 'Id'"
  # echo statusCmd
  let (status, statusRc) = gorgeEx(statusCmd)
  # echo status
  if "sha256" in status:
    echo fmt"The {image} exists."
  else:
    echo fmt"The {image} does not exist, creating it..."

    let buildCmd = fmt"docker build --tag={image} env/debian/."
    # echo buildCmd

    exec buildCmd

    echo ""
    echo "If no errors, run drun again to run the container."
    quit(1)
    exit()

  let containerCmd = fmt"docker inspect {container} 2>/dev/null | grep Status"
  let (containerStatus, rc2) = gorgeEx(containerCmd)
  # echo containerStatus
  if "running" in containerStatus:
    echo fmt"The {container} is running, attaching to it..."
    let attachCmd = fmt"docker attach {container}"
    exec attachCmd
  elif "exited" in containerStatus:
    echo fmt"The {container} exists but its not running, starting it..."
    let runCmd = fmt"docker start -ai {container}"
    exec runCmd
  else:
    echo fmt"The {container} does not exist, creating it..."
    # todo: get statictea the folder dynamically.
    let staticteaFolder = "/Users/steve/code/statictea"
    let shared_option = fmt"-v {staticteaFolder}:/home/teamaster/statictea"
    let createCmd = fmt"docker run --name={container} -it {shared_option} {image}"
    exec createCmd

task ddelete, "\tDelete the statictea docker image and container.":
  let cmd = fmt"docker rm {container}; docker image rm {image}"
  # echo cmd
  let (output, rc) = gorgeEx(cmd)
  echo output

task dlist, "\tList the docker image and container.":
  let cmd = fmt"docker inspect {image} 2>/dev/null | grep 'Id'"
  # echo cmd
  let (imageStatus, rc) = gorgeEx(cmd)
  # echo imageStatus
  if "sha256" in imageStatus:
    echo fmt"The {image} exists."
  else:
    echo fmt"No {image}."

  let cmd2=fmt"docker inspect {container} 2>/dev/null | grep Status"
  let (containerStatus, rc2) = gorgeEx(cmd2)
  # echo containerStatus
  if "running" in containerStatus:
    echo fmt"The {container} is running."
  elif "exited" in containerStatus:
    echo fmt"The {container} is stopped."
  else:
    echo fmt"No {container}."
